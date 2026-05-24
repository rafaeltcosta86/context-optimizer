const fs = require('fs');
const path = require('path');
const os = require('os');

const skillSource = path.join(__dirname, '..', 'skill', 'context-optimizer.md');
const skillDestDir = path.join(os.homedir(), '.claude', 'skills');
const skillDest = path.join(skillDestDir, 'context-optimizer.md');

try {
  if (!fs.existsSync(skillDestDir)) {
    fs.mkdirSync(skillDestDir, { recursive: true });
    console.log(`Created directory: ${skillDestDir}`);
  }

  fs.copyFileSync(skillSource, skillDest);
  console.log(`Copied skill to: ${skillDest}`);
} catch (error) {
  console.error(`Error during postinstall: ${error.message}`);
  process.exit(1);
}
