#!/usr/bin/env node
'use strict';

// 一条命令把明文工程封存进这个仓库并推上去。
//
//   node tools/publish.js --src E:\jiaweisi\tend-ios
//   node tools/publish.js --src E:\jiaweisi\tend-android --out enc-android
//
// 做三件事：封存、把密文提交、推。仓库里永远只有密文。

const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '..');
const index = process.argv.indexOf('--src');
const src = index === -1 ? '' : process.argv[index + 1];
// 默认封到 enc；安卓走 enc-android。两边各放一处，互不打扰。
const outIndex = process.argv.indexOf('--out');
const out = outIndex === -1 ? 'enc' : process.argv[outIndex + 1];

if (!src) {
  console.error('用法：node tools/publish.js --src <明文工程目录> [--out enc-android]');
  process.exit(1);
}

function run(command, args, options = {}) {
  return execFileSync(command, args, { cwd: root, stdio: 'inherit', ...options });
}

run('node', [path.join(__dirname, 'tendpack.js'), 'seal', '--src', src, '--out', path.join(root, out)]);
run('git', ['add', '-A']);
run('git', ['-c', 'core.quotepath=false', 'commit', '-m', 'sync', '--allow-empty-message'], { stdio: 'pipe' });
run('git', ['push']);
console.log('推好了：' + out);
