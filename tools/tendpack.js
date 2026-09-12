#!/usr/bin/env node
'use strict';

// Tend 的源码封存工具。
//
// 公开仓库里只放密文，明文永远只在本地和 CI 的内存里。
// 一个文件一个密文，文件名是路径的哈希——从公开仓库看不出项目结构。
//
// 用法：
//   封存：node tools/tendpack.js seal        --src <明文工程> --out <公开仓库的 enc 目录>
//   解开：node tools/tendpack.js unseal      --src <enc 目录>  --out <解到哪>
//   封一个文件（编译产物走这条）：seal-file   --in <文件> --out <文件>
//   解一个文件：                  unseal-file --in <文件> --out <文件>
//
// 口令从环境变量 TEND_SOURCE_KEY 读，或者从同目录的 .tend-key 文件读。
// 口令丢了，密文就永远打不开了——这一条没有后路。

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');

const MAGIC = Buffer.from('TEND1');
// 不是秘密，只是让同一个口令在不同用途下派生出不同的密钥。
const SALT = Buffer.from('tend-source-v1-9f2c4a7e5b30d1c8');

function keyFrom(passphrase) {
  if (!passphrase) throw new Error('没有口令：设 TEND_SOURCE_KEY，或者在 tools/.tend-key 里写一行。');
  return crypto.scryptSync(passphrase, SALT, 32, { N: 1 << 15, r: 8, p: 1, maxmem: 512 * 1024 * 1024 });
}

function sealBuffer(buffer, key) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const body = Buffer.concat([cipher.update(buffer), cipher.final()]);
  return Buffer.concat([MAGIC, iv, cipher.getAuthTag(), body]);
}

function unsealBuffer(buffer, key) {
  if (buffer.length < 33 || !buffer.subarray(0, 5).equals(MAGIC)) {
    throw new Error('不是 tendpack 的密文，或者文件坏了。');
  }
  const iv = buffer.subarray(5, 17);
  const tag = buffer.subarray(17, 33);
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(buffer.subarray(33)), decipher.final()]);
}

function slotFor(relative) {
  return crypto.createHash('sha256').update(relative).digest('hex').slice(0, 24);
}

/** 封存时用 git 的索引来决定收哪些文件：仓库里有什么，密文里就有什么，一份不多一份不少。 */
function trackedFiles(srcDir) {
  const raw = execFileSync('git', ['-C', srcDir, 'ls-files', '-z'], { maxBuffer: 1 << 28 });
  return raw.toString('utf8').split('\0').filter(Boolean).sort();
}

function seal(srcDir, outDir) {
  const key = keyFrom(process.env.TEND_SOURCE_KEY || readKeyFile());
  const files = trackedFiles(srcDir);
  fs.mkdirSync(outDir, { recursive: true });

  const index = { files: {} };
  for (const relative of files) {
    const bytes = fs.readFileSync(path.join(srcDir, relative));
    const slot = slotFor(relative);
    fs.writeFileSync(path.join(outDir, slot + '.enc'), sealBuffer(bytes, key));
    index.files[slot] = {
      path: relative,
      bytes: bytes.length,
      sha256: crypto.createHash('sha256').update(bytes).digest('hex')
    };
  }

  // 目录里多出来的密文（这次删掉的文件）要清掉，不然会一直留着。
  const keep = new Set(Object.keys(index.files).map((slot) => slot + '.enc'));
  keep.add('index.enc');
  for (const name of fs.readdirSync(outDir)) {
    if (!keep.has(name)) fs.unlinkSync(path.join(outDir, name));
  }

  fs.writeFileSync(path.join(outDir, 'index.enc'), sealBuffer(Buffer.from(JSON.stringify(index)), key));
  return files.length;
}

function unseal(srcDir, outDir) {
  const key = keyFrom(process.env.TEND_SOURCE_KEY || readKeyFile());
  const index = JSON.parse(unsealBuffer(fs.readFileSync(path.join(srcDir, 'index.enc')), key).toString('utf8'));

  let count = 0;
  for (const [slot, entry] of Object.entries(index.files)) {
    const bytes = unsealBuffer(fs.readFileSync(path.join(srcDir, slot + '.enc')), key);
    const digest = crypto.createHash('sha256').update(bytes).digest('hex');
    if (digest !== entry.sha256) throw new Error('解开之后和封存时对不上：' + entry.path);
    const target = path.join(outDir, entry.path);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, bytes);
    count += 1;
  }
  return count;
}

function readKeyFile() {
  const file = path.join(__dirname, '.tend-key');
  if (!fs.existsSync(file)) return '';
  return fs.readFileSync(file, 'utf8').trim();
}

function argument(name) {
  const index = process.argv.indexOf('--' + name);
  return index === -1 ? '' : process.argv[index + 1];
}

function sealFile(input, output) {
  const key = keyFrom(process.env.TEND_SOURCE_KEY || readKeyFile());
  fs.writeFileSync(output, sealBuffer(fs.readFileSync(input), key));
}

function unsealFile(input, output) {
  const key = keyFrom(process.env.TEND_SOURCE_KEY || readKeyFile());
  fs.writeFileSync(output, unsealBuffer(fs.readFileSync(input), key));
}

const mode = process.argv[2];
const src = argument('src');
const out = argument('out');

try {
  if (mode === 'seal') {
    if (!src || !out) throw new Error('seal 需要 --src 和 --out');
    console.log('封存 ' + seal(src, out) + ' 个文件');
  } else if (mode === 'unseal') {
    if (!src || !out) throw new Error('unseal 需要 --src 和 --out');
    console.log('解开 ' + unseal(src, out) + ' 个文件');
  } else if (mode === 'seal-file') {
    sealFile(argument('in'), argument('out'));
    console.log('封好了：' + argument('out'));
  } else if (mode === 'unseal-file') {
    unsealFile(argument('in'), argument('out'));
    console.log('解好了：' + argument('out'));
  } else {
    console.log('用法：node tools/tendpack.js seal|unseal|seal-file|unseal-file ...');
    process.exit(1);
  }
} catch (error) {
  console.error('失败：' + error.message);
  process.exit(1);
}
