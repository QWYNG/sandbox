requires "simp.k"
requires "domains.md"

module SIMP-SPEC-SYNTAX
    imports SIMP-SYNTAX

endmodule

module VERIFICATION
    imports K-EQUAL
    imports SIMP-SPEC-SYNTAX
    imports SIMP
    imports MAP-SYMBOLIC
endmodule

module SIMP-SPEC
    imports VERIFICATION

syntax Id ::= "$x" [token]
            | "$y" [token]

claim <k> int $x, $y;
          $x = X:Int;
          $y = Y:Int;
          if ( $x < $y ) {
            $y = $x;
          } else {
            $x = $y;
          }
      => .K </k>
      <state> STATE => STATE [$x <- X] [$y <- X] </state>
      requires notBool(X ==Int Y)
          andBool notBool($x in keys(STATE))
          andBool notBool($y in keys(STATE [ $x <- 0 ]))
endmodule
