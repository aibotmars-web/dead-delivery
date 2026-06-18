# 台灣外送哥 - Art Style Guide
# 美術規範文件

> Version: 1.0
> Last Updated: 2026-06-11
> Style Reference: `/Users/marsbot/game-assets/dd_upgrade_tiers.jpg`

---

## 1. Overall Style

### 1.1 Art Direction
```
風格：乾淨像素風（Clean Pixel Art）
參考：機車升級圖（dd_upgrade_tiers.jpg）的側面展示風格
特色：
  - 線條清晰，不模糊
  - 色塊分明，不用太多漸層
  - Q 版比例但不幼稚
  - 霓虹色調點綴（夜市感）
```

### 1.2 NOT This Style
```
❌ 寫實像素（太複雜）
❌ 極簡幾何（太抽象）
❌ 日系動漫（不是這個方向）
❌ 3D 渲染（技術不符）
❌ 塗鴉手繪風（不統一）
```

---

## 2. Color Palette（調色盤）

### 2.1 Core Palette — 32 色限制
```
所有素材必須只使用以下 32 色，確保風格統一。

背景色（4色）：
  #0A0A1A  極深藍黑（夜空）
  #1A1A2E  深藍（建築陰影）
  #16213E  深藍灰（地面）
  #2C2C44  中灰藍（次要背景）

地面/建築（6色）：
  #4A4A68  灰藍（柏油路）
  #6B6B8D  淺灰（人行道）
  #8B7355  棕（土路/木頭）
  #A08D6E  淺棕（木材/箱子）
  #5C4033  深棕（門/家具）
  #3D2B1F  極深棕（陰影）

角色/物件（8色）：
  #E8E8E8  白（衣服亮部/UI文字）
  #B0B0B0  淺灰（衣服暗部）
  #F5A623  橙黃（外送包/安全帽）
  #D4830A  深橙（外送包陰影）
  #4ECDC4  青綠（機車/科技感）
  #2D9B93  深青（機車陰影）
  #FF6B6B  珊瑚紅（重要標示/生命值）
  #CC4444  深紅（危險/扣血）

霓虹/夜市（6色）：
  #FF2D78  霓虹粉（招牌）
  #00E5FF  霓虹青（招牌）
  #FFD700  霓虹金（燈光/金幣）
  #7B68EE  霓虹紫（特效）
  #00FF88  霓虹綠（正面事件）
  #FF4444  霓虹紅（紅燈/警告）

皮膚/食物（4色）：
  #F0C896  膚色亮
  #D4A76A  膚色暗
  #8BC34A  綠（蔬菜/綠燈）
  #E57373  肉色/食物

UI 專用（4色）：
  #FFFFFF  純白（重要文字）
  #888888  中灰（次要文字）
  #333333  深灰（UI背景）
  #000000  純黑（邊框/描邊）
```

### 2.2 Color Rules
```
1. 角色永遠用橙黃系（外送員識別色）
2. 機車用青綠系
3. 夜市場景多用霓虹色點綴
4. UI 文字只用白/灰/黑
5. 正面事件 = 綠/金，負面事件 = 紅
6. 背景永遠偏暗，讓角色跳出來
```

---

## 3. Sprite Specifications

### 3.1 Size Standards
```
角色（人物）：    32 x 32 px
機車：           48 x 32 px（橫向較寬）
NPC：           32 x 32 px
寵物：          24 x 24 px
地圖 Tile：     16 x 16 px
建築物：        64 x 64 px 或 64 x 96 px（高樓）
UI Icon：       16 x 16 px
裝備 Icon：     24 x 24 px
卡片插圖：      128 x 96 px
全螢幕插圖：    320 x 480 px（手機直式）
```

### 3.2 Character Proportions
```
頭身比：1:1.5（Q版偏大頭）
頭部：約 12x12 px
身體：約 12x8 px
腿部：約 12x8 px

  ┌──────┐
  │ 頭   │ 12px
  │      │
  ├──────┤
  │ 身體 │ 8px
  ├──────┤
  │ 腿   │ 8px
  └──────┘
    12px
```

### 3.3 Animation Frames
```
角色動畫：
  idle（待機）：    2 幀（微微上下晃）
  walk（走路）：    4 幀
  ride（騎車）：    2 幀（身體微晃）
  pickup（取餐）：  3 幀
  deliver（送餐）：  3 幀
  fall（摔倒）：    3 幀
  celebrate（開心）：3 幀

機車動畫：
  idle：     1 幀
  moving：   2 幀（輪子轉）
  boost：    2 幀（加速線）
  breakdown：2 幀（冒煙）

NPC 動畫：
  idle：     2 幀
  talk：     2 幀
  angry：    2 幀
  happy：    2 幀
```

---

## 4. Map Tiles

### 4.1 Tile Set（16x16 px each）
```
地面：
  - 柏油路（直/橫/十字/T字/轉角）
  - 人行道
  - 斑馬線
  - 紅磚道（老街）
  - 草地

建築：
  - 夜市攤位（多種）
  - 便利商店
  - 餐廳
  - 住宅大樓
  - 公寓
  - 廟宇

道具/裝飾：
  - 紅綠燈
  - 路燈
  - 機車停放
  - 垃圾桶
  - 電線桿
  - 霓虹招牌
  - 紅燈籠
  - 盆栽
  - 消防栓
```

### 4.2 Map View
```
視角：正上方俯視（Top-down）
鏡頭：跟隨角色，角色永遠在畫面中央
地圖大小（Phase 1）：50 x 50 tiles = 800 x 800 px 實際範圍
縮放：2x pixel scaling（16px tile 顯示為 32px）
```

---

## 5. UI Design

