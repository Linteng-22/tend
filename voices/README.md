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