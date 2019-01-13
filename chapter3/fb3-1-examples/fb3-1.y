/* calculator with AST */
%{
#include <stdio.h>
#include <stdlib.h>
#include "fb3-1.h"
%}

%union
{
    struct ast * a;
    int d;
}

/* declare tokens */
%token <d> NUMBER
%token EOL

%type <a> exp factor term

%%
calclist : /* nothing */
| calclist exp EOL {
    printf("=%d\n", eval($2));     /* evaluate and print the AST */
    treefree($2);                     /* free the AST */
    }
| calclist EOL {printf("> "); }
;

exp: factor      { $$ = $1; }
| exp '+' factor { $$ = newast('+', $1, $3); }
| exp '-' factor { $$ = newast('-', $1, $3); }
;

factor: term      { $$ = $1; }
| factor '*' factor { $$ = newast('*', $1, $3); }
| factor '/' factor { $$ = newast('/', $1, $3); }
| '(' exp ')'     { $$ = $2; }
;

term: NUMBER      { $$ = newnum($1); }
| '|' term        { $$ = newast('|', $2, NULL); }
| '-' term        { $$ = newast('M', $2, NULL); }
;
%%
