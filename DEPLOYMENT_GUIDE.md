# 받아쓰기 서비스 배포 가이드

이 문서는 받아쓰기 서비스를 실제로 배포하는 방법을 설명합니다.

## 📋 배포 전 체크리스트

### 1. SendGrid 설정 (이메일 발송용)
- [ ] SendGrid 계정 생성 (https://sendgrid.com)
- [ ] API 키 발급 (Settings > API Keys > Create API Key)
- [ ] 발신자 이메일 인증 (Settings > Sender Authentication)
- [ ] `badasugi.app@gmail.com` 발신자로 등록

### 2. 토스페이먼츠 설정 (결제용)
- [ ] 토스페이먼츠 가입 (https://developers.tosspayments.com)
- [ ] 사업자등록번호 등록 및 승인 대기
- [ ] 승인 완료 후 라이브 키 발급

---

## 🚀 서버 배포 방법

### 옵션 1: Railway (추천)

1. **Railway 계정 생성**
   - https://railway.app 접속
   - GitHub 계정으로 로그인

2. **새 프로젝트 생성**
   ```bash
   # Railway CLI 설치
   npm install -g @railway/cli
   
   # 로그인
   railway login
   
   # 프로젝트 초기화
   cd Server
   railway init
   
   # 배포
   railway up
   ```

3. **환경변수 설정**
   Railway 대시보드 > Variables 메뉴에서:
   - `SENDGRID_API_KEY`: SendGrid API 키
   - `EMAIL_FROM`: badasugi.app@gmail.com
   - `TOSS_SECRET_KEY`: 토스페이먼츠 시크릿 키

4. **커스텀 도메인 연결**
   - Settings > Domains에서 `api.badasugi.com` 연결
   - DNS에 CNAME 레코드 추가

### 옵션 2: Render

1. **Render 계정 생성**
   - https://render.com 접속
   - GitHub 연동

2. **새 Web Service 생성**
   - New > Web Service
   - GitHub 저장소의 Server 폴더 선택

3. **환경변수 설정**
   Environment Variables에서 동일하게 설정

### 옵션 3: Vercel (서버리스)

1. **Vercel 계정 생성**
   - https://vercel.com 접속

2. **프로젝트 배포**
   ```bash
   cd Server
   npx vercel
   ```

---

## 🔧 환경변수 설정

| 변수명 | 설명 | 예시 |
|--------|------|------|
| `PORT` | 서버 포트 | `3001` |
| `SENDGRID_API_KEY` | SendGrid API 키 | `SG.xxx...` |
| `EMAIL_FROM` | 발신자 이메일 | `badasugi.app@gmail.com` |
| `TOSS_SECRET_KEY` | 토스페이먼츠 시크릿 키 | `test_sk_...` 또는 `live_sk_...` |

---

## 📱 웹사이트 배포

### GitHub Pages (추천)

1. **저장소 설정**
   - Repository > Settings > Pages
   - Source: Deploy from a branch
   - Branch: main / Website 폴더

2. **커스텀 도메인**
   - `www.badasugi.com` 연결
   - DNS에 CNAME 레코드 추가

### Vercel/Netlify

1. **배포**
   ```bash
   cd Website
   npx vercel
   # 또는
   npx netlify deploy --prod
   ```

---

## 🔐 토스페이먼츠 승인 후 체크리스트

토스페이먼츠 사업자등록 승인이 완료되면:

### 1. 서버 변경 (.env)
```bash
# 테스트 키를 주석 처리
# TOSS_SECRET_KEY=test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R

# 라이브 키로 교체
TOSS_SECRET_KEY=live_sk_xxxxxxxxxxxxxxxxxxxxxxxx
```

### 2. 웹사이트 변경 (index.html)
```javascript
// 1369번째 줄 근처
// 테스트 키를 라이브 키로 교체
const TOSS_CLIENT_KEY = 'live_ck_xxxxxxxxxxxxxxxxxxxxxxxx';
```

### 3. API URL 확인 (index.html)
```javascript
// 1352번째 줄 근처
// 프로덕션 URL이 올바른지 확인
const API_BASE_URL = 'https://api.badasugi.com';
```

---

## 🧪 테스트 방법

### 1. 서버 테스트
```bash
# 서버 상태 확인
curl https://api.badasugi.com/api/health

# 응답 예시
{"status":"ok","timestamp":"2026-01-09T...","service":"badasugi-license-server"}
```

### 2. 라이선스 발급 테스트
```bash
# 테스트 라이선스 발급
curl -X POST https://api.badasugi.com/api/test/license \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","quantity":1}'
```

### 3. 결제 테스트 (토스페이먼츠 테스트 모드)
- 웹사이트에서 구매 버튼 클릭
- 테스트 카드 정보 입력:
  - 카드번호: 4330-0000-0000-0000
  - 유효기간: 아무 미래 날짜
  - CVC: 아무 3자리

---

## 📞 문의

배포 관련 문의사항은 badasugi.app@gmail.com으로 연락주세요.

