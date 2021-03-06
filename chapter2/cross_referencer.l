/* fb2-5 C cross-ref */
%option noyywrap nodefault yylineno

%x COMMENT
%x IFILE

/* some complex named patterns */
/* universal character name */
UCN (\\u[0-9a-fA-F]{4}|\\U[0-9a-fA-F]{8})
/* float exponent */
EXP ([Ee][-+]?[0-9]+)
/* integer length */
ILEN ([Uu](L|l|LL|ll)?|(L|l|LL|ll)[Uu]?)

/* the symbol table */
%{
struct symbol { /* a variable name */
struct ref *reflist;
char *name;
};
struct ref {
struct ref *next;
char *filename;
int flags; /* 01 - definition */
int lineno;
};
/* simple symtab of fixed size */
#define NHASH 9997
struct symbol symtab[NHASH];
struct symbol *lookup(char*);
void addref(int, char*, char*, int);
char *curfilename; /* name of current input file */
/* include file stack */
struct bufstack {
struct bufstack *prev; /* previous entry */
YY_BUFFER_STATE bs; /* saved buffer */
int lineno; /* saved line number in this file */
char *filename; /* name of this file */
FILE *f; /* current file */
} *curbs;
int newfile(char *fn);
int popfile(void);
int defining; /* names are probably definitions */
%}

%%
 /* comments */
"/*" { BEGIN(COMMENT); }
<COMMENT>"*/" { BEGIN(INITIAL); }
<COMMENT>([^*]|\n)+|.
<COMMENT><<EOF>> { printf("%s:%d: Unterminated comment\n", curfilename, yylineno); return 0; }
 /* C++ comment, a common extension */
"//".*\n

inline |
int |
long |
register |
restrict |
short |
signed |
static |
struct |
typedef |
union |
unsigned |
void |
volatile { defining = 1; }
 /* keywords */
break
case
continue
default
do
else
for
goto
if
return
sizeof
switch
while

 /* constants */
 /* integers */
0[0-7]*{ILEN}?
[1-9][0-9]*{ILEN}?
0[Xx][0-9a-fA-F]+{ILEN}?
 /* decimal float */
([0-9]*\.[0-9]+|[0-9]+\.){EXP}?[flFL]?
[0-9]+{EXP}[flFL]?
 /* hex float */
0[Xx]([0-9a-fA-F]*\.[0-9a-fA-F]+|[0-9a-fA-F]+\.?)[Pp][-+]?[0-9]+[flFL]?
 /* char const */
\'([^'\\]|\\['"?\\abfnrtv]|\\[0-7]{1,3}|\\[Xx][0-9a-fA-F]+|{UCN})+\'
 /* string literal */
L?\"([^"\\]|\\['"?\\abfnrtv]|\\[0-7]{1,3}|\\[Xx][0-9a-fA-F]+|{UCN})*\"
 /* punctuators */
"{"|"<%"|";" { defining = 0; }
"["|"]"|"("|")"|"{"|"}"|"."|"->"
"++"|"--"|"&"|"*"|"+"|"-"|"~"|"!"
"/"|"%"|"<<"|">>"|"<"|">"|"<="|">="|"=="|"!="|"^"|"|"|"&&"|"||"
"?"|":"|";"|"..."
"="|"*="|"/="|"%="|"+="|"-="|"<<="|">>="|"&="|"^=""|="
","|"#"|"##"
"<:"|":>"|"%>"|"%:"|"%:%:"
 /* identifier */
([_a-zA-Z]|{UCN})([_a-zA-Z0-9]|{UCN})* {
addref(yylineno, curfilename, yytext, defining); }
 /* whitespace */
[ \t\n]+
 /* continued line */
\\$
 /* some preprocessor stuff */
"#"" "*if.*\n
"#"" "*else.*\n
"#"" "*endif.*\n
"#"" "*define.*\n
"#"" "*line.*\n
 /* recognize an include */
^"#"[ \t]*include[ \t]*[\"<] { BEGIN IFILE; }
<IFILE>[^>\"]+ {
{ int c;
while((c = input()) && c != '\n') ;
}
newfile(strdup(yytext));
BEGIN INITIAL;
}
<IFILE>.|\n { fprintf(stderr, "%s:%d bad include line\n",
curfilename, yylineno);
BEGIN INITIAL;
}
<<EOF>> { if(!popfile()) yyterminate(); }
 /* invalid character */
. { printf("%s:%d: Mystery character '%s'\n",
curfilename, yylineno, yytext);
}
%%

void printrefs()
{
    struct symbol * sp;
    qsort(symtab, NHASH, sizeof(struct symbol), symcompare);

    for(sp=symtab; sp->name && sp <symtab+NHASH; sp++)
    {
        char * prevfn = NULL;

        /* reverse the list of references */
        struct ref * rp = sp->reflist; 
        struct ref * rpp = 0;          /* previous ref */
        struct ref * rpn;              /* next ref */
    
        do
        {
            rpn = rp->next;
            rp->next = rpp;
            rpp = rp;
            rp = rpn;
        } while (rp);

        /* now print the word and its references */
        printf("10s", sp->name);
        for(rp = rpp; rp; rp = rp->next)
        {
            if (rp->filename == prevfn)
            {
                printf(" %d", rp->lineno);    
            }
            else
            {
                printf(" %s:%d", rp->filename, rp->lineno);
                prevfn = rp->filename;
            }

            if (rp->flags & 01)
                printf("*");
        }
        printf("\n");
    } 
}

int main(int argc, char ** argv)
{
    int i;

    if (argc < 2)
    {
        fprintf(stderr, "need filename\n");
        return 1;
    }

    for (i = 1; i < argc; i++)
    {
        if (newfile(argv[i]))
            yylex();
    }

    printfrefs();
    return 0;
}
