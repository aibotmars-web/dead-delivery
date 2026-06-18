# 台灣外送哥 - Game Design Document (GDD)
# Taiwan Delivery Bro - 遊戲設計文件

> Version: 1.1
> Last Updated: 2026-06-11
> Status: Pre-Development

---

## 1. Game Overview

### 1.1 Concept
**一句話：** 從頂樓加蓋騎破車開始，靠外送＋炒股買到豪宅養貓的外送員人生模擬器。

**遊戲名稱：** 台灣外送哥 / Taiwan Delivery Bro
**類型：** 外送模擬 + Roguelike 隨機事件 + 經營養成
**平台：** Web（Phase 1）→ iOS / Android（Phase 2+）
**引擎：** Flutter + Flame Engine
**美術風格：** 像素風（Pixel Art），霓虹夜市色調，機車升級圖那種乾淨側面展示風格
**操作方式：** 點擊 + 選擇（單手可玩）
**目標玩家：** 外送員、上班族、學生、所有對台灣日常有共鳴的人
**商業模式：** 廣告（AdMob / AdSense）+ 未來可選 IAP

### 1.2 Core Loop
```
接單 → 取餐(A點) → 規劃路線 → 騎車送餐(B點)
  → 途中隨機事件不斷發生
  → 到達 → 下車 → 送餐互動（爬樓梯/客人反應）
  → 獲得報酬 + 抽卡
  → 接下一單 or 回家休息
  → 每日結算：外送收入 + 股票損益
  → 升級裝備 / 佈置房間 / 養寵物
  → 下一天（難度漸增）
```

### 1.3 Unique Selling Points (USP)
1. **全世界第一款「外送員人生模擬器」** — 不是駕駛遊戲，是生活模擬
2. **AI 即時新聞系統** — 真實新聞自動轉換成遊戲事件（獨家）
3. **真實天氣/股票連動** — 現實下雨遊戲也下雨，台積電漲遊戲也漲
4. **台灣在地文化** — 夜市、媽祖遶境、機車文化，辨識度極高
5. **自帶傳播力** — 每個事件都是社群分享素材

---

## 2. Gameplay Systems (16 Systems)

### System 1: Core Delivery（送餐核心）⭐ Phase 1
```
流程：
  1. 打開手機 APP → 看到可接訂單列表
  2. 選擇訂單（顯示：餐廳位置、客戶位置、報酬、時限）
  3. 點擊餐廳 → 角色自動騎車前往
  4. 到達餐廳 → 取餐互動（等餐/催餐/餐沒好要等）
  5. 點擊客戶位置 → 自動騎車前往
  6. 途中觸發隨機事件
  7. 到達目的地 → 送餐互動（爬樓梯/客人反應/小費）
  8. 完成 → 獲得報酬 → 可接下一單

操作方式：
  - 地圖俯視角，點擊目的地自動移動
  - 事件彈出時選 A 或 B
  - 全程點擊+選擇，單手操作

限時機制：
  - 每單有倒數計時
  - 準時送達 → 全額 + 可能有小費
  - 超時 5 分鐘內 → 開始扣錢（每分鐘扣 $10）
  - 超時太久 → 客人取消，白跑
  - 提前送達 → 額外獎金

進階（Phase 2+）：
  - 多點取餐：A取+B取 → 照順序送 C→D
  - 客人途中取消訂單
  - 客人臨時改地址
  - 同時接多單（外送包容量限制）
```

### System 2: Random Events（隨機事件三層系統）⭐ Phase 1

