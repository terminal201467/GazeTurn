# 相機權限設定說明

## 在 Xcode 中添加相機權限

GazeTurn 需要存取前置相機來進行臉部和手勢檢測。請按照以下步驟添加相機權限：

### 步驟 1: 打開 Info.plist

1. 在 Xcode 中打開 `GazeTurn.xcodeproj`
2. 在項目導航器中選擇 `GazeTurn` 目標
3. 選擇 `Info` 標籤頁

### 步驟 2: 添加相機權限描述

在 `Custom iOS Target Properties` 中添加以下鍵值對：

**方法 A: 使用 Info 標籤**
1. 點擊 `+` 按鈕
2. 選擇 `Privacy - Camera Usage Description`
3. 設定值為：`GazeTurn 需要使用相機來偵測您的眼動和頭部動作，以實現免手翻頁功能。`

**方法 B: 直接編輯 Info.plist（如果存在）**
```xml
<key>NSCameraUsageDescription</key>
<string>GazeTurn 需要使用相機來偵測您的眼動和頭部動作，以實現免手翻頁功能。</string>
```

### 英文版本

如果需要英文描述：
```
GazeTurn needs camera access to detect your eye movements and head gestures for hands-free page turning.
```

### 步驟 3: 驗證設定

1. 編譯並運行應用程式
2. 首次啟動時應該會看到相機權限請求
3. 授予權限後，相機功能將正常運作

## 權限處理

應用程式已實作以下權限處理邏輯（在 `GazeTurnViewModel` 中）：

- ✅ 自動檢查權限狀態
- ✅ 請求權限
- ✅ 處理權限被拒絕的情況
- ✅ 顯示權限狀態給用戶

## 除錯

如果相機無法啟動，請檢查：
1. Info.plist 中是否正確添加了 `NSCameraUsageDescription`
2. 在 iOS 設定中檢查應用程式的相機權限
3. 確認使用實體裝置測試（模擬器可能無法完整測試相機功能）
