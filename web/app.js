const presets = {
  preview: `dhoro mat = misa;\n\njodi(mat == hasa){\n    dekha "Thik ase";\n} naile {\n    dekha "Thik nay, bhejal";\n}`,
  factorial: `dekha "=== Factorial Calculator ===";\n\ndekha "Ekta shongkha (n) dein:";\ndhoro n;\nne n;\n\ndhoro fact = 1;\nghur (dhoro i = 1; i <= n; i = i + 1) {\n  fact = fact * i;\n}\n\ndekha "Factorial is:";\ndekha fact;`,
  ghur_loop: `dekha "=== For Loop (ghur) Countdown ===";\n\nghur (dhoro i = 5; i > 0; i = i - 1) {\n  dekha "Countdown:";\n  dekha i;\n}\ndekha "Lift off!";`,
  ghuro_loop: `dekha "=== While Loop (ghuro) Sum ===";\n\ndhoro count = 5;\ndhoro total = 0;\n\nghuro (count > 0) {\n  total = total + count;\n  count = count - 1;\n}\n\ndekha "Sum of 1 to 5:";\ndekha total;`,
  simple: `dekha "Ekta shongkha dein (Enter a number):";\ndhoro x;\nne x;\n\ndekha "Afne disoin (You entered):";\ndekha x;`,
  calculator: `dekha "=== Sylheti Calculator ===";\n\ndekha "Enter first number (a):";\ndhoro a;\nne a;\n\ndekha "Enter second number (b):";\ndhoro b;\nne b;\n\ndhoro sum = a + b;\ndekha "a + b =";\ndekha sum;\n\ndhoro pwr = a ^ b;\ndekha "a ^ b =";\ndekha pwr;`,
  power: `dekha "=== Exponentiation Power ^ Test ===";\n\ndhoro base = 2;\ndhoro exp = 3;\ndhoro res = base ^ exp;\ndekha "2 ^ 3 =";\ndekha res;\n\ndhoro assoc = 2 ^ 3 ^ 2;\ndekha "2 ^ 3 ^ 2 =";\ndekha assoc;`,
  logical: `dekha "=== Logical Operators Test ===";\n\ndhoro x = 15;\ndhoro y = 30;\n\njodi (x > 10 ar y > 20) {\n  dekha "Both TRUE (ar)!";\n}\n\njodi (x == 100 ernay y == 30) {\n  dekha "At least one TRUE (ernay)!";\n}`
};

function loadPreset() {
  const selected = document.getElementById("presetSelect").value;
  document.getElementById("codeEditor").value = presets[selected] || "";
  updateHighlighting();
}

function insertKeyword(kw) {
  const editor = document.getElementById("codeEditor");
  const start = editor.selectionStart;
  const end = editor.selectionEnd;
  const text = editor.value;
  editor.value = text.substring(0, start) + kw + text.substring(end);
  editor.focus();
  editor.selectionStart = editor.selectionEnd = start + kw.length;
  updateHighlighting();
}

function clearConsole() {
  document.getElementById("consoleOutput").textContent = "";
}

function printConsole(text) {
  const consoleEl = document.getElementById("consoleOutput");
  consoleEl.textContent += text + "\n";
  consoleEl.scrollTop = consoleEl.scrollHeight;
}

let inputResolver = null;

function promptInput(varName) {
  return new Promise((resolve) => {
    const inputRow = document.getElementById("inputRow");
    const inputField = document.getElementById("userInput");
    inputRow.classList.add("active");
    inputField.value = "";
    inputField.focus();
    inputResolver = resolve;
  });
}

function handleInputSubmit(e) {
  if (e.key === "Enter") {
    const val = parseInt(document.getElementById("userInput").value) || 0;
    document.getElementById("inputRow").classList.remove("active");
    printConsole(`> ${val}`);
    if (inputResolver) {
      const res = inputResolver;
      inputResolver = null;
      res(val);
    }
  }
}

// =========================================================================
// SYLHETI LEXER, PARSER & AST INTERPRETER ENGINE
// =========================================================================

const KEYWORDS = new Set([
  'dhoro', 'dekha', 'ne', 'jodi', 'naile', 'ghuro', 'ghur',
  'hasa', 'misa', 'ar', 'ernay', 'nabe'
]);

