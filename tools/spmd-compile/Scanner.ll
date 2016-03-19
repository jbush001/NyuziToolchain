%{
	int CurrentLine;
	#include "AstNode.h"
	#include "Parser.hpp"
%}

%option noyywrap

%%

\/\/[^\n]*					{	/* Skip Comments */ }
[0-9]*					{
							yylval.numVal = atoi(yytext);
							return TOK_NUMBER;
						}

"\n"					{ 	CurrentLine++; }
[\t ]+					{ 	/* Ignore Whitespace */ }

\"[.^\"]\"	 			{
							strcpy( yylval.strval, yytext + 1 );
							yylval.strval[ strlen( yytext ) - 2 ] = 0;
							return TOK_STRING;
						}


"&&"					{ return TOK_LOGICAL_AND; }
"||"					{ return TOK_LOGICAL_OR; }
"=="					{ return TOK_EQUALS; }
"!="					{ return TOK_NOT_EQUAL; }

"++"                    { return TOK_INCR; }
"--"                    { return TOK_DECR; }

[\.\+\-\/\*/=\%()><:;,\[\]\{\}\!\&\~\!]	{	return yytext[0];	}


float 					{ return TOK_FLOAT; }
if						{ return TOK_IF; }
else					{ return TOK_ELSE; }
end						{ return TOK_END; }
for                     { return TOK_FOR; }
while					{ return TOK_WHILE; }
return					{ return TOK_RETURN; }

[A-Za-z_][A-Za-z_0-9]*	{
							strcpy( yylval.strval, yytext );
							return TOK_IDENTIFIER;
						}
