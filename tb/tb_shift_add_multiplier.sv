`timescale 1ns/1ps

module tb_shift_add_multiplier;

    // Signals
    logic clk;
    logic rst;
    logic [7:0] multiplicand;
    logic [7:0] multiplier;
    logic [15:0] result;
    logic end_op;

    // DUT
    shift_add_multiplier uut (
        .clk(clk), .rst(rst), .multiplicand(multiplicand), .multiplier(multiplier),
        .result(result), .end_op(end_op)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Test vectors (simple arrays for compatibility)
    logic [7:0] test_a [0:5];
    logic [7:0] test_b [0:5];

    integer i;
    integer cycles;
    integer timeout;
    logic [15:0] expected;

    initial begin
    $dumpfile("sim/shift_add_multiplier.vcd");
        $dumpvars(0, tb_shift_add_multiplier);

        // Prepare test vectors
        test_a[0] = 8'd3;   test_b[0] = 8'd5;
        test_a[1] = 8'd10;  test_b[1] = 8'd12;
        test_a[2] = 8'd127; test_b[2] = 8'd201;
        test_a[3] = 8'd255; test_b[3] = 8'd255;
        test_a[4] = 8'd0;   test_b[4] = 8'd123;
        test_a[5] = 8'd13;  test_b[5] = 8'd11;

        // Run tests
        for (i = 0; i < 6; i = i + 1) begin
            multiplicand = test_a[i];
            multiplier   = test_b[i];

            // Reset pulse to initialize the multiplier
            rst = 1;
            @(posedge clk);
            @(posedge clk);
            rst = 0;

            // Wait for end_op or timeout
            cycles = 0;
            timeout = 200;
            while (!end_op && cycles < timeout) begin
                    @(posedge clk);
                    cycles = cycles + 1;
                    // debug: print internal registers and control signals
                    $display(" cycle=%0d A=0x%0h B=0x%0h Q=0x%0h | sum=0x%0h c_out=%b",
                        cycles, uut.A_out, uut.B_out, uut.Q_out, uut.sum, uut.c_out);
            end

            // Compute expected result
            expected = multiplicand * multiplier;

            $display("--------------------------------------------------");
            $display("Test %0d: %0d x %0d", i, multiplicand, multiplier);
            $display("Cycles waited: %0d, end_op=%0b", cycles, end_op);
            $display("Result DUT = %0d (0x%0h), Expected = %0d (0x%0h)", result, result, expected, expected);
            if (result === expected) $display("PASS"); else $display("FAIL");

            // Small gap between tests
            repeat (4) @(posedge clk);
        end

        $display("All tests completed.");
        #20 $finish;
    end

endmodule