function lexer(code) {
  const tokens = [];
  let i = 0;
  const len = code.length;

  while (i < len) {
    let ch = code[i];

    // Skip whitespace
    if (/\s/.test(ch)) {
      i++;
      continue;
    }

    // Skip single-line comments
    if (ch === '/' && code[i + 1] === '/') {
      i += 2;
      while (i < len && code[i] !== '\n') i++;
      continue;
    }

    // Numbers
    if (/[0-9]/.test(ch)) {
      let numStr = '';
      while (i < len && /[0-9]/.test(code[i])) {
        numStr += code[i];
        i++;
      }
      tokens.push({ type: 'INT', value: parseInt(numStr, 10) });
      continue;
    }

    // Strings (support standard & smart quotes)
    if (ch === '"' || ch === '“' || ch === '”' || ch === "'" || ch === '‘' || ch === '’') {
      const quoteChar = ch;
      i++;
      let strVal = '';
      while (i < len && code[i] !== quoteChar && code[i] !== '"' && code[i] !== '”') {
        if (code[i] === '\\' && i + 1 < len) {
          i++;
          if (code[i] === 'n') strVal += '\n';
          else if (code[i] === 't') strVal += '\t';
          else strVal += code[i];
        } else {
          strVal += code[i];
        }
        i++;
      }
      i++; // skip closing quote
      tokens.push({ type: 'STRING', value: strVal });
      continue;
    }

    // Identifiers & Keywords (case-insensitive for keywords)
    if (/[a-zA-Z_]/.test(ch)) {
      let id = '';
      while (i < len && /[a-zA-Z0-9_]/.test(code[i])) {
        id += code[i];
        i++;
      }
      const lowerId = id.toLowerCase();
      if (KEYWORDS.has(lowerId)) {
        tokens.push({ type: lowerId.toUpperCase(), value: lowerId });
      } else {
        tokens.push({ type: 'IDENTIFIER', value: id });
      }
      continue;
    }

    // Multi-character operators
    if (ch === '=' && code[i + 1] === '=') {
      tokens.push({ type: 'EQ', value: '==' });
      i += 2;
      continue;
    }
    if (ch === '!' && code[i + 1] === '=') {
      tokens.push({ type: 'NEQ', value: '!=' });
      i += 2;
      continue;
    }
    if (ch === '<' && code[i + 1] === '=') {
      tokens.push({ type: 'LE', value: '<=' });
      i += 2;
      continue;
    }
    if (ch === '>' && code[i + 1] === '=') {
      tokens.push({ type: 'GE', value: '>=' });
      i += 2;
      continue;
    }

    // Single-character symbols & operators
    if ('+-*/^=()<>{};'.includes(ch)) {
      tokens.push({ type: ch, value: ch });
      i++;
      continue;
    }

    throw new Error(`Unexpected character: '${ch}'`);
  }

  tokens.push({ type: 'EOF', value: null });
  return tokens;
}

class Parser {
  constructor(tokens) {
    this.tokens = tokens;
    this.pos = 0;
  }

  peek() {
    return this.tokens[this.pos];
  }

  consume(type) {
    const tok = this.peek();
    if (type && tok.type !== type) {
      throw new Error(`Expected token '${type}', but found '${tok.type}' (${tok.value})`);
    }
    this.pos++;
    return tok;
  }

  match(type) {
    if (this.peek().type === type) {
      this.consume(type);
      return true;
    }
    return false;
  }

  parseProgram() {
    const statements = [];
    while (this.peek().type !== 'EOF') {
      const stmt = this.parseStatement();
      if (stmt) statements.push(stmt);
    }
    return { type: 'PROGRAM', body: statements };
  }

