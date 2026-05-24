const fs = require('fs');
const path = require('path');
const os = require('os');

const skillSource = path.join(__dirname, '..', 'skill', 'context-optimizer.md');
const skillDestDir = path.join(os.homedir(), '.claude', 'skills', 'context-optimizer');
const skillDest = path.join(skillDestDir, 'SKILL.md');

try {
  if (!fs.existsSync(skillDestDir)) {
    fs.mkdirSync(skillDestDir, { recursive: true });
  }

  fs.copyFileSync(skillSource, skillDest);
  console.log(`context-optimizer installed → ${skillDest}`);
} catch (error) {
  console.error(`Error during postinstall: ${error.message}`);
  process.exit(1);
}
