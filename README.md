# Nyz-Lang (.nyz)

**Nyz-Lang** is a custom programming language designed with an intuitive domain vocabulary, a Flex lexical scanner, a Bison LALR parser, an Abstract Syntax Tree (AST) generator, and a C execution interpreter.

---

## 🏛️ Architecture Overview

The Nyz-Lang compiler pipeline consists of three core stages:

```
                  +-------------------+
                  |  Source (.nyz)    |
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
- Converts `.nyz` raw source code into structured tokens: keywords (`morphe`, `manifest`, `absorb`, `perchance`, `otherwise`, `persist`), identifiers, integer constants, double-quoted string literals, and operators (`^`, `+`, `-`, `*`, `/`, `==`, `!=`, `<=`, `>=`).
- Handles escape sequences (`\n`, `\t`, `\"`, `\\`), skips whitespace, and strips single-line `//` comments.

### 2. Syntax Analysis & AST Generation (`parser.y`)
- Built using **GNU Bison**.
- Parses the token stream according to formal context-free grammar rules.
- Builds an Abstract Syntax Tree (AST) composed of typed nodes (`AST_DECLARATION`, `AST_ASSIGNMENT`, `AST_PRINT_EXPR`, `AST_PRINT_STRING`, `AST_INPUT`, `AST_IF`, `AST_WHILE`, `AST_BLOCK`, `AST_EXPRESSION`).

### 3. Runtime Interpreter Engine (`parser.y`)
- Recursively evaluates the AST statement lists.
- Manages a runtime symbol table (`symbols`) for variable declarations and assignments.
- Performs integer evaluation, string literal unescaping, and power calculation (`evaluate_power`).
- Handles runtime exceptions cleanly (e.g., division by zero, negative integer powers, undefined variables).

---

## ⚡ Key Features

- **Custom Vocabulary**:
  - `morphe`: Variable declaration with optional initializer (e.g., `morphe x = 5;`).
  - `manifest`: Print output for expressions and string literals (e.g., `manifest "Hello!";`).
  - `absorb`: Runtime user input reading from standard input into a variable (e.g., `absorb x;`).
  - `perchance` / `otherwise`: If-Else conditional branching.
  - `persist`: While loop control structure.
- **Unique Exponentiation Operator (`^`)**:
  - Native right-associative exponentiation operator `^` (e.g., `2 ^ 3` evaluates to `8`, `2 ^ 3 ^ 2` evaluates to `2 ^ (3 ^ 2) = 512`).
  - Strict operator precedence (`^` > `*`/`/` > `+`/`-` > Relational).
- **String Literal Output**: Supports escape characters (`\n`, `\t`, `\"`) in `manifest` statements.

---

## 🛠️ Technical Challenges & Solutions

### 1. Resolving Dangling-Else Ambiguity
- **Challenge**: The optional `otherwise` clause in `perchance (cond) { stmts } otherwise { stmts }` creates potential shift/reduce grammar conflicts in LALR parsers.
- **Solution**: Explicit precedence tokens `%nonassoc LOWER_THAN_OTHERWISE` and `%nonassoc OTHERWISE` were declared in `parser.y`, forcing Bison to resolve `otherwise` binding to the innermost `perchance` statement with **0 shift/reduce conflicts**.

### 2. Handling Nested Statement Blocks
- **Challenge**: Supporting arbitrarily nested `{ ... }` block statements without memory loss or list corruption.
- **Solution**: Designed a dynamic doubly-referenced `StatementList` structure (`head` and `tail` pointers) linked inside AST nodes (`AST_BLOCK` and `AST_PROGRAM`), allowing linear statement append operations and recursive traversal.

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

This compiles `lexer.l` and `parser.y` into the executable `nyz_lang` (`nyz_lang.exe` on Windows).

### Run Example Scripts
```bash
./nyz_lang examples/demo.nyz
./nyz_lang examples/calculator.nyz
./nyz_lang examples/keywords_test.nyz
./nyz_lang examples/power_test.nyz
```

### Clean Build Artifacts
```bash
make clean
```
