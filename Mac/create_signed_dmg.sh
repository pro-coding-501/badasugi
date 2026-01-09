#!/bin/bash

# Badasugi Code Signed DMG 생성 및 Notarization 스크립트
# 사용법: ./create_signed_dmg.sh
# 
# 사전 요구사항:
# 1. Apple Developer Program 가입 완료 (승인 필요)
# 2. Xcode에서 자동 서명 설정 확인
# 3. App-specific password 생성 (Notarization용)

set -e

echo "🚀 Badasugi Code Signed DMG 생성 및 Notarization 시작..."

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

# 1. Apple Developer 계정 확인
echo -e "${BLUE}🔐 Apple Developer 계정 확인 중...${NC}"
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo -e "${YELLOW}⚠️  Developer ID 인증서를 찾을 수 없습니다.${NC}"
    echo -e "${YELLOW}   Xcode > Preferences > Accounts에서 인증서를 생성하세요.${NC}"
    echo -e "${YELLOW}   또는 다음 명령어로 확인: security find-identity -v -p codesigning${NC}"
    exit 1
fi

DEVELOPER_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')
echo -e "${GREEN}✅ Developer ID 인증서 발견: ${DEVELOPER_ID}${NC}"

# 2. 빌드 디렉토리 생성
echo -e "${YELLOW}📁 빌드 디렉토리 생성 중...${NC}"
mkdir -p "${BUILD_DIR}"

# 3. Archive 생성 (Code Signing 포함)
echo -e "${YELLOW}📦 Archive 생성 중 (Code Signing 포함)...${NC}"
xcodebuild archive \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${ARCHIVE_PATH}" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-AUNHQZL489}"

# 4. 앱이 생성되었는지 확인
if [ ! -d "${APP_PATH}" ]; then
    echo -e "${RED}❌ 앱을 찾을 수 없습니다: ${APP_PATH}${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archive 생성 완료: ${ARCHIVE_PATH}${NC}"

# 5. 앱 서명 확인
echo -e "${BLUE}🔍 앱 서명 확인 중...${NC}"
codesign -dv --verbose=4 "${APP_PATH}" 2>&1 | grep -E "Authority|Identifier|Format" || true
codesign --verify --verbose "${APP_PATH}" || {
    echo -e "${RED}❌ 앱 서명 검증 실패${NC}"
    exit 1
}
echo -e "${GREEN}✅ 앱 서명 확인 완료${NC}"

# 6. DMG 디렉토리 준비
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

3. 이제 보안 경고 없이 바로 실행됩니다! 🎉

7일 무료 체험을 시작하세요!
INSTALL_GUIDE

# 7. DMG 생성 (읽기/쓰기 가능한 형태로 먼저 생성)
echo -e "${YELLOW}💿 DMG 파일 생성 중...${NC}"
DMG_RW_PATH="${BUILD_DIR}/${PROJECT_NAME}_rw.dmg"
hdiutil create -volname "${PROJECT_NAME}" \
    -srcfolder "${DMG_TEMP_DIR}" \
    -ov \
    -format UDRW \
    -fs HFS+ \
    "${DMG_RW_PATH}"

# 8. DMG 마운트
echo -e "${YELLOW}📌 DMG 마운트 중...${NC}"
MOUNT_DIR="/Volumes/${PROJECT_NAME}"
hdiutil attach -readwrite -noverify -noautoopen "${DMG_RW_PATH}" > /dev/null

# 잠시 대기 (마운트 완료 대기)
sleep 2

# 9. DMG 창 설정 및 아이콘 배치
echo -e "${YELLOW}🎨 DMG 창 설정 중...${NC}"

# 아이콘 위치 설정
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

# 10. DMG 언마운트
echo -e "${YELLOW}📌 DMG 언마운트 중...${NC}"
hdiutil detach "${MOUNT_DIR}" > /dev/null

# 11. 최종 DMG 생성 (압축된 읽기 전용)
echo -e "${YELLOW}💿 최종 DMG 파일 생성 중...${NC}"
hdiutil convert "${DMG_RW_PATH}" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${DMG_PATH}"

# 12. DMG 서명
echo -e "${BLUE}🔐 DMG 서명 중...${NC}"
codesign --force --verify --verbose --sign "${DEVELOPER_ID}" "${DMG_PATH}" || {
    echo -e "${RED}❌ DMG 서명 실패${NC}"
    exit 1
}
echo -e "${GREEN}✅ DMG 서명 완료${NC}"

# 13. Notarization (선택사항 - App-specific password 필요)
echo -e "${BLUE}📤 Notarization 진행 중...${NC}"
echo -e "${YELLOW}   App-specific password가 필요합니다.${NC}"
echo -e "${YELLOW}   https://appleid.apple.com > Sign-In and Security > App-Specific Passwords${NC}"
read -p "App-specific password를 입력하세요 (또는 Enter로 건너뛰기): " APP_PASSWORD

if [ -n "$APP_PASSWORD" ]; then
    # Notarization 제출
    echo -e "${YELLOW}📤 Apple에 제출 중...${NC}"
    NOTARIZATION_UUID=$(xcrun notarytool submit "${DMG_PATH}" \
        --apple-id "${APPLE_ID:-$(git config user.email)}" \
        --password "${APP_PASSWORD}" \
        --team-id "${DEVELOPMENT_TEAM:-AUNHQZL489}" \
        --wait \
        --timeout 30m 2>&1 | grep -i "id:" | awk '{print $NF}' || echo "")
    
    if [ -n "$NOTARIZATION_UUID" ]; then
        echo -e "${GREEN}✅ Notarization 완료: ${NOTARIZATION_UUID}${NC}"
        
        # Notarization 스테이플링
        echo -e "${YELLOW}📎 스테이플링 중...${NC}"
        xcrun stapler staple "${DMG_PATH}" || {
            echo -e "${YELLOW}⚠️  스테이플링 실패 (수동으로 진행 가능)${NC}"
        }
        echo -e "${GREEN}✅ 스테이플링 완료${NC}"
    else
        echo -e "${YELLOW}⚠️  Notarization 제출 실패 (나중에 수동으로 진행 가능)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Notarization 건너뛰기 (나중에 수동으로 진행 가능)${NC}"
    echo -e "${YELLOW}   수동 Notarization: xcrun notarytool submit ${DMG_PATH} --apple-id YOUR_EMAIL --password APP_PASSWORD --team-id AUNHQZL489${NC}"
fi

# 14. 정리
echo -e "${YELLOW}🧹 임시 파일 정리 중...${NC}"
rm -f "${DMG_RW_PATH}"
rm -rf "${DMG_TEMP_DIR}"

# 15. 완료
if [ -f "${DMG_PATH}" ]; then
    DMG_SIZE=$(du -h "${DMG_PATH}" | cut -f1)
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Code Signed DMG 파일 생성 완료!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}📦 파일 위치: ${DMG_PATH}${NC}"
    echo -e "${GREEN}📊 파일 크기: ${DMG_SIZE}${NC}"
    echo ""
    echo "다음 단계:"
    echo "1. DMG 파일을 테스트해보세요: open ${DMG_PATH}"
    echo "2. GitHub Releases에 업로드하세요"
    echo "3. 웹사이트 다운로드 링크가 자동으로 작동합니다"
    echo ""
else
    echo -e "${RED}❌ DMG 파일 생성 실패${NC}"
    exit 1
fi

