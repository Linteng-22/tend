# Tend

**一个把「助手」当人处、而不是当搜索框用的多模型 AI 客户端。**

iPhone 和安卓两个原生客户端，接任意 OpenAI 兼容的接口。所有功能都在手机上自己跑完——
不依赖任何一台电脑开着，也没有服务器。**没有云端，没有订阅。**

**[→ 下载最新版](../../releases/latest)**　（这个仓库里别的东西都不用看）

---

## 目录

- [看两眼界面](#看两眼界面)
- [装它](#装它)
- [装完第一件事：加一个渠道](#装完第一件事加一个渠道)
- [它能做什么](#它能做什么)
- [它不做什么](#它不做什么)
- [没有服务器这件事](#没有服务器这件事)
- [安全上做了什么，没做什么](#安全上做了什么没做什么)
- [常见问题](#常见问题)
- [这个仓库里有什么](#这个仓库里有什么)
- [给维护者](#给维护者)

---

## 看两眼界面

<p align="center">
  <img src="docs/shots/02d-new-chat.png" width="24%" alt="空窗口：标记、名字、一句招呼">
  <img src="docs/shots/01-chat.png" width="24%" alt="对话">
  <img src="docs/shots/02-drawer.png" width="24%" alt="抽屉：搜索、按时间分堆的会话">
  <img src="docs/shots/06-settings.png" width="24%" alt="设置">
</p>

界面是照着「不要有 AI 感」做的：没有渐变、没有闪光星星、没有机器人头像，
也不用左右气泡那一套。层次靠排版、留白和字号拉开。系统玻璃只用在导航栏和工具栏，
内容区一律不透明。

---

## 装它

### 安卓

1. 去 [Releases](../../releases/latest) 下 `Tend-x.y.z.apk`
2. 手机上点开它，系统会问一次「允许安装未知应用」，允许即可
3. 装完打开，去 **设置 → 渠道** 加一个接口

最低 **Android 8.0**。包已经用固定密钥签过名，以后升级直接覆盖安装，不用卸载，
聊天记录也不会丢。

### iPhone

Releases 里的 `Tend-x.y.z-unsigned.ipa` 是**没签名**的包。苹果不允许直接装，
得用自己的 Apple ID 签一次：

- 用 **AltStore**、**Sideloadly** 或者 **Xcode** 都行；
- 免费 Apple ID 签出来的有效期是 **7 天**，到期重签（AltStore 可以配局域网自动刷新）；
- **99 美元/年**的开发者账号签出来是一年。想长期天天用，这个钱不算白花。

最低 **iOS 18**。自用的话不必上架 App Store。

---

## 装完第一件事：加一个渠道

**设置 → 渠道 → 加一条**，填三样：

| 填什么 | 说明 |
|---|---|
| 接口地址 | 形如 `https://api.deepseek.com/v1`，末尾不要带 `/chat/completions` |
| 路径 | 默认 `/chat/completions`，个别服务不一样才改 |
| 模型名 | 一个渠道下可以列多个，随时切换 |

**渠道不按厂商抽象**：它只认 BaseURL、路径、模型清单、以及推理字段叫什么名字。
换一家服务，加一条渠道就行；换模型，不会换人。

API Key 存在系统钥匙串（安卓是 Keystore 加密的保险箱）里，不进数据库、不进备份。
渠道里预置了 DeepSeek、通义千问、智谱、Kimi、硅基流动几个常见接入点，
点一下就填好地址和模型名——预置只是省一次手打，填完照样能改。

---

## 它能做什么

### 说话这件事

- **多模型对话**：一个渠道下挂多个模型，随时切。
- **人设**：所有渠道、所有模型都走同一条人设。内置「默认」和「贾维斯」两条，也能自己写。
  每个会话还能单独挑一条——同一个 App 里可以一个窗口说英文、一个窗口说中文，互不打扰。
- **关系**：它会记得你们处到什么程度。见了三天的和处了两年的，说话方式不一样；
  三十天不来会慢慢变淡，但不会退回陌生人。**关系没到，你说过的事它只记着、不拿出来用**——
  新人说完一件事，下一句它不会「你刚说你……」。
- **思考过程可见**：支持思维链的模型直接把推理原文摆出来，默认展开、可以折叠；
  不支持的，界面上只有一行不可展开的**「思考中」**——**不编造思考过程**。
- **深度思考 / 联网搜索**：输入框上两个开关，状态会记住，下次进来还是上次那样。
  联网搜索是真发工具出去查（走 Brave Search，没填 Key 就走免 key 的那条路），
  **搜不到就照实说搜不到**，不用「我搜了一下」盖过去。

### 记得住这件事

- **分层记忆**：全局 / 项目 / 会话三层。新对话默认继承全局，项目层按需加载。
- **资料库（RAG）**：上传 txt / md / pdf / docx，在本机切块、算向量、做检索——
  用苹果自带的 NLEmbedding（安卓是本地向量化），不需要联网，也不产生 API 费用。
  翻什么资料由你指定，**不交给模型自己决定**。

### 动手这件事

- **能力**：能真的定闹钟、写日历、记提醒——**到点是真的响**，不是弹个提示。
- **操控别的 App**：只在你勾过的白名单里。密码框和验证码不读也不填；
  读出来的字里六位以上的数字串会当场换成一句说明。
- **敏感操作**：转账、付款、报验证码、报密码这一类工具**压根不存在**——
  不是默认关着，是模型连「有这么个工具」都不知道。
- **分享扩展**：在别的 App 里选中文字、图片、文件，直接丢进 Tend。

### 别的

- **语音输入**：按住说话。系统识别能本地认就本地认，**音频不上传**。
- **念稿**：iOS 上可以装自己的离线音色（sherpa-onnx）。贾维斯那条音色是英式英语，
  选中它之后中文内容会自动交给别的中文音色——逼一个英文音色念中文只会出一串怪音。
- **账号与同步**（可选）：一份加密档案放在你自己的 GitHub 私有仓库里。
  登录同一个账号，iPhone 和安卓上的记录跟着走。**没有服务器参与**。
- **灵动岛 / 状态栏待命**：没事做的时候在岛上留一个位置，等你的召唤。
- **备份与恢复**：导出一个文件，换手机时搬过去。**API Key 不进备份。**

---

## 它不做什么

这些话同时写在 App 里，不只写在 README 上：

- **不假装**。做不到就如实说做不到。图上不去、搜不到、模型不返回推理、
  手机没连上网——各自说各自的实话，不用一句「抱歉，我无法完成」糊过去。
- **不摆点不动的按钮**。做不到的功能宁可不出现在界面上，
  也不放一个按下去没反应的入口装样子。
- **不做控制电脑**。计划里，还没做。真要做，也是做成「电脑没开就直说电脑没开」。
- **不上传你的东西**。没有服务器可传。除了你自己填的模型接口，
  它不与任何第三方说话。

---

## 没有服务器这件事

**这是设计约束，不是省钱的选择。**

- 所有功能都在手机本地跑：检索、向量化、记忆、关系状态、语音识别、离线音色。
- 唯一的外部请求是**你自己配置的模型接口**，以及你打开联网搜索时的搜索服务。
- 「同步」用的是你自己的 GitHub 私有仓库，不是我们的服务器——
  所以**我们没有你的数据，也不可能有**。
- 电脑关机了，App 照常运行。

---

## 安全上做了什么，没做什么

安卓包做到了：

- **R8 混淆**：类名、字段名、字符串常量一起打散，反编译出来是一堆 `a.b.c`；
- **只信系统证书**：用户装的 CA 证书一律不认，装个抓包代理也看不明白；
- **禁代理**：走系统代理的请求直接不走；
- **签名校验**：改过包、重签过的版本，检测到就不发请求。

做不到：**挡不住 root + Frida**。这类工具能直接改内存，任何本地校验都过得了。
这话写在 App 里，不粉饰。

**API Key 存在系统钥匙串里**，不进数据库、不进备份、不进同步档案（除非你自己打开那一项，
打开时会明确警告你口令要当命看着）。

---

## 常见问题

**Q：需要自己有 API Key 吗？**
需要。Tend 不带 Key、不转卖额度。你去 DeepSeek 或任何 OpenAI 兼容的服务申请一个，
填进去就行。

**Q：不用 Key 能用吗？**
不能。所有回答都来自你自己配的那个接口。

**Q：iPhone 装完一周就不能用了？**
免费 Apple ID 签的有效期是 7 天。重签一次即可，聊天记录不会丢。嫌烦就上 99 美元/年的账号。

**Q：换手机怎么搬？**
设置 → 备份与恢复，导出一个文件搬过去；或者用「账号与同步」，
两台设备登同一个账号。API Key 两种方式都不跟着走，得重新填一次。

**Q：安卓和 iPhone 功能一样吗？**
尽量对齐，有差异的地方会明说。比如安卓没有灵动岛，
待命就做成状态栏上一条不走的通知——不假装有那块屏。

---

## 这个仓库里有什么

**没有源码。**

`enc/`（iOS）和 `enc-android/`（安卓）里是**密封过的**工程文件：
AES-256-GCM，每个文件的文件名是它路径的哈希。从外面看不出项目结构，也解不开——
口令只在 GitHub Secret（`TEND_SOURCE_KEY`）和作者本机各存一份。

编译跑在 GitHub Actions 上：流水线先解开密文到临时工作目录，编完随工作目录一起消失。
产物同样封过再上传，正式发布时才解封放进 Releases。

所以：**这个仓库是拿来用的，不是拿来看的。**

---

## 给维护者

需要 `TEND_SOURCE_KEY`（环境变量，或放在 `tools/.tend-key`，已被 .gitignore 排掉）。

~~~sh
# 单独封/解一个目录
node tools/tendpack.js seal        --src <明文工程> --out enc
node tools/tendpack.js unseal      --src enc        --out <解到哪>

# 单个文件（用来处理构建产物）
node tools/tendpack.js seal-file   --in <文件> --out <文件>
node tools/tendpack.js unseal-file --in <文件> --out <文件>

# 提交前跑这个：它会封存并推上去，顺便触发 Actions
node tools/publish.js --src <安卓明文工程> --out enc-android
node tools/publish.js --src <iOS 明文工程>
~~~

工作流：

| 工作流 | 干什么 |
|---|---|
| `build` | 解开 iOS 密文 → XcodeGen 生成工程 → 编无签名 ipa → 封回去当 artifact |
| `android` | 解开安卓密文 → Gradle 编译 → 签名 apk → 封回去当 artifact |
| `screenshots` | 装进苹果模拟器，逐屏截图 |
| `android-shots` | 装进安卓模拟器，逐屏截图 |
| `genkey` | 生成安卓签名密钥（只跑一次） |

发版流程：等 Actions 绿 → 下 artifact → 用 `unseal-file` 解封 → 扔进 Releases。

---

## English

**Tend** is a multi-model AI assistant for iPhone and Android, written natively in SwiftUI and
Jetpack Compose. It talks to any OpenAI-compatible endpoint you configure yourself.

There is **no server, no account system and no cloud**: retrieval, embeddings, memory,
speech recognition and offline voice synthesis all run on the device. The only outbound
requests are the model endpoint you configure, plus a search service if you switch web
search on. "Sync", if you enable it, uses your own private GitHub repository.

Design-wise it deliberately avoids the usual AI-app look — no gradients, no sparkle icons,
no chat bubbles — and it never fabricates: if a model cannot return its reasoning, the UI
says "thinking..." and nothing more.

**This repository contains no source code.** The `enc/` folders hold sealed (AES-256-GCM)
project files that are decrypted only inside GitHub Actions for the duration of a build.
Download the app from [Releases](../../releases/latest).