#### Layer 1: 機會 & 命運卡（大富翁式）
每送完一單，抽一張卡：
```
🟡 機會卡（好事，60%機率）：
  - 客人多給小費 $200
  - 路上撿到改裝零件
  - 手機訊號超好，導航加速
  - 連續三個綠燈
  - 神秘客人送你限定家具
  - 你買的股票漲停了
  - 前方道路暢通無阻
  - 店家多送你一份吃的

🔴 命運卡（壞事，35%機率）：
  - 前方施工繞路 3 分鐘
  - 被開罰單 $600
  - 手機摔地上螢幕裂
  - 突然暴雨
  - 被狗追
  - 股票跌停
  - 外送包拉鍊壞了
  - 機車被拖走（違停）

🟣 稀有卡（5%機率）：
  - 外送之神降臨（全部訂單完成）
  - 撿到鑽石項鍊（一個月薪水）
  - 送餐到鬼屋（恐怖特殊關卡）
  - 被星探發現（隱藏結局線索）
```

#### Layer 2: 城市即時事件（路上隨機觸發）
```
交通事件：
  - 車禍封路 → 自動改道
  - 路跑活動 → 整條路封
  - 警察臨檢 → 停下來等
  - 道路施工 → 替代路線
  - 三寶切車 → 閃避（失敗=摔車）
  - 超長紅燈 → 等 or 闖（罰單風險）
  - 逆向機車 → 緊急閃避
  - 塞車 → 鑽車縫小遊戲

民俗事件：
  - 媽祖出巡 → 封路，拜一下運氣+
  - 廟會鞭炮 → 嚇到摔車機率+
  - 元宵燈會 → 人多騎不動，小費加倍
  - 中元普渡 → 路邊燒紙錢，特殊事件

AI 路人事件：
  - 醉漢擋路
  - 阿伯逆向
  - 小孩衝出來
  - 路邊吵架圍觀
  - 有人問路

取餐事件：
  - 餐還沒好 → 等
  - 飲料忘了做 → 多等
  - 店家搞錯單 → 重做
  - 秒出餐 → Lucky!

送餐事件：
  - 12 樓沒電梯 → 爬樓梯（體力消耗）
  - 下車滑倒餐打翻 → 損失
  - 客人不接電話 → 等待
  - 地址寫錯 → 多繞路
  - 客人途中取消 → 白跑
  - 到了人消失 → 等+打電話
  - 客人叫上樓 → 扣時間
  - 問有沒有備湯匙 → 有=小費，沒有=差評
  - 客人給現金小費 → 獎勵
  - 奧客要求重送 → 大扣時間
```

#### Layer 3: AI 新聞卡（獨家功能）⭐ Phase 2
```
技術實現：
  1. 每日 Claude API 抓台灣新聞頭條
  2. AI 分析 → 轉換成遊戲事件參數
  3. fal.ai 自動生成事件卡圖片
  4. 推送到所有玩家

範例：
  「核電延役未通過」→ 空氣差、移動速度 -2%
  「油價上漲」→ 加油變貴
  「颱風警報」→ 風雨加劇、單價翻倍
  「某區停電」→ 紅綠燈全壞
  「世界棒球賽贏了」→ 慶祝訂單暴增
  「股市大跌」→ 投資慘、但外送單多
  「食安問題」→ 某店訂單歸零
  「選舉造勢」→ 某區交通癱瘓
  「梅雨季」→ 連續下雨一週
```

### System 3: Equipment Upgrade（裝備升級）⭐ Phase 1
```
7 個裝備欄位：

  🛵 機車（核心裝備）
    Lv.1 破舊二手車 → 速度慢、容易拋錨
    Lv.2 一般機車 → 正常速度
    Lv.3 改裝機車 → 速度快、穩定
    Lv.4 氮氣加速車 → 極速、有衝刺技能
    Lv.5 末日戰車 → 最終型態
    每級影響：速度、穩定性（餐不容易翻）、油耗

  📦 外送包
    影響：保溫（餐不會涼）、防震（不容易翻）、容量（接多單）
  
  ⛑️ 安全帽
    影響：防禦（摔車損失減少）、生命值上限

  📹 行車記錄器
    影響：小地圖偵測範圍、提前看到事件

  🎧 藍芽耳機
    影響：閃避率（聽到殭屍/三寶聲音預警）

  🧤 手套
    影響：攻擊速度、下雨時餐不容易滑掉

  👟 雨鞋
    影響：下雨不減速、爬樓梯速度

  額外裝備：
  📱 手機 → 電量、導航清晰度、股票刷新速度
  🥢 備品包 → 有湯匙筷子=小費神器
```

