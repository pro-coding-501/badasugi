# 🚀 서버 배포 가이드

받아쓰기 라이선스 서버를 배포하는 방법입니다. **Railway** 또는 **Render** 중 하나를 선택하세요.

---

## 방법 1: Railway (추천) ⭐

Railway는 가장 간단하고 빠르게 배포할 수 있습니다.

### Step 1: Railway 계정 생성

1. https://railway.app 접속
2. **"Start a New Project"** 클릭
3. GitHub 계정으로 로그인 (또는 이메일로 가입)

### Step 2: 프로젝트 생성

1. **"Deploy from GitHub repo"** 선택
2. `Badasugi/badasugi` 저장소 선택
3. **"Root Directory"** 설정:
   - `Server` 폴더 선택
   - (또는 "Add Service" > "GitHub Repo" > "Server" 폴더 선택)

### Step 3: 환경변수 설정

Railway 대시보드에서 **Variables** 탭 클릭 후 다음 변수 추가:

| 변수명 | 값 | 설명 |
|--------|-----|------|
| `PORT` | `3001` | 서버 포트 (Railway가 자동 설정하지만 명시) |
| `SENDGRID_API_KEY` | `SG.xxxxx...` | SendGrid API 키 (이미 발급받으셨음) |
| `EMAIL_FROM` | `badasugi.app@gmail.com` | 발신자 이메일 |
| `TOSS_SECRET_KEY` | `test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R` | 토스페이먼츠 테스트 키 (나중에 라이브 키로 변경) |

### Step 4: 서버 URL 확인

배포 완료 후:
1. **Settings** 탭 클릭
2. **"Generate Domain"** 클릭 (또는 자동 생성됨)
3. 생성된 URL 확인 (예: `badasugi-license-server-production.up.railway.app`)

### Step 5: 커스텀 도메인 설정 (선택사항)

나중에 `api.badasugi.com`으로 연결하려면:
1. **Settings** > **"Custom Domain"**
2. `api.badasugi.com` 입력
3. DNS에 CNAME 레코드 추가:
   ```
   api.badasugi.com → badasugi-license-server-production.up.railway.app
   ```

---

## 방법 2: Render

Render도 무료 플랜이 있고 간단합니다.

### Step 1: Render 계정 생성

1. https://render.com 접속
2. GitHub 계정으로 로그인

### Step 2: 새 Web Service 생성

1. **"New +"** > **"Web Service"** 클릭
2. GitHub 저장소 연결: `Badasugi/badasugi`
3. 설정:
   - **Name**: `badasugi-license-server`
   - **Root Directory**: `Server`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`

### Step 3: 환경변수 설정

**Environment Variables** 섹션에서:

| 변수명 | 값 |
|--------|-----|
| `PORT` | `3001` |
| `SENDGRID_API_KEY` | `SG.xxxxx...` |
| `EMAIL_FROM` | `badasugi.app@gmail.com` |
| `TOSS_SECRET_KEY` | `test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R` |

### Step 4: 배포 및 URL 확인

1. **"Create Web Service"** 클릭
2. 배포 완료 후 URL 확인 (예: `badasugi-license-server.onrender.com`)

---

## ✅ 배포 확인

서버가 정상 작동하는지 확인:

```bash
# 서버 상태 확인
curl https://YOUR_SERVER_URL/api/health

# 예상 응답:
# {"status":"ok","timestamp":"2026-01-09T...","service":"badasugi-license-server"}
```

---

## 🔧 웹사이트에 서버 URL 적용

서버 배포 후 받은 URL을 웹사이트에 적용해야 합니다.

**파일:** `Website/index.html` (1354번째 줄)

```javascript
// 변경 전
const API_BASE_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:3001'
    : 'https://api.badasugi.com'; // 프로덕션 URL로 변경 필요

// 변경 후 (실제 서버 URL로 교체)
const API_BASE_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:3001'
    : 'https://YOUR_SERVER_URL'; // ← 여기에 실제 서버 URL 입력
```

**예시:**
- Railway: `https://badasugi-license-server-production.up.railway.app`
- Render: `https://badasugi-license-server.onrender.com`

---

## 💰 비용

### Railway
- 무료 플랜: 월 $5 크레딧 (충분함)
- 사용량 초과 시: $5/월

### Render
- 무료 플랜: 15분 비활성 시 슬리프 모드 (첫 요청 시 깨어남)
- 유료 플랜: $7/월 (항상 켜져있음)

**추천:** Railway (무료 플랜으로 충분)

---

## 🐛 문제 해결

### 배포 실패
- `package.json`에 `start` 스크립트가 있는지 확인
- 환경변수가 모두 설정되었는지 확인

### 서버가 응답하지 않음
- `/api/health` 엔드포인트로 확인
- Railway/Render 로그 확인

### 이메일 전송 실패
- SendGrid API 키 확인
- SendGrid 발신자 이메일 인증 확인

---

## 📝 다음 단계

서버 배포 완료 후:
1. ✅ 서버 URL을 웹사이트에 적용 (`Website/index.html`)
2. ✅ 웹사이트 배포 (GitHub Pages, Vercel, Netlify 등)
3. ⏳ Apple Developer 승인 대기
4. ⏳ 토스페이먼츠 사업자등록 승인 대기

