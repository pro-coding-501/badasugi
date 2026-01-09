# 받아쓰기(Badasugi) 설치 가이드

## macOS 보안 경고 해결 방법

받아쓰기를 다운로드하여 실행하면 다음과 같은 보안 경고가 나타날 수 있습니다:

> **"Badasugi" Not Opened**
> 
> Apple could not verify "Badasugi" is free of malware that may harm your Mac or compromise your privacy.

이는 앱이 Apple Developer ID로 공식 서명되지 않았기 때문에 발생하는 정상적인 macOS 보안 기능입니다. 받아쓰기는 안전한 오픈소스 소프트웨어이며, 다음 방법으로 설치할 수 있습니다.

---

## ✅ 설치 방법 (권장)

### 1단계: DMG 파일 다운로드 및 열기

1. [https://www.badasugi.com](https://www.badasugi.com) 또는 [GitHub Releases](https://github.com/Badasugi/badasugi/releases)에서 `Badasugi.dmg` 다운로드
2. 다운로드한 DMG 파일을 더블클릭하여 열기

### 2단계: Applications 폴더로 이동

1. DMG 창에서 **Badasugi.app**을 **Applications** 폴더로 드래그
2. 복사가 완료될 때까지 대기
3. DMG 창 닫기

### 3단계: Control+클릭으로 앱 실행

1. **Finder** → **응용 프로그램(Applications)** 폴더 열기
2. **Badasugi** 앱 찾기
3. **⌃ Control 키를 누른 채로 앱 클릭** (또는 마우스 오른쪽 버튼 클릭)
4. 메뉴에서 **"열기"** 선택
5. 경고 대화상자가 나타나면 **"열기"** 버튼 클릭

<img width="500" alt="Control+클릭 → 열기" src="https://support.apple.com/library/content/dam/edam/applecare/images/en_US/macos/Big-Sur/macos-big-sur-right-click-open.jpg">

> **참고**: 이 방법은 **처음 실행할 때만 필요**합니다. 이후에는 일반적인 방법으로 실행할 수 있습니다.

---

## 🔧 대안 방법: 터미널 사용

터미널을 사용하여 격리(quarantine) 속성을 제거할 수도 있습니다:

```bash
# Applications 폴더로 앱을 복사한 후
xattr -cr /Applications/Badasugi.app
```

이 명령어를 실행한 후 일반적인 방법으로 앱을 실행할 수 있습니다.

---

## 🛡️ 보안에 대해

### 왜 이런 경고가 나타나나요?

macOS는 **Gatekeeper**라는 보안 기능을 사용하여 인터넷에서 다운로드한 앱을 검사합니다. Apple Developer ID로 서명되지 않은 앱은 기본적으로 차단됩니다.

### 받아쓰기는 안전한가요?

- ✅ **오픈소스**: 모든 소스 코드가 [GitHub](https://github.com/Badasugi/badasugi)에 공개되어 있습니다
- ✅ **GPL v3 라이선스**: 투명하고 자유로운 오픈소스 라이선스
- ✅ **로컬 처리**: 음성 데이터는 사용자의 Mac에서만 처리됩니다 (클라우드 옵션 선택 시 제외)
- ✅ **커뮤니티 검증**: 누구나 코드를 검토하고 기여할 수 있습니다

### Apple Developer ID 서명을 하지 않는 이유는?

Apple Developer ID 서명을 받으려면:
- 연간 $99의 Apple Developer Program 비용이 필요합니다
- 복잡한 공증(Notarization) 과정이 필요합니다

받아쓰기는 완전 무료 오픈소스 프로젝트이므로, 현재는 서명 없이 배포하고 있습니다. 향후 충분한 지원이 모이면 공식 서명을 추가할 계획입니다.

---

## 💡 권한 설정

받아쓰기를 처음 실행하면 다음 권한을 요청합니다:

### 필수 권한
- **마이크 접근 권한**: 음성 녹음을 위해 필요
- **접근성 권한**: 녹음된 텍스트를 자동으로 입력하기 위해 필요

### 선택적 권한
- **화면 녹화 권한**: Power Mode 기능 (활성 앱에 따른 자동 설정)을 사용하려면 필요

권한 설정 방법:
1. **시스템 설정** 열기
2. **개인정보 보호 및 보안** → 해당 권한 항목 선택
3. 받아쓰기 앱의 스위치 켜기

---

## 🆘 문제 해결

### "손상되었기 때문에 열 수 없습니다" 오류

다음 명령어를 실행하세요:

```bash
xattr -cr /Applications/Badasugi.app
```

### 앱이 실행되지 않음

1. macOS 버전 확인: **macOS 14.0 이상** 필요
2. 권한 확인: 시스템 설정 → 개인정보 보호 및 보안
3. 완전히 삭제 후 재설치:
   ```bash
   # 앱 삭제
   rm -rf /Applications/Badasugi.app
   
   # 설정 파일 삭제 (선택사항)
   rm -rf ~/Library/Application\ Support/Badasugi
   rm -rf ~/Library/Preferences/com.badasugi.app.plist
   ```

### 그 외 문제

- **이메일**: badasugi.app@gmail.com
- **GitHub Issues**: [https://github.com/Badasugi/badasugi/issues](https://github.com/Badasugi/badasugi/issues)

---

## 📚 추가 자료

- [사용자 가이드](https://www.badasugi.com)
- [소스 코드 빌드하기](BUILDING.md)
- [GitHub 저장소](https://github.com/Badasugi/badasugi)
- [라이선스 정보](LICENSE)

---

즐거운 음성 기록 되세요! 🎙️✨

