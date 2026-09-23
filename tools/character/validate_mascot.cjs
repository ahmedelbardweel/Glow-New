const fs = require('node:fs');
const path = require('node:path');
const validator = require('gltf-validator');

const filename = process.argv[2]
  ? path.resolve(process.argv[2])
  : path.resolve(__dirname, '../../assets/3d/glow_mascot.glb');
const sourceOption = process.argv.indexOf('--source');
const validate = file => validator.validateBytes(new Uint8Array(fs.readFileSync(file)), {
  uri: path.basename(file), maxIssues: 100,
});
(async () => {
  const report = await validate(filename);
  // Keep all warnings visible. A baseline can accept an unchanged source
  // warning, without adding approximate tangents to silence the validator.
  const inherited = new Set();
  if (sourceOption !== -1) {
    const source = path.resolve(process.argv[sourceOption + 1]);
    const baseline = await validate(source);
    for (const issue of baseline.issues.messages) {
      if (issue.severity === 1) inherited.add(issue.code);
    }
    report.sourceBaseline = {file: source, issues: baseline.issues};
  }
  fs.writeFileSync(path.join(__dirname, 'validation_report.json'),
    JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify(report.issues, null, 2));
  const newWarnings = report.issues.messages.filter(issue =>
    issue.severity === 1 && !inherited.has(issue.code));
  if (report.issues.numErrors || newWarnings.length) process.exitCode = 1;
})().catch(error => { console.error(error); process.exitCode = 1; });
