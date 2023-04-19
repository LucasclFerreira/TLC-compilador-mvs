%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "lexico.c"
#include "utils.c"
int conta;
int rotulo = 0;
int tipo;
char esc = 'G';
int npar;

int posFunc;
int numVarLoc = 0;
int numArgs;

%}

%token T_PROGRAMA
%token T_INICIO
%token T_FIM
%token T_LEIA
%token T_ESCREVA
%token T_SE
%token T_ENTAO
%token T_SENAO
%token T_FIMSE
%token T_ENQUANTO
%token T_FACA
%token T_FIMENQUANTO
%token T_INTEIRO
%token T_LOGICO
%token T_MAIS
%token T_MENOS
%token T_VEZES
%token T_DIV
%token T_MAIOR
%token T_MENOR
%token T_IGUAL
%token T_E 
%token T_OU 
%token T_NAO
%token T_ABRE
%token T_FECHA
%token T_ATRIBUICAO
%token T_V 
%token T_F 
%token T_IDENTIF
%token T_NUMERO
%token T_FUNC
%token T_RETORNE
%token T_FIMFUNC

%start programa

%left T_E T_OU
%left T_IGUAL
%left T_MAIOR T_MENOR
%left T_MAIS T_MENOS
%left T_VEZES T_DIV

%%

programa 
    : cabecalho 
        { conta = 0; }
    variaveis 
        {
            mostra_tabela();
            empilha(conta); 
            if (conta) 
                fprintf(yyout,"\tAMEM\t%d\n", conta); 
        }
    rotinas 
    T_INICIO lista_comandos T_FIM
        {
            int conta = desempilha();
            if (conta)
                fprintf(yyout, "\tDMEM\t%d\n", conta); 
            fprintf(yyout, "\tFIMP\n");
            mostrapilha("FIM! A pilha deve estar vazia.");
        }
    ;

cabecalho
    : T_PROGRAMA T_IDENTIF
        { fprintf(yyout,"\tINPP\n"); }
    ;

variaveis
    : 
    | declaracao_variaveis
    ;

declaracao_variaveis
    : tipo lista_variaveis declaracao_variaveis
    | tipo lista_variaveis
    ;

tipo 
    : T_LOGICO
        { tipo = LOG;}
    | T_INTEIRO
        { tipo = INT;}
    ;

lista_variaveis
    : lista_variaveis T_IDENTIF 
        {  
            strcpy(elem_tab.id, atomo);
            elem_tab.escopo = esc;
            if (elem_tab.escopo == 'L')
                elem_tab.endereco = numVarLoc++;
            else
                elem_tab.endereco = conta;
            elem_tab.rotulo = -1;  // var não tem rótulo
            elem_tab.tipo = tipo;
            elem_tab.cat = 'V';
            elem_tab.npar = -1;  // var não tem número de params

            insere_simbolo(elem_tab);
            conta++;
            
        }
    | T_IDENTIF
        { 
            strcpy(elem_tab.id, atomo);
            elem_tab.escopo = esc;
            if (elem_tab.escopo == 'L')
                elem_tab.endereco = numVarLoc++;
            else
                elem_tab.endereco = conta;
            elem_tab.rotulo = -1;
            elem_tab.tipo = tipo;
            elem_tab.cat = 'V';
            elem_tab.npar = -1;
            insere_simbolo(elem_tab);
            conta++;               
        }
    ;

rotinas
    : 
    | 
        {
            fprintf(yyout, "\tDSVS\tL0\n");
        }
    lista_funcoes
        {
            fprintf(yyout, "L0\tNADA\t\n");
        }
    ;

lista_funcoes
    : funcao
    | funcao lista_funcoes
    ;

funcao
    : T_FUNC tipo T_IDENTIF
        {
            // entrou na função, incrementa rótulo
            rotulo++;
            
            // escreve função na tabela de simbolos
            strcpy(elem_tab.id, atomo);
            elem_tab.endereco = conta;
            elem_tab.rotulo = rotulo;
            elem_tab.tipo = tipo;
            elem_tab.cat = 'F';
            elem_tab.escopo = esc;
            insere_simbolo(elem_tab);
            conta++;

            // guarda id da função para buscar a posição depois
            char *idFunc = atomo;
            posFunc = busca_simbolo(idFunc);

            // marca lugar para ser desviada a execução
            fprintf(yyout, "L%d\tENSP\t\n", rotulo);

            // depois de entrar no subprograma o escopo é Local
            esc = 'L';
        }
    T_ABRE 
        {
            // variavel pra contar o numero total de params da função
            npar = 0;
        }
    parametros T_FECHA
        {
            // ajustar deslocamentos
            ajusta_desloc();         
            tabSimb[posFunc].npar = npar;
        }
    variaveis
        {
            if (numVarLoc != 0)
                fprintf(yyout, "\tAMEM\t%d\n", numVarLoc);
        } 
    T_INICIO lista_comandos T_FIMFUNC
        {
            mostra_tabela();  // tabela antes de apagar

            // tira as variaveis locais da tabela de símbolos
            tira_local();

            mostra_tabela();  // tabela depois de apagar

            npar = 0;
            numVarLoc = 0;
            esc = 'G';
        }
    ;

