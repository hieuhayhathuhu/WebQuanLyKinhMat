// Prefer the project's QA dependency; also support the runtime on the development machine.
const path = require('node:path');
try {
  module.exports = require('playwright');
} catch (error) {
  if (error.code !== 'MODULE_NOT_FOUND') throw error;
  const profile = process.env.USERPROFILE;
  if (!profile) throw new Error('Install QA dependencies first: npm install --prefix scripts');
  try {
    module.exports = require(path.join(profile, '.cache', 'codex-runtimes', 'codex-primary-runtime', 'dependencies', 'node', 'node_modules', 'playwright'));
  } catch {
    throw new Error('Install QA dependencies first: npm install --prefix scripts');
  }
}
