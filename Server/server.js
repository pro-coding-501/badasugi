const express = require('express');
const cors = require('cors');
const sgMail = require('@sendgrid/mail');
const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 미들웨어
app.use(cors());
app.use(express.json());

// 라이선스 데이터 파일 경로
const LICENSE_DB_PATH = path.join(__dirname, 'licenses.json');

// Polar API 설정 (더 이상 사용하지 않음 - 자체 시스템 사용)
// const POLAR_API_URL = 'https://api.polar.sh';
// const POLAR_ORG_ID = process.env.POLAR_ORG_ID;
// const POLAR_API_TOKEN = process.env.POLAR_API_TOKEN;

// SendGrid 설정
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY;
const EMAIL_FROM = process.env.EMAIL_FROM || 'badasugi.app@gmail.com';

// ============================================
// 토스페이먼츠 설정
// ============================================
// ⚠️ 실제 서비스 전환 시 .env 파일의 TOSS_SECRET_KEY만 변경하면 됩니다!
// 
// 현재: 테스트 모드 (실제 결제 안 됨)
// 변경: 토스페이먼츠에서 라이브 시크릿 키 발급 후 .env 파일 수정
//
// 테스트 시크릿 키: test_sk_... (현재 사용 중)
// 라이브 시크릿 키: live_sk_... (실제 서비스 시 사용)
//
// 변경 위치: Server/.env 파일의 TOSS_SECRET_KEY 값
// ============================================
const TOSS_SECRET_KEY = process.env.TOSS_SECRET_KEY || 'test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R';
const TOSS_API_URL = 'https://api.tosspayments.com/v1/payments/confirm';

// SendGrid 초기화
if (SENDGRID_API_KEY) {
  sgMail.setApiKey(SENDGRID_API_KEY);
  console.log('✅ SendGrid API 키가 설정되었습니다.');
} else {
  console.warn('⚠️ SendGrid API 키가 설정되지 않았습니다. 이메일 전송 기능이 작동하지 않습니다.');
}

// ============================================
// 자체 라이선스 관리 시스템
// ============================================

// 라이선스 데이터베이스 초기화
async function initLicenseDB() {
  try {
    await fs.access(LICENSE_DB_PATH);
  } catch {
    // 파일이 없으면 빈 객체로 초기화
    await fs.writeFile(LICENSE_DB_PATH, JSON.stringify({ licenses: {} }, null, 2));
    console.log('📝 라이선스 데이터베이스 초기화 완료');
  }
}

