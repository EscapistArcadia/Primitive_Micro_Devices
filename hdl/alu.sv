module alu32
import rv32cpu_type::*;
(
    input   logic   [31:0]      a, b,
    input   logic   [2:0]       op_funct3,
    input   logic               op_funct7,

    output  logic   [31:0]      out
    // output  logic               negative, zero, positive, overflow, carry
);
    always_comb begin
        unique case (op_funct3)
            arith_f3_add: out = a + (b ^ {32{op_funct7}}) + {31'd0, op_funct7};
            arith_f3_sll: out = a << b[4:0];
            arith_f3_slt: out = (signed'(a) < signed'(b)) ? 32'd1 : 32'd0;
            arith_f3_sltu: out = (unsigned'(a) < unsigned'(b)) ? 32'd1 : 32'd0;
            arith_f3_xor: out = a ^ b;
            arith_f3_sr: out = (op_funct7) ? unsigned'(signed'(a) >>> b[4:0]) : a >> b[4:0];
            arith_f3_or: out = a | b;
            arith_f3_and: out = a & b;
            default: out = 'x;
        endcase
    end

    // always_comb begin
    //     unique case (op)
    //         alu_op_add: out = a + b;
    //         alu_op_sll: out = a << b[4:0];
    //         alu_op_sra: out = unsigned'(signed'(a) >>> b[4:0]);
    //         alu_op_sub: out = a - b;
    //         alu_op_xor: out = a ^ b;
    //         alu_op_srl: out = a >> b[4:0];
    //         alu_op_or : out = a | b;
    //         alu_op_and: out = a & b;
    //         default   : out = 'x;
    //     endcase

    //     zero = ~|out;
    //     negative = ~zero & out[31];
    //     positive = ~zero & ~out[31];
    //     overflow = ~op[2] & ~(op[1] ^ op[0]) & (
    //                (~op[0] & ~a[31] & ~b[31] &  out[31]) |
    //                (~op[0] &  a[31] &  b[31] & ~out[31]) |
    //                ( op[0] & ~a[31] &  b[31] &  out[31]) |
    //                ( op[0] &  a[31] & ~b[31] & ~out[31])
    //     );
    //     carry = ((~op[2] & ~op[1] & ~op[0]) & (out < a) |
    //              (~op[2] &  op[1] &  op[0]) & (a < b));
    // end
endmodule