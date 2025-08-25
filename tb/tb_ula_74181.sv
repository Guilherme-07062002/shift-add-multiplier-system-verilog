`timescale 1ns/1ps

module tb_ula_74181_simple;

    // Sinais de entrada
    reg [3:0] a, b, s;
    reg m, cin;
    
    // Sinais de saída
    wire [3:0] f;
    wire cout;
    
    // Instanciação da ULA
    ula_74181 uut (
        .a(a),
        .b(b),
        .s(s),
        .m(m),
        .cin(cin),
        .f(f),
        .cout(cout)
    );

    // Contadores de teste
    integer errors = 0;
    integer total_tests = 0;

    // Função para calcular o resultado esperado (modo aritmético - soma)
    function [4:0] calculate_expected_sum;
        input [3:0] a_val, b_val;
        input cin_val;
        begin
            calculate_expected_sum = {1'b0, a_val} + {1'b0, b_val} + (cin_val ? 5'd1 : 5'd0);
        end
    endfunction

    // Task para testar modo aritmético (soma)
    task test_arithmetic;
        input [3:0] a_val, b_val;
        input cin_val;
        reg [4:0] expected_result;
        reg [3:0] expected_f;
        reg expected_cout;
        begin
            a = a_val;
            b = b_val;
            s = 4'b1001; // Configuração para soma A + B
            m = 1'b0;    // Modo aritmético
            cin = cin_val;
            
            #10; // Aguarda estabilização
            
            expected_result = calculate_expected_sum(a_val, b_val, cin_val);
            expected_f = expected_result[3:0];
            expected_cout = expected_result[4];
            
            total_tests = total_tests + 1;
            
            if (f === expected_f && cout === expected_cout) begin
                $display("PASS: %d + %d + %d = %d (carry=%d)", a, b, cin, f, cout);
            end else begin
                errors = errors + 1;
                $display("FAIL: %d + %d + %d = %d (carry=%d), esperado %d (carry=%d)", 
                         a, b, cin, f, cout, expected_f, expected_cout);
            end
        end
    endtask

    // Task para testar modo lógico (XOR)
    task test_logic;
        input [3:0] a_val, b_val;
        reg [3:0] expected_f;
        begin
            a = a_val;
            b = b_val;
            s = 4'b1001; // Qualquer valor para modo lógico
            m = 1'b1;    // Modo lógico
            cin = 1'b0;
            
            #10; // Aguarda estabilização
            
            expected_f = a_val ^ b_val; // XOR conforme implementação
            
            total_tests = total_tests + 1;
            
            if (f === expected_f && cout === 1'b0) begin
                $display("PASS (LOGIC): %04b XOR %04b = %04b", a, b, f);
            end else begin
                errors = errors + 1;
                $display("FAIL (LOGIC): %04b XOR %04b = %04b, esperado %04b", 
                         a, b, f, expected_f);
            end
        end
    endtask

    initial begin
    $dumpfile("../sim/ula_74181.vcd");
        $dumpvars(0, tb_ula_74181_simple);
        
        $display("=== Teste da ULA 74181 (Versão Simplificada) ===");
        $display("Testando modo aritmético (soma):");
        
        // Testes básicos de soma
        test_arithmetic(4'd0, 4'd0, 1'b0);
        test_arithmetic(4'd1, 4'd1, 1'b0);
        test_arithmetic(4'd5, 4'd3, 1'b0);
        test_arithmetic(4'd15, 4'd1, 1'b0);
        test_arithmetic(4'd15, 4'd15, 1'b0);
        
        // Testes com carry in
        test_arithmetic(4'd0, 4'd0, 1'b1);
        test_arithmetic(4'd1, 4'd1, 1'b1);
        test_arithmetic(4'd7, 4'd8, 1'b1);
        test_arithmetic(4'd15, 4'd0, 1'b1);
        
        // Testes que geram carry out
        test_arithmetic(4'd8, 4'd8, 1'b0);
        test_arithmetic(4'd15, 4'd1, 1'b0);
        test_arithmetic(4'd15, 4'd15, 1'b1);
        
        $display("\nTestando modo lógico (XOR):");
        
        // Testes básicos de XOR
        test_logic(4'd0, 4'd0);
        test_logic(4'd15, 4'd15);
        test_logic(4'd5, 4'd3);
        test_logic(4'd12, 4'd10);
        test_logic(4'd15, 4'd0);
        
        $display("\n=== Resumo dos Testes ===");
        $display("Total de testes: %d", total_tests);
        $display("Erros: %d", errors);
        $display("Taxa de sucesso: %.1f%%", (total_tests - errors) * 100.0 / total_tests);
        
        if (errors == 0) begin
            $display("✓ TODOS OS TESTES PASSARAM!");
        end else begin
            $display("✗ ALGUNS TESTES FALHARAM!");
        end
        
        #20 $finish;
    end

endmodule
