const express = require('express');
const cors = require('cors');
const { spawn, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'web')));

// Get backend binary path
function getExecutablePath() {
  const isWindows = process.platform === 'win32';
  const exeName = isWindows ? 'sylheti.exe' : 'sylheti';
  const binPath = path.join(__dirname, exeName);

  if (!fs.existsSync(binPath)) {
    try {
      console.log('Executable not found. Running make to compile...');
      execSync('make', { cwd: __dirname });
    } catch (err) {
      console.error('Failed to compile sylheti via make:', err.message);
    }
  }
  return binPath;
}

// API endpoint to execute Sylheti code via compiled C binary
app.post('/api/run', (req, res) => {
  const { code, inputs } = req.body;

  if (typeof code !== 'string') {
    return res.status(400).json({ success: false, error: 'Code string is required' });
  }

  const binPath = getExecutablePath();
  if (!fs.existsSync(binPath)) {
    return res.status(500).json({
      success: false,
      error: 'Sylheti binary not compiled. Please run make on the server.'
    });
  }

  const tempDir = os.tmpdir();
  const tempFile = path.join(tempDir, `script_${Date.now()}_${Math.random().toString(36).substring(2)}.syl`);

  fs.writeFile(tempFile, code, 'utf8', (err) => {
    if (err) {
      return res.status(500).json({ success: false, error: 'Failed to write temporary script file' });
    }

    const process = spawn(binPath, [tempFile]);

    let stdout = '';
    let stderr = '';

    // If user provided input array, feed them into stdin
    if (Array.isArray(inputs) && inputs.length > 0) {
      inputs.forEach(input => {
        process.stdin.write(`${input}\n`);
      });
      process.stdin.end();
    }

    process.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    process.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    process.on('close', (code) => {
      // Clean up temp file
      fs.unlink(tempFile, () => {});

      if (code === 0) {
        res.json({ success: true, output: stdout || 'Program finished with no output.' });
      } else {
        res.json({
          success: false,
          output: stdout,
          error: stderr || `Process exited with code ${code}`
        });
      }
    });

    process.on('error', (procErr) => {
      fs.unlink(tempFile, () => {});
      res.status(500).json({ success: false, error: procErr.message });
    });
  });
});

app.listen(PORT, () => {
  console.log(`Sylheti Language Server running at http://localhost:${PORT}`);
});