// 라이선스 데이터 로드
async function loadLicenses() {
  try {
    const data = await fs.readFile(LICENSE_DB_PATH, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('라이선스 DB 로드 실패:', error);
    return { licenses: {} };
  }
}

// 라이선스 데이터 저장
async function saveLicenses(data) {
  await fs.writeFile(LICENSE_DB_PATH, JSON.stringify(data, null, 2));
}

// 고유 라이선스 키 생성
function generateLicenseKey() {
  const prefix = 'BADA';
  const timestamp = Date.now().toString(36).toUpperCase();
  const random1 = crypto.randomBytes(4).toString('hex').toUpperCase();
  const random2 = crypto.randomBytes(4).toString('hex').toUpperCase();
  return `${prefix}-${timestamp}-${random1}-${random2}`;
}

// 라이선스 키 저장
async function saveLicenseKey(licenseKey, email, quantity) {
  const db = await loadLicenses();
  
  db.licenses[licenseKey] = {
    email: email,
    quantity: quantity,
    createdAt: new Date().toISOString(),
    activations: {},
    status: 'active'
  };
  
  await saveLicenses(db);
  console.log(`💾 라이선스 키 저장: ${licenseKey}`);
}

// 라이선스 키 검증
async function validateLicenseKey(licenseKey) {
  const db = await loadLicenses();
  const license = db.licenses[licenseKey];
  
  if (!license) {
    return { valid: false, error: '유효하지 않은 라이선스 키입니다.' };
  }
  
  if (license.status !== 'active') {
    return { valid: false, error: '비활성화된 라이선스 키입니다.' };
  }
  
  return {
    valid: true,
    license: license,
    activationCount: Object.keys(license.activations).length,
    maxActivations: license.quantity
  };
}

// 디바이스 활성화
async function activateDevice(licenseKey, deviceId, deviceName) {
  const db = await loadLicenses();
  const license = db.licenses[licenseKey];
  
  if (!license) {
    return { success: false, error: '유효하지 않은 라이선스 키입니다.' };
  }
  
  if (license.status !== 'active') {
    return { success: false, error: '비활성화된 라이선스 키입니다.' };
  }
  
  // 이미 활성화된 디바이스인지 확인
  if (license.activations[deviceId]) {
    return {
      success: true,
      message: '이미 활성화된 디바이스입니다.',
      activeDevices: Object.keys(license.activations).length,
      maxDevices: license.quantity
    };
  }
  
  // 활성화 제한 확인
  const currentActivations = Object.keys(license.activations).length;
  if (currentActivations >= license.quantity) {
    return {
      success: false,
      error: `활성화 제한에 도달했습니다. (${currentActivations}/${license.quantity})`,
      activeDevices: currentActivations,
      maxDevices: license.quantity
    };
  }
  
  // 디바이스 활성화
  license.activations[deviceId] = {
    deviceName: deviceName,
    activatedAt: new Date().toISOString()
  };
  
  await saveLicenses(db);
  
  return {
    success: true,
    message: '라이선스가 성공적으로 활성화되었습니다.',
    activeDevices: Object.keys(license.activations).length,
    maxDevices: license.quantity
  };
}

// 디바이스 비활성화
async function deactivateDevice(licenseKey, deviceId) {
  const db = await loadLicenses();
  const license = db.licenses[licenseKey];
  
  if (!license) {
    return { success: false, error: '유효하지 않은 라이선스 키입니다.' };
  }
  
  if (license.activations[deviceId]) {
    delete license.activations[deviceId];
    await saveLicenses(db);
    return { success: true, message: '디바이스가 비활성화되었습니다.' };
  }
  
  return { success: false, error: '활성화되지 않은 디바이스입니다.' };
}

// 자체 라이선스 키 생성 및 저장
async function createLicenseKey(quantity, email) {
  // 고유 라이선스 키 생성
  const licenseKey = generateLicenseKey();
  
  // 데이터베이스에 저장
  await saveLicenseKey(licenseKey, email, quantity);
  
  console.log(`🔑 라이선스 키 생성: ${licenseKey} (이메일: ${email}, 기기: ${quantity}대)`);
  
  return licenseKey;
}

// 이메일 전송 함수 (SendGrid 사용)
async function sendLicenseEmail(email, licenseKey, quantity) {
  if (!SENDGRID_API_KEY) {
    throw new Error('SendGrid API 키가 설정되지 않았습니다.');
  }

  const msg = {
    to: email,
    from: {
      email: EMAIL_FROM,
      name: '받아쓰기',
    },
    subject: '[받아쓰기] 라이선스 키 발급 완료',
    html: `
      <!DOCTYPE html>
      <html lang="ko">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>라이선스 키 발급 완료</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Pretendard', sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f7;
          }
          .container {
            background-color: #ffffff;
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
          }
          .header {
            text-align: center;
            margin-bottom: 30px;
          }
          .logo {
            font-size: 24px;
            font-weight: 700;
            color: #00D9A5;
            margin-bottom: 10px;
          }
          .title {
            font-size: 20px;
            font-weight: 600;
            color: #1a1a1c;
            margin-bottom: 20px;
          }
          .license-box {
            background-color: #f5f5f7;
            border: 2px solid #00D9A5;
            border-radius: 12px;
            padding: 20px;
            margin: 30px 0;
            text-align: center;
          }
          .license-key {
            font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
            font-size: 18px;
            font-weight: 600;
            color: #1a1a1c;
            letter-spacing: 1px;
            word-break: break-all;
          }
          .info-section {
            background-color: #f9f9f9;
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
          }
          .info-item {
            margin: 10px 0;
            color: #666;
          }
          .info-label {
            font-weight: 600;
            color: #333;
          }
          .button {
            display: inline-block;
            background: linear-gradient(180deg, #2DD4BF 0%, #00D9A5 100%);
            color: #ffffff;
            padding: 14px 28px;
            border-radius: 12px;
            text-decoration: none;
            font-weight: 600;
            margin: 20px 0;
            text-align: center;
          }
          .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e5e5e7;
            text-align: center;
            color: #86868b;
            font-size: 14px;
          }
          .warning {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin: 20px 0;
            border-radius: 8px;
            color: #856404;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">받아쓰기</div>
            <div class="title">라이선스 키 발급 완료</div>
          </div>
          
          <p>안녕하세요,</p>
          <p>받아쓰기 라이선스를 구매해 주셔서 감사합니다!</p>
          
          <div class="license-box">
            <div style="margin-bottom: 10px; color: #666; font-size: 14px;">라이선스 키</div>
            <div class="license-key">${licenseKey}</div>
          </div>
          
          <div class="info-section">
            <div class="info-item">
              <span class="info-label">활성화 가능 기기 수:</span> ${quantity}대
            </div>
            <div class="info-item">
              <span class="info-label">발급일시:</span> ${new Date().toLocaleString('ko-KR')}
            </div>
          </div>
          
          <div class="warning">
            <strong>⚠️ 중요:</strong> 이 라이선스 키는 이메일로만 전송됩니다. 안전하게 보관해 주세요.
          </div>
          
          <h3 style="color: #1a1a1c; margin-top: 30px;">라이선스 키 사용 방법</h3>
          <ol style="color: #666; line-height: 1.8;">
            <li>받아쓰기 앱을 실행합니다</li>
            <li>설정에서 "라이선스 키 입력" 메뉴를 선택합니다</li>
            <li>위의 라이선스 키를 복사하여 입력합니다</li>
            <li>활성화가 완료되면 모든 기능을 사용할 수 있습니다</li>
          </ol>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="https://www.badasugi.com" class="button">받아쓰기 다운로드</a>
          </div>
          
          <div class="footer">
            <p>문의사항이 있으시면 언제든지 연락주세요.</p>
            <p>이메일: <a href="mailto:badasugi.app@gmail.com" style="color: #00D9A5;">badasugi.app@gmail.com</a></p>
            <p style="margin-top: 20px; font-size: 12px;">
              © 2026 받아쓰기. All rights reserved.
            </p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
받아쓰기 라이선스 키 발급 완료

안녕하세요,

받아쓰기 라이선스를 구매해 주셔서 감사합니다!

라이선스 키: ${licenseKey}
활성화 가능 기기 수: ${quantity}대
발급일시: ${new Date().toLocaleString('ko-KR')}

라이선스 키 사용 방법:
1. 받아쓰기 앱을 실행합니다
2. 설정에서 "라이선스 키 입력" 메뉴를 선택합니다
3. 위의 라이선스 키를 복사하여 입력합니다
4. 활성화가 완료되면 모든 기능을 사용할 수 있습니다

문의사항이 있으시면 언제든지 연락주세요.
이메일: badasugi.app@gmail.com

© 2026 받아쓰기. All rights reserved.
    `,
  };

  try {
    const response = await sgMail.send(msg);
    console.log('✅ 이메일 전송 성공:', email);
    console.log('📧 SendGrid 응답 상태:', response[0]?.statusCode);
    console.log('📧 SendGrid 응답 헤더:', JSON.stringify(response[0]?.headers, null, 2));
    console.log('📧 라이선스 키:', licenseKey);
    return { success: true, email: email };
  } catch (error) {
    console.error('❌ 이메일 전송 실패:', error);
    console.error('❌ 에러 코드:', error.code);
    console.error('❌ 에러 메시지:', error.message);
    if (error.response) {
      console.error('❌ SendGrid 응답 상태:', error.response.statusCode);
      console.error('❌ SendGrid 응답 바디:', JSON.stringify(error.response.body, null, 2));
      console.error('❌ SendGrid 응답 헤더:', JSON.stringify(error.response.headers, null, 2));
    }
    throw new Error(`이메일 전송에 실패했습니다: ${error.message}`);
  }
}

// 토스페이먼츠 결제 승인 및 라이선스 발급 API
app.post('/api/payment/confirm', async (req, res) => {
  try {
    const { paymentKey, orderId, amount, email, quantity } = req.body;

    // 필수 필드 검증
    if (!paymentKey || !orderId || !amount || !email || !quantity) {
      return res.status(400).json({
        success: false,
        error: '필수 결제 정보가 누락되었습니다.',
      });
    }

    // 이메일 형식 검증
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        error: '유효한 이메일 주소를 입력해주세요.',
      });
    }

    console.log(`💳 결제 승인 요청: orderId=${orderId}, amount=${amount}, email=${email}`);

    // 토스페이먼츠 결제 승인 요청
    const secretKeyBase64 = Buffer.from(TOSS_SECRET_KEY + ':').toString('base64');
    
    const tossResponse = await axios.post(
      TOSS_API_URL,
      {
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
      },
      {
        headers: {
          'Authorization': `Basic ${secretKeyBase64}`,
          'Content-Type': 'application/json',
        },
      }
    );

    console.log('✅ 토스페이먼츠 결제 승인 성공:', tossResponse.data.orderId);

    // 결제 승인 성공 시 라이선스 발급
    const qty = parseInt(quantity);
    const licenseKey = await createLicenseKey(qty, email);
    console.log(`🔑 라이선스 키 생성 완료: ${licenseKey}`);

    // 이메일 전송
    try {
      await sendLicenseEmail(email, licenseKey, qty);
      console.log(`📧 이메일 전송 완료: ${email}`);
      console.log(`📧 전송된 라이선스 키: ${licenseKey}`);
    } catch (emailError) {
      console.error('❌ 이메일 전송 중 오류 발생:', emailError.message);
      // 이메일 전송 실패해도 결제는 완료된 것으로 처리 (나중에 수동 전송 가능)
      console.warn('⚠️ 이메일 전송 실패했지만 결제는 완료되었습니다. 라이선스 키:', licenseKey);
    }

    // 성공 응답
    res.json({
      success: true,
      message: '결제가 완료되었습니다. 라이선스 키가 이메일로 전송되었습니다.',
      orderId: orderId,
      email: email,
      quantity: qty,
    });

  } catch (error) {
    console.error('❌ 결제 승인 오류:', error.response?.data || error.message);
    
    // 토스페이먼츠 API 오류 처리
    if (error.response?.data) {
      const tossError = error.response.data;
      return res.status(400).json({
        success: false,
        error: tossError.message || '결제 승인에 실패했습니다.',
        code: tossError.code,
      });
    }
    
    res.status(500).json({
      success: false,
      error: error.message || '서버 오류가 발생했습니다.',
    });
  }
});

