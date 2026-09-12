# Tend

iOS 上的多模型 AI 助手。自用。

这个仓库不存源码，只存**密封过的**源码。`enc/` 里每个文件都是 AES-256-GCM 的密文，
文件名是路径的哈希——从外面看不出项目结构，也解不开。口令只在 GitHub Secret
（`TEND_SOURCE_KEY`）和作者本机各存一份。

编译和截图都跑在 GitHub Actions 上：流水线先解开密文到 runner 的工作目录，再交给
XcodeGen 和 xcodebuild，跑完就随工作目录一起没了。产物（未签名的 ipa、模拟器截图）
**也封过再上传**——公开仓库的 artifact 谁都能下，一个没签名的 ipa 别人自己签一下就能装。

## 工具

```sh
node tools/tendpack.js seal        --src <明文工程> --out enc
node tools/tendpack.js unseal      --src enc        --out <解到哪>
node tools/tendpack.js seal-file   --in <文件> --out <文件>
node tools/tendpack.js unseal-file --in <文件> --out <文件>
```

口令从环境变量 `TEND_SOURCE_KEY` 读，或者放在 `tools/.tend-key`（已被 .gitignore 排掉）。
