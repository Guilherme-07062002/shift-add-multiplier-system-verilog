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

    // Test vectors
    typedef struct packed { logic [7:0] a; logic [7:0] b; } test_t;
    test_t tests[6];

    initial begin
        $dumpfile("shift_add_multiplier.vcd");
        $dumpvars(0, tb_shift_add_multiplier);

        // Prepare test vectors
        tests[0] = '{8'd3, 8'd5};
        tests[1] = '{8'd10, 8'd12};
        tests[2] = '{8'd127, 8'd201};
        tests[3] = '{8'd255, 8'd255};
        tests[4] = '{8'd0, 8'd123};
        tests[5] = '{8'd13, 8'd11};

        // Run tests
        for (int i = 0; i < $size(tests); i++) begin
            multiplicand = tests[i].a;
            multiplier   = tests[i].b;

            // Reset pulse to initialize the multiplier
            rst = 1;
            @(posedge clk);
            @(posedge clk);
            rst = 0;

            // Wait for end_op or timeout
            int cycles = 0;
            int timeout = 200;
            while (!end_op && cycles < timeout) begin
                @(posedge clk);
                cycles++;
            end

            // Compute expected result
            int expected = multiplicand * multiplier;

            $display("--------------------------------------------------");
            $display("Test %0d: %0d x %0d", i, multiplicand, multiplier);
            $display("Cycles waited: %0d, end_op=%0b, state=%0b", cycles, end_op, uut.state);
            $display("Result DUT = %0d (0x%0h), Expected = %0d (0x%0h)", result, result, expected, expected);
            if (result === expected) $display("PASS"); else $display("FAIL");

            // Small gap between tests
            repeat (4) @(posedge clk);
        end

        $display("All tests completed.");
        #20 $finish;
    end

endmodule
