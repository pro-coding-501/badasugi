# Badasugi (받아쓰기)

Badasugi is a macOS application for voice transcription and dictation, designed to convert speech to text with support for multiple transcription models and AI-powered text enhancement.

## Overview

Badasugi provides real-time and offline voice transcription capabilities for macOS. The application supports multiple transcription models including local Whisper models, cloud-based services, and native Apple transcription. It includes features for text enhancement, context-aware configurations, and integration with macOS accessibility features.

## Open Source Notice

This software is based on the open-source project VoiceInk and is licensed under the GNU General Public License v3 (GPL v3).

The source code of Badasugi is available under the GPL v3 license, which grants users the right to use, modify, and distribute the software in accordance with the terms of that license.

## Commercial Distribution

While the source code is available under GPL v3, Badasugi also offers commercial distribution channels:

- **Pre-built binaries**: Official releases distributed through the Badasugi website
- **Automatic updates**: Update services provided for licensed installations
- **License management**: Commercial license activation and validation services

These commercial services are separate from the GPL-licensed source code. Users who obtain the software through commercial channels receive the same GPL v3 rights to the source code, but the commercial distribution, updates, and license services are provided as additional services.

## Features

- **Multiple Transcription Models**: Support for local Whisper models, cloud-based transcription services, and native Apple transcription
- **Real-time Recording**: Record audio from microphone input with hotkey support
- **Audio File Processing**: Transcribe audio files in multiple formats (WAV, MP3, M4A, AIFF, MP4, MOV, AAC, FLAC, CAF)
- **AI Text Enhancement**: Optional AI-powered text improvement and correction
- **Power Modes**: Context-aware configurations that automatically adjust settings based on active applications
- **Menu Bar Integration**: Quick access through the macOS menu bar
- **Keyboard Shortcuts**: Customizable hotkeys for recording and playback control
- **Transcription History**: View and manage past transcriptions
- **Multiple Language Support**: Support for multilingual transcription models

## Get Started

### Download from Website

Visit [https://www.badasugi.com](https://www.badasugi.com) to download the latest release.

### Install via Homebrew

```bash
brew install --cask voiceink
```

## Build from Source

### Prerequisites

- macOS 14.0 or later
- Xcode (latest version recommended)
- Swift (latest version recommended)
- Git

### Quick Build with Makefile

The recommended way to build Badasugi is using the included Makefile:

```bash
# Clone the repository
git clone https://github.com/Badasugi/badasugi.git
cd badasugi

# Build everything (includes whisper framework setup)
make all

# Or for development (build and run)
make dev
```

### Available Makefile Commands

- `make check` or `make healthcheck` - Verify all required tools are installed
- `make whisper` - Clone and build whisper.cpp XCFramework automatically
- `make setup` - Prepare the whisper framework for linking
- `make build` - Build the Badasugi Xcode project
- `make run` - Launch the built Badasugi app
- `make dev` - Build and run (ideal for development workflow)
- `make all` - Complete build process (default)
- `make clean` - Remove build artifacts and dependencies
- `make help` - Show all available commands

### Manual Build Process

1. Clone the repository:
```bash
git clone https://github.com/Badasugi/badasugi.git
cd badasugi
```

2. Build whisper.cpp framework:
```bash
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp
./build-xcframework.sh
```

3. Add the whisper.xcframework to the Xcode project:
   - Drag and drop `whisper.cpp/build-apple/whisper.xcframework` into the project navigator, or
   - Add it manually in the "Frameworks, Libraries, and Embedded Content" section of project settings

4. Build and run in Xcode:
   - Build the project using Cmd+B or Product > Build
   - Run the project using Cmd+R or Product > Run

For detailed build instructions, see [BUILDING.md](BUILDING.md).

## Requirements

- **Operating System**: macOS 14.0 or later
- **Hardware**: Mac computer with microphone access
- **Permissions**: 
  - Microphone access (required for recording)
  - Accessibility permissions (for text insertion features)
  - Screen recording permissions (for context-aware features)

## Support

For support, bug reports, or feature requests:

- **Email**: badasugi.app@gmail.com
- **Website**: [https://www.badasugi.com](https://www.badasugi.com)

## License

The source code of Badasugi is licensed under the GNU General Public License v3 (GPL v3). See the LICENSE file for the full license text.

## Acknowledgments

Badasugi uses the following open-source dependencies:

- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) - High-performance inference of OpenAI's Whisper automatic speech recognition model
- [Sparkle](https://sparkle-project.org/) - Software update framework for macOS

---

© 2026 Badasugi (받아쓰기)