### 5.1 HUD（遊戲中常駐 UI）
```
┌──────────────────────────────────┐
│ ⏱️ 08:45  💰$1,250  ⭐4.7  ⚡80% │ ← 頂部資訊列
│                                    │
│                                    │
│          [遊戲地圖畫面]              │
│                                    │
│                                    │
│                         [小地圖]    │ ← 右下角
│                                    │
├──────────────────────────────────┤
│  📱手機    目前訂單資訊    🛵上/下車  │ ← 底部操作列
└──────────────────────────────────┘

頂部：計時器 | 金錢 | 評分星等 | 體力百分比
底部：手機按鈕 | 當前訂單 | 上下車按鈕
右下：小地圖（顯示目的地方向）
```

### 5.2 Phone UI（覆蓋層）
```
點擊 📱 打開手機介面：

┌──────────────────────┐
│  ╔══════════════════╗ │
│  ║  📋 訂單  📈 股票 ║ │ ← Tab 切換
│  ║  🗺️ 地圖  ⚙️ 設定 ║ │
│  ╠══════════════════╣ │
│  ║                    ║ │
│  ║  訂單列表 / 股票   ║ │
│  ║  / 全地圖 / 設定   ║ │
│  ║                    ║ │
│  ╠══════════════════╣ │
│  ║    [關閉手機]      ║ │
│  ╚══════════════════╝ │
└──────────────────────┘
```

### 5.3 Event Popup
```
┌──────────────────────────┐
│                            │
│  ⚠️ [事件圖示]              │
│                            │
│  「突然下大雨了！」          │
│                            │
│  ┌──────┐  ┌──────────┐   │
│  │穿雨衣  │  │硬騎不穿    │   │
│  │-速度   │  │-餐點品質   │   │
│  └──────┘  └──────────┘   │
│                            │
└──────────────────────────┘

特點：
  - 半透明黑色背景覆蓋遊戲畫面
  - 中央彈出卡片
  - 最多 2-3 個選項
  - 每個選項顯示效果預覽
```

### 5.4 Card Draw（抽卡動畫）
```
送完一單 → 卡片從底部飛入 → 翻轉 → 顯示內容

卡片設計：
  🟡 機會卡：金色邊框，星星裝飾
  🔴 命運卡：紅色邊框，骷髏裝飾
  🟣 稀有卡：紫色邊框，鑽石裝飾，發光特效

卡片內容：
  ┌────────────────┐
  │ ★ 機會 ★        │ ← 卡片類型
  │                  │
  │  [事件插圖]      │ ← 128x96 插圖
  │                  │
  │ 客人給你$200小費  │ ← 事件描述
  │                  │
  │ 💰 +$200        │ ← 效果
  └────────────────┘
```

---

## 6. fal.ai Prompt Templates

### 6.1 Standard Prefix（所有生圖都加這段）
```
"16-bit clean pixel art, top-down game asset, 
limited 32-color palette, dark background, 
Taiwan night market neon style, 
consistent with retro SNES aesthetic, 
sharp pixel edges, no anti-aliasing, "
```

### 6.2 Character Prompt
```
PREFIX + "chibi proportions 1:1.5 head-to-body ratio, 
delivery rider character wearing orange helmet and vest, 
[SPECIFIC POSE/ACTION], 
32x32 pixel sprite, game asset"
```

### 6.3 Environment Prompt
```
PREFIX + "top-down view tileset, 
Taiwan urban street at night, 
[SPECIFIC ELEMENTS: night market stalls / apartment buildings / traffic lights], 
16x16 tile grid, seamless tileable, game asset"
```

### 6.4 UI Prompt
```
PREFIX + "game UI element, 
[SPECIFIC UI: health bar / skill icon / card frame], 
clean flat design, dark background, 
pixel art icon, game asset"
```

### 6.5 Card Illustration Prompt
```
PREFIX + "event card illustration 128x96 pixels, 
[SPECIFIC EVENT: rainy delivery / angry customer / stock market crash], 
dramatic scene, expressive characters, 
bordered card frame, game asset"
```

---

## 7. Audio Direction

### 7.1 Music Style
```
BGM：Chiptune + Lo-fi 混合
  - 送餐中：輕快節奏，有摩托車引擎聲底
  - 夜市場景：熱鬧，有叫賣聲採樣
  - 房間：放鬆 lo-fi，雨聲背景
  - 緊張時刻：節奏加快，加入鼓點
  - 每日結算：輕鬆愉快
```

### 7.2 Sound Effects
```
核心音效：
  - 機車發動/引擎聲
  - 煞車聲
  - 取餐「叮」
  - 送達「噹噹！」
  - 金幣掉落
  - 升級音效
  - 抽卡翻轉
  - 好事件（歡樂短旋律）
  - 壞事件（低沉短旋律）
  - 下雨聲
  - 紅綠燈倒數
  - 手機通知音
  - 按鈕點擊
```

---

## 8. Responsive Design

### 8.1 Target Resolutions
```
手機直式（主力）：
  360 x 640  (HD)
  375 x 812  (iPhone X+)
  390 x 844  (iPhone 13+)
  412 x 915  (Android 常見)

平板：
  768 x 1024 (iPad)

電腦：
  1920 x 1080（遊戲置中，兩側留黑邊或裝飾）
```

### 8.2 Scaling Strategy
```
遊戲畫面固定比例 9:16（直式）
Pixel art 用整數倍縮放（2x, 3x, 4x）
UI 元素自適應螢幕寬度
底部操作列固定在安全區域內（避開瀏海/Home 鍵）
```

---

*所有美術素材生成時必須參考本文件。風格不統一時以本文件為準。*
