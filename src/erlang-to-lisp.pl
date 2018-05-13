% Main
erlang2lisp(File_name) :-
    access_file(File_name, 'read'),
    read_file_to_codes(File_name, Codes, []),
    translate(Lisp_translation, Codes, []),
    writeln(Lisp_translation),
    !.

% Reguły DCG
translate(Lisp_translation) --> line(Line), whitespace, {atomic_list_concat([Line], Lisp_translation)}.
translate(Lisp_translation) --> line(Line), whitespace, newline, translate(Lines), {atomic_list_concat([Line, '\n', Lines], Lisp_translation)}.
translate(Lisp_translation) --> line(Line), whitespace, newline, {atomic_list_concat([Line, '\n'], Lisp_translation)}.

% Kolejne linie
line(Line) --> whitespace, comment_sign, anything(_), {concat_atom([''], Line)}.
line(Line) --> whitespace, statements(Statements), {concat_atom([Statements], Line)}.

% Statements
statements(Statements) --> exp(Expression), {atomic_list_concat([Expression], Statements)}.

% Wyrażenia arytmetyczne
exp(Expression) --> number(Number1), " ", operator(Op), " ", number(Number2), {atomic_list_concat(['(', Op, ' ', Number1, ' ', Number2, ')'], Expression)}.

% Liczby
number(N) --> integer_number(N).
number(N) --> float_number(N).
digit(Digit) --> [Digit1], {code_type(Digit1, digit), atom_codes(Digit, [Digit1])}.

% Liczby całkowite, złożone z jednej lub więcej cyfr.
integer_number(Int) --> digit(Int1), integer_number(Rest), {concat_atom([Int1, Rest], Int)}.
integer_number(Int) --> digit(Int).

% Liczby float
float_number(Float) --> digit(Digit), ".", integer_number(Rest), {concat_atom([Digit, '.', Rest], Float)}.
float_number(Float) --> digit(Digit), integer_number(Int), ".", integer_number(Rest), {concat_atom([Digit, Int, '.', Rest], Float)}.

% Operatory
operator(Op) --> "+", {atomic_list_concat(['+'], Op)}.
operator(Op) --> "-", {atomic_list_concat(['-'], Op)}.
operator(Op) --> "*", {atomic_list_concat(['*'], Op)}.
operator(Op) --> "/", {atomic_list_concat(['/'], Op)}.

% Białe znaki.
whitespace --> " ", whitespace.
whitespace --> "\t", whitespace.
whitespace --> "".

% Znaki nowej linii.
newline --> "\n".
newline --> "\r".
newline --> "\r\n".
newline --> "\n\r".

% Komentarz
comment_sign --> "%".

% Cokolwiek
anything(A) --> [A1], anything(A3), {atom_codes(A2, [A1]), concat_atom([A2, A3], A)}.
anything(A) --> [A1], {atom_codes(A2, [A1]), concat_atom([A2], A)}.
