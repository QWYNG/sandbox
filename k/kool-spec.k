requires "kool.md"
requires "domains.md"

module KOOL-SPEC-SYNTAX
    imports KOOL-SYNTAX

endmodule

module VERIFICATION
    imports K-EQUAL
    imports KOOL-SPEC-SYNTAX
    imports KOOL
    imports MAP-SYMBOLIC
endmodule

module KOOL-SPEC
    imports VERIFICATION

claim
 <k>
    class Main {
        method Main(.Ids) {
            3 + 4;
        }
    } => .K
 </k>
endmodule
