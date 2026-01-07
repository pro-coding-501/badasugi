<div align="center">
  <img src="VoiceInk/Assets.xcassets/AppIcon.appiconset/256-mac.png" width="180" height="180" />
  <h1>받아쓰기 (Badasugi)</h1>
  <p>Voice to text app for macOS to transcribe what you say to text almost instantly</p>

  [![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
  ![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-brightgreen)
  [![GitHub release (latest by date)](https://img.shields.io/github/v/release/Beingpax/VoiceInk)](https://github.com/Beingpax/VoiceInk/releases)
  ![GitHub all releases](https://img.shields.io/github/downloads/Beingpax/VoiceInk/total)
  ![GitHub stars](https://img.shields.io/github/stars/Beingpax/VoiceInk?style=social)
  <p>
    <a href="https://tryvoiceink.com">Website</a> •
    <a href="https://www.youtube.com/@tryvoiceink">YouTube</a>
  </p>

  <a href="https://tryvoiceink.com">
    <img src="https://img.shields.io/badge/Download%20Now-Latest%20Version-blue?style=for-the-badge&logo=apple" alt="Download 받아쓰기" width="250"/>
  </a>
</div>

---

받아쓰기(Badasugi)는 당신이 말하는 것을 거의 즉시 텍스트로 변환하는 네이티브 macOS 애플리케이션입니다. 모든 정보와 앱 다운로드는 [여기](https://tryvoiceink.com)에서 확인할 수 있습니다. 

![받아쓰기 Mac App](https://github.com/user-attachments/assets/12367379-83e7-48a6-b52c-4488a6a04bba)

After dedicating the past 5 months to developing this app, I've decided to open source it for the greater good. 

My goal is to make it **the most efficient and privacy-focused voice-to-text solution for macOS** that is a joy to use. While the source code is now open for experienced developers to build and contribute, purchasing a license helps support continued development and gives you access to automatic updates, priority support, and upcoming features.

## Features

- 🎙️ **Accurate Transcription**: Local AI models that transcribe your voice to text with 99% accuracy, almost instantly
- 🔒 **Privacy First**: 100% offline processing ensures your data never leaves your device
- ⚡ **Power Mode**: Intelligent app detection automatically applies your perfect pre-configured settings based on the app/ URL you're on
- 🧠 **Context Aware**: Smart AI that understands your screen content and adapts to the context
- 🎯 **Global Shortcuts**: Configurable keyboard shortcuts for quick recording and push-to-talk functionality
- 📝 **Personal Dictionary**: Train the AI to understand your unique terminology with custom words, industry terms, and smart text replacements
- 🔄 **Smart Modes**: Instantly switch between AI-powered modes optimized for different writing styles and contexts
- 🤖 **AI Assistant**: Built-in voice assistant mode for a quick chatGPT like conversational assistant

## Get Started

### Download
무료 체험판이 포함된 최신 버전을 [tryvoiceink.com](https://tryvoiceink.com)에서 받으세요. 구매는 받아쓰기를 풀타임으로 개발하고 새로운 기능과 업데이트로 지속적으로 개선하는 데 도움이 됩니다.

#### Homebrew
또는 `brew`를 통해 받아쓰기를 설치할 수 있습니다:

```shell
brew install --cask voiceink
```

### Build from Source
오픈소스 프로젝트로서 [BUILDING.md](BUILDING.md)의 지침에 따라 받아쓰기를 직접 빌드할 수 있습니다. 그러나 컴파일된 버전에는 자동 업데이트, Discord 및 이메일을 통한 우선 지원과 같은 추가 혜택이 포함되며 지속적인 개발 자금 지원에 도움이 됩니다.

## Requirements

- macOS 14.0 or later

## Documentation

- [Building from Source](BUILDING.md) - Detailed instructions for building the project
- [Contributing Guidelines](CONTRIBUTING.md) - 받아쓰기에 기여하는 방법
- [Code of Conduct](CODE_OF_CONDUCT.md) - Our community standards

## Contributing

We welcome contributions! However, please note that all contributions should align with the project's goals and vision. Before starting work on any feature or fix:

1. Read our [Contributing Guidelines](CONTRIBUTING.md)
2. Open an issue to discuss your proposed changes
3. Wait for maintainer feedback

For build instructions, see our [Building Guide](BUILDING.md).

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please:
1. Check the existing issues in the GitHub repository
2. Create a new issue if your problem isn't already reported
3. Provide as much detail as possible about your environment and the problem

## Acknowledgments

### Core Technology
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) - High-performance inference of OpenAI's Whisper model
- [FluidAudio](https://github.com/FluidInference/FluidAudio) - Used for Parakeet model implementation

### Essential Dependencies
- [Sparkle](https://github.com/sparkle-project/Sparkle) - 받아쓰기를 최신 상태로 유지
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - User-customizable keyboard shortcuts
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) - Launch at login functionality
- [MediaRemoteAdapter](https://github.com/ejbills/mediaremote-adapter) - Media playback control during recording
- [Zip](https://github.com/marmelroy/Zip) - File compression and decompression utilities
- [SelectedTextKit](https://github.com/tisfeng/SelectedTextKit) - A modern macOS library for getting selected text
- [Swift Atomics](https://github.com/apple/swift-atomics) - Low-level atomic operations for thread-safe concurrent programming


---

Made with ❤️ by Pax
