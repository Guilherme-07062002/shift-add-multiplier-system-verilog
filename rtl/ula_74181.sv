// ULA 4 bits simplificada: modo aritmético (m=0) soma com carry; modo lógico (m=1) XOR.
module ula_74181 (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic [3:0] s,
    input  logic       m,
    input  logic       cin,
    output logic [3:0] f,
    output logic       cout
);

    logic [4:0] sum;
    assign sum = {1'b0, a} + {1'b0, b} + (cin ? 1'b1 : 1'b0);
    assign f = (m == 1'b0) ? sum[3:0] : (a ^ b);
    assign cout = (m == 1'b0) ? sum[4] : 1'b0;

endmodule