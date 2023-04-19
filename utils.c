#include <ctype.h>

#define TAM_TAB 100
#define MAX_PAR 20

enum {INT, LOG};

struct elem_tab_simbolos {
    char id[100];
    int endereco;
    int tipo;
    int rotulo;
    char escopo;
    char cat;
    int npar;
    int params[MAX_PAR];

} tabSimb[TAM_TAB], elem_tab;

int pos_tab = 0;

void maiuscula (char *s) {
    for (int i = 0; s[i]; i++)
        s[i] = toupper(s[i]);
    
}


int busca_simbolo (char *id) {
    int i;
    for (i = pos_tab - 1; strcmp(tabSimb[i].id, id) && i >= 0; i--)
        ;
    if (i == -1) {
        char msg[200];
        sprintf(msg, "Identificador [%s] não encontrado!", id);
        yyerror(msg);
    }
    return i;
}

void insere_simbolo (struct elem_tab_simbolos elem) {
    int i;
    if (pos_tab == TAM_TAB)
        yyerror("Tabela de Simbolos Cheia!");

    for (i = pos_tab - 1; i >= 0; i--) {
        if (!(strcmp(tabSimb[i].id, elem.id)) && (tabSimb[i].escopo == elem.escopo))
            break;
    }

    if (i != -1) {
        char msg[200];
        sprintf(msg, "Identificador [%s] duplicado!", elem.id);
        yyerror(msg);
    }
    tabSimb[pos_tab++] = elem;

}

void mostra_params(struct elem_tab_simbolos elem) {
    printf("=> [");
    for (int i = 0; i < elem.npar; i++) {
        if ((i + 1) == elem.npar)
            printf("(t=%s)", elem.params[i] == INT? "INT" : "LOG");
        else
            printf("(t=%s), ", elem.params[i] == INT? "INT" : "LOG");
    }
    printf("]");
}

void mostra_tabela() {
    puts("\n\n\t\t\t\t   Tabela de Simbolos");
    puts("\t\t\t\t   ------------------");
    printf("%30s | %s | %s | %s | %s | %s | %s | %s \n", "ID", "END", "ROT", "TIP", "CAT", "ESC", "NPA", "PAR");
    for (int i = 0; i < 100; i++)
        printf("-");
    for (int i = 0; i < pos_tab; i++) {
        printf("\n%30s | %3d | %3d | %s | %3c | %3c | %3d | ", tabSimb[i].id, tabSimb[i].endereco, tabSimb[i].rotulo, tabSimb[i].tipo == INT? "INT" : "LOG", tabSimb[i].cat, tabSimb[i].escopo, tabSimb[i].npar);
        mostra_params(tabSimb[i]);
    }
    printf("\n");
    
}

int ajusta_desloc() {
    int ajuste = -3;
    int i = 1;
    while (tabSimb[pos_tab - i].escopo == 'L') {
        tabSimb[pos_tab - i].endereco = ajuste--;
        i++;
    }
    tabSimb[pos_tab - i].endereco = ajuste;  // ajustando endereco da função
}

void tira_local() {
    int i = 1;
    while (tabSimb[pos_tab - 1].escopo == 'L') {
        pos_tab--;
    }
}

#define TAM_PIL 100
int topo = -1;

int pilha[TAM_PIL];

void empilha (int valor) {
    if (topo == TAM_PIL)
        yyerror ("Pilha semântica cheia!");
    pilha[++topo] = valor;
}

int desempilha() {
    if (topo == -1) 
        yyerror("Pilha semântica vazia!");
    return pilha[topo--];
}

void mostrapilha(char *s) {
    printf("\nPilha (%s) = [ topo=>", s);
    for (int i = topo; i >= 0; i--) {
        printf("%d ", pilha[i]);
    }
    printf("]\n");
}

void testa_tipo(int tipo1, int tipo2, int ret){
    int t1 = desempilha();
    int t2 = desempilha();

    //printf("TIPO1: %d | TIPO2:  %d\n", t1, t2);
    if(t1 != tipo1 || t2 != tipo2)
        yyerror("Incompatibilidade de tipo!");
    empilha(ret);
}
