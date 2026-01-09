#!/bin/bash

# Badasugi DMG 생성 스크립트
# 사용법: ./create_dmg.sh

set -e

echo "🚀 Badasugi DMG 파일 생성 시작..."

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 프로젝트 정보
PROJECT_NAME="Badasugi"
SCHEME_NAME="Badasugi"
CONFIGURATION="Release"
APP_NAME="${PROJECT_NAME}.app"
DMG_NAME="${PROJECT_NAME}.dmg"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${PROJECT_NAME}/Info.plist" 2>/dev/null || echo "1.0.0")

# 빌드 디렉토리
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
APP_PATH="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"

# 1. 빌드 디렉토리 생성
echo -e "${YELLOW}📁 빌드 디렉토리 생성 중...${NC}"
mkdir -p "${BUILD_DIR}"

# 2. Archive 생성
echo -e "${YELLOW}📦 Archive 생성 중...${NC}"
xcodebuild archive \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${ARCHIVE_PATH}" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# 3. 앱이 생성되었는지 확인
if [ ! -d "${APP_PATH}" ]; then
    echo -e "${RED}❌ 앱을 찾을 수 없습니다: ${APP_PATH}${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archive 생성 완료: ${ARCHIVE_PATH}${NC}"

# 4. DMG 디렉토리 준비
echo -e "${YELLOW}📦 DMG 준비 중...${NC}"
DMG_TEMP_DIR="${BUILD_DIR}/dmg_temp"
rm -rf "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}"

# 앱 복사
cp -R "${APP_PATH}" "${DMG_TEMP_DIR}/"

# 설치 안내 텍스트 파일 생성
cat > "${DMG_TEMP_DIR}/설치 방법.txt" <<'INSTALL_GUIDE'
받아쓰기 설치 방법

1. Badasugi.app을 Applications 폴더로 드래그하세요
   (Finder 사이드바의 Applications 폴더로 드래그)

2. 설치 후 Applications 폴더에서 받아쓰기를 실행하세요

3. 처음 실행 시 보안 경고가 나타날 수 있습니다:
   - 시스템 설정 > 개인정보 보호 및 보안으로 이동
   - "확인 없이 열기" 버튼 클릭

7일 무료 체험을 시작하세요!
INSTALL_GUIDE

# 5. DMG 생성 (읽기/쓰기 가능한 형태로 먼저 생성)
echo -e "${YELLOW}💿 DMG 파일 생성 중...${NC}"
DMG_RW_PATH="${BUILD_DIR}/${PROJECT_NAME}_rw.dmg"
hdiutil create -volname "${PROJECT_NAME}" \
    -srcfolder "${DMG_TEMP_DIR}" \
    -ov \
    -format UDRW \
    -fs HFS+ \
    "${DMG_RW_PATH}"

# 6. DMG 마운트
echo -e "${YELLOW}📌 DMG 마운트 중...${NC}"
MOUNT_DIR="/Volumes/${PROJECT_NAME}"
hdiutil attach -readwrite -noverify -noautoopen "${DMG_RW_PATH}" > /dev/null

# 잠시 대기 (마운트 완료 대기)
sleep 2

# 7. DMG 창 설정 및 아이콘 배치
echo -e "${YELLOW}🎨 DMG 창 설정 중...${NC}"

# 아이콘 위치 설정
# Badasugi.app: 왼쪽 상단
# 설치 방법.txt: 오른쪽 상단
/usr/bin/osascript <<EOF
tell application "Finder"
    tell disk "${PROJECT_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 920, 420}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set position of item "${APP_NAME}" to {200, 100}
        set position of item "설치 방법.txt" to {400, 100}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# 8. DMG 언마운트
echo -e "${YELLOW}📌 DMG 언마운트 중...${NC}"
hdiutil detach "${MOUNT_DIR}" > /dev/null

# 9. 최종 DMG 생성 (압축된 읽기 전용)
echo -e "${YELLOW}💿 최종 DMG 파일 생성 중...${NC}"
hdiutil convert "${DMG_RW_PATH}" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${DMG_PATH}"

# 10. 정리
echo -e "${YELLOW}🧹 임시 파일 정리 중...${NC}"
rm -f "${DMG_RW_PATH}"
rm -rf "${DMG_TEMP_DIR}"

# 7. 완료
if [ -f "${DMG_PATH}" ]; then
    DMG_SIZE=$(du -h "${DMG_PATH}" | cut -f1)
    echo -e "${GREEN}✅ DMG 파일 생성 완료!${NC}"
    echo -e "${GREEN}📦 파일 위치: ${DMG_PATH}${NC}"
    echo -e "${GREEN}📊 파일 크기: ${DMG_SIZE}${NC}"
    echo ""
    echo "다음 단계:"
    echo "1. DMG 파일을 테스트해보세요: open ${DMG_PATH}"
    echo "2. GitHub Releases에 업로드하세요"
    echo "3. 웹사이트 다운로드 링크를 업데이트하세요"
else
    echo -e "${RED}❌ DMG 파일 생성 실패${NC}"
    exit 1
fi

