 ```k
module CLASS-SYNTAX
  imports DOMAINS-SYNTAX

  syntax Id ::= "Object" [token] | "Main" [token]

  syntax Stmt ::= "var" Exps ";"
                | "method" Id "(" Ids ")" Block  // called "function" in SIMPLE
                | "class" Id Block               // CLASS
                | "class" Id "extends" Id Block  // CLASS

  syntax Exp ::= Int | Bool | String | Id
               | "this"                                 // CLASS
               | "super"                                // CLASS
               | "(" Exp ")"             [bracket]
               | "++" Exp
               | Exp "instanceOf" Id     [strict(1)]    // CLASS
               | "(" Id ")" Exp          [strict(2)]    // CLASS  cast
               | "new" Id "(" Exps ")"   [strict(2)]    // CLASS
               | Exp "." Id                             // CLASS
               > Exp "[" Exps "]"        [strict]
               > Exp "(" Exps ")"        [strict(2)]    // was strict in SIMPLE
               | "-" Exp                 [strict]
               | "sizeOf" "(" Exp ")"    [strict]
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

  syntax Stmt ::= Stmt Stmt                          [right]


  rule if (E) S => if (E) S else {}
  rule for(Start Cond; Step) {S} => {Start while (Cond) {S Step;}}
  rule for(Start Cond; Step) {} => {Start while (Cond) {Step;}}
  rule var E1:Exp, E2:Exp, Es:Exps; => var E1; var E2, Es;
  rule var X:Id = E; => var X; X = E;
endmodule
```

```k
module CLASS
  imports CLASS-SYNTAX
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
                <k > $PGM:Stmt ~> execute </k>
                <control >
                  <fstack > .List </fstack>
                  <crntObj>
                      <crntClass> Object </crntClass>
                      <envStack> .List </envStack>
                      <location multiplicity="?"> .K </location>
                  </crntObj>
                </control>
                <env > .Map </env>
                <store > .Map </store>
                <nextLoc > 0 </nextLoc>
                <classes >        
                    <classData multiplicity="*" type="Map" >
                    <className > Main </className>
                    <baseClass > Object </baseClass>
                    <declarations > .K </declarations>
                    </classData>
                </classes>
                <output > .List </output>
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
  rule <k> lookup(L) => V ...</k> <store>... L |-> V:Val ...</store>
```


```k
  syntax Stmt ::= mkDecls(Ids,Vals)  [function]
  rule mkDecls((X:Id, Xs:Ids), (V:Val, Vs:Vals)) => var X=V; mkDecls(Xs,Vs)
```

```k
  rule mkDecls(.Ids,.Vals) => {}
```

```k
  rule <k> return(V:Val); ~> _ => V ~> K </k>
       <control>
         <fstack> ListItem(fstackFrame(Env,K,<crntObj> CO </crntObj>)) => .List ...</fstack>
         <crntObj> _ => CO </crntObj>
       </control>
       <env> _ => Env </env>
```

```k

  syntax Val ::= "nothing"
  rule return; => return nothing;
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
  rule lvalue(objectClosure(Class, ListItem(envStackFrame(Class,Env)) EStack)
              . X
              => lookupMember(ListItem(envStackFrame(Class,Env)) EStack,
                              X))
  rule lvalue(objectClosure(Class, (ListItem(envStackFrame(Class':Id,_)) => .List) _)
              . _X)
    requires Class =/=K Class'
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
  rule lvalue(lookup(L:Int) => loc(L))
```


```k
  context ++(HOLE => lvalue(HOLE))
```

```k
  rule <k> ++loc(L) => I +Int 1 ...</k>
       <store>... L |-> (I => I +Int 1) ...</store>
```


```k
  syntax Val ::= objectClosure(Id, List)
               | methodClosure(Id,Int,Ids,Stmt)
```


```k
rule [class]: class C:Id S => class C extends Object S

rule [extend]: <k> class Class1 extends Class2 { S } => .K ...</k>
      <classes>... (.Bag => <classData>
                          <className> Class1 </className>
                          <baseClass> Class2 </baseClass>
                          <declarations> S </declarations>
                      </classData>)
      ...</classes>
```

```k
  syntax KItem ::= "envStackFrame" "(" Id "," Map ")"

  rule [new]: <k> new Class:Id(Vs:Vals) ~> K
           => create(Class) ~> storeObj ~> Class(Vs); return this; </k>
       <env> Env => .Map </env>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
       <control>
         <crntObj> Obj
                   => <crntClass> Object </crntClass>
                      <envStack> ListItem(envStackFrame(Object, .Map)) </envStack>
                      <location> L </location>
         </crntObj>
         <fstack> .List => ListItem(fstackFrame(Env, K, <crntObj> Obj </crntObj>)) ...</fstack>
       </control>

  syntax KItem ::= create(Id)

  rule <k> create(Class:Id)
           => create(Class1) ~> setCrntClass(Class) ~> S ~> addEnvLayer ...</k>
       <className> Class </className>
       <baseClass> Class1:Id </baseClass>
       <declarations> S </declarations>

  rule <k> create(Object) => .K ...</k>

  syntax KItem ::= setCrntClass(Id)

  rule <k> setCrntClass(C) => .K ...</k>
       <crntClass> _ => C </crntClass>

  syntax KItem ::= "addEnvLayer"

  rule <k> addEnvLayer => .K ...</k>
       <env> Env => .Map </env>
       <crntClass> Class:Id </crntClass>
       <envStack> .List => ListItem(envStackFrame(Class, Env)) ...</envStack>

  syntax KItem ::= "storeObj"

  rule <k> storeObj => .K ...</k>
       <crntObj> <crntClass> CC </crntClass> <envStack> ES </envStack> (<location> L:Int </location> => .Bag) </crntObj>
       <store>... .Map => L |-> objectClosure(CC, ES) ...</store>

  rule <k> this => objectClosure(CC, ES) ...</k>
       <crntObj> <crntClass> CC </crntClass> <envStack> ES </envStack> </crntObj>

```