// 결제 완료 후 라이선스 키 발급 및 이메일 전송 API (기존 테스트용)
app.post('/api/purchase/complete', async (req, res) => {
  try {
    const { email, quantity, paymentId, amount } = req.body;

    // 필수 필드 검증
    if (!email || !quantity) {
      return res.status(400).json({
        success: false,
        error: '이메일과 기기 수량은 필수입니다.',
      });
    }

    // 이메일 형식 검증
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        error: '유효한 이메일 주소를 입력해주세요.',
      });
    }

    // 수량 검증
    const qty = parseInt(quantity);
    if (isNaN(qty) || qty < 1) {
      return res.status(400).json({
        success: false,
        error: '기기 수량은 1 이상이어야 합니다.',
      });
    }

    console.log(`결제 완료 처리 시작: ${email}, 수량: ${qty}`);

    // 1. 라이선스 키 생성
    const licenseKey = await createLicenseKey(qty, email);
    console.log(`라이선스 키 생성 완료: ${licenseKey}`);

    // 2. 이메일 전송
    await sendLicenseEmail(email, licenseKey, qty);
    console.log(`이메일 전송 완료: ${email}`);

    // 3. 성공 응답
    res.json({
      success: true,
      message: '라이선스 키가 성공적으로 발급되어 이메일로 전송되었습니다.',
      licenseKey: licenseKey, // 개발/테스트용 (프로덕션에서는 제거 권장)
      email: email,
      quantity: qty,
    });
  } catch (error) {
    console.error('결제 완료 처리 오류:', error);
    res.status(500).json({
      success: false,
      error: error.message || '서버 오류가 발생했습니다.',
    });
  }
});

