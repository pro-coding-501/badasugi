# 받아쓰기 라이선스 서버

토스페이먼츠 결제 승인 후 라이선스 키를 자동으로 발급하고 SendGrid를 통해 사용자 이메일로 전송하는 서버입니다.

## ✨ 주요 기능

- **토스페이먼츠 결제 승인**: 웹사이트에서 결제 후 자동 승인 처리
- **자체 라이선스 시스템**: 라이선스 키 생성, 검증, 활성화 관리
- **이메일 자동 발송**: SendGrid를 통한 라이선스 키 이메일 전송
- **디바이스 활성화 관리**: 라이선스 당 활성화 기기 수 제한

## 🚀 빠른 시작

### 1. 의존성 설치

```bash
npm install
```

### 2. 환경 변수 설정

```bash
cp env.example .env
```

`.env` 파일을 열어 필요한 값들을 설정:

```bash
# 서버 포트
PORT=3001

# SendGrid (이메일 발송)
SENDGRID_API_KEY=SG.xxxxx
EMAIL_FROM=badasugi.app@gmail.com

# 토스페이먼츠 (결제)
# 테스트 키 (사업자등록 승인 전)
TOSS_SECRET_KEY=test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R
# 라이브 키 (사업자등록 승인 후)
# TOSS_SECRET_KEY=live_sk_xxxxxxx
```

### 3. 서버 실행

```bash
# 개발 모드 (자동 재시작)
npm run dev

# 프로덕션 모드
npm start
```

서버가 `http://localhost:3001`에서 실행됩니다.

## 📡 API 엔드포인트

### 결제 관련

| Method | Endpoint | 설명 |
|--------|----------|------|
| `POST` | `/api/payment/confirm` | 토스페이먼츠 결제 승인 및 라이선스 발급 |
| `POST` | `/api/purchase/complete` | 결제 완료 처리 (테스트용) |
| `POST` | `/api/test/license` | 테스트 라이선스 발급 |

### 라이선스 관련

| Method | Endpoint | 설명 |
|--------|----------|------|
| `POST` | `/api/license/validate` | 라이선스 키 검증 |
| `POST` | `/api/license/activate` | 라이선스 디바이스 활성화 |
| `POST` | `/api/license/deactivate` | 라이선스 디바이스 비활성화 |

### 시스템

| Method | Endpoint | 설명 |
|--------|----------|------|
| `GET` | `/api/health` | 서버 상태 확인 |

## 📖 API 상세

### 토스페이먼츠 결제 승인

**POST** `/api/payment/confirm`

```json
// 요청
{
  "paymentKey": "토스페이먼츠_결제키",
  "orderId": "BADASUGI_1234567890_abc",
  "amount": 29000,
  "email": "user@example.com",
  "quantity": 1
}

// 응답 (성공)
{
  "success": true,
  "message": "결제가 완료되었습니다. 라이선스 키가 이메일로 전송되었습니다.",
  "orderId": "BADASUGI_1234567890_abc",
  "email": "user@example.com",
  "quantity": 1
}
```

### 라이선스 검증

**POST** `/api/license/validate`

```json
// 요청
{
  "licenseKey": "BADA-XXXXX-XXXX-XXXX"
}

// 응답 (성공)
{
  "success": true,
  "message": "유효한 라이선스 키입니다.",
  "activeDevices": 1,
  "maxDevices": 3,
  "email": "user@example.com"
}
```

### 라이선스 활성화

**POST** `/api/license/activate`

```json
// 요청
{
  "licenseKey": "BADA-XXXXX-XXXX-XXXX",
  "deviceId": "unique-device-id",
  "deviceName": "MacBook Pro"
}

// 응답 (성공)
{
  "success": true,
  "message": "라이선스가 성공적으로 활성화되었습니다.",
  "activeDevices": 1,
  "maxDevices": 3
}
```

## 🔧 SendGrid 설정

1. [SendGrid](https://sendgrid.com)에서 무료 계정 생성
2. Settings > API Keys > Create API Key (Full Access)
3. Settings > Sender Authentication에서 발신자 이메일 인증
4. API 키를 `.env` 파일의 `SENDGRID_API_KEY`에 입력

**참고:** SendGrid 무료 플랜은 일일 100개 이메일 전송 가능

## 💳 토스페이먼츠 설정

현재 테스트 모드로 설정되어 있습니다. 사업자등록 승인 후:

1. [토스페이먼츠 개발자센터](https://developers.tosspayments.com) 접속
2. 인증키 관리 > 라이브 키 복사
3. `.env` 파일의 `TOSS_SECRET_KEY`를 라이브 키로 교체

자세한 내용은 [TOSSPAYMENTS_CHECKLIST.md](../TOSSPAYMENTS_CHECKLIST.md) 참조

## 🚢 배포

### Railway (추천)

```bash
# Railway CLI 설치
npm install -g @railway/cli

# 로그인 및 배포
railway login
railway init
railway up
```

### Render

저장소 연결 후 `render.yaml` 설정이 자동 적용됩니다.

자세한 내용은 [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) 참조

## 🐛 문제 해결

### 이메일이 전송되지 않는 경우
- SendGrid API 키 확인
- 발신자 이메일 인증 여부 확인
- SendGrid Activity Feed에서 실패 로그 확인

### 결제 승인 실패
- 토스페이먼츠 키가 올바른지 확인 (테스트 vs 라이브)
- 서버 콘솔 로그 확인
- 토스페이먼츠 개발자센터에서 결제 로그 확인

### 라이선스 활성화 실패
- 라이선스 키 형식 확인 (BADA-XXXXX-XXXX-XXXX)
- `licenses.json` 파일에서 라이선스 데이터 확인
- 활성화 제한 초과 여부 확인

## 📁 파일 구조

```
Server/
├── server.js          # 메인 서버 코드
├── licenses.json      # 라이선스 데이터베이스
├── package.json       # 의존성 정보
├── env.example        # 환경변수 예시
├── Procfile           # Heroku/Railway 배포용
├── railway.json       # Railway 설정
└── render.yaml        # Render 설정
```
