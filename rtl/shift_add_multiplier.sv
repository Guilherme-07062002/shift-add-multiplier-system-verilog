module shift_add_multiplier (
    input  logic clk,
    input  logic rst,
    input  logic [7:0] multiplicand, // B
    input  logic [7:0] multiplier,   // Q
    output logic [15:0] result,
    output logic end_op
);

    // Registers for A, B, Q
    logic [7:0] A_out, B_out, Q_out;

    // Internal counter
    integer cnt;

    // ALU wires (combinational)
    logic [7:0] sum;
    logic c_out;

    // ULA instance for A + B
    wire aeqb, overflow, p, g, c_intermediate;
    ula_8_bits alu (
        .a(A_out),
        .b(B_out),
        .s(4'b1001), // A + B
        .m(1'b0),
        .c_in(1'b0),
        .f(sum),
        .a_eq_b(aeqb),
        .c_out(c_out),
        .overflow(overflow),
        .p(p),
        .g(g),
        .c_intermediate(c_intermediate)
    );

    // FSM states as localparams (avoid enum casting issues)
    localparam logic [1:0] S_LOAD = 2'b00;
    localparam logic [1:0] S_RUN  = 2'b01;
    localparam logic [1:0] S_DONE = 2'b10;
    logic [1:0] state, next_state;

    // Sequential logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_LOAD;
            A_out <= 8'd0;
            B_out <= 8'd0;
            Q_out <= 8'd0;
            cnt <= 0;
        end else begin
            state <= next_state;
            case (state)
                S_LOAD: begin
                    // synchronous load
                    A_out <= 8'd0;
                    B_out <= multiplicand;
                    Q_out <= multiplier;
                    cnt <= 8; // 8 iterations
                end
                S_RUN: begin
                    // perform one iteration per clock
                    logic [7:0] newA;
                    logic [7:0] newQ;
                    if (Q_out[0]) begin
                        // add then shift right with carry into MSB of A
                        newA = {c_out, sum[7:1]};
                        newQ = {sum[0], Q_out[7:1]};
                    end else begin
                        // no add, shift A right inserting 0 into MSB
                        newA = {1'b0, A_out[7:1]};
                        newQ = {A_out[0], Q_out[7:1]};
                    end
                    A_out <= newA;
                    Q_out <= newQ;
                    cnt <= cnt - 1;
                end
                S_DONE: begin
                    // hold
                    A_out <= A_out;
                    B_out <= B_out;
                    Q_out <= Q_out;
                end
            endcase
        end
    end

    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            S_LOAD: next_state = S_RUN;
            S_RUN:  next_state = (cnt <= 1) ? S_DONE : S_RUN;
            S_DONE: next_state = S_DONE;
            default: next_state = S_LOAD;
        endcase
    end

    assign result = {A_out, Q_out};
    assign end_op = (state == S_DONE);

endmodule
