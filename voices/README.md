# Tend 声音包

这一份和 [tend-voices](https://github.com/Linteng-22/tend-voices) 里那份是同一份内容：那边照旧，这边也放一份，
从哪边进来都拿得到。

Tend 里「设置 → 声音」的内置目录指向 [tend-voices 的 Release](https://github.com/Linteng-22/tend-voices/releases/tag/v1)。

## 下载

| 文件 | 大小 | 直接下 |
| --- | --- | --- |
| `jarvis-medium.tar` | 约 61 MB | [下载](https://github.com/Linteng-22/tend-voices/releases/download/v1/jarvis-medium.tar) |
| `melo-zh-en.tar` | 约 182 MB | [下载](https://github.com/Linteng-22/tend-voices/releases/download/v1/melo-zh-en.tar) |
| `espeak-ng-data.tar` | 约 17 MB | [下载](https://github.com/Linteng-22/tend-voices/releases/download/v1/espeak-ng-data.tar) |

## 为什么是不压缩的 tar

iOS 上没有现成的解压 API。模型本身压不动多少，与其为 `.zip` 或 `.tar.bz2`
让 App 背上一整套第三方解压库，不如直接给不压缩的 tar——手机端按 512 字节的
块头顺序切开就能写盘，纯 Foundation 读完。

## 内容

| 文件 | 说明 | 来源 | 许可 |
| --- | --- | --- | --- |
| `jarvis-medium.tar` | 贾维斯英式英语音色 | [jgkawell/jarvis](https://huggingface.co/jgkawell/jarvis)（Piper 格式） | MIT |
| `melo-zh-en.tar` | 中文女声，中英混 | MeloTTS | MIT |
| `espeak-ng-data.tar` | Piper 系模型共用的音素数据 | [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) | MIT |

## 包内约定

每个包根目录放一个 `voice.json`，说明这是谁、说什么语言、哪个文件是模型：

```json
{
  "id": "jarvis-medium",
  "name": "贾维斯",
  "language": "en-GB",
  "model": "jarvis-medium.onnx",
  "tokens": "tokens.txt",
  "sample": "samples/speaker_0.mp3",
  "needs_espeak_data": true
}
```

没有 `voice.json` 也能装——Tend 会退回按文件名嗅探，并读 Piper 自带的
`.onnx.json` 拿语言和采样率。这里放它只是为了不用猜。

## 两种「包不完整」会让引擎直接退出进程

Piper 那一系的模型有两处是硬要求，缺哪一处都不是「报个错」，而是引擎当场 `exit()`——
这会杀掉整个 App，一层 catch 都进不去，在手机上看着就是「一点试听就闪退」：

1. **`tokens.txt` 必须在。** 引擎靠它把 espeak 的音素映射成编号。
   Piper 官方仓库只给 `.onnx` 和 `.onnx.json`，`tokens.txt` 要自己从 `.onnx.json`
   里的 `phoneme_id_map` 展开（一个记号一行：`记号 编号`，空格那一个写成单独一行数字）。
2. **`.onnx` 里必须有元数据。** 原版 Piper 导出的模型元数据是空的，引擎读不到
   `sample_rate` 会以同样的方式退出。至少要写进 `sample_rate`、`n_speakers`、
   `language`，以及一条含 `piper` 字样的 `comment`（引擎靠它认定这是 Piper 系）。

`jarvis-medium.tar` 原先漏了第 1 条、也缺第 2 条，2026-09-13 已补齐并重新上传。
MeloTTS 那一份（`melo-zh-en.tar`）自带元数据和 `tokens.txt`，不受影响。