### System 4: Stock Investment（股票投資）⭐ Phase 2
```
5 支代表性股票：
  🟦 台積電 (2330) - 穩定成長型
  🟥 鴻海 (2317) - 波動中等
  🟩 聯發科 (2454) - 高波動
  🟨 中華電 (2412) - 防禦型（穩定配息）
  🟪 長榮 (2603) - 高風險高報酬

操作時機：
  - 等紅燈時 → 打開手機看盤
  - 等餐時 → 下單買賣
  - 每日結算 → 看損益

連動方式（Phase 3）：
  - 連動真實股票漲跌方向（不是真實金額）
  - 遊戲幣操作，不是真錢
  - 每天開盤收盤

Phase 1 替代方案：
  - 用模擬演算法產生漲跌
  - 受 AI 新聞事件影響
```

### System 5: Side Jobs（副業 + 多元收入）Phase 3
```
  🏪 便利商店夜班 → 固定時薪
  📸 美食部落客 → 拍食記賺業配
  🔧 機車行學徒 → 學修車省錢
  🎓 線上課程 → 花錢學新技能
  🏪 終極目標：開自己的餐廳 → 視角翻轉
```

### System 6: Housing（住房系統）Phase 3
```
5 個等級：
  Lv.1 頂樓加蓋（免費）→ 小、漏水、體力恢復差
  Lv.2 雅房（月租 $5,000）→ 有冷氣、正常恢復
  Lv.3 套房（月租 $12,000）→ 可養寵物、可擺家具
  Lv.4 小公寓（買 $300萬）→ 有廚房、大空間佈置
  Lv.5 豪宅（買 $2,000萬）→ 終極目標、成就解鎖
```

### System 7: Room Decoration（房間佈置）Phase 3
```
家具來源：商店買 / 送餐獎勵 / 成就解鎖 / 隨機掉落

可佈置：
  🛏️ 床 → 影響體力恢復
  🖥️ 電腦桌 → 在家看股票
  🎮 遊戲機 → 休息日小遊戲
  🏍️ 機車模型架 → 展示收藏
  📸 照片牆 → 自動記錄精彩瞬間
  🪴 盆栽 → 心情值+
  🏅 獎盃櫃 → 展示成就

社群功能：一鍵截圖分享 / 逛別人房間 / 按讚排行
```

### System 8: Pet System（寵物系統）Phase 3
```
  🐕 狗 → 閃避率 +5%，要買飼料
  🐈 貓 → 運氣 +5%，偶爾打翻東西
  🐹 倉鼠 → 存錢利息 +2%，成本最低
  🦎 蜥蜴 → 冷靜值+（奧客傷害減半），偶爾嚇到客人
  🐟 魚缸 → 體力恢復 +5%，要換水

互動：餵食、玩耍、一起睡、拍照分享
```

### System 9: Health & Stamina（體力健康系統）Phase 2
```
  💪 體力值 → 送餐消耗，爬樓梯消耗更多，歸零強制回家
  🍔 飲食 → 路邊攤/便利商店/自己煮，各有成本和恢復量
  😴 睡眠 → 床品質影響恢復，熬夜隔天體力上限降
  🤕 受傷 → 摔車扣血，嚴重要看醫生花錢花時間
  😷 生病 → 淋雨太久感冒、熬夜生病，強制休息
```

### System 10: Relationships（人際關係）Phase 2
```
  🏪 店家好感度 → 常去的店出餐變快、多送吃的
  👤 常客系統 → 重複送同客人，小費越多，解鎖劇情
  🛵 外送員同行 → 打招呼、分享情報、搶單競爭
```

