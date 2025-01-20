 ```k
module THREAD-SYNTAX
  imports DOMAINS-SYNTAX

  syntax Id ::= "Object" [token] | "Main" [token]

  syntax Stmt ::= "var" Exps ";"
                | "method" Id "(" Ids ")" Block  // called "function" in SIMPLE
                | "class" Id Block               // THREAD
                | "class" Id "extends" Id Block  // THREAD

  syntax Exp ::= Int | Bool | String | Id
               | "this"                                 // THREAD
               | "super"                                // THREAD
               | "(" Exp ")"             [bracket]
               | "++" Exp
               | Exp "instanceOf" Id     [strict(1)]    // THREAD
               | "(" Id ")" Exp          [strict(2)]    // THREAD  cast
               | "new" Id "(" Exps ")"   [strict(2)]    // THREAD
               | Exp "." Id                             // THREAD
               > Exp "[" Exps "]"        [strict]
               > Exp "(" Exps ")"        [strict(2)]    // was strict in SIMPLE
               | "-" Exp                 [strict]
               | "sizeOf" "(" Exp ")"    [strict]
               | "read" "(" ")"
               > left:
                 Exp "*" Exp             [strict, left]
               | Exp "/" Exp             [strict, left]
               | Exp "%" Exp             [strict, left]
               > left:
                 Exp "+" Exp             [strict, left]
               | Exp "-" Exp             [strict, left]
               > non-assoc:
                 Exp "<" Exp             [strict, non-assoc]
               | Exp "<=" Exp            [strict, non-assoc]
               | Exp ">" Exp             [strict, non-assoc]
               | Exp ">=" Exp            [strict, non-assoc]
               | Exp "==" Exp            [strict, non-assoc]
               | Exp "!=" Exp            [strict, non-assoc]
               > "!" Exp                 [strict]
               > left:
                 Exp "&&" Exp            [strict(1), left]
               | Exp "||" Exp            [strict(1), left]
               > "spawn" Block
               > Exp "=" Exp             [strict(2), right]

  syntax Ids  ::= List{Id,","}

  syntax Exps ::= List{Exp,","}          [strict, overload(exps)]
  syntax Val
  syntax Vals ::= List{Val,","}          [overload(exps)]

  syntax Block ::= "{" "}"
                | "{" Stmt "}"

  syntax Stmt ::= Block
                | Exp ";"                               [strict]
                | "if" "(" Exp ")" Block "else" Block   [avoid, strict(1)]
                | "if" "(" Exp ")" Block                [macro]
                | "while" "(" Exp ")" Block
                | "for" "(" Stmt Exp ";" Exp ")" Block  [macro]
                | "return" Exp ";"                      [strict]
                | "return" ";"                          [macro]
                | "print" "(" Exps ")" ";"              [strict]
                | "try" Block "catch" "(" Id ")" Block
                | "throw" Exp ";"                       [strict]
                | "join" Exp ";"                        [strict]
                | "acquire" Exp ";"                     [strict]
                | "release" Exp ";"                     [strict]
                | "rendezvous" Exp ";"                  [strict]

  syntax Stmt ::= Stmt Stmt                          [right]


  rule if (E) S => if (E) S else {}
  rule for(Start Cond; Step) {S} => {Start while (Cond) {S Step;}}
  rule for(Start Cond; Step) {} => {Start while (Cond) {Step;}}
  rule var E1:Exp, E2:Exp, Es:Exps; => var E1; var E2, Es;
  rule var X:Id = E; => var X; X = E;
endmodule
```

```k
module THREAD
  imports THREAD-SYNTAX
  imports DOMAINS

  syntax Val ::=  Int |Bool | String
               | array(Int,Int)
  syntax Exp ::= Val
  syntax Exps ::= Vals

 syntax KResult ::= Val
 syntax KResult ::= Vals

  syntax EnvCell
  syntax ControlCell
  syntax EnvStackCell
  syntax CrntObjCellFragment
```


```k
configuration <T>
                <threads>
                  <thread multiplicity="*" type="Set" initial="">
                    <k> $PGM:Stmt </k>
                    <env> .Map </env>
                    <holds> .Map </holds>
                    <id> 0 </id>
                  </thread>
                </threads>

                <store> .Map </store>
                <busy> .Set </busy>
                <terminated> .Set </terminated>
                <nextLoc> 0 </nextLoc>
                <output> .List </output>
              </T>
```


```k
  syntax KItem ::= "undefined"

  rule <k> var X:Id; => .K ...</k>
       <env> Env => Env[X <- L] </env>
       <store>... .Map => L |-> undefined ...</store>
       <nextLoc> L => L +Int 1 </nextLoc>
```

```k
  context var _:Id[HOLE];
```


```k
  rule <k> var X:Id[N:Int]; => .K ...</k>
       <env> Env => Env[X <- L] </env>
       <store>... .Map => L |-> array(L +Int 1, N)
                          (L +Int 1) ... (L +Int N) |-> undefined ...</store>
       <nextLoc> L => L +Int 1 +Int N </nextLoc>
    requires N >=Int 0
```