  parseStatement() {
    // Ignore extra semicolons
    while (this.peek().type === ';') {
      this.consume(';');
    }

    const tok = this.peek();
    if (tok.type === 'EOF') return null;

    if (tok.type === 'DHORO') {
      this.consume('DHORO');
      const nameTok = this.consume('IDENTIFIER');
      let init = null;
      if (this.match('=')) {
        init = this.parseExpression();
      }
      this.match(';');
      return { type: 'DECLARATION', name: nameTok.value, init };
    }

    if (tok.type === 'DEKHA') {
      this.consume('DEKHA');
      let expr;
      if (this.peek().type === 'STRING') {
        expr = { type: 'STRING_LITERAL', value: this.consume('STRING').value };
      } else if (this.match('(')) {
        if (this.peek().type === 'STRING') {
          expr = { type: 'STRING_LITERAL', value: this.consume('STRING').value };
        } else {
          expr = this.parseExpression();
        }
        this.consume(')');
      } else {
        expr = this.parseExpression();
      }
      this.match(';');
      return { type: 'PRINT', expr };
    }

    if (tok.type === 'NE') {
      this.consume('NE');
      const nameTok = this.consume('IDENTIFIER');
      this.match(';');
      return { type: 'INPUT', name: nameTok.value };
    }

    if (tok.type === 'JODI') {
      this.consume('JODI');
      this.consume('(');
      const cond = this.parseExpression();
      this.consume(')');
      const body = this.parseStatement();
      let elseBody = null;
      if (this.match('NAILE')) {
        elseBody = this.parseStatement();
      }
      return { type: 'IF', cond, body, elseBody };
    }

    if (tok.type === 'GHURO') {
      this.consume('GHURO');
      this.consume('(');
      const cond = this.parseExpression();
      this.consume(')');
      const body = this.parseStatement();
      return { type: 'WHILE', cond, body };
    }

    if (tok.type === 'GHUR') {
      this.consume('GHUR');
      this.consume('(');
      let init = null;
      if (this.peek().type !== ';') {
        if (this.peek().type === 'DHORO') {
          this.consume('DHORO');
          const nameTok = this.consume('IDENTIFIER');
          let expr = null;
          if (this.match('=')) expr = this.parseExpression();
          this.match(';');
          init = { type: 'DECLARATION', name: nameTok.value, init: expr };
        } else if (this.peek().type === 'IDENTIFIER') {
          const nameTok = this.consume('IDENTIFIER');
          this.consume('=');
          const expr = this.parseExpression();
          this.match(';');
          init = { type: 'ASSIGNMENT', name: nameTok.value, expr };
        }
      } else {
        this.consume(';');
      }

      const cond = this.parseExpression();
      this.match(';');

      let step = null;
      if (this.peek().type !== ')') {
        const nameTok = this.consume('IDENTIFIER');
        this.consume('=');
        const expr = this.parseExpression();
        step = { type: 'ASSIGNMENT', name: nameTok.value, expr };
      }
      this.consume(')');

      const body = this.parseStatement();
      return { type: 'FOR', init, cond, step, body };
    }

    if (tok.type === '{') {
      this.consume('{');
      const stmts = [];
      while (this.peek().type !== '}' && this.peek().type !== 'EOF') {
        const stmt = this.parseStatement();
        if (stmt) stmts.push(stmt);
      }
      this.consume('}');
      return { type: 'BLOCK', body: stmts };
    }

    if (tok.type === 'IDENTIFIER') {
      const nameTok = this.consume('IDENTIFIER');
      this.consume('=');
      const expr = this.parseExpression();
      this.match(';');
      return { type: 'ASSIGNMENT', name: nameTok.value, expr };
    }

    throw new Error(`Unexpected statement starting with '${tok.value || tok.type}'`);
  }

  parseExpression() {
    return this.parseLogicalOr();
  }

  parseLogicalOr() {
    let left = this.parseLogicalAnd();
    while (this.peek().type === 'ERNAY') {
      const op = this.consume('ERNAY').value;
      const right = this.parseLogicalAnd();
      left = { type: 'BINARY', op, left, right };
    }
    return left;
  }

  parseLogicalAnd() {
    let left = this.parseEquality();
    while (this.peek().type === 'AR') {
      const op = this.consume('AR').value;
      const right = this.parseEquality();
      left = { type: 'BINARY', op, left, right };
    }
    return left;
  }

  parseEquality() {
    let left = this.parseRelational();
    while (['EQ', 'NEQ'].includes(this.peek().type)) {
      const op = this.consume(this.peek().type).value;
      const right = this.parseRelational();
      left = { type: 'BINARY', op, left, right };
    }
    return left;
  }

  parseRelational() {
    let left = this.parseAdditive();
    while (['<', 'LE', '>', 'GE'].includes(this.peek().type)) {
      const op = this.consume(this.peek().type).value;
      const right = this.parseAdditive();
      left = { type: 'BINARY', op, left, right };
    }
    return left;
  }

  parseAdditive() {
    let left = this.parseMultiplicative();
    while (['+', '-'].includes(this.peek().type)) {
      const op = this.consume(this.peek().type).value;
      const right = this.parseMultiplicative();
      left = { type: 'BINARY', op, left, right };
    }
    return left;
  }

  parseMultiplicative() {
    let left = this.parseExponentiation();
    while (['*', '/'].includes(this.peek().type)) {
      const op = this.consume(this.peek().type).value;
      const right = this.parseExponentiation();
      left = { type: 'BINARY', op, left, right };
    }
    return left;
  }

