#!/usr/bin/env node
'use strict';

// 一条命令把明文工程封存进这个仓库并推上去。
//
//   node tools/publish.js --src E:\jiaweisi\tend-ios --note "输入坞改回正常高度"
//   node tools/publish.js --src E:\jiaweisi\tend-android --out enc-android --note "问候语那个逗号"
//
// 做三件事：封存、把密文提交、推。仓库里永远只有密文。
//
// 提交信息要写清楚：密封模式下，外面的人只能从提交记录看出这个项目在动。
// 一条 sync 什么都说明不了，所以不给 --note 的时候会退回到「哪个端 + 封了多少文件」。

const path = require('path');
const fs = require('fs');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '..');

function flag(name, fallback) {
  const i = process.argv.indexOf('--' + name);
  return i === -1 ? fallback : process.argv[i + 1];
}

const src = flag('src', '');
const out = flag('out', 'enc');
const note = (flag('note', '') || '').trim();

if (!src) {
  console.error('用法：node tools/publish.js --src <明文工程目录> [--out enc-android] [--note "这次改了什么"]');
  process.exit(1);
}

// 哪个端，按封存目录判断就够了——两边各封一处，互不打扰。
const side = out === 'enc' ? 'iOS' : out === 'enc-android' ? '安卓' : out;

function run(command, args, options = {}) {
  return execFileSync(command, args, { cwd: root, stdio: 'inherit', ...options });
}

run('node', [path.join(__dirname, 'tendpack.js'), 'seal', '--src', src, '--out', path.join(root, out)]);

function countSealed(dir) {
  let n = 0;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) n += countSealed(path.join(dir, entry.name));
    else n += 1;
  }
  return n;
}

const sealed = countSealed(path.join(root, out));
const stamp = new Date().toISOString().slice(0, 16).replace('T', ' ');
const message = note
  ? note + '\n\n' + side + ' · 封存 ' + sealed + ' 个文件 · ' + stamp
  : side + ' · 封存 ' + sealed + ' 个文件（没写 --note）· ' + stamp;

run('git', ['add', '-A']);
run('git', ['-c', 'core.quotepath=false', 'commit', '-m', message, '--allow-empty-message'], { stdio: 'pipe' });
run('git', ['push']);
console.log('推好了：' + out);
