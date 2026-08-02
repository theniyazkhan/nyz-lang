%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
  AST_PROGRAM,
  AST_DECLARATION,
  AST_ASSIGNMENT,
  AST_PRINT,
  AST_BLOCK,
  AST_WHILE,
  AST_EXPRESSION,
  AST_CONDITION
} AstType;

typedef enum {
  EXPR_INT,
  EXPR_VARIABLE,
  EXPR_BINARY,
  EXPR_NEGATE
} ExprType;

typedef enum {
  OP_ADD,
  OP_SUB,
  OP_MUL,
  OP_DIV,
  OP_NEG
} OpType;

typedef enum {
  COND_LT,
  COND_LE,
  COND_GT,
  COND_GE,
  COND_EQ,
  COND_NE
} CondType;

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
    } print_stmt;
    struct {
      StatementList *body;
    } block;
    struct {
      Ast *condition;
      Ast *body;
    } while_loop;
    struct {
      ExprType kind;
      union {
        int int_value;
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
    struct {
      CondType op;
      Ast *left;
      Ast *right;
    } condition;
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
static Ast *make_print_node(Ast *expr);
static Ast *make_block_node(StatementList *body);
static Ast *make_while_node(Ast *condition, Ast *body);
static Ast *make_binary_expr(OpType op, Ast *left, Ast *right);
static Ast *make_unary_expr(OpType op, Ast *child);
static Ast *create_expression_int(int value);
static Ast *create_expression_variable(char *name);
static Ast *make_condition_node(CondType op, Ast *left, Ast *right);
static int evaluate_expression(Ast *expr);
static int evaluate_condition(Ast *cond);
static void execute_statement(Ast *stmt);
static void execute_statement_list(StatementList *list);
static void execute_program(Ast *program);
static int lookup_symbol(const char *name, int *value);
static void assign_symbol(const char *name, int value);
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
%token <string_value> IDENTIFIER
%token EQ NEQ LE GE
%left '+' '-'
%left '*' '/'
%right UMINUS

%type <ast> program statement declaration assignment print_statement while_statement block expression condition
%type <ast> factor term
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
      append_statement($1, $2);
      $$ = $1;
    }
  ;

statement:
    declaration { $$ = $1; }
  | assignment { $$ = $1; }
  | print_statement { $$ = $1; }
  | while_statement { $$ = $1; }
  | block { $$ = $1; }
  | keyword_statement { $$ = NULL; }
  ;

keyword_statement:
    MORPHE
  | MANIFEST
  | ABSORB
  | PERCHANCE
  | OTHERWISE
  | PERSIST
  ;

declaration:
    INT IDENTIFIER ';' {
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
    PRINT '(' expression ')' ';' {
      $$ = make_print_node($3);
    }
  ;

while_statement:
    WHILE '(' condition ')' statement {
      $$ = make_while_node($3, $5);
    }
  ;

block:
    '{' statement_list '}' {
      $$ = make_block_node($2);
    }
  ;

condition:
    expression '<' expression { $$ = make_condition_node(COND_LT, $1, $3); }
  | expression LE expression { $$ = make_condition_node(COND_LE, $1, $3); }
  | expression '>' expression { $$ = make_condition_node(COND_GT, $1, $3); }
  | expression GE expression { $$ = make_condition_node(COND_GE, $1, $3); }
  | expression EQ expression { $$ = make_condition_node(COND_EQ, $1, $3); }
  | expression NEQ expression { $$ = make_condition_node(COND_NE, $1, $3); }
  ;

expression:
    expression '+' term { $$ = make_binary_expr(OP_ADD, $1, $3); }
  | expression '-' term { $$ = make_binary_expr(OP_SUB, $1, $3); }
  | term { $$ = $1; }
  ;

term:
    term '*' factor { $$ = make_binary_expr(OP_MUL, $1, $3); }
  | term '/' factor { $$ = make_binary_expr(OP_DIV, $1, $3); }
  | factor { $$ = $1; }
  ;

factor:
    INTEGER { $$ = create_expression_int($1); }
  | IDENTIFIER { $$ = create_expression_variable($1); }
  | '(' expression ')' { $$ = $2; }
  | '-' factor { $$ = make_unary_expr(OP_NEG, $2); }
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

static Ast *make_print_node(Ast *expr) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_PRINT;
  node->as.print_stmt.expr = expr;
  return node;
}

static Ast *make_block_node(StatementList *body) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_BLOCK;
  node->as.block.body = body;
  return node;
}

static Ast *make_while_node(Ast *condition, Ast *body) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_WHILE;
  node->as.while_loop.condition = condition;
  node->as.while_loop.body = body;
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

static Ast *make_condition_node(CondType op, Ast *left, Ast *right) {
  Ast *node = calloc(1, sizeof(*node));
  node->type = AST_CONDITION;
  node->as.condition.op = op;
  node->as.condition.left = left;
  node->as.condition.right = right;
  return node;
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
        fprintf(stderr, "Undefined variable: %s\n", expr->as.expression.data.name);
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
            fprintf(stderr, "Division by zero\n");
            exit(1);
          }
          return left / right;
        case OP_NEG:
          return -left;
      }
    }
    case EXPR_NEGATE:
      return -evaluate_expression(expr->as.expression.data.unary.child);
  }

  return 0;
}

static int evaluate_condition(Ast *cond) {
  int left = evaluate_expression(cond->as.condition.left);
  int right = evaluate_expression(cond->as.condition.right);

  switch (cond->as.condition.op) {
    case COND_LT: return left < right;
    case COND_LE: return left <= right;
    case COND_GT: return left > right;
    case COND_GE: return left >= right;
    case COND_EQ: return left == right;
    case COND_NE: return left != right;
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
    case AST_PRINT: {
      int value = evaluate_expression(stmt->as.print_stmt.expr);
      printf("%d\n", value);
      break;
    }
    case AST_BLOCK:
      execute_statement_list(stmt->as.block.body);
      break;
    case AST_WHILE:
      while (evaluate_condition(stmt->as.while_loop.condition)) {
        execute_statement(stmt->as.while_loop.body);
      }
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

int yyparse(void);

int yylex(void);

int main(int argc, char **argv);