```k
  rule <k> X:Id => this . X ...</k> <env> Env:Map </env>
    requires notBool(X in keys(Env))

  context HOLE._::Id requires (HOLE =/=K super)


  rule objectClosure(Class:Id, ListItem(envStackFrame(Class,Env)) EStack)
       . X:Id
    => lookupMember(ListItem(envStackFrame(Class,Env)) EStack, X)
  rule objectClosure(Class:Id, (ListItem(envStackFrame(Class':Id,_)) => .List) _)
       . _X:Id
    requires Class =/=K Class'

  rule <k> super . X => lookupMember(EStack, X) ...</k>
       <crntClass> Class:Id </crntClass>
       <envStack> ListItem(envStackFrame(Class,_)) EStack </envStack>
  rule <k> super . _X ...</k>
       <crntClass> Class </crntClass>
       <envStack> ListItem(envStackFrame(Class':Id,_)) => .List ...</envStack>
    requires Class =/=K Class'
```

```k
  rule <k> method F:Id(Xs:Ids) S => .K ...</k>
       <crntClass> Class:Id </crntClass>
       <location> OL:Int </location>
       <env> Env => Env[F <- L] </env>
       <store>... .Map => L |-> methodClosure(Class,OL,Xs,S) ...</store>
       <nextLoc> L => L +Int 1 </nextLoc>
```


```k
  rule <k> (X:Id => V)(_:Exps) ...</k>
       <env>... X |-> L ...</env>
       <store>... L |-> V:Val ...</store>

  rule <k> (X:Id => this . X)(_:Exps) ...</k>
       <env> Env </env>
    requires notBool(X in keys(Env))

  context HOLE._::Id(_) requires HOLE =/=K super

  rule (objectClosure(_, EStack) . X
    => lookupMember(EStack, X:Id))(_:Exps)

  rule <k> (super . X
            => lookupMember(EStack,X))(_:Exps)...</k>
       <crntClass> Class </crntClass>
       <envStack> ListItem(envStackFrame(Class,_)) EStack </envStack>
  rule <k> (super . _X)(_:Exps) ...</k>
       <crntClass> Class </crntClass>
       <envStack> ListItem(envStackFrame(Class':Id,_)) => .List ...</envStack>
    requires Class =/=K Class'

  rule (A:Exp(B:Exps))(C:Exps) => A(B) ~> #freezerFunCall(C)
  rule (A:Exp[B:Exps])(C:Exps) => A[B] ~> #freezerFunCall(C)
  rule V:Val ~> #freezerFunCall(C:Exps) => V(C)
  syntax KItem ::= "#freezerFunCall" "(" K ")"
  rule <k> (lookup(L) => V)(_:Exps) ...</k>  <store>... L |-> V:Val ...</store>
```


```k
  rule <k> methodClosure(Class,OL,Xs,S)(Vs:Vals) ~> K
           => mkDecls(Xs,Vs) S return; </k>
       <env> Env => .Map </env>
       <store>... OL |-> objectClosure(_, EnvStack)...</store>
       <control>
          <fstack> .List => ListItem(fstackFrame(Env, K, <crntObj> Obj' </crntObj>))
          ...</fstack>
          <crntObj> Obj' => <crntClass> Class </crntClass> <envStack> EnvStack </envStack> </crntObj>
       </control>
```

```k
    syntax Exp ::= lookupMember(List, Id)  [function]

  rule lookupMember(ListItem(envStackFrame(_, X|->L _)) _, X)
    => lookup(L)


  rule lookupMember(ListItem(envStackFrame(_, Env)) Rest, X) =>
       lookupMember(Rest, X)
    requires notBool(X in keys(Env))
```

```k
  rule objectClosure(_, ListItem(envStackFrame(C,_)) _)
       instanceOf C => true

  rule objectClosure(_, (ListItem(envStackFrame(C,_)) => .List) _)
       instanceOf C'  requires C =/=K C'

  rule objectClosure(_, .List) instanceOf _ => false
```


```k
  rule (C) objectClosure(_ , EnvStack) => objectClosure(C ,EnvStack)
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


  syntax KItem ::= "execute"
  rule <k> execute => new Main(.Vals); </k>
       <env> .Map </env>

  syntax KItem ::= fstackFrame(Map,K,K)
                 | (Map,K,K)


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
  rule isKResult(nothing) => true
endmodule
```
