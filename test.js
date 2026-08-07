const { spawnSync, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const isWindows = process.platform === 'win32';
const exeName = isWindows ? 'sylheti.exe' : 'sylheti';
const binPath = path.join(__dirname, exeName);

// Ensure executable is built
if (!fs.existsSync(binPath)) {
  console.log('Compiler executable not found. Running `make`...');
  try {
    execSync('make', { cwd: __dirname, stdio: 'inherit' });
  } catch (err) {
    console.error('Failed to compile sylheti via make:', err.message);
    process.exit(1);
  }
}

const tests = [
  {
    file: 'demo.syl',
    inputs: [],
    expectedOutputs: ['125', 'Result is greater than 100!', 'Count:', '1']
  },
  {
    file: 'factorial.syl',
    inputs: ['5\n'],
    expectedOutputs: ['Factorial of n is:', '120']
  },
  {
    file: 'calculator.syl',
    inputs: ['10\n', '5\n'],
    expectedOutputs: ['a + b =', '15', 'a - b =', '5', 'a * b =', '50', 'a / b =', '2', 'a ^ b =', '100000']
  },
  {
    file: 'keywords_test.syl',
    inputs: [],
    expectedOutputs: ['a is smaller than b!', 'a and b are NOT equal', 'Keywords Test Passed']
  },
  {
    file: 'logical_test.syl',
    inputs: [],
    expectedOutputs: ['Both conditions TRUE', 'At least one condition TRUE', 'Condition is NOT zero', 'Boolean HASA is TRUE']
  },
  {
    file: 'loop_test.syl',
    inputs: [],
    expectedOutputs: ['ghuranti diya 1..5 or jugfol:', '15', 'Count ghur:', '3', '1']
  },
  {
    file: 'power_test.syl',
    inputs: [],
    expectedOutputs: ['2 ^ 3 =', '8', '2 ^ 3 ^ 2 (Right-Associative) =', '512', '3 + 2 ^ 3 * 4 (Precedence) =', '35']
  },
  {
    file: 'test.syl',
    inputs: ['7\n'],
    expectedOutputs: ['Afne disoin', '7', 'Its square is', '49']
  }
];

console.log('========================================');
console.log('   Sylheti-Lang Test Suite Execution    ');
console.log('========================================\n');

let passedCount = 0;
let failedCount = 0;

tests.forEach(({ file, inputs, expectedOutputs }) => {
  const filePath = path.join(__dirname, 'examples', file);
  console.log(`RUNNING: ${file}...`);

  const proc = spawnSync(binPath, [filePath], {
    input: inputs.join(''),
    encoding: 'utf8'
  });

  if (proc.error) {
    console.error(`  ❌ FAILED to execute: ${proc.error.message}`);
    failedCount++;
    return;
  }

  if (proc.status !== 0) {
    console.error(`  ❌ FAILED with exit code ${proc.status}`);
    console.error(`  stderr: ${proc.stderr}`);
    failedCount++;
    return;
  }

  const output = proc.stdout || '';
  const missing = expectedOutputs.filter(exp => !output.includes(exp));

  if (missing.length > 0) {
    console.error(`  ❌ FAILED - Missing expected outputs: ${JSON.stringify(missing)}`);
    console.error(`  Actual stdout:\n${output}`);
    failedCount++;
  } else {
    console.log(`  ✅ PASSED`);
    passedCount++;
  }
});

console.log('\n========================================');
console.log(`SUMMARY: ${passedCount} PASSED, ${failedCount} FAILED out of ${tests.length} tests.`);
console.log('========================================');

if (failedCount > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
