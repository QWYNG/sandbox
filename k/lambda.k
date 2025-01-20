module LAMBDA-SYNTAX
  imports DOMAINS-SYNTAX
  imports ID-SYNTAX
  syntax Val ::= Int | Bool 
               | "[" Vals "]"
  syntax Vals ::= List{Val,","}

  syntax Exp ::= Val
               | Id
               | "[" Exp "|" Exp "]" [strict]
               | "head" Exp [strict]
               | "tail" Exp [strict]
               | "empty?" Exp [strict]
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
               | "letrec" Id Id "=" Exp "in" Exp
               | "mu" Id "." Exp
endmodule

module LAMBDA
  imports LAMBDA-SYNTAX
  imports DOMAINS

  configuration <T>
                  <k> $PGM:Exp </k>
                  <env> .Map </env>
                  <store> .Map </store>
                </T>

  syntax Val ::= closure(Map,Id,Exp)
  syntax Val ::= recClosure(Map, Exp)
  syntax KResult ::= Val

  rule head [Val, _] => Val
  rule tail [_, Vals] => [Vals]
  rule empty? [ .Vals ] => true
  rule empty? [ _ ] => false [owise]
  rule [V | [Exp]] => [V,Exp]

  rule - I => 0 -Int I
  rule I1 * I2 => I1 *Int I2
  rule I1 / I2 => I1 /Int I2
  rule I1 + I2 => I1 +Int I2
  rule I1 <= I2 => I1 <=Int I2

  rule if true  then E else _ => E
  rule if false then _ else E => E

  rule [let]: let X = E in E':Exp => (lambda X . E') E
  rule [letrec]: letrec F:Id X = E in E' => let F = mu F . lambda X . E in E'

  rule [lambdaToClosure]: <k> lambda X:Id . E => closure(Rho,X,E) ...</k>
       <env> Rho </env>

  rule [createRecClosure]: <k> mu F . E => recClosure(Rho[F <- !N], E) ...</k>
       <env> Rho </env>
       <store>... .Map => (!N:Int |-> recClosure(Rho[F <- !N], E)) ...</store>
  rule <k> recClosure(Rho, E) => E ~> Rho' ...</k>
       <env> Rho' => Rho </env>

  rule [application]: <k> closure(Rho,X,E) V:Val => E ~> Rho' ...</k>
       <env> Rho' => Rho[X <- !N] </env>
       <store>... .Map => (!N:Int |-> V) ...</store>

  rule [lookup]: <k> X => V ...</k>
       <env>... X |-> N ...</env>
       <store>... N |-> V ...</store>

  rule [recoverEnv]: <k> _:Val ~> (Rho => .K) ...</k> <env> _ => Rho </env>
endmodule