// 테스트용 라이선스 키 발급 API (토스페이먼츠 연동 전 테스트용)
app.post('/api/test/license', async (req, res) => {
  try {
    const { email, quantity } = req.body;

    if (!email || !quantity) {
      return res.status(400).json({
        success: false,
        error: '이메일과 기기 수량은 필수입니다.',
      });
    }

    const qty = parseInt(quantity);
    if (isNaN(qty) || qty < 1) {
      return res.status(400).json({
        success: false,
        error: '기기 수량은 1 이상이어야 합니다.',
      });
    }

    // 테스트용 라이선스 키 생성 (실제 Polar API 대신 임시 키 생성)
    const testLicenseKey = `TEST-${Date.now()}-${Math.random().toString(36).substring(2, 15).toUpperCase()}`;
    
    // 이메일 전송
    await sendLicenseEmail(email, testLicenseKey, qty);

    res.json({
      success: true,
      message: '테스트 라이선스 키가 발급되어 이메일로 전송되었습니다.',
      licenseKey: testLicenseKey,
      email: email,
      quantity: qty,
      note: '이것은 테스트용 라이선스 키입니다.',
    });
  } catch (error) {
    console.error('테스트 라이선스 발급 오류:', error);
    res.status(500).json({
      success: false,
      error: error.message || '서버 오류가 발생했습니다.',
    });
  }
});

