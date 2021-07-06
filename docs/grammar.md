# The Grammar of Teal

Here is the complete syntax of Teal in extended BNF, based on the Lua 5.4
grammar. Lines starting with `+` are existing lines from the Lua grammar
with additions; lines marked with `*` are entirely new.

As usual in extended BNF, `{A}` means 0 or more `A`s, and `[A]` means an
optional `A`. For a description of the terminals Name, Numeral, and
LiteralString, see [Section 3.1 of the Lua 5.3 Reference
Manual](https://www.lua.org/manual/5.3/manual.html#3.1). For operator
precedence, see below.

```
   chunk ::= block

   block ::= {stat} [retstat]

   stat ::=  ‘;’ |
       varlist ‘=’ explist |
       functioncall |
       label |
       ‘break’ |
       ‘goto’ Name |
       ‘do’ block ‘end’ |
       ‘while’ exp ‘do’ block ‘end’ |
       ‘repeat’ block ‘until’ exp |
       ‘if’ exp ‘then’ block {‘elseif’ exp ‘then’ block} [‘else’ block] ‘end’ |
       ‘for’ Name ‘=’ exp ‘,’ exp [‘,’ exp] ‘do’ block ‘end’ |
       ‘for’ namelist ‘in’ explist ‘do’ block ‘end’ |
       ‘function’ funcname funcbody |
+      ‘local’ attnamelist [‘:’ typelist] [‘=’ explist] |
       ‘local’ ‘function’ Name funcbody |
*      ‘local’ ‘record’ Name recordbody |
*      ‘local’ ‘enum’ Name enumbody |
*      ‘local’ ‘type’ Name ‘=’ newtype |
*      ‘global’ attnamelist ‘:’ typelist [‘=’ explist] |
*      ‘global’ attnamelist ‘=’ explist |
*      ‘global’ ‘function’ Name funcbody |
*      ‘global’ ‘record’ Name recordbody |
*      ‘global’ ‘enum’ Name enumbody |
*      ‘global’ ‘type’ Name ‘=’ newtype

   attnamelist ::=  Name [attrib] {‘,’ Name [attrib]}

   attrib ::= ‘<’ Name ‘>’

   retstat ::= ‘return’ [explist] [‘;’]

   label ::= ‘::’ Name ‘::’

   funcname ::= Name {‘.’ Name} [‘:’ Name]

   varlist ::= var {‘,’ var}

   var ::=  Name | prefixexp ‘[’ exp ‘]’ | prefixexp ‘.’ Name

   namelist ::= Name {‘,’ Name}

   explist ::= exp {‘,’ exp}

   exp ::=  ‘nil’ | ‘false’ | ‘true’ | Numeral | LiteralString | ‘...’ | functiondef |
       prefixexp | tableconstructor | exp binop exp | unop exp |
*      exp ‘as’ type | exp ‘as’ ‘(’ typelist ‘)’ | Name ‘is’ type

   prefixexp ::= var | functioncall | ‘(’ exp ‘)’

   functioncall ::=  prefixexp args | prefixexp ‘:’ Name args

   args ::=  ‘(’ [explist] ‘)’ | tableconstructor | LiteralString

   functiondef ::= ‘function’ funcbody

+  funcbody ::= [typeargs] ‘(’ [parlist] ‘)’ [‘:’ retlist] block ‘end’

+  parlist ::= parnamelist [‘,’ ‘...’ [‘:’ type]] | ‘...’ [‘:’ type]

   tableconstructor ::= ‘{’ [fieldlist] ‘}’

   fieldlist ::= field {fieldsep field} [fieldsep]

   field ::= ‘[’ exp ‘]’ ‘=’ exp |
+      Name [‘:’ type] ‘=’ exp |
       exp

   fieldsep ::= ‘,’ | ‘;’

   binop ::=  ‘+’ | ‘-’ | ‘*’ | ‘/’ | ‘//’ | ‘^’ | ‘%’ |
       ‘&’ | ‘~’ | ‘|’ | ‘>>’ | ‘<<’ | ‘..’ |
       ‘<’ | ‘<=’ | ‘>’ | ‘>=’ | ‘==’ | ‘~=’ |
       ‘and’ | ‘or’

   unop ::= ‘-’ | ‘not’ | ‘#’ | ‘~’

*  type ::= ‘(’ type ‘)’ | basetype {‘|’ basetype}

*  basetype ::= ‘string’ | ‘boolean’ | ‘nil’ | ‘number’ |
*      ‘{’ type {',' type} ‘}’ | ‘{’ type ‘:’ type ‘}’ | functiontype
*      | Name {{‘.’ Name }} [typeargs]

*  typelist ::= type {‘,’ type}

*  retlist ::= ‘(’ [typelist] [‘...’] ‘)’ | typelist [‘...’]

*  typeargs ::= ‘<’ [typearglist] ‘>’

*  typearglist ::= Name {‘,’ Name } {‘,’ Name ‘...’] } |
*      Name ‘...’ {‘,’ Name ‘...’ }

*  typevals ::= ‘<’ [typelist] ‘>’

*  newtype ::= ‘record’ recordbody | ‘enum’ enumbody | type

*  recordbody ::= [typevals] {recordentry} ‘end’

*  recordentry ::= ‘userdata’ | ‘{’ type ‘}’ |
*      Name ‘=’ newtype | [‘metamethod’] recordkey ‘:’ type

*  recordkey ::= Name | ‘[’ LiteralString ‘]’

*  enumbody ::= {LiteralString} ‘end’

*  functiontype ::= ‘function’ [typevals] ‘(’ [partypelist] ‘)’ [‘:’ retlist]

*  partypelist ::= partype {‘,’ partype}

*  partype ::= [Name ‘:’] type

*  parnamelist ::= parname {‘,’ parname}

*  parname ::= Name [‘:’ type]
```

## Operator precedence

Operator precedence in Teal follows the table below, from lower to higher priority:

```
     or
     and
     is
     <     >     <=    >=    ~=    ==
     |
     ~
     &
     <<    >>
     ..
     +     -
     *     /     //    %
     unary operators (not   #     -     ~)
     ^
     as
```

As usual, you can use parentheses to change the precedences of an expression.
The concatenation (`..`) and exponentiation (`^`) operators are right
associative. All other binary operators are left associative.
