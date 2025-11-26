# GazeTurn

<p align="center">
  <img src="assets/logo.png" alt="GazeTurn Logo" width="200"/>
</p>

<p align="center">
  <strong>智能眼動翻譜 - 讓音樂演奏更自由</strong>
</p>

<p align="center">
  使用眼動追蹤和手勢識別技術，實現免手操作的樂譜翻頁體驗
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

## 技術架構

### 核心技術棧
- **語言**: Swift
- **UI 框架**: SwiftUI
- **視覺框架**: Vision Framework (臉部和眼動追蹤)
- **機器學習**: Core ML
- **架構模式**: MVVM

### 專案結構

```
GazeTurn/
├── AI/                              # AI 和機器學習模組
│   ├── EnvironmentAnalyzer.swift   # 環境分析
│   ├── GestureLearningEngine.swift # 手勢學習
│   ├── GesturePredictionModel.swift # 手勢預測
│   └── SmartCalibrationEngine.swift # 智能校準
├── Engine/                          # 核心引擎
├── FeatManager/                     # 特徵管理
├── Gestures/                        # 手勢檢測
│   └── MicroGestureDetector.swift
├── Model/                           # 資料模型
├── View/                            # UI 視圖
│   ├── ContentView.swift           # 主視圖
│   ├── DashboardView.swift         # 儀表板
│   ├── CalibrationView.swift       # 校準介面
│   ├── BrowseView.swift            # 瀏覽介面
│   ├── FileListView.swift          # 檔案列表
│   ├── InstrumentSelectionView.swift # 樂器選擇
│   ├── SettingsView.swift          # 設定介面
│   └── GestureVisualizationView.swift # 手勢視覺化
├── ViewModel/                       # 視圖模型
└── GazeTurnApp.swift               # App 入口點
```

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

1. **啟動應用程式**
   - 首次啟動時會要求相機權限，請允許存取

2. **選擇樂器**
   - 選擇您演奏的樂器類型
   - 系統會根據樂器調整偵測參數

3. **校準**
   - 進入設定 → 校準
   - 按照畫面指示完成眼動校準

4. **開始使用**
   - 匯入 PDF 樂譜
   - 使用眼動或頭部手勢翻頁

## 使用方式

### 翻頁手勢

- **向右看** → 下一頁
- **向左看** → 上一頁
- **頭部右轉** → 下一頁
- **頭部左轉** → 上一頁

### 校準建議

為獲得最佳體驗，建議：
- 在穩定的光線環境下使用
- 保持設備與眼睛的適當距離
- 定期重新校準以適應不同環境

## 開發路線圖

### 當前版本功能
- ✅ 眼動追蹤基礎功能
- ✅ 手勢識別
- ✅ AI 智能學習
- ✅ 多樂器支援
- ✅ PDF 樂譜管理

### 未來計劃
- ⏳ Apple Watch 配對支援
- ⏳ 雲端樂譜同步
- ⏳ 多人協作模式
- ⏳ 樂譜註解功能
- ⏳ 錄音整合
- ⏳ 更多手勢自訂選項

## 貢獻指南

歡迎貢獻！如果您想為 GazeTurn 做出貢獻：

1. Fork 此專案
2. 創建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟 Pull Request

## 技術支援

遇到問題？
- 查看 [Issues](https://github.com/terminal201467/GazeTurn/issues)
- 提交新的 Issue
- 參考 [相機權限設定說明](CAMERA_PERMISSION_SETUP.md)

## 授權

此專案使用 MIT 授權 - 詳見 [LICENSE](LICENSE) 文件

## 致謝

- 感謝 Apple Vision Framework 提供強大的視覺識別能力
- 感謝所有貢獻者和測試者的支持

## 聯絡方式

- **專案負責人**: Jhen Mu
- **GitHub**: [@terminal201467](https://github.com/terminal201467)
- **專案連結**: [https://github.com/terminal201467/GazeTurn](https://github.com/terminal201467/GazeTurn)

---

<p align="center">
  用眼神翻譜，讓音樂更流暢 🎵👁️
</p>

<p align="center">
  Made with ❤️ for musicians everywhere
</p>
