# Apple Developer Program 설정 가이드

## ✅ 승인 대기 중 확인사항

### 1. Apple Developer 계정 상태 확인
- [ ] https://developer.apple.com/account/ 접속
- [ ] 계정 상태가 "Active"로 변경되었는지 확인
- [ ] 보통 24-48시간 내 승인 완료

### 2. Xcode 설정 확인
- [ ] Xcode > Preferences > Accounts
- [ ] Apple ID 추가/확인
- [ ] "Download Manual Profiles" 클릭하여 인증서 다운로드

### 3. App-Specific Password 생성 (Notarization용)
- [ ] https://appleid.apple.com 접속
- [ ] Sign-In and Security > App-Specific Passwords
- [ ] 새 비밀번호 생성 (예: "Badasugi Notarization")
- [ ] 생성된 비밀번호 복사해두기 (한 번만 표시됨!)

---

## 🚀 승인 완료 후 진행 단계

### Step 1: Developer ID 인증서 확인

```bash
# 터미널에서 실행
security find-identity -v -p codesigning | grep "Developer ID"
```

**예상 결과:**
```
1) ABC123DEF456 "Developer ID Application: Your Name (TEAM_ID)"
```

### Step 2: Code Signed DMG 생성

```bash
cd Mac
./create_signed_dmg.sh
```

스크립트가 자동으로:
1. ✅ Archive 생성 (Code Signing 포함)
2. ✅ 앱 서명 확인
3. ✅ DMG 생성 및 서명
4. ✅ Notarization 제출 (선택사항)
5. ✅ 스테이플링

### Step 3: Notarization (선택사항)

**자동 (스크립트 내에서):**
- App-specific password 입력하면 자동 진행

**수동 진행:**
```bash
# 1. Notarization 제출
xcrun notarytool submit build/Badasugi.dmg \
  --apple-id YOUR_EMAIL@example.com \
  --password YOUR_APP_SPECIFIC_PASSWORD \
  --team-id AUNHQZL489 \
  --wait

# 2. 스테이플링
xcrun stapler staple build/Badasugi.dmg

# 3. 확인
xcrun stapler validate build/Badasugi.dmg
```

### Step 4: GitHub Release 업로드

```bash
# 기존 DMG 삭제
gh release delete-asset v1.0.0 Badasugi.dmg --repo Badasugi/badasugi --yes

# 새 DMG 업로드
gh release upload v1.0.0 Mac/build/Badasugi.dmg --repo Badasugi/badasugi --clobber
```

---

## 🔍 문제 해결

### 문제: "Developer ID 인증서를 찾을 수 없습니다"

**해결:**
1. Xcode > Preferences > Accounts
2. Apple ID 선택 > "Download Manual Profiles"
3. 또는 Xcode에서 프로젝트 열기 > Signing & Capabilities > Team 선택

### 문제: Notarization 실패

**원인:**
- App-specific password 오류
- 앱 서명 문제
- Entitlements 설정 문제

**해결:**
```bash
# 앱 서명 재확인
codesign -dv --verbose=4 Mac/build/Badasugi.xcarchive/Products/Applications/Badasugi.app

# Entitlements 확인
codesign -d --entitlements - Mac/build/Badasugi.xcarchive/Products/Applications/Badasugi.app
```

### 문제: "code object is not signed at all"

**해결:**
- Xcode에서 프로젝트 열기
- Signing & Capabilities > Team 선택
- Archive 다시 생성

---

## 📚 참고 자료

- [Apple Developer Program](https://developer.apple.com/programs/)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

---

## ⏱️ 예상 소요 시간

- 승인 대기: 24-48시간
- Code Signing 설정: 10분
- DMG 생성: 5분
- Notarization: 10-30분 (Apple 서버 처리 시간)

**총 예상 시간: 승인 후 30분 내외**

