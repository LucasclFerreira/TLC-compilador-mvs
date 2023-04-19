simples: lexico.l sintatico.y utils.c;
	flex -o lexico.c lexico.l;\
	bison -v -d sintatico.y -o sintatico.c;\
	gcc sintatico.c -o simples;

limpa: ;
	rm lexico.c sintatico.c sintatico.h sintatico.output simples