```k
  syntax Id ::= "$1" [token] | "$2" [token]
  rule var X:Id[N1:Int, N2:Int, Vs:Vals];
    => var X[N1];
       {
         for(var $1 = 0; $1 <= N1 - 1; ++$1) {
           var $2[N2, Vs];
           X[$1] = $2;
         }
       }
```


```k
  rule <k> X:Id => V ...</k>
       <env>... X |-> L ...</env>
       <store>... L |-> V:Val ...</store>  [group(lookup)]
```

```k
  syntax Exp ::= lookup(Int)

  rule V:Val[N1:Int, N2:Int, Vs:Vals] => V[N1][N2, Vs]
  rule array(L,_)[N:Int] => lookup(L +Int N)
```

```k
  syntax Exp ::= lvalue(K)
  context (HOLE => lvalue(HOLE)) = _
```

```k
  syntax Val ::= loc(Int)
  rule <k> lvalue(X:Id => loc(L)) ...</k> <env>... X |-> L:Int ...</env>

  rule <k> lvalue(X:Id => this . X) ...</k>  <env> Env </env>
    requires notBool(X in keys(Env))
  context lvalue((HOLE . _)::Exp)
```

```k
  rule <k> loc(L) = V:Val => V ...</k> <store>... L |-> (_ => V) ...</store>
```

```k
  context lvalue(_::Exp[HOLE::Exps])
```

```k
  context lvalue(HOLE::Exp[_::Exps])
```

```k
  rule [spawn]: <thread>...
         <k> spawn S => !T:Int ...</k>
         <env> Env </env>
       ...</thread>
       (.Bag => <thread>...
               <k> S </k>
               <env> Env </env>
               <id> !T </id>
             ...</thread>)
```

```k
  rule (<thread>... <k>.K</k> <holds>H</holds> <id>T</id> ...</thread> => .Bag)
       <busy> Busy => Busy -Set keys(H) </busy>
       <terminated>... .Set => SetItem(T) ...</terminated>
```

```k
  rule <k> join T:Int; => .K ...</k>
       <terminated>... SetItem(T) ...</terminated>
```


```k
  rule [acquire]: <k> acquire V:Val; => .K ...</k>
       <holds>... .Map => V |-> 0 ...</holds>
       <busy> Busy (.Set => SetItem(V)) </busy>
    requires (notBool(V in Busy))
```


```k
  rule <k> acquire V; => .K ...</k>
     <holds>... V:Val |-> (N => N +Int 1) ...</holds>
```

```k
  rule <k> release V:Val; => .K ...</k>
       <holds>... V |-> (N => N -Int 1) ...</holds>
    requires N >Int 0
```

```k
  rule <k> release V; => .K ...</k> <holds>... V:Val |-> 0 => .Map ...</holds>
       <busy>... SetItem(V) => .Set ...</busy>
```
```k
  rule <k> rendezvous V:Val; => .K ...</k>
       <k> rendezvous V; => .K ...</k>
```

```k
  rule I1 + I2 => I1 +Int I2
  rule Str1 + Str2 => Str1 +String Str2
  rule I1 - I2 => I1 -Int I2
  rule I1 * I2 => I1 *Int I2
  rule I1 / I2 => I1 /Int I2 requires I2 =/=K 0
  rule I1 % I2 => I1 %Int I2 requires I2 =/=K 0
  rule - I => 0 -Int I
  rule I1 < I2 => I1 <Int I2
  rule I1 <= I2 => I1 <=Int I2
  rule I1 > I2 => I1 >Int I2
  rule I1 >= I2 => I1 >=Int I2
  rule V1:Val == V2:Val => V1 ==K V2
  rule V1:Val != V2:Val => V1 =/=K V2

  rule sizeOf(array(_,N)) => N

  rule ! T => notBool(T)
  rule true  && E => E
  rule false && _ => false
  rule true  || _ => true
  rule false || E => E

  rule {} => .K

  rule <k> { S } => S ~> setEnv(Env) ...</k>  <env> Env </env>

  rule S1:Stmt S2:Stmt => S1 ~> S2
  rule _:Val; => .K

  rule if ( true) S else _ => S
  rule if (false) _ else S => S

  rule while (E) S => if (E) {S while(E)S}

  syntax KItem ::= setEnv(Map)
  rule <k> setEnv(Env) => .K ...</k>
       <env> _ => Env </env>
  rule (setEnv(_) => .K) ~> setEnv(_)

  syntax Map ::= Int "..." Int "|->" K [function]
  rule N...M |-> _ => .Map  requires N >Int M
  rule N...M |-> K => N |-> K (N +Int 1)...M |-> K  requires N <=Int M
  rule <k> print((V:Val, Es) => Es); ...</k> <output>... .List => ListItem(V) </output>
  rule print(.Vals); => .K

  rule isKResult(_:Val) => true
  rule isKResult(_:Vals) => true
endmodule
```