parametros
    : 
    | parametro parametros
    ;

parametro
    : tipo T_IDENTIF 
        {
            strcpy(elem_tab.id, atomo);
            elem_tab.tipo = tipo;
            elem_tab.cat = 'P';
            elem_tab.escopo = esc;
            elem_tab.rotulo = -1; // não tem
            insere_simbolo(elem_tab);

            tabSimb[posFunc].params[npar] = tipo;
            npar++;
        }
    ;

lista_comandos
    : 
    | comando lista_comandos
    ;

comando 
    : entrada_saida
    | repeticao
    | selecao
    | atribuicao 
    | retorno 
    ;

retorno
    : 
        {
            if (esc == 'G')
                yyerror("\"retorne\" só pode ser utilizado em contexto local.");
        }
    T_RETORNE expressao
        {       
            mostrapilha("retorno ANTES");
            
            int tipo = desempilha();
            if (tabSimb[posFunc].tipo != tipo)
                yyerror("Tipo retornado não compatível com o tipo de função.");

            fprintf(yyout, "\tARZL\t%d\n", tabSimb[posFunc].endereco);
            
            if (numVarLoc != 0)
                fprintf(yyout, "\tDMEM\t%d\n", numVarLoc);
            fprintf(yyout, "\tRTSP\t%d\n", npar);

            mostrapilha("retorno DEPOIS");
        }
    ;

entrada_saida
    : leitura
    | escrita
    ;

leitura 
    : T_LEIA T_IDENTIF
        { 
            int pos = busca_simbolo(atomo);
            if (tabSimb[pos].escopo == 'G')
                fprintf(yyout,"\tLEIA\n\tARZG\t%d\n", tabSimb[pos].endereco);
            else
                fprintf(yyout,"\tLEIA\n\tARZL\t%d\n", tabSimb[pos].endereco); 
        }
    ;

escrita 
    : T_ESCREVA expressao
        { 
            desempilha();
            fprintf(yyout,"\tESCR\n"); 
        }
    ;

repeticao
    : T_ENQUANTO 
        { 
            fprintf(yyout,"L%d\tNADA\n", ++rotulo);
            empilha(rotulo);
        } 
    expressao T_FACA 
        { 
            mostrapilha("repetição");
            int tipo = desempilha();
            if(tipo != LOG )
                yyerror("Incompatibilidade de tipo!");
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo); 
            empilha(rotulo);
        }
    lista_comandos 
    T_FIMENQUANTO
        { 
            int rot1 = desempilha();
            int rot2 = desempilha();
            fprintf(yyout,"\tDSVS\tL%d\nL%d\tNADA\n", rot2, rot1); 
        }
    ;

selecao
    : T_SE expressao T_ENTAO 
        {
            int tipo = desempilha();
            if(tipo != LOG )
                yyerror("Incompatibilidade de tipo!");
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo);
            empilha(rotulo);
        }
    lista_comandos T_SENAO
        {
            int rot = desempilha();
            fprintf(yyout,"\tDSVS\tL%d\n", ++rotulo); 
            fprintf(yyout,"L%d\tNADA\n", rot); 
            empilha(rotulo);
        }
    lista_comandos T_FIMSE
        { 
            int rot = desempilha();
            fprintf(yyout,"L%d\tNADA\n", rot); 
        }
    ;

atribuicao
    : T_IDENTIF
        {
            int pos = busca_simbolo(atomo);
            empilha(pos);
        }
    T_ATRIBUICAO expressao
        { 
            mostrapilha("atribuição");
            int tipo = desempilha();
            int pos = desempilha();

            if(tabSimb[pos].tipo != tipo)
                yyerror("Incompatibilidade de tipo!");

            if (tabSimb[pos].escopo == 'G')
                fprintf(yyout,"\tARZG\t%d\n", tabSimb[pos].endereco);
            else
                fprintf(yyout,"\tARZL\t%d\n", tabSimb[pos].endereco); 
        }
    ;

