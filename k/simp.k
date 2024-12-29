module SIMP-SYNTAX
  imports DOMAINS-SYNTAX
  syntax AExp  ::= Int | Id
                 > AExp "+" AExp              [left, strict]
  syntax BExp  ::= Bool
                 | AExp "<" AExp             [seqstrict]
  syntax Block ::= "{" Stmt "}"
                 | "{" "}"
  syntax Stmt  ::= Id "=" AExp ";"            [strict(2)]
                 | "if" "(" BExp ")" Block "else" Block [strict(1)]
                 | Block
                 > Stmt Stmt                  [left]
  syntax Pgm ::= "int" Ids ";" Stmt
  syntax Ids ::= List{Id,","}
endmodule

module SIMP
  imports SIMP-SYNTAX
  imports DOMAINS
  syntax KResult ::= Int | Bool

  configuration <T>
                  <k> $PGM:Pgm </k>
                  <state> .Map </state>
                </T>

  rule <k> X:Int + Y:Int => X +Int Y ...</k>
  rule <k> X:Int < Y:Int => X <Int Y ...</k>
  rule [lookup]:<k> X:Id => I ...</k> <state>... X |-> I ...</state>
  rule <k> X = I:Int; => .K ...</k> <state>... X |-> (_ => I) ...</state>
  rule S1:Stmt S2:Stmt => S1 ~> S2
  rule if (true)  S else _ => S
  rule if (false) _ else S => S
  rule {} => .K
  rule {S} => S
  rule <k> int (X,Xs => Xs);_ </k> <state> Rho:Map (.Map => X|->0) </state>
      requires notBool (X in keys(Rho))
  rule int .Ids; S => S
endmodule
