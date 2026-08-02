%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
  AST_PROGRAM,
  AST_DECLARATION,
  AST_ASSIGNMENT,
  AST_PRINT_EXPR,
  AST_PRINT_STRING,
  AST_INPUT,
  AST_IF,
  AST_WHILE,
  AST_BLOCK,
  AST_EXPRESSION
} AstType;

typedef enum {
  EXPR_INT,
  EXPR_STRING,
  EXPR_VARIABLE,
  EXPR_BINARY,
  EXPR_NEGATE
} ExprType;

typedef enum {
  OP_ADD,
  OP_SUB,
  OP_MUL,
  OP_DIV,
  OP_POW,
  OP_LT,
  OP_LE,
  OP_GT,
  OP_GE,
  OP_EQ,
  OP_NE
} OpType;

typedef struct Ast Ast;
typedef struct StatementList {
  Ast *head;
  Ast *tail;
} StatementList;

typedef struct Ast {
  AstType type;
  union {
    struct {
      StatementList *body;
    } program;
    struct {
      char *name;
      Ast *initializer;
    } declaration;
    struct {
      char *name;
      Ast *value;
    } assignment;
    struct {
      Ast *expr;
    } print_expr;
    struct {
      char *str;
    } print_string;
    struct {
      char *name;
    } input_stmt;
    struct {
      Ast *condition;
      Ast *body;
      Ast *else_body;
    } if_stmt;
    struct {
      Ast *condition;
      Ast *body;
    } while_loop;
    struct {
      StatementList *body;
    } block;
    struct {
      ExprType kind;
      union {
        int int_value;
        char *str_value;
        char *name;
        struct {
          OpType op;
          Ast *left;
          Ast *right;
        } binary;
        struct {
          Ast *child;
        } unary;
      } data;
    } expression;
  } as;
  Ast *next;
} Ast;

typedef struct Symbol {
  char *name;
  int value;
  struct Symbol *next;
} Symbol;

extern FILE *yyin;
extern int yylex(void);
int yyparse(void);
void yyerror(const char *message);

static Ast *root = NULL;
static Symbol *symbols = NULL;

static StatementList *create_statement_list(void);
static void append_statement(StatementList *list, Ast *stmt);
static Ast *make_program_node(StatementList *body);
static Ast *make_declaration_node(char *name, Ast *initializer);
static Ast *make_assignment_node(char *name, Ast *value);
static Ast *make_print_expr_node(Ast *expr);
static Ast *make_print_string_node(char *str);
static Ast *make_input_node(char *name);
static Ast *make_if_node(Ast *condition, Ast *body, Ast *else_body);
static Ast *make_while_node(Ast *condition, Ast *body);
static Ast *make_block_node(StatementList *body);
static Ast *make_binary_expr(OpType op, Ast *left, Ast *right);
static Ast *make_unary_expr(OpType op, Ast *child);
static Ast *create_expression_int(int value);
static Ast *create_expression_variable(char *name);
static int evaluate_expression(Ast *expr);
static void execute_statement(Ast *stmt);
static void execute_statement_list(StatementList *list);
static void execute_program(Ast *program);
static int lookup_symbol(const char *name, int *value);
static void assign_symbol(const char *name, int value);
static int evaluate_power(int base, int exp);
static void print_unescaped_string(const char *str);
%}

%code requires {
typedef struct Ast Ast;
typedef struct StatementList StatementList;
}

%union {
  int int_value;
  char *string_value;
  Ast *ast;
  StatementList *stmt_list;
}

%token INT PRINT WHILE
%token MORPHE MANIFEST ABSORB PERCHANCE OTHERWISE PERSIST
%token <int_value> INTEGER
%token <string_value> IDENTIFIER STRING
%token EQ NEQ LE GE POW

%nonassoc LOWER_THAN_OTHERWISE
%nonassoc OTHERWISE

%left EQ NEQ
%left '<' LE '>' GE
%left '+' '-'
%left '*' '/'
%right POW '^'
%right UMINUS

%type <ast> program statement declaration assignment print_statement input_statement perchance_statement persist_statement block expression
%type <stmt_list> statement_list
%start program

%%
program:
    statement_list {
      $$ = make_program_node($1);
      root = $$;
    }
  ;

