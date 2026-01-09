# 📦 GitHub 저장소 설정 가이드

받아쓰기 프로젝트를 GitHub에 업로드하고 배포 설정하는 방법입니다.

---

## Step 1: GitHub 저장소 생성

### 1. GitHub에서 새 저장소 생성

1. https://github.com 접속 및 로그인
2. 우측 상단 **"+"** > **"New repository"** 클릭
3. 설정:
   - **Repository name**: `badasugi`
   - **Description**: `받아쓰기 - 한국 전용 음성 인식 서비스`
   - **Visibility**: `Public` (또는 Private)
   - **Initialize this repository with**: 체크 해제 (이미 로컬에 코드가 있음)
4. **"Create repository"** 클릭

### 2. 저장소 이름 확인

생성된 저장소 URL이 `https://github.com/YOUR_USERNAME/badasugi` 형식인지 확인하세요.

**중요:** 웹사이트와 서버 코드에서 `Badasugi/badasugi`로 참조하고 있으므로, 
- 사용자명이 `Badasugi`가 아니면 나중에 수정 필요합니다.
- 또는 GitHub Organization `Badasugi`를 생성하고 그 안에 저장소를 만들 수도 있습니다.

---

## Step 2: 로컬 저장소 초기화 및 업로드

터미널에서 실행:

```bash
# 프로젝트 루트로 이동
cd /Users/hyeinyu/Desktop/badasugi_test/badasugi

# Git 초기화 (이미 되어있으면 생략)
git init

# .gitignore 확인 (필요한 파일 제외)
cat .gitignore

# 모든 파일 추가
git add .

# 첫 커밋
git commit -m "Initial commit: 받아쓰기 서비스"

# GitHub 저장소 연결 (YOUR_USERNAME을 실제 사용자명으로 변경)
git remote add origin https://github.com/YOUR_USERNAME/badasugi.git

# 또는 SSH 사용 시
# git remote add origin git@github.com:YOUR_USERNAME/badasugi.git

# 메인 브랜치 설정
git branch -M main

# 업로드
git push -u origin main
```

---

## Step 3: GitHub Release 생성 (DMG 다운로드용)

웹사이트에서 DMG 파일을 다운로드하려면 GitHub Release가 필요합니다.

### 방법 1: GitHub 웹사이트에서

1. 저장소 페이지에서 **"Releases"** 클릭
2. **"Create a new release"** 클릭
3. 설정:
   - **Tag version**: `v1.0.0`
   - **Release title**: `받아쓰기 v1.0.0`
   - **Description**: 
     ```
     받아쓰기 첫 번째 정식 버전
     
     ## 주요 기능
     - 한국어 음성 인식
     - 7일 무료 체험
     - 라이선스 키 활성화
     ```
   - **Attach binaries**: `Mac/build/Badasugi.dmg` 파일 업로드
4. **"Publish release"** 클릭

### 방법 2: GitHub CLI 사용 (터미널)

```bash
# GitHub CLI 설치 (없으면)
brew install gh

# 로그인
gh auth login

# Release 생성 및 DMG 업로드
gh release create v1.0.0 \
  Mac/build/Badasugi.dmg \
  --title "받아쓰기 v1.0.0" \
  --notes "받아쓰기 첫 번째 정식 버전"
```

---

## Step 4: 웹사이트 코드 수정 (저장소 이름 확인)

만약 GitHub 사용자명이 `Badasugi`가 아니라면, 웹사이트의 다운로드 링크를 수정해야 합니다.

**파일:** `Website/index.html`

다음 부분들을 찾아서 수정:

```javascript
// 606번째 줄, 631번째 줄, 1047번째 줄 근처
// 변경 전
href="https://github.com/Badasugi/badasugi/releases/latest/download/Badasugi.dmg"

// 변경 후 (YOUR_USERNAME을 실제 사용자명으로)
href="https://github.com/YOUR_USERNAME/badasugi/releases/latest/download/Badasugi.dmg"
```

**검색 및 일괄 변경:**
```bash
# 터미널에서 실행 (YOUR_USERNAME을 실제 사용자명으로 변경)
cd Website
sed -i '' 's/Badasugi\/badasugi/YOUR_USERNAME\/badasugi/g' index.html
```

---

## Step 5: appcast.xml 수정 (자동 업데이트용)

Mac 앱의 자동 업데이트를 위해 `appcast.xml`도 수정:

**파일:** `Mac/appcast.xml` (19번째 줄)

```xml
<!-- 변경 전 -->
<enclosure url="https://github.com/Badasugi/badasugi/releases/download/v1.64/Badasugi.dmg" .../>

<!-- 변경 후 (YOUR_USERNAME으로) -->
<enclosure url="https://github.com/YOUR_USERNAME/badasugi/releases/download/v1.64/Badasugi.dmg" .../>
```

---

## Step 6: GitHub Pages 설정 (웹사이트 배포)

웹사이트를 GitHub Pages로 배포하려면:

1. 저장소 **Settings** > **Pages** 클릭
2. **Source**: `Deploy from a branch` 선택
3. **Branch**: `main` / `/Website` 폴더 선택
4. **Save** 클릭

배포 완료 후 URL: `https://YOUR_USERNAME.github.io/badasugi/`

**또는 커스텀 도메인:**
- **Custom domain**: `www.badasugi.com` 입력
- DNS에 CNAME 레코드 추가:
  ```
  www.badasugi.com → YOUR_USERNAME.github.io
  ```

---

## ✅ 체크리스트

- [ ] GitHub 저장소 생성 완료
- [ ] 코드 업로드 완료
- [ ] GitHub Release 생성 및 DMG 업로드 완료
- [ ] 웹사이트 다운로드 링크 수정 완료 (필요시)
- [ ] appcast.xml 수정 완료 (필요시)
- [ ] GitHub Pages 배포 완료 (선택사항)

---

## 📝 다음 단계

GitHub 설정 완료 후:
1. ✅ 서버 배포 (Railway 또는 Render) - `SERVER_DEPLOYMENT.md` 참조
2. ✅ 웹사이트에 서버 URL 적용
3. ⏳ Apple Developer 승인 대기
4. ⏳ 토스페이먼츠 사업자등록 승인 대기

---

## 🔗 참고

- GitHub 저장소: `https://github.com/YOUR_USERNAME/badasugi`
- Release 다운로드: `https://github.com/YOUR_USERNAME/badasugi/releases/latest/download/Badasugi.dmg`
- 웹사이트: `https://YOUR_USERNAME.github.io/badasugi/` (GitHub Pages 사용 시)

