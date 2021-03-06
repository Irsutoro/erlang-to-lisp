% Main
erlang2lisp(File_name) :-
    access_file(File_name, 'read'),
    read_file_to_codes(File_name, Codes, []),
    translate(Lisp_translation, Codes, []),
    writeln(Lisp_translation),
    !.

% Reguły DCG
translate(Lisp_translation) --> line(Line), whitespace, {atomic_list_concat([Line], Lisp_translation)};
                                line(Line), whitespace, newlines, translate(Lines), {atomic_list_concat([Line, '\n', Lines], Lisp_translation)};
                                line(Line), whitespace, newlines, {atomic_list_concat([Line, '\n'], Lisp_translation)}.

% Kolejne linie
line(Line) --> whitespace, comment_sign, anything(_), {concat_atom([''], Line)};
               whitespace, statements(Statements), {concat_atom([Statements], Line)}.

% Statements
statements(Statements) --> exp(Expression), {atomic_list_concat([Expression], Statements)}.
statements(Statements) --> assignment(Assignment), {atomic_list_concat([Assignment], Statements)}.
statements(Statements) --> fundef(FunDef), {atomic_list_concat([FunDef], Statements)}.
statements(Statements) --> exportormodule(Exportmod), {atomic_list_concat([Exportmod], Statements)}.
statements(Statements) --> format_print(Print), {atomic_list_concat([Print], Statements)}.
statements(Statements) --> ifelse(Ifelse), {atomic_list_concat([Ifelse], Statements)}.
statements(Statements) --> function_call(Call), {atomic_list_concat([Call], Statements)}.

ifelse(Ifelse) --> "if", whitespace, newline, whitespace, comparision(Comp), whitespace, "->", whitespace, newline, whitespace, callable(Stat1), whitespace, newline, whitespace, else(Else), whitespace, "end", whitespace, {atomic_list_concat(['(if ', Comp, ' ', Stat1, ' ', Else, ')'], Ifelse)}.

else(Else) --> "true ->", whitespace, newline, whitespace, callable(Stat1), whitespace, newline, whitespace, {atomic_list_concat([Stat1], Else)};
                "", {atomic_list_concat(['()'], Else)}.



callable(Callable) --> function_call(Callable); assignment(Callable); exp(Callable); format_print(Callable); ifelse(Callable).

function_call(FunCall) --> variable_rest(Function), "()", {atomic_list_concat(['(', Function, ')'], FunCall)}.

exportormodule(Expormod) --> "-module(", variable_rest(_), ").", whitespace, {atomic_list_concat([''], Expormod)};
                             "-export([", variable_rest(_), "/", number(_), "]).", {atomic_list_concat([''], Expormod)}.

fundef(FunDef) --> variable_rest(Function), "() ->", newline, whitespace, funbody(Funbody), {atomic_list_concat(['(defun ', Function, ' () ', Funbody, ')'], FunDef)}.

funbody(Funbody) --> exp(Funbody);
                     assignment(Funbody);
                     format_print(Funbody);
                     ifelse(Funbody);
                     function_call(Funbody).

% Wypisywanie
format_print(Print) --> "io:format(", variable(Variable), ")", {atomic_list_concat(['(print ', Variable, ')'], Print)}.
format_print(Print) --> "io:format(", number(Number), ")", {atomic_list_concat(['(print ', Number, ')'], Print)}.
format_print(Print) --> "io:format(", str(Str), ")", {atomic_list_concat(['(print ', Str, ')'], Print)}.


% Wyrażenia arytmetyczne
exp(Expression) --> exparg(Number1), " ", operator(Op), " ", exparg(Number2), {atomic_list_concat(['(', Op, ' ', Number1, ' ', Number2, ')'], Expression)}.
comparision(Expression) --> exparg(Number1), " ", comparision_op(Op), " ", exparg(Number2), {atomic_list_concat(['(', Op, ' ', Number1, ' ', Number2, ')'], Expression)}.


exparg(ExpArg) --> number(ExpArg); variable(ExpArg).
% Przypisanie do zmiennej
assignment(Assignment) --> variable(V1), " = ", assignable(N1), {atomic_list_concat(['(setq', ' ', V1, ' ', N1, ')'], Assignment)}.

assignable(Assignable) --> number(Assignable); variable(Assignable); str(Assignable); exp(Assignable).

str(A) --> "\"", str_body(B), "\"", {concat_atom(['\"', B, '\"'], A)}.

str_body(A) --> variable_rest(A).
str_body(A) --> variable_rest(B), " ", str_body(C), {concat_atom([B, ' ', C], A)}.
% Zmienna
% TODO Wziąć pod uwagę fakt, że w lispie nie ma znaczenia wielkość liter, tzn. FOO == foo == Foo == fOo itd
variable(Variable) --> uppercase(V1), variable_rest(Rest), {concat_atom([V1, Rest], Variable)};
                       uppercase(Variable).
variable_rest(Variable_rest) --> prolog_identifier_continue(V1), variable_rest(Rest), {concat_atom([V1, Rest], Variable_rest)};
                                 prolog_identifier_continue(Variable_rest).
uppercase(Variable) --> [V1], {code_type(V1, upper), atom_codes(Variable, [V1])}.
prolog_identifier_continue(Variable_rest) --> [V1], {code_type(V1, prolog_identifier_continue), atom_codes(Variable_rest, [V1])}.

% Liczby
number(N) --> integer_number(N); float_number(N).
digit(Digit) --> [Digit1], {code_type(Digit1, digit), atom_codes(Digit, [Digit1])}.

% Liczby całkowite, złożone z jednej lub więcej cyfr.
integer_number(Int) --> digit(Int1), integer_number(Rest), {concat_atom([Int1, Rest], Int)};
                        digit(Int).

% Liczby float
float_number(Float) --> digit(Digit), ".", integer_number(Rest), {concat_atom([Digit, '.', Rest], Float)};
                        digit(Digit), integer_number(Int), ".", integer_number(Rest), {concat_atom([Digit, Int, '.', Rest], Float)}.

% Operatory
operator(Op) --> "+", {atomic_list_concat(['+'], Op)};
                 "-", {atomic_list_concat(['-'], Op)};
                 "*", {atomic_list_concat(['*'], Op)};
                 "/", {atomic_list_concat(['/'], Op)}.

comparision_op(Op) --> "==", {atomic_list_concat(['='], Op)};
                 "/=", {atomic_list_concat(['/='], Op)};
                 "<", {atomic_list_concat(['<'], Op)};
                 ">", {atomic_list_concat(['>'], Op)};
                 ">=", {atomic_list_concat(['>='], Op)};
                 "=<", {atomic_list_concat(['<='], Op)}.

% Białe znaki.
whitespace --> " ", whitespace;
               "\t", whitespace;
               "".

% Znaki nowej linii.
newline --> "\n"; "\r"; "\r\n"; "\n\r".

newlines --> newline, whitespace; newlines, newline, whitespace.

% Komentarz
comment_sign --> "%".

% Cokolwiek
anything(A) --> [A1], anything(A3), {atom_codes(A2, [A1]), concat_atom([A2, A3], A)};
                [A1], {atom_codes(A2, [A1]), concat_atom([A2], A)}.