statement_list:
    %empty { $$ = create_statement_list(); }
  | statement_list statement {
      if ($2 != NULL) {
        append_statement($1, $2);
      }
      $$ = $1;
    }
  ;

statement:
    declaration { $$ = $1; }
  | assignment { $$ = $1; }
  | print_statement { $$ = $1; }
  | input_statement { $$ = $1; }
  | perchance_statement { $$ = $1; }
  | persist_statement { $$ = $1; }
  | block { $$ = $1; }
  ;

declaration:
    MORPHE IDENTIFIER ';' {
      $$ = make_declaration_node($2, NULL);
    }
  | MORPHE IDENTIFIER '=' expression ';' {
      $$ = make_declaration_node($2, $4);
    }
  | INT IDENTIFIER ';' {
      $$ = make_declaration_node($2, NULL);
    }
  | INT IDENTIFIER '=' expression ';' {
      $$ = make_declaration_node($2, $4);
    }
  ;

assignment:
    IDENTIFIER '=' expression ';' {
      $$ = make_assignment_node($1, $3);
    }
  ;

print_statement:
    MANIFEST expression ';' {
      $$ = make_print_expr_node($2);
    }
  | MANIFEST STRING ';' {
      $$ = make_print_string_node($2);
    }
  | PRINT '(' expression ')' ';' {
      $$ = make_print_expr_node($3);
    }
  | PRINT '(' STRING ')' ';' {
      $$ = make_print_string_node($3);
    }
  ;

input_statement:
    ABSORB IDENTIFIER ';' {
      $$ = make_input_node($2);
    }
  ;

perchance_statement:
    PERCHANCE '(' expression ')' statement %prec LOWER_THAN_OTHERWISE {
      $$ = make_if_node($3, $5, NULL);
    }
  | PERCHANCE '(' expression ')' statement OTHERWISE statement {
      $$ = make_if_node($3, $5, $7);
    }
  ;

persist_statement:
    PERSIST '(' expression ')' statement {
      $$ = make_while_node($3, $5);
    }
  | WHILE '(' expression ')' statement {
      $$ = make_while_node($3, $5);
    }
  ;

block:
    '{' statement_list '}' {
      $$ = make_block_node($2);
    }
  ;

expression:
    expression '+' expression { $$ = make_binary_expr(OP_ADD, $1, $3); }
  | expression '-' expression { $$ = make_binary_expr(OP_SUB, $1, $3); }
  | expression '*' expression { $$ = make_binary_expr(OP_MUL, $1, $3); }
  | expression '/' expression { $$ = make_binary_expr(OP_DIV, $1, $3); }
  | expression POW expression { $$ = make_binary_expr(OP_POW, $1, $3); }
  | expression '^' expression { $$ = make_binary_expr(OP_POW, $1, $3); }
  | expression '<' expression { $$ = make_binary_expr(OP_LT, $1, $3); }
  | expression LE expression  { $$ = make_binary_expr(OP_LE, $1, $3); }
  | expression '>' expression { $$ = make_binary_expr(OP_GT, $1, $3); }
  | expression GE expression  { $$ = make_binary_expr(OP_GE, $1, $3); }
  | expression EQ expression  { $$ = make_binary_expr(OP_EQ, $1, $3); }
  | expression NEQ expression { $$ = make_binary_expr(OP_NE, $1, $3); }
  | '-' expression %prec UMINUS { $$ = make_unary_expr(OP_SUB, $2); }
  | '(' expression ')'        { $$ = $2; }
  | INTEGER                   { $$ = create_expression_int($1); }
  | IDENTIFIER                { $$ = create_expression_variable($1); }
  ;

%%

static StatementList *create_statement_list(void) {
  StatementList *list = calloc(1, sizeof(*list));
  return list;
}

static void append_statement(StatementList *list, Ast *stmt) {
  if (!list || !stmt) {
    return;
  }
  stmt->next = NULL;
  if (!list->head) {
    list->head = stmt;
    list->tail = stmt;
  } else {
    list->tail->next = stmt;
    list->tail = stmt;
  }
}

static Ast *make_program_node(StatementList *body) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_PROGRAM;
  node->as.program.body = body;
  return node;
}

