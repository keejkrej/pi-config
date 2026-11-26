const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const [piDir] = process.argv.slice(2);
assert(piDir, 'Expected the Pi agent directory');
const file = path.join(piDir, 'settings.json');
const fragment = require('../codex-fast.settings.json');
const memory = require('../pi-memory.settings.json');
let original;
try {
  original = fs.readFileSync(file, 'utf8');
} catch (error) {
  if (error.code !== 'ENOENT') throw error;
}
const settings = original === undefined ? {} : JSON.parse(original.replace(/^\uFEFF/, ''));
const previous = structuredClone(settings);

function pinNpmPackage(packages, pkg) {
  const name = pkg.slice(0, pkg.lastIndexOf('@'));
  const remaining = [];
  let found = false;
  for (const entry of packages) {
    const source = typeof entry === 'string' ? entry : entry?.source;
    const normalized = source?.trim().replace(/^npm:\s*/, 'npm:');
    if (normalized !== name && !normalized?.startsWith(name + '@')) {
      remaining.push(entry);
    } else if (!found) {
      remaining.push(typeof entry === 'string' ? pkg : { ...entry, source: pkg });
      found = true;
    }
  }
  if (!found) remaining.push(pkg);
  return remaining;
}
settings.packages = [...fragment.packages, ...memory.packages].reduce(pinNpmPackage, settings.packages ?? []);
settings['pi-codex-fast'] = { ...settings['pi-codex-fast'], ...fragment['pi-codex-fast'] };

const versionFile = path.join(piDir, 'install', 'current-version');
const version = fs.existsSync(versionFile) ? fs.readFileSync(versionFile, 'utf8').trim() : '';
const subagent = `install/releases/${version}/node_modules/@earendil-works/pi-coding-agent/examples/extensions/subagent/index.ts`;
if (version && fs.existsSync(path.join(piDir, subagent))) {
  const others = (settings.extensions ?? []).filter((entry) => !entry.includes('examples/extensions/subagent/'));
  settings.extensions = [...others, subagent];
} else {
  console.warn('!! Bundled subagent not found; left extensions unchanged. Re-run after installing Pi.');
}

if (JSON.stringify(previous) === JSON.stringify(settings)) {
  console.log('    unchanged settings.json');
} else {
  if (original !== undefined) fs.copyFileSync(file, `${file}.bak.${Date.now()}`, fs.constants.COPYFILE_EXCL);
  fs.writeFileSync(file, JSON.stringify(settings, null, 2) + '\n');
  console.log('    updated settings.json');
}
