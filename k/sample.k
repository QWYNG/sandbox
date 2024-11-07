module K-SAMPLE

  syntax Color ::= Yellow() | Blue()
  syntax Fruit ::= Banana() | Blueberry()
  syntax Color ::= colorOf(Fruit)

  configuration <T>
                  <k> $PGM:Color </k>
                </T>

  rule [banana]: colorOf(Banana()) => Yellow()
  rule [bluebery]: colorOf(Blueberry()) => Blue()

endmodule