### System 11: In-Game Social Media（遊戲內社群「外送圈」）Phase 3
```
  自動發文「今日外送日記」
  NPC 也發文（有些藏隱藏任務線索）
  熱門排行：最慘外送員、最高收入、最扯奧客
```

### System 12: Achievements & Titles（成就稱號）⭐ Phase 1
```
  外送成就：菜鳥騎士、老手、外送之王、鐵人、暴風騎士
  搞笑成就：翻車大師、奧客剋星、紅燈王、被狗追達人
  隱藏成就：午夜送餐員、媽祖加持、人生贏家
  稱號顯示在角色頭上
```

### System 13: Vehicle Customization（機車外觀）Phase 2
```
  塗裝：熊貓紅、Uber 綠、閃電黃、節日限定
  安全帽貼紙：搞笑文字
  外送包掛飾：公仔、幸運符
```

### System 14: Seasonal Events（季節活動）Phase 2+
```
  🧧 過年：紅包雨、年夜飯大單、金色機車
  🥟 端午：送粽子、龍舟封路
  🥮 中秋：烤肉單暴增、放天燈
  🎃 萬聖節：鬼屋送餐、殭屍客人
  🎄 聖誕節：聖誕老人裝、送禮物任務
```

### System 15: Daily Missions & Streaks（每日任務 + 連登）⭐ Phase 1
```
  每日任務（3個）：
    - 送 5 單 → 金幣獎勵
    - 準時送達 3 次 → 裝備獎勵
    - 完成 1 次雨天送餐 → 稀有成就

  連續登入：
    Day 1: 金幣
    Day 3: 稀有安全帽
    Day 7: 新機車塗裝
    Day 30: 限定寵物
    斷了歸零
```

### System 16: Main Story（主線劇情）Phase 2
```
  Chapter 1：菜鳥入行 → 學操作、破爛機車、被奧客罵
  Chapter 2：漸入佳境 → 認識常客、找到路線
  Chapter 3：人生低谷 → 車壞、房租到期、股票虧
  Chapter 4：翻身 → 升級裝備、炒股賺錢
  Chapter 5：選擇 → 繼續外送 or 開餐廳 or 全職投資
  
  每 Chapter 解鎖新地圖、新角色、新事件
```

---

## 3. Art Direction

### 3.1 Style Reference
- **基準風格：** 機車升級 4 階段那張圖（dd_upgrade_tiers.jpg）
- **特色：** 乾淨像素線條、霓虹色調、側面展示感
- **色調：** 深色背景 + 霓虹粉紅/青綠/暖橘
- **角色比例：** Q 版，頭身比約 1:2
- **像素規格：** 角色 32x32，場景 tile 16x16
- **調色盤：** 限制 32 色，確保全遊戲風格統一

### 3.2 Asset List
```
角色：
  - 外送員（男/女各 1）idle + walk + ride 動畫
  - NPC 店家老闆 x5
  - NPC 客人 x10（含奧客、好客人、阿嬤等）
  - NPC 路人 x5
  - 寵物 x5（狗/貓/倉鼠/蜥蜴/魚）

機車：
  - 5 階段外觀（破車→末日戰車）
  - 每階段 3 色塗裝

場景：
  - 城市地圖 tiles（道路、建築、夜市攤位）
  - 室內場景：餐廳、客戶家門口、樓梯間
  - 房間佈置用家具 x30+

UI：
  - HUD（血條、體力條、金錢、計時器、小地圖）
  - 手機介面（接單、地圖、股票、社群）
  - 卡片（機會卡、命運卡、新聞卡）
  - 裝備欄、商店、每日結算

特效：
  - 天氣（雨、霧、雪）
  - 機車排氣、加速線
  - 金幣掉落、升級光效
```

### 3.3 Concept Art Location
所有概念圖存放於：`/Users/marsbot/game-assets/`

---

## 4. Technical Architecture