  parseExponentiation() {
    let left = this.parseUnary();
    if (this.peek().type === '^') {
      const op = this.consume('^').value;
      const right = this.parseExponentiation(); // Right-associative
      return { type: 'BINARY', op, left, right };
    }
    return left;
  }

  parseUnary() {
    if (this.peek().type === 'NABE') {
      this.consume('NABE');
      return { type: 'UNARY', op: 'NABE', expr: this.parseUnary() };
    }
    if (this.peek().type === '-') {
      this.consume('-');
      return { type: 'UNARY', op: '-', expr: this.parseUnary() };
    }
    return this.parsePrimary();
  }

  parsePrimary() {
    const tok = this.peek();

    if (tok.type === 'INT') {
      this.consume('INT');
      return { type: 'INT_LITERAL', value: tok.value };
    }
    if (tok.type === 'HASA') {
      this.consume('HASA');
      return { type: 'INT_LITERAL', value: 1 };
    }
    if (tok.type === 'MISA') {
      this.consume('MISA');
      return { type: 'INT_LITERAL', value: 0 };
    }
    if (tok.type === 'IDENTIFIER') {
      this.consume('IDENTIFIER');
      return { type: 'VARIABLE', name: tok.value };
    }
    if (tok.type === '(') {
      this.consume('(');
      const expr = this.parseExpression();
      this.consume(')');
      return expr;
    }

    throw new Error(`Unexpected expression token '${tok.value || tok.type}'`);
  }
}

// =========================================================================
// AST INTERPRETER EVALUATOR
// =========================================================================

async function evaluateExpr(node, env) {
  if (!node) return 0;

  switch (node.type) {
    case 'INT_LITERAL':
      return node.value;
    case 'VARIABLE':
      if (!(node.name in env)) {
        throw new Error(`Undefined variable '${node.name}'`);
      }
      return env[node.name];
    case 'UNARY': {
      const val = await evaluateExpr(node.expr, env);
      if (node.op === 'NABE') return val ? 0 : 1;
      if (node.op === '-') return -val;
      return val;
    }
    case 'BINARY': {
      const left = await evaluateExpr(node.left, env);
      const right = await evaluateExpr(node.right, env);
      switch (node.op) {
        case '+': return left + right;
        case '-': return left - right;
        case '*': return left * right;
        case '/':
          if (right === 0) throw new Error('Division by zero');
          return Math.floor(left / right);
        case '^': return Math.pow(left, right);
        case '<': return left < right ? 1 : 0;
        case '<=': return left <= right ? 1 : 0;
        case '>': return left > right ? 1 : 0;
        case '>=': return left >= right ? 1 : 0;
        case '==': return left === right ? 1 : 0;
        case '!=': return left !== right ? 1 : 0;
        case 'ar': return (left && right) ? 1 : 0;
        case 'ernay': return (left || right) ? 1 : 0;
      }
    }
  }
  return 0;
}

async function executeAstNode(node, env) {
  if (!node) return;

  switch (node.type) {
    case 'PROGRAM':
      for (const stmt of node.body) {
        await executeAstNode(stmt, env);
      }
      break;

    case 'BLOCK':
      for (const stmt of node.body) {
        await executeAstNode(stmt, env);
      }
      break;

    case 'DECLARATION': {
      const val = node.init ? await evaluateExpr(node.init, env) : 0;
      env[node.name] = val;
      break;
    }

    case 'ASSIGNMENT': {
      const val = await evaluateExpr(node.expr, env);
      env[node.name] = val;
      break;
    }

    case 'PRINT': {
      if (node.expr.type === 'STRING_LITERAL') {
        printConsole(node.expr.value);
      } else {
        const val = await evaluateExpr(node.expr, env);
        printConsole(val);
      }
      break;
    }

    case 'INPUT': {
      const val = await promptInput(node.name);
      env[node.name] = val;
      break;
    }

    case 'IF': {
      const condVal = await evaluateExpr(node.cond, env);
      if (condVal) {
        await executeAstNode(node.body, env);
      } else if (node.elseBody) {
        await executeAstNode(node.elseBody, env);
      }
      break;
    }

    case 'WHILE': {
      while (await evaluateExpr(node.cond, env)) {
        await executeAstNode(node.body, env);
      }
      break;
    }

    case 'FOR': {
      if (node.init) await executeAstNode(node.init, env);
      while (await evaluateExpr(node.cond, env)) {
        await executeAstNode(node.body, env);
        if (node.step) await executeAstNode(node.step, env);
      }
      break;
    }
  }
}

// =========================================================================
// MAIN EXECUTION CONTROLLER (JS vs C BACKEND)
// =========================================================================

async function runSylhetiCode() {
  clearConsole();
  document.getElementById("statusBadge").textContent = "Running...";
  document.getElementById("statusBadge").style.color = "#f59e0b";

  const code = document.getElementById("codeEditor").value;

  try {
    const tokens = lexer(code);
    const parser = new Parser(tokens);
    const ast = parser.parseProgram();
    const env = {};
    await executeAstNode(ast, env);

    document.getElementById("statusBadge").textContent = "Exit 0";
    document.getElementById("statusBadge").style.color = "#10b981";
  } catch (err) {
    printConsole("Syntax/Runtime Error: " + err.message);
    document.getElementById("statusBadge").textContent = "Error";
    document.getElementById("statusBadge").style.color = "#ef4444";
  }
}

function handleEditorKeyDown(e) {
  const textarea = e.target;
  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  const val = textarea.value;

  if (e.key === 'Tab') {
    e.preventDefault();
    textarea.value = val.substring(0, start) + "  " + val.substring(end);
    textarea.selectionStart = textarea.selectionEnd = start + 2;
    updateHighlighting();
  } else if (e.key === 'Enter') {
    e.preventDefault();
    const lineStart = val.lastIndexOf('\n', start - 1) + 1;
    const currentLine = val.substring(lineStart, start);
    
    const indentMatch = currentLine.match(/^\s*/);
    let indent = indentMatch ? indentMatch[0] : '';
    
    const trimmedBeforeCursor = currentLine.trimEnd();
    const addExtraIndent = trimmedBeforeCursor.endsWith('{');
    if (addExtraIndent) {
      indent += "  ";
    }

    const nextChar = val.charAt(start);
    if (addExtraIndent && nextChar === '}') {
      const prevIndent = indent.substring(2);
      const insertText = '\n' + indent + '\n' + prevIndent;
      textarea.value = val.substring(0, start) + insertText + val.substring(end);
      textarea.selectionStart = textarea.selectionEnd = start + 1 + indent.length;
    } else {
      const insertText = '\n' + indent;
      textarea.value = val.substring(0, start) + insertText + val.substring(end);
      textarea.selectionStart = textarea.selectionEnd = start + insertText.length;
    }
    updateHighlighting();
  }
}

function syncScroll() {
  const ed = document.getElementById("codeEditor");
  const hl = document.getElementById("highlighting");
  if (ed && hl) {
    hl.scrollTop = ed.scrollTop;
    hl.scrollLeft = ed.scrollLeft;
  }
}

function highlightSyntax(code) {
  function escapeHtml(str) {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  const tokenRegex = /(\/\/[^\n]*)|("[^"\\]*(?:\\.[^"\\]*)*")|\b(dhoro|dekha|ne|jodi|naile|ghuro|ghur|ar|ernay|nabe)\b|\b(hasa|misa)\b|\b(\d+)\b|([==|!=|<=|>=|\+|\-|\*|\/|\^|=|{|}|;|\(|\)])/g;

  let result = '';
  let lastIndex = 0;
  let match;

  while ((match = tokenRegex.exec(code)) !== null) {
    result += escapeHtml(code.substring(lastIndex, match.index));

    const [fullMatch, comment, str, kw, boolVal, num, op] = match;

    if (comment !== undefined) {
      result += `<span class="syn-comment">${escapeHtml(comment)}</span>`;
    } else if (str !== undefined) {
      result += `<span class="syn-string">${escapeHtml(str)}</span>`;
    } else if (kw !== undefined) {
      result += `<span class="syn-keyword">${escapeHtml(kw)}</span>`;
    } else if (boolVal !== undefined) {
      result += `<span class="syn-boolean">${escapeHtml(boolVal)}</span>`;
    } else if (num !== undefined) {
      result += `<span class="syn-number">${escapeHtml(num)}</span>`;
    } else if (op !== undefined) {
      result += `<span class="syn-operator">${escapeHtml(op)}</span>`;
    } else {
      result += escapeHtml(fullMatch);
    }

    lastIndex = tokenRegex.lastIndex;
  }

  result += escapeHtml(code.substring(lastIndex));

  if (code.endsWith('\n')) {
    result += ' ';
  }

  return result;
}

function updateHighlighting() {
  const code = document.getElementById("codeEditor").value;
  document.getElementById("highlightingContent").innerHTML = highlightSyntax(code);
  syncScroll();
}

// Initialize with default preset on load
window.addEventListener("DOMContentLoaded", () => {
  loadPreset();
});
