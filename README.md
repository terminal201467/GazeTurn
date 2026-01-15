# GazeTurn

<p align="center">
  <img src="assets/logo.png" alt="GazeTurn Logo" width="200"/>
</p>

<p align="center">
  <strong>智能眼動翻譜 - 讓音樂演奏更自由</strong><br/>
  <strong>Smart Eye-Tracking Page Turner - Free Your Hands for Music</strong>
</p>

<p align="center">
  <a href="#簡介">中文</a> | <a href="#introduction">English</a>
</p>

---

## 簡介

**GazeTurn** 是一款創新的 iOS 應用程式，專為音樂家設計，透過眼動追蹤和頭部手勢識別技術，讓您在演奏樂器時能夠免手翻頁樂譜。無論您是鋼琴家、吉他手、小提琴家還是任何樂器演奏者，GazeTurn 都能讓您專注於音樂，不再為翻頁而中斷演奏。

## 主要特色

### 👁️ 智能眼動追蹤
- 使用前置相機即時偵測眼球移動
- 支援眼球注視點檢測
- 自適應校準系統，適應不同使用習慣

### 🤲 手勢識別
- 微手勢檢測 (Micro-Gesture Detection)
- 頭部動作識別（左轉/右轉）
- 多種手勢組合支援

### 🤖 AI 智能學習
- **環境分析器** - 自動適應不同光線和使用環境
- **手勢學習引擎** - 學習您的個人手勢習慣
- **智能校準引擎** - 動態調整偵測參數
- **手勢預測模型** - 提前預測翻頁意圖

### 🎵 多樂器支援
- 鋼琴 (Keyboard)
- 吉他 (Guitar)
- 小提琴 (Violin)
- 其他樂器類型可擴展

### 📄 PDF 樂譜管理
- 瀏覽和管理樂譜文件
- 即時 PDF 預覽
- 檔案清單管理

### ⚙️ 完善的設定系統
- 靈敏度調整
- 校準功能
- 樂器切換
- 個性化設定

## 系統需求

- **平台**: iOS 15.0 或更高版本
- **硬體**: 具備前置相機的 iPhone 或 iPad
- **權限**: 需要相機權限以進行眼動和手勢檢測

## 快速開始

### 安裝步驟

1. **Clone 專案**
   ```bash
   git clone git@github.com:terminal201467/GazeTurn.git
   cd GazeTurn
   ```

2. **安裝依賴**
   ```bash
   pod install
   ```

3. **開啟專案**
   ```bash
   open GazeTurn.xcworkspace
   ```

4. **設定相機權限**

   專案已包含相機權限設定，詳細說明請參考 [CAMERA_PERMISSION_SETUP.md](CAMERA_PERMISSION_SETUP.md)

5. **編譯並運行**
   - 在 Xcode 中選擇目標設備
   - 點擊 Run (⌘R)

### 首次使用

1. **啟動應用程式** - 首次啟動時會要求相機權限，請允許存取
2. **選擇樂器** - 選擇您演奏的樂器類型，系統會根據樂器調整偵測參數
3. **校準** - 進入設定 → 校準，按照畫面指示完成眼動校準
4. **開始使用** - 匯入 PDF 樂譜，使用眼動或頭部手勢翻頁

### 翻頁手勢

- **向右看** → 下一頁
- **向左看** → 上一頁
- **頭部右轉** → 下一頁
- **頭部左轉** → 上一頁

---

## Introduction

**GazeTurn** is an innovative iOS application designed for musicians, using eye-tracking and head gesture recognition technology to enable hands-free page turning while playing instruments. Whether you're a pianist, guitarist, violinist, or any other instrumentalist, GazeTurn lets you focus on your music without interrupting your performance to turn pages.

## Key Features

### 👁️ Smart Eye Tracking
- Real-time eye movement detection using the front camera
- Gaze point detection support
- Adaptive calibration system that adjusts to different usage habits

### 🤲 Gesture Recognition
- Micro-gesture detection
- Head movement recognition (turn left/right)
- Multiple gesture combination support

### 🤖 AI-Powered Learning
- **Environment Analyzer** - Automatically adapts to different lighting conditions and environments
- **Gesture Learning Engine** - Learns your personal gesture habits
- **Smart Calibration Engine** - Dynamically adjusts detection parameters
- **Gesture Prediction Model** - Anticipates page-turning intent

### 🎵 Multi-Instrument Support
- Piano / Keyboard
- Guitar
- Violin / String Instruments
- Wind Instruments
- Expandable to other instrument types

