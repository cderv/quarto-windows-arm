// Test if Node.js ARM64 can spawn x64 Rscript subprocess
// This determines if the issue is Deno-specific or general Windows ARM limitation

const { spawn } = require('child_process');

const rscriptPath = process.argv[2];
const scriptPath = process.argv[3];

console.log('Testing Node.js subprocess spawning of x64 Rscript...');
console.log(`Node.js version: ${process.version}`);
console.log(`Node.js arch: ${process.arch}`);
console.log(`Rscript: ${rscriptPath}`);
console.log(`Script: ${scriptPath}`);
console.log();

const child = spawn(rscriptPath, [scriptPath], {
  stdio: ['ignore', 'pipe', 'pipe']
});

let stdout = '';
let stderr = '';

child.stdout.on('data', (data) => {
  stdout += data.toString();
});

child.stderr.on('data', (data) => {
  stderr += data.toString();
});

child.on('close', (code) => {
  console.log(`Exit code: ${code}`);
  console.log(`Stdout:`);
  console.log(stdout);

  if (stderr) {
    console.log(`Stderr:`);
    console.log(stderr);
  }

  if (code === 0) {
    console.log('\n[SUCCESS] Node.js subprocess spawn SUCCEEDED');
    console.log('This means the issue is Deno-specific, not a general Windows ARM limitation');
    process.exit(0);
  } else {
    console.log(`\n[FAILED] Node.js subprocess spawn FAILED with exit code ${code}`);
    console.log('This means the issue affects multiple runtimes, not just Deno');
    process.exit(1);
  }
});

child.on('error', (error) => {
  console.error('\n[FAILED] Node.js subprocess spawn threw exception:');
  console.error(error);
  process.exit(1);
});