// ============================================
// 라이선스 검증 및 활성화 API
// ============================================

// 라이선스 키 검증 API
app.post('/api/license/validate', async (req, res) => {
  try {
    const { licenseKey } = req.body;
    
    if (!licenseKey) {
      return res.status(400).json({
        success: false,
        error: '라이선스 키를 입력해주세요.',
      });
    }
    
    const result = await validateLicenseKey(licenseKey);
    
    if (!result.valid) {
      return res.status(400).json({
        success: false,
        error: result.error,
      });
    }
    
    res.json({
      success: true,
      message: '유효한 라이선스 키입니다.',
      activeDevices: result.activationCount,
      maxDevices: result.maxActivations,
      email: result.license.email,
    });
    
  } catch (error) {
    console.error('라이선스 검증 오류:', error);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다.',
    });
  }
});

// 라이선스 활성화 API
app.post('/api/license/activate', async (req, res) => {
  try {
    const { licenseKey, deviceId, deviceName } = req.body;
    
    if (!licenseKey || !deviceId) {
      return res.status(400).json({
        success: false,
        error: '라이선스 키와 디바이스 ID는 필수입니다.',
      });
    }
    
    const result = await activateDevice(licenseKey, deviceId, deviceName || 'Unknown Device');
    
    if (!result.success) {
      return res.status(400).json(result);
    }
    
    res.json(result);
    
  } catch (error) {
    console.error('라이선스 활성화 오류:', error);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다.',
    });
  }
});

// 라이선스 비활성화 API
app.post('/api/license/deactivate', async (req, res) => {
  try {
    const { licenseKey, deviceId } = req.body;
    
    if (!licenseKey || !deviceId) {
      return res.status(400).json({
        success: false,
        error: '라이선스 키와 디바이스 ID는 필수입니다.',
      });
    }
    
    const result = await deactivateDevice(licenseKey, deviceId);
    
    res.json(result);
    
  } catch (error) {
    console.error('라이선스 비활성화 오류:', error);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다.',
    });
  }
});

// 건강 상태 확인 API
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'badasugi-license-server',
  });
});

// 서버 시작
app.listen(PORT, async () => {
  // 라이선스 DB 초기화
  await initLicenseDB();
  
  console.log(`🚀 받아쓰기 라이선스 서버가 포트 ${PORT}에서 실행 중입니다.`);
  console.log(`📧 SendGrid: ${SENDGRID_API_KEY ? '✅ 설정됨' : '⚠️ 설정 필요'}`);
  console.log(`💳 토스페이먼츠: ${TOSS_SECRET_KEY ? '✅ 설정됨' : '⚠️ 설정 필요'} ${TOSS_SECRET_KEY?.startsWith('test_') ? '(테스트 모드)' : '(라이브 모드)'}`);
  console.log(`🔑 라이선스 시스템: ✅ 자체 시스템 (Polar 대체)`);
  console.log(`\n📝 API 엔드포인트:`);
  console.log(`   - POST /api/payment/confirm      (토스페이먼츠 결제 승인)`);
  console.log(`   - POST /api/license/validate     (라이선스 키 검증)`);
  console.log(`   - POST /api/license/activate     (라이선스 활성화)`);
  console.log(`   - POST /api/license/deactivate   (라이선스 비활성화)`);
  console.log(`   - POST /api/purchase/complete    (기존 테스트용)`);
  console.log(`   - POST /api/test/license         (테스트용 라이선스)`);
  console.log(`   - GET  /api/health               (서버 상태 확인)\n`);
});