### 📄 PDF Sheet Music Management
- Browse and manage sheet music files
- Real-time PDF preview
- File list management

### ⚙️ Comprehensive Settings
- Sensitivity adjustment
- Calibration functionality
- Instrument switching
- Personalized settings

## System Requirements

- **Platform**: iOS 15.0 or later
- **Hardware**: iPhone or iPad with front-facing camera
- **Permissions**: Camera access required for eye and gesture detection

## Technical Architecture

### Core Technology Stack
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Vision Framework**: Apple Vision Framework (Face and Eye Tracking)
- **Machine Learning**: Core ML
- **Architecture Pattern**: MVVM

### Project Structure

```
GazeTurn/
├── AI/                              # AI and Machine Learning Modules
│   ├── EnvironmentAnalyzer.swift   # Environment Analysis
│   ├── GestureLearningEngine.swift # Gesture Learning
│   ├── GesturePredictionModel.swift # Gesture Prediction
│   └── SmartCalibrationEngine.swift # Smart Calibration
├── Engine/                          # Core Engines
├── FeatManager/                     # Feature Management
├── Gestures/                        # Gesture Detection
│   └── MicroGestureDetector.swift
├── Model/                           # Data Models
├── View/                            # UI Views
│   ├── ContentView.swift           # Main View
│   ├── DashboardView.swift         # Dashboard
│   ├── CalibrationView.swift       # Calibration Interface
│   ├── BrowseView.swift            # Browse Interface
│   ├── FileListView.swift          # File List
│   ├── InstrumentSelectionView.swift # Instrument Selection
│   ├── SettingsView.swift          # Settings Interface
│   └── GestureVisualizationView.swift # Gesture Visualization
├── ViewModel/                       # View Models
└── GazeTurnApp.swift               # App Entry Point
```

## Getting Started

### Installation

1. **Clone the repository**
   ```bash
   git clone git@github.com:terminal201467/GazeTurn.git
   cd GazeTurn
   ```

2. **Install dependencies**
   ```bash
   pod install
   ```

3. **Open the project**
   ```bash
   open GazeTurn.xcworkspace
   ```

4. **Configure camera permissions**

   The project includes camera permission configuration. See [CAMERA_PERMISSION_SETUP.md](CAMERA_PERMISSION_SETUP.md) for details.

5. **Build and run**
   - Select your target device in Xcode
   - Click Run (⌘R)

### First-Time Setup

1. **Launch the app** - Grant camera permission when prompted on first launch
2. **Select your instrument** - Choose your instrument type; the system will adjust detection parameters accordingly
3. **Calibrate** - Go to Settings → Calibration and follow the on-screen instructions
4. **Start using** - Import PDF sheet music and use eye movements or head gestures to turn pages

### Page-Turning Gestures

- **Look right** → Next page
- **Look left** → Previous page
- **Turn head right** → Next page
- **Turn head left** → Previous page

### Calibration Tips

For the best experience:
- Use in stable lighting conditions
- Maintain appropriate distance between the device and your eyes
- Re-calibrate periodically to adapt to different environments

## Roadmap

### Current Features
- ✅ Eye tracking functionality
- ✅ Gesture recognition
- ✅ AI-powered learning
- ✅ Multi-instrument support
- ✅ PDF sheet music management
- ✅ Comprehensive UI tests

### Future Plans
- ⏳ Apple Watch pairing support
- ⏳ Cloud sheet music sync
- ⏳ Multi-user collaboration mode
- ⏳ Sheet music annotation
- ⏳ Recording integration
- ⏳ More gesture customization options

## Contributing

Contributions are welcome! If you'd like to contribute to GazeTurn:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Support

Having issues?
- Check [Issues](https://github.com/terminal201467/GazeTurn/issues)
- Submit a new Issue
- Refer to [Camera Permission Setup](CAMERA_PERMISSION_SETUP.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to Apple Vision Framework for providing powerful visual recognition capabilities
- Thanks to all contributors and testers for their support

## Contact

- **Project Lead**: Jhen Mu
- **GitHub**: [@terminal201467](https://github.com/terminal201467)
- **Project Link**: [https://github.com/terminal201467/GazeTurn](https://github.com/terminal201467/GazeTurn)

---

<p align="center">
  用眼神翻譜，讓音樂更流暢 🎵👁️<br/>
  Turn pages with your eyes, let the music flow
</p>

<p align="center">
  Made with ❤️ for musicians everywhere
</p>