### 4.1 Tech Stack
```
Framework: Flutter 3.44+ (Web → iOS → Android)
Game Engine: Flame Engine (2D game framework for Flutter)
Language: Dart
State Management: Riverpod
Local Storage: SharedPreferences + Hive (local database)
Backend (Phase 2+): Supabase (auth, leaderboard, social)
AI Integration: Claude API (news → events)
Art Generation: fal.ai (asset pipeline)
Ads: Google AdSense (Web) → AdMob (App)
Analytics: Firebase Analytics
```

### 4.2 Project Structure
```
dead-delivery/
├── docs/
│   ├── GDD.md              ← 你在這裡
│   ├── PROGRESS.md          ← 開發進度追蹤
│   ├── PHASE_1_SPEC.md      ← Phase 1 詳細規格
│   └── ART_GUIDE.md         ← 美術規範
├── assets/
│   ├── sprites/             ← 角色 sprite sheets
│   ├── tiles/               ← 地圖 tiles
│   ├── ui/                  ← UI 元素
│   └── audio/               ← 音效音樂
├── lib/
│   ├── main.dart
│   ├── config/              ← 遊戲設定、常數
│   ├── models/              ← 資料模型
│   │   ├── player.dart
│   │   ├── order.dart
│   │   ├── equipment.dart
│   │   ├── event_card.dart
│   │   └── stock.dart
│   ├── game/                ← Flame 遊戲核心
│   │   ├── dead_delivery_game.dart
│   │   ├── components/      ← 遊戲物件
│   │   └── systems/         ← 遊戲系統
│   ├── screens/             ← Flutter UI 頁面
│   │   ├── home_screen.dart
│   │   ├── game_screen.dart
│   │   ├── inventory_screen.dart
│   │   ├── daily_summary_screen.dart
│   │   └── room_screen.dart
│   ├── services/            ← 後端服務
│   │   ├── game_state_service.dart
│   │   ├── event_service.dart
│   │   ├── ad_service.dart
│   │   └── news_service.dart
│   └── widgets/             ← 共用 UI 元件
├── test/                    ← 測試
└── web/                     ← Web 平台設定
```

---

## 5. Monetization

### 5.1 Ad Strategy
```
Banner Ad（持續顯示）：
  - 遊戲畫面底部，不擋操作
  - eCPM: $1-3

Interstitial Ad（插頁）：
  - 每日結算後
  - 每 5 單完成後
  - eCPM: $5-15

Rewarded Video Ad（看廣告換獎勵）：
  - 「看廣告免費叫拖車」（機車拋錨時）
  - 「看廣告撿回打翻的餐」
  - 「看廣告多一個升級選項」
  - 「看廣告雙倍今日收入」
  - 「看廣告免費復活」（體力歸零時）
  - eCPM: $15-45（最高收入來源）
```

### 5.2 Revenue Estimate (Conservative)
```
假設 DAU 1,000 人：
  Banner: 1000 × $2 CPM × 10 impressions = $20/天
  Interstitial: 1000 × 3 次 × $10 CPM = $30/天
  Rewarded: 1000 × 2 次 × $30 CPM = $60/天
  
  Total: ~$110/天 = ~$3,300/月 = ~NT$100,000/月

假設 DAU 10,000 人：
  ~NT$1,000,000/月
```

---

## 6. Development Phases

### Phase 1: MVP（最小可玩版）— 2 週
```
目標：驗證「外送模擬」有沒有人想玩

包含：
  ✅ System 1: 送餐核心（1 張地圖、3 餐廳、5 客戶點）
  ✅ System 2: 隨機事件（Layer 1 抽卡 10 張 + Layer 2 城市事件 10 個）
  ✅ System 3: 裝備升級（機車 3 階 + 外送包 3 階）
  ✅ System 12: 成就系統（10 個基本成就）
  ✅ System 15: 每日任務（3 個）+ 連登 7 天
  ✅ 廣告：Banner + Interstitial + Rewarded
  ✅ Web 版上線（GitHub Pages / Cloudflare）

不包含：
  ❌ 股票、房間、寵物、劇情、社群
  ❌ 多點連送
  ❌ AI 新聞卡
  ❌ App 版本

驗證指標：
  - Day 1 Retention > 40%
  - Day 7 Retention > 15%
  - 平均遊玩時間 > 10 分鐘/次
```

