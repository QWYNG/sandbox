module LAMBDA-SYNTAX
  imports DOMAINS-SYNTAX
  imports ID-SYNTAX
  syntax Val ::= Int | Bool
  syntax Exp ::= Val
               | Id
               | "lambda" Id "." Exp
               | Exp Exp              [strict, left]
               | "(" Exp ")"          [bracket]
               > "-" Int
               | Exp "*" Exp          [strict, left]
               | Exp "/" Exp          [strict]
               > Exp "+" Exp          [strict, left]
               > Exp "<=" Exp         [strict]
  syntax Exp ::= "if" Exp "then" Exp "else" Exp  [strict(1)] 
               | "let" Id "=" Exp "in" Exp           
endmodule

module LAMBDA
  imports LAMBDA-SYNTAX
  imports DOMAINS

  configuration <T color="yellow">
                  <k color="green"> $PGM:Exp </k>
                  <env color="blue"> .Map </env>
                  <store color="red"> .Map </store>
                </T>

  syntax Val ::= closure(Map,Id,Exp)
  syntax KResult ::= Val

  rule - I => 0 -Int I
  rule I1 * I2 => I1 *Int I2
  rule I1 / I2 => I1 /Int I2
  rule I1 + I2 => I1 +Int I2
  rule I1 <= I2 => I1 <=Int I2

  rule if true  then E else _ => E
  rule if false then _ else E => E

  rule [let]: let X = E in E':Exp => (lambda X . E') E

  rule [lambdaToClosure]: <k> lambda X:Id . E => closure(Rho,X,E) ...</k>
       <env> Rho </env>

  rule [application]: <k> closure(Rho,X,E) V:Val => E ~> Rho' ...</k>
       <env> Rho' => Rho[X <- !N] </env>
       <store>... .Map => (!N:Int |-> V) ...</store>

  rule [lookup]: <k> X => V ...</k>
       <env>... X |-> N ...</env>
       <store>... N |-> V ...</store>

  rule [recoverEnv]: <k> _:Val ~> (Rho => .K) ...</k> <env> _ => Rho </env>
endmodule