static Ast *make_declaration_node(char *name, Ast *initializer) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_DECLARATION;
  node->as.declaration.name = name;
  node->as.declaration.initializer = initializer;
  return node;
}

static Ast *make_assignment_node(char *name, Ast *value) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_ASSIGNMENT;
  node->as.assignment.name = name;
  node->as.assignment.value = value;
  return node;
}

static Ast *make_print_expr_node(Ast *expr) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_PRINT_EXPR;
  node->as.print_expr.expr = expr;
  return node;
}

static Ast *make_print_string_node(char *str) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_PRINT_STRING;
  node->as.print_string.str = str;
  return node;
}

static Ast *make_input_node(char *name) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_INPUT;
  node->as.input_stmt.name = name;
  return node;
}

static Ast *make_if_node(Ast *condition, Ast *body, Ast *else_body) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_IF;
  node->as.if_stmt.condition = condition;
  node->as.if_stmt.body = body;
  node->as.if_stmt.else_body = else_body;
  return node;
}

static Ast *make_while_node(Ast *condition, Ast *body) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_WHILE;
  node->as.while_loop.condition = condition;
  node->as.while_loop.body = body;
  return node;
}

static Ast *make_block_node(StatementList *body) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_BLOCK;
  node->as.block.body = body;
  return node;
}

static Ast *make_binary_expr(OpType op, Ast *left, Ast *right) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_EXPRESSION;
  node->as.expression.kind = EXPR_BINARY;
  node->as.expression.data.binary.op = op;
  node->as.expression.data.binary.left = left;
  node->as.expression.data.binary.right = right;
  return node;
}

static Ast *make_unary_expr(OpType op, Ast *child) {
  (void)op;
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_EXPRESSION;
  node->as.expression.kind = EXPR_NEGATE;
  node->as.expression.data.unary.child = child;
  return node;
}

static Ast *create_expression_int(int value) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_EXPRESSION;
  node->as.expression.kind = EXPR_INT;
  node->as.expression.data.int_value = value;
  return node;
}

static Ast *create_expression_variable(char *name) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_EXPRESSION;
  node->as.expression.kind = EXPR_VARIABLE;
  node->as.expression.data.name = name;
  return node;
}

static char *duplicate_string(const char *text) {
  size_t length = strlen(text) + 1;
  char *copy = malloc(length);
  if (!copy) {
    fprintf(stderr, "Out of memory\n");
    exit(1);
  }
  memcpy(copy, text, length);
  return copy;
}

static int evaluate_power(int base, int exp) {
  if (exp < 0) {
    fprintf(stderr, "Runtime Error: Negative exponent (%d) is not supported for integers\n", exp);
    exit(1);
  }
  int result = 1;
  while (exp > 0) {
    if (exp & 1) {
      result *= base;
    }
    base *= base;
    exp >>= 1;
  }
  return result;
}

static void print_unescaped_string(const char *str) {
  if (!str) return;
  for (size_t i = 0; str[i] != '\0'; i++) {
    if (str[i] == '\\' && str[i + 1] != '\0') {
      i++;
      switch (str[i]) {
        case 'n': putchar('\n'); break;
        case 't': putchar('\t'); break;
        case 'r': putchar('\r'); break;
        case '\\': putchar('\\'); break;
        case '"': putchar('"'); break;
        default: putchar(str[i]); break;
      }
    } else {
      putchar(str[i]);
    }
  }
  putchar('\n');
}

static int evaluate_expression(Ast *expr) {
  if (!expr) {
    return 0;
  }

  if (expr->type != AST_EXPRESSION) {
    fprintf(stderr, "Internal error: expected expression node\n");
    exit(1);
  }

  switch (expr->as.expression.kind) {
    case EXPR_INT:
      return expr->as.expression.data.int_value;
    case EXPR_VARIABLE: {
      int value = 0;
      if (!lookup_symbol(expr->as.expression.data.name, &value)) {
        fprintf(stderr, "Runtime Error: Undefined variable '%s'\n", expr->as.expression.data.name);
        exit(1);
      }
      return value;
    }
    case EXPR_BINARY: {
      int left = evaluate_expression(expr->as.expression.data.binary.left);
      int right = evaluate_expression(expr->as.expression.data.binary.right);
      switch (expr->as.expression.data.binary.op) {
        case OP_ADD: return left + right;
        case OP_SUB: return left - right;
        case OP_MUL: return left * right;
        case OP_DIV:
          if (right == 0) {
            fprintf(stderr, "Runtime Error: Division by zero\n");
            exit(1);
          }
          return left / right;
        case OP_POW:
          return evaluate_power(left, right);
        case OP_LT: return left < right;
        case OP_LE: return left <= right;
        case OP_GT: return left > right;
        case OP_GE: return left >= right;
        case OP_EQ: return left == right;
        case OP_NE: return left != right;
      }
      break;
    }
    case EXPR_NEGATE:
      return -evaluate_expression(expr->as.expression.data.unary.child);
    case EXPR_STRING:
      return 0;
  }

  return 0;
}