### Phase 2: Content Update — +2 週
```
前提：Phase 1 驗證通過

新增：
  ✅ System 4: 股票投資（模擬數據）
  ✅ System 9: 體力健康系統
  ✅ System 10: 人際關係（店家+客人好感度）
  ✅ System 13: 機車外觀自訂
  ✅ System 14: 第一個季節活動
  ✅ System 16: 主線劇情 Chapter 1-2
  ✅ 多點連送（A→B→C→D）
  ✅ 隨機事件擴充到 30+
  ✅ 地圖擴大（夜市區、商業區、住宅區）
```

### Phase 3: Life Sim Update — +2 週
```
前提：Phase 2 留存率穩定

新增：
  ✅ System 5: 副業系統
  ✅ System 6: 住房（租→買）
  ✅ System 7: 房間佈置
  ✅ System 8: 寵物系統
  ✅ System 11: 遊戲內社群「外送圈」
  ✅ 主線劇情 Chapter 3-5
  ✅ AI 新聞卡系統上線
  ✅ 真實天氣/股票連動
```

### Phase 4: App Store Launch — +1 週
```
前提：Web 版穩定、有流量

執行：
  ✅ Google Play 上架（$25）
  ✅ Apple App Store 上架（$99/年，確定能賺回來再開）
  ✅ AdMob 替換 AdSense
  ✅ 推播通知（每日任務提醒）
  ✅ 排行榜
  ✅ 逛別人房間
```

---

## 7. Marketing Strategy

### 7.1 Launch Plan
```
開發期間：
  - TikTok 拍開發過程（「我一個人做了一款外送員遊戲」）
  - 每天 1 支短影片

上線時：
  - PTT FoodDelivery 板發文
  - Dcard 外送員板
  - 巴哈姆特
  - Facebook 外送員社團

持續：
  - 每次 AI 新聞卡觸發大事件 → 截圖分享
  - 每個節日活動 → 宣傳素材
  - 玩家分享房間截圖 → UGC 內容
```

### 7.2 Viral Hooks
```
  「幹這遊戲也太真實了吧」→ 外送員共鳴
  「我房間比現實的還漂亮」→ 佈置截圖
  「台積電漲停我遊戲裡也賺爆」→ 股票連動
  「遊戲裡也在颱風太扯」→ 天氣連動
  「被奧客搞到」→ 事件分享
```

---

## 8. Progress Tracking

開發進度追蹤在：`/Users/marsbot/dead-delivery/docs/PROGRESS.md`

### How to Resume Development
```
任何 AI session 接手時：
1. 讀 docs/GDD.md（本文件）→ 了解遊戲全貌
2. 讀 docs/PROGRESS.md → 了解目前進度
3. 讀 docs/PHASE_1_SPEC.md → 了解當前 Phase 詳細規格
4. 繼續開發
```

---

## 9. Reference Files

```
概念圖：/Users/marsbot/game-assets/
  - dd_navigation.jpg      → 夜市街道騎車
  - dd_gameplay.jpg         → 遊戲畫面
  - dd_upgrade_tiers.jpg    → 機車升級（美術基準）
  - dd_equipment_ui.jpg     → 裝備欄 UI
  - dd_room.jpg             → 房間佈置
  - dd_housing_tiers.jpg    → 住房升級
  - dd_pets.jpg             → 寵物圖鑑
  - dd_events.jpg           → 隨機事件卡
  - dd_summary.jpg          → 每日結算
  - dd_hero_select.jpg      → 角色選擇
  - dd_enemies.jpg          → 敵人圖鑑
  - dd_gameplay_upgrade.jpg → 升級選擇

既有 Flutter 項目（可參考結構）：/Users/marsbot/piccraft/
```

---

*Document maintained by Claude Code. Update this file whenever game design changes.*