expressao
    : expressao T_VEZES expressao
        { 
            testa_tipo(INT, INT, INT);
            fprintf(yyout,"\tMULT\n"); 
        }
    | expressao T_DIV expressao
        { 
            testa_tipo(INT, INT, INT);
            fprintf(yyout,"\tDIVI\n"); 
        }
    | expressao T_MAIS expressao
        {
            testa_tipo(INT, INT, INT);
            fprintf(yyout,"\tSOMA\n"); 
        }
    | expressao T_MENOS expressao
        {
            testa_tipo(INT, INT, INT);
            fprintf(yyout,"\tSUBT\n"); 
        }
    | expressao T_MAIOR expressao
        {
            testa_tipo(INT, INT, LOG);
            fprintf(yyout,"\tCMMA\n"); 
        }
    | expressao T_MENOR expressao
        {
            testa_tipo(INT, INT, LOG);
            fprintf(yyout,"\tCMME\n"); 
        }
    | expressao T_IGUAL expressao
        {
            testa_tipo(INT, INT, LOG);
            fprintf(yyout,"\tCMIG\n"); 
        }
    | expressao T_E expressao
        {
            testa_tipo(LOG, LOG, LOG);
            fprintf(yyout,"\tCONJ\n"); 
        }
    | expressao T_OU expressao
        {
            testa_tipo(LOG, LOG, LOG);
            fprintf(yyout,"\tDISJ\n"); 
        }
    | termo
    ;

argumentos
    : 
    | expressao 
        {
            int tipo = desempilha();
            numArgs = desempilha();

            if (tabSimb[posFunc].npar > 0 && tabSimb[posFunc].params[numArgs] != tipo)
                yyerror("Argumento de tipo incompativel!");

            numArgs++;
            empilha(numArgs);
        }
    argumentos
    ;

chamada
    :   
        {  
            int pos = desempilha();
        
            if (tabSimb[pos].escopo == 'G')
                fprintf(yyout,"\tCRVG\t%d\n", tabSimb[pos].endereco);
            else
                fprintf(yyout,"\tCRVL\t%d\n", tabSimb[pos].endereco);
            empilha(tabSimb[pos].tipo);
        }
    | T_ABRE 
        {
            fprintf(yyout, "\tAMEM\t1\n");
            numArgs = 0;
            empilha(numArgs);
        }
    argumentos T_FECHA 
        {
            mostrapilha("chamada func antes");

            numArgs = desempilha();
            int pos = desempilha();

            // verificando se o numero de args é o mesmo que o numero de npar
            if (tabSimb[pos].npar != numArgs)
                yyerror("Número de argumentos imcompatível com o número da função.");

            fprintf(yyout, "\tSVCP\t\n");
            fprintf(yyout, "\tDSVS\tL%d\n", tabSimb[pos].rotulo);

            empilha(tabSimb[pos].tipo);

            mostrapilha("chamada func depois");
        }

identificador
    : T_IDENTIF
        {
            int pos = busca_simbolo(atomo);
            empilha(pos);
        }
    ;

termo
    : identificador chamada 
    | T_NUMERO
        { 
            fprintf(yyout,"\tCRCT\t%s\n", atomo);
            empilha(INT);
         }
    | T_V
        { 
            fprintf(yyout,"\tCRCT\t1\n"); 
            empilha(LOG);
        }
    | T_F
        { 
            fprintf(yyout,"\tCRCT\t0\n");
            empilha(LOG);
         }
    | T_NAO termo
        { 
            int t = desempilha();
            if(t != LOG ) yyerror ("Incompatibilidade de tipo!");
            fprintf(yyout,"\tNEGA\n"); 
            empilha(LOG);
        }
    | T_ABRE expressao T_FECHA
    ;



%%

int main (int argc, char *argv[]) {
    char *p, nameIn[100], nameOut[100]; // duas variáveis para guardar os nomes de saida e entrada
    argv++;
    if (argc < 2) {
        puts("\n Compilador Simples");
        puts("\n\tUso:./simples <NOME>[.simples]\n\n");
        exit(10);
    }
    p = strstr(argv[0], ".simples"); //função que procura uma string na string e posiciona no início
    if (p) *p = 0;
    strcpy(nameIn, argv[0]);
    strcat(nameIn, ".simples");
    strcpy(nameOut, argv[0]);
    strcat(nameOut, ".mvs");
    yyin = fopen (nameIn, "rt");
    if (!yyin) {
        puts("Programa fonte não encontrado!");
        exit(20);
    }
    yyout = fopen(nameOut, "wt");
    yyparse();
    puts ("Programa ok!");
}