# Sylheti Programming Language (.syl)

**Sylheti** is a custom programming language featuring a unique **Sylheti domain vocabulary**, a Flex lexical scanner, a Bison LALR parser, an Abstract Syntax Tree (AST) generator, and a C execution interpreter.

**GitHub Repository**: [https://github.com/theniyazkhan/syleti_lang](https://github.com/theniyazkhan/syleti_lang)

---

## 🏛️ Architecture Overview

The Sylheti compiler pipeline consists of three core stages:

```
                  +-------------------+
                  |  Source (.syl)    |
                  +---------+---------+
                            |
                            v
                  +-------------------+
                  |   Flex Scanner    |  (lexer.l)
                  |  (Lexical Tokens) |
                  +---------+---------+
                            |
                            v
                  +-------------------+
                  |   Bison Parser    |  (parser.y)
                  | (AST Construction)|
                  +---------+---------+
                            |
                            v
                  +-------------------+
                  | C AST Interpreter |  (execute_program)
                  | (Symbol Engine)   |
                  +-------------------+
```

### 1. Lexical Analysis (`lexer.l`)
- Built using **Flex**.
- Converts `.syl` raw source code into structured tokens:
  - Sylheti Keywords: `dhoro`, `dekha`, `ne`, `jodi`, `naile`, `ghuro`, `ghur`
  - Booleans: `hasa` (true), `misa` (false)
  - Logical Operators: `ar` (and), `ernay` (or), `nabe` (not)
  - Identifiers, integer constants, double-quoted string literals, and arithmetic/relational operators (`^`, `+`, `-`, `*`, `/`, `==`, `!=`, `<=`, `>=`).
- Handles escape sequences (`\n`, `\t`, `\"`, `\\`), skips whitespace, and strips single-line `//` comments.

### 2. Syntax Analysis & AST Generation (`parser.y`)
- Built using **GNU Bison**.
- Parses the token stream according to formal context-free grammar rules.
- Builds an Abstract Syntax Tree (AST) composed of typed nodes (`AST_DECLARATION`, `AST_ASSIGNMENT`, `AST_PRINT_EXPR`, `AST_PRINT_STRING`, `AST_INPUT`, `AST_IF`, `AST_WHILE`, `AST_FOR`, `AST_BLOCK`, `AST_EXPRESSION`).

### 3. Runtime Interpreter Engine (`parser.y`)
- Recursively evaluates the AST statement lists.
- Manages a runtime symbol table (`symbols`) for variable declarations and assignments.
- Performs integer evaluation, string literal unescaping, and power calculation (`evaluate_power`).
- Handles runtime exceptions cleanly (e.g., division by zero, negative integer powers, undefined variables).

---

## ⚡ Sylheti Vocabulary & Key Features

| Concept | Sylheti Keyword | Meaning / Action | Sylheti Code Example |
| :--- | :--- | :--- | :--- |
| **Variable Declaration** | `dhoro` | *"Suppose / Let"* | `dhoro x = 10;` |
| **Print Output** | `dekha` | *"Show / Display"* | `dekha "Assalamu Alaikum!";` |
| **Runtime Input** | `ne` | *"Take / Get"* | `ne x;` |
| **Conditional (If)** | `jodi` | *"If"* | `jodi (x > 5) { ... }` |
| **Otherwise (Else)** | `naile` | *"Otherwise / Else"* | `jodi (x > 5) { ... } naile { ... }` |
| **While Loop** | `ghuro` | *"Repeat / Loop while"* | `ghuro (x > 0) { ... }` |
| **For Loop** | `ghur` | *"Loop for count"* | `ghur (dhoro i = 0; i < 5; i = i + 1) { ... }` |
| **Boolean True/False** | `hasa` / `misa` | *"True / False"* | `dhoro active = hasa;` |
| **Logical Operators** | `ar` / `ernay` / `nabe` | *"And / Or / Not"* | `jodi (x > 0 ar y > 0) { ... }` |
| **Exponentiation Operator** | `^` | Power calculation (right-associative) | `dhoro p = 2 ^ 3 ^ 2; // 512` |

---

## 🛠️ Technical Challenges & Solutions

### 1. Resolving Dangling-Else Ambiguity
- **Challenge**: The optional `naile` clause in `jodi (cond) { stmts } naile { stmts }` creates potential shift/reduce grammar conflicts in LALR parsers.
- **Solution**: Explicit precedence tokens `%nonassoc LOWER_THAN_NAILE` and `%nonassoc NAILE` were declared in `parser.y`, forcing Bison to resolve `naile` binding to the innermost `jodi` statement.

### 2. Supporting Ghur (For Loop) & Ghuro (While Loop)
- **Challenge**: Supporting both counter-based loops (`ghur (init; cond; step) { ... }`) and condition-based loops (`ghuro (cond) { ... }`) in the parser.
- **Solution**: Created a dedicated `AST_FOR` AST node and custom `for_init` / `for_step` grammar productions in Bison, enabling full `for` loop syntax evaluation.

### 3. Exponentiation Precedence & Associativity
- **Challenge**: Math conventions dictate that exponentiation is right-associative (`a^b^c = a^(b^c)`) and takes higher precedence than multiplication.
- **Solution**: Specified `%right POW '^'` in Bison precedence declarations and implemented a fast exponentiation helper (`evaluate_power`) handling $O(\log n)$ integer power computation.

---

## 🚀 Building & Running

### Prerequisites
- GCC (`gcc`)
- GNU Make (`make`)
- Flex (`flex` / `win_flex`)
- Bison (`bison` / `win_bison`)

### Compile
Run from the repository root:

```bash
make
```

This compiles `lexer.l` and `parser.y` into the executable `sylheti` (`sylheti.exe` on Windows).

### Run Example Scripts
```bash
./sylheti examples/demo.syl
./sylheti examples/calculator.syl
```

### Clean Build Artifacts
```bash
make clean
```

---

## 🌐 Web Server & Execution API

Sylheti includes an Express.js backend server (`server.js`) that serves an interactive web interface and exposes a REST API for running `.syl` scripts dynamically.

### Setup & Launch

1. Install Node.js dependencies:
   ```bash
   npm install
   ```

2. Start the web server:
   ```bash
   npm start
   # or for development mode:
   npm run dev
   ```

3. Open your browser and navigate to `http://localhost:3000` (or `http://localhost:<PORT>` if setting `PORT` environment variable).

### API Endpoint (`POST /api/run`)

Executes Sylheti source code via the compiled binary and returns stdout/stderr.

- **URL**: `/api/run`
- **Method**: `POST`
- **Headers**: `Content-Type: application/json`
- **Request Body**:
  ```json
  {
    "code": "dhoro x = 5;\ndekha x ^ 2;",
    "inputs": []
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "output": "25\n"
  }
  ```

