#!/bin/bash

# Apple Developer Program 승인 상태 확인 스크립트

echo "🔍 Apple Developer Program 상태 확인 중..."
echo ""

# 1. 계정 상태 확인 (웹사이트 열기)
echo "📱 Apple Developer 계정 페이지를 엽니다..."
open https://developer.apple.com/account/

echo ""
echo "위 페이지에서 다음을 확인하세요:"
echo "  ✅ 'Active' 상태 → 승인 완료!"
echo "  ⏳ 'Your membership is being processed' → 승인 대기 중"
echo ""

# 2. 로컬 인증서 확인
echo "🔐 로컬 인증서 확인:"
echo "─────────────────────────────────────"

DEVELOPER_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1)

if [ -n "$DEVELOPER_ID" ]; then
    echo "✅ Developer ID 인증서 발견:"
    echo "$DEVELOPER_ID" | sed 's/^/   /'
else
    echo "⚠️  Developer ID 인증서를 찾을 수 없습니다."
    echo "   승인 완료 후 Xcode에서 인증서를 생성하세요."
fi

echo ""
echo "─────────────────────────────────────"

# 3. Xcode 계정 확인
echo ""
echo "💻 Xcode 계정 확인:"
echo "─────────────────────────────────────"

if command -v xcodebuild &> /dev/null; then
    XCODE_ACCOUNTS=$(xcodebuild -checkFirstLaunchStatus 2>&1 || echo "")
    echo "Xcode가 설치되어 있습니다."
    echo ""
    echo "수동 확인: Xcode > Preferences > Accounts"
else
    echo "⚠️  Xcode를 찾을 수 없습니다."
fi

echo ""
echo "─────────────────────────────────────"
echo ""
echo "📋 다음 단계:"
echo "  1. 승인 완료 대기 (보통 24-48시간)"
echo "  2. 승인 완료 후: ./create_signed_dmg.sh 실행"
echo ""