static void execute_statement(Ast *stmt) {
  if (!stmt) {
    return;
  }

  switch (stmt->type) {
    case AST_DECLARATION: {
      int value = 0;
      if (stmt->as.declaration.initializer) {
        value = evaluate_expression(stmt->as.declaration.initializer);
      }
      assign_symbol(stmt->as.declaration.name, value);
      break;
    }
    case AST_ASSIGNMENT: {
      int value = evaluate_expression(stmt->as.assignment.value);
      assign_symbol(stmt->as.assignment.name, value);
      break;
    }
    case AST_PRINT_EXPR: {
      int value = evaluate_expression(stmt->as.print_expr.expr);
      printf("%d\n", value);
      break;
    }
    case AST_PRINT_STRING: {
      print_unescaped_string(stmt->as.print_string.str);
      break;
    }
    case AST_INPUT: {
      int value = 0;
      if (scanf("%d", &value) != 1) {
        fprintf(stderr, "Runtime Error: Failed to read integer input for '%s'\n", stmt->as.input_stmt.name);
        exit(1);
      }
      assign_symbol(stmt->as.input_stmt.name, value);
      break;
    }
    case AST_IF: {
      int cond_val = evaluate_expression(stmt->as.if_stmt.condition);
      if (cond_val) {
        execute_statement(stmt->as.if_stmt.body);
      } else if (stmt->as.if_stmt.else_body) {
        execute_statement(stmt->as.if_stmt.else_body);
      }
      break;
    }
    case AST_WHILE: {
      while (evaluate_expression(stmt->as.while_loop.condition)) {
        execute_statement(stmt->as.while_loop.body);
      }
      break;
    }
    case AST_BLOCK:
      execute_statement_list(stmt->as.block.body);
      break;
    case AST_PROGRAM:
      execute_statement_list(stmt->as.program.body);
      break;
    default:
      break;
  }
}

static void execute_statement_list(StatementList *list) {
  if (!list) {
    return;
  }

  for (Ast *node = list->head; node; node = node->next) {
    execute_statement(node);
  }
}

static void execute_program(Ast *program) {
  execute_statement(program);
}

static int lookup_symbol(const char *name, int *value) {
  for (Symbol *current = symbols; current; current = current->next) {
    if (strcmp(current->name, name) == 0) {
      *value = current->value;
      return 1;
    }
  }
  return 0;
}

static void assign_symbol(const char *name, int value) {
  for (Symbol *current = symbols; current; current = current->next) {
    if (strcmp(current->name, name) == 0) {
      current->value = value;
      return;
    }
  }

  Symbol *new_symbol = calloc(1, sizeof(*new_symbol));
  new_symbol->name = duplicate_string(name);
  new_symbol->value = value;
  new_symbol->next = symbols;
  symbols = new_symbol;
}

void yyerror(const char *message) {
  fprintf(stderr, "Syntax error: %s\n", message);
}

int main(int argc, char **argv) {
  if (argc != 2) {
    fprintf(stderr, "Usage: %s <source-file>\n", argv[0]);
    return 1;
  }

  yyin = fopen(argv[1], "r");
  if (!yyin) {
    perror("Unable to open source file");
    return 1;
  }

  int parse_result = yyparse();
  if (parse_result == 0 && root) {
    execute_program(root);
  }

  fclose(yyin);
  return parse_result == 0 ? 0 : 1;
}

int yywrap(void) {
  return 1;
}
