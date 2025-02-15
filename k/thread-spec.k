requires "thread.md"
requires "domains.md"

module THREAD-SPEC-SYNTAX
    imports THREAD-SYNTAX

endmodule

module VERIFICATION
    imports K-EQUAL
    imports THREAD-SPEC-SYNTAX
    imports THREAD
    imports MAP-SYMBOLIC
endmodule

module THREAD-SPEC
    imports VERIFICATION

syntax Id ::= "$x" [token]
            | "$t1" [token]

claim <k> var $x;
        $x = 2;

        var $t1;
        $t1 = spawn {
        if ($x > 1) {
            $x = $x - 1;
        }
        };

        if ($x > 1) {
        $x = $x - 1;
        }

        join $t1;  
      => .K </k>
      <store> STORE => STORE [0 <- 1] ...</store>
endmodule
