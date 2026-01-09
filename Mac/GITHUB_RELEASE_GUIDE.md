# GitHub Releases 업로드 가이드

## 방법 1: 웹 브라우저에서 (가장 쉬움)

### 1단계: GitHub 저장소로 이동
1. 브라우저에서 https://github.com/Badasugi/badasugi 로 이동
2. 로그인 (필요시)

### 2단계: Release 생성
1. 저장소 페이지에서 오른쪽 사이드바의 **"Releases"** 클릭
   - 또는 직접 https://github.com/Badasugi/badasugi/releases 로 이동
2. **"Create a new release"** 또는 **"Draft a new release"** 버튼 클릭

### 3단계: Release 정보 입력
- **Tag version**: `v1.0.0` (또는 원하는 버전 번호)
  - 처음이면 "Create new tag: v1.0.0" 선택
- **Release title**: `Badasugi v1.0.0` (또는 원하는 제목)
- **Description**: 
  ```markdown
  ## 첫 번째 공식 릴리스 🎉
  
  ### 주요 기능
  - 7일 무료 체험
  - 로컬 및 클라우드 음성 인식
  - 한국어 최적화
  
  ### ⚠️ 중요: macOS 보안 경고 해결 방법
  
  다운로드 후 실행 시 "Apple could not verify 'Badasugi' is free of malware" 경고가 나타날 수 있습니다.
  
  **설치 방법:**
  1. DMG를 열고 Badasugi.app을 Applications 폴더로 드래그
  2. Finder에서 Applications 폴더 열기
  3. **⌃ Control 키를 누른 채로 Badasugi 앱 클릭**
  4. "열기" 선택 후 다시 "열기" 클릭
  
  자세한 설치 가이드: [INSTALLATION.md](https://github.com/Badasugi/badasugi/blob/main/INSTALLATION.md)
  
  ### 다운로드
  DMG 파일을 다운로드하여 설치하세요.
  ```

### 4단계: DMG 파일 업로드
1. **"Attach binaries by dropping them here"** 영역에 `Mac/build/Badasugi.dmg` 파일을 드래그 앤 드롭
   - 또는 **"Choose your files"** 클릭하여 파일 선택

### 5단계: 발행
- **"Publish release"** 버튼 클릭

완료! 이제 다운로드 URL이 생성됩니다:
```
https://github.com/Badasugi/badasugi/releases/latest/download/Badasugi.dmg
```

---

## 방법 2: GitHub CLI 사용 (고급)

```bash
# GitHub CLI 설치 (없는 경우)
brew install gh

# 로그인
gh auth login

# Release 생성 및 파일 업로드
cd Mac
gh release create v1.0.0 \
  build/Badasugi.dmg \
  --title "Badasugi v1.0.0" \
  --notes "첫 번째 공식 릴리스"
```

---

## 다음 단계
Release가 생성되면 웹사이트의 다운로드 링크를 업데이트하세요!

