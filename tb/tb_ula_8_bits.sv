`timescale 1ns/1ps

module tb_ula_8_bits;

        reg [7:0] a, b;
        reg [3:0] s;
        reg m, c_in;

        wire [7:0] f;
        wire a_eq_b, c_out, overflow;
        wire c_intermediate;

        integer errors = 0;
        integer total_tests = 0;

        function automatic [7:0] ref_logic;
                input [3:0] s_local;
                input [7:0] a_local, b_local;
                begin
                        case (s_local)
                                4'b0000: ref_logic = ~a_local;             // ~A
                                4'b0001: ref_logic = ~(a_local & b_local); // NAND
                                4'b0010: ref_logic = (~a_local) | b_local; // ~A + B
                                4'b0011: ref_logic = 8'hFF;                // 1
                                4'b0100: ref_logic = ~(a_local | b_local); // NOR
                                4'b0101: ref_logic = ~b_local;             // ~B
                                4'b0110: ref_logic = ~(a_local ^ b_local); // XNOR
                                4'b0111: ref_logic = a_local | (~b_local); // A + ~B
                                4'b1000: ref_logic = (~a_local) & b_local; // ~A & B
                                4'b1001: ref_logic = a_local ^ b_local;    // XOR
                                4'b1010: ref_logic = b_local;              // B
                                4'b1011: ref_logic = a_local | b_local;    // OR
                                4'b1100: ref_logic = 8'h00;                // 0
                                4'b1101: ref_logic = a_local | (~b_local); // A + ~B
                                4'b1110: ref_logic = a_local & b_local;    // AND
                                4'b1111: ref_logic = a_local;              // A
                                default: ref_logic = 8'hxx;
                        endcase
                end
        endfunction

        // Referência de 4 bits: mesma aritmética do 74181
        function automatic [4:0] ref_arith4;
                input [3:0] s_local;
                input [3:0] a4, b4;
                input       cin_local;
                reg [4:0] result;
                begin
                        case (s_local)
                                4'b0000: result = {1'b0, a4} + 5'b0_1111 + cin_local;                         // A - 1 / A
                                4'b0001: result = {1'b0, (a4 & b4)} + 5'b0_1111 + cin_local;                  // (A&B) - 1 / (A&B)
                                4'b0010: result = {1'b0, (a4 & ~b4)} + 5'b0_1111 + cin_local;                 // (A&~B) - 1 / (A&~B)
                                4'b0011: result = 5'b0_0000 + 5'b0_1111 + cin_local;                          // -1 / 0
                                4'b0100: result = {1'b0, a4} + {1'b0, a4} + {1'b0, ~b4} + cin_local;          // A + (A + ~B) [+1]
                                4'b0101: result = {1'b0, (a4 & b4)} + {1'b0, a4} + {1'b0, ~b4} + cin_local;   // (A&B) + (A + ~B) [+1]
                                4'b0110: result = {1'b0, a4} + {1'b0, ~b4} + cin_local;                       // A - B - 1 / A - B
                                4'b0111: result = {1'b0, a4} + {1'b0, ~b4} + cin_local;                       // A + ~B [+1]
                                4'b1000: result = {1'b0, a4} + {1'b0, a4} + {1'b0, b4} + cin_local;           // A + (A + B) [+1]
                                4'b1001: result = {1'b0, a4} + {1'b0, b4} + cin_local;                        // A + B [+1]
                                4'b1010: result = {1'b0, (a4 & ~b4)} + {1'b0, a4} + {1'b0, b4} + cin_local;   // (A&~B) + (A + B) [+1]
                                4'b1011: result = {1'b0, a4} + {1'b0, b4} + cin_local;                        // A + B [+1]
                                4'b1100: result = {1'b0, a4} + {1'b0, a4} + cin_local;                        // A + A [+1]
                                4'b1101: result = {1'b0, (a4 & b4)} + {1'b0, a4} + cin_local;                 // (A&B) + A [+1]
                                4'b1110: result = {1'b0, (a4 & ~b4)} + {1'b0, a4} + cin_local;                // (A&~B) + A [+1]
                                4'b1111: result = {1'b0, a4} + 5'b0_0000 + cin_local;                         // A [+1]
                                default: result = 5'h1x;
                        endcase
                        ref_arith4 = result;
                end
        endfunction

        // C_out apresentado (datasheet) a partir do carry verdadeiro de 4 bits
        function automatic bit ref_cout_from_true;
                input [3:0] s_local;
                input       true_cout4;
                begin
                        case (s_local)
                                4'b0000,4'b0010,4'b0011,4'b0110,4'b0111,4'b1011: ref_cout_from_true = ~true_cout4;
                                default: ref_cout_from_true = true_cout4;
                        endcase
                end
        endfunction

        function automatic bit ref_overflow;
                input [3:0] s_local;
                input [7:0] a_local, b_local, f_local;
                input       m_local;
                begin
                        if (m_local == 1'b0) begin
                                ref_overflow = ((s_local == 4'b1001) && (a_local[7] == b_local[7]) && (a_local[7] != f_local[7])) ||
                                                           ((s_local == 4'b0110) && (a_local[7] != b_local[7]) && (f_local[7] == b_local[7]));
                        end else ref_overflow = 1'b0;
                end
        endfunction

        task automatic run_and_check;
                input [3:0] s_local;
                input [7:0] a_local, b_local;
                input       m_local, cin_local;
                reg [8:0] r9;
                reg [7:0] f_exp;
                bit cout_exp, ovf_exp, eq_exp;
                reg [4:0] r_l, r_m;
                bit pass;
                begin
                        s = s_local; a = a_local; b = b_local; m = m_local; c_in = cin_local;
                        #2;
                        if (m_local) begin
                                f_exp = ref_logic(s_local, a_local, b_local);
                                cout_exp = 1'b0; ovf_exp = 1'b0;
                        end else begin
                                // Em 8 bits reais, duas 74181 em cascata com ripple carry verdadeiro
                                r_l   = ref_arith4(s_local, a_local[3:0], b_local[3:0], cin_local);
                                r_m   = ref_arith4(s_local, a_local[7:4], b_local[7:4], r_l[4]);
                                f_exp = {r_m[3:0], r_l[3:0]};
                                cout_exp = ref_cout_from_true(s_local, r_m[4]);
                                ovf_exp  = ref_overflow(s_local, a_local, b_local, f_exp, m_local);
                        end
                        eq_exp = (a_local == b_local);
                        total_tests++;
                        pass = (f === f_exp) && (c_out === cout_exp) && (a_eq_b === eq_exp) && (overflow === ovf_exp);
                        if (!pass) errors++;
                        $display("| %s | %04b | %02h | %02h |  %b  | %02h |  %b   |   %b   |    %b     |  %b  | %s |",
                                         m_local ? "LOG" : "ARI", s_local, a_local, b_local, cin_local, f, c_out, c_intermediate, overflow, a_eq_b, pass ? "PASS" : "FAIL");
                        if (!pass) $display("  -> ESPERADO: f=%02h c_out=%b overflow=%b a_eq_b=%b", f_exp, cout_exp, ovf_exp, eq_exp);
                end
        endtask

        ula_8_bits uut (
                .a(a), .b(b), .s(s), .m(m), .c_in(c_in),
                .f(f), .a_eq_b(a_eq_b), .c_out(c_out), .overflow(overflow), .c_intermediate(c_intermediate)
        );

        initial begin
                $monitor("t=%0t | M=%b S=%04b A=%02h B=%02h Cin=%b => F=%02h Cout=%b Cint=%b A=B=%b Ovf=%b",
                                 $time, m, s, a, b, c_in, f, c_out, c_intermediate, a_eq_b, overflow);
        end

        initial begin
                $dumpfile("../sim/ula_8_bits.vcd");
                $dumpvars(0, tb_ula_8_bits);
                $display("=== Testbench ULA 8 bits (consolidado) ===");

                m = 1'b0; s = 4'b1001; c_in = 1'b0;
                a = 8'h01; b = 8'h02; #10;
                a = 8'h0F; b = 8'h01; #10;
                a = 8'h7F; b = 8'h01; #10;
                a = 8'hFF; b = 8'h01; #10;

                s = 4'b1000;
                a = 8'h0A; b = 8'h05; #10;
                a = 8'h05; b = 8'h0A; #10;
                a = 8'h80; b = 8'h01; #10;

                // Varredura completa
                $display("\n=== Varredura Completa das 32 Funcoes ===");
                $display("| Modo | S    |   A   |   B   | Cin |   F   | Cout | C_Int | Overflow | A=B | Status |");
                $display("|------|------|-------|-------|-----|-------|------|-------|----------|-----|--------|");
                for (int mode = 0; mode <= 1; mode++) begin
                        for (int func = 0; func < 16; func++) begin
                                for (int cinv = 0; cinv <= 1; cinv++) begin
                                        run_and_check(func[3:0], 8'h00, 8'h00, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'hFF, 8'h00, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'h00, 8'hFF, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'hAA, 8'h55, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'h55, 8'hAA, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'h7F, 8'h01, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'h80, 8'h01, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'hF0, 8'h0F, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'h10, 8'h01, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'h01, 8'h10, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'h33, 8'h33, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'h0F, 8'h01, mode[0], cinv[0]);
                                        run_and_check(func[3:0], 8'h01, 8'h0F, mode[0], cinv[0]);
                                end
                        end
                end

                if (errors == 0) $display("\n=== TODOS OS TESTES AUTOMATICOS PASSARAM! (total=%0d) ===", total_tests);
                else $display("\n=== %0d FALHAS em %0d testes automaticos ===", errors, total_tests);

                #50; $finish;
        end

endmodule
