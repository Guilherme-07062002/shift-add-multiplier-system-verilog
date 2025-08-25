module shift_add_multiplier (
    input  logic clk,
    input  logic rst,
    input  logic [7:0] multiplicand, // B
    input  logic [7:0] multiplier,   // Q
    output logic [15:0] result,
    output logic end_op
);

    // Internal signals
    logic [7:0] A_out, B_out, Q_out;
    logic [7:0] A_next, Q_next;
    logic [7:0] sum;
    logic c_out;

    // Dynamic control signals for shift_registers
    logic [1:0] regA_ctrl, regB_ctrl, regQ_ctrl;
    logic [7:0] regA_parallel_in, regB_parallel_in, regQ_parallel_in;

    // Instantiate three shift registers: A (accumulator), B (multiplicand), Q (multiplier)
    shift_register #(.N(8)) regA (
        .clk(clk), .rst(rst), .ctrl(regA_ctrl),
        .parallel_in(regA_parallel_in), .ser_in(1'b0),
        .parallel_out(A_out), .ser_out() // ser_out not used directly
    );

    shift_register #(.N(8)) regB (
        .clk(clk), .rst(rst), .ctrl(regB_ctrl),
        .parallel_in(regB_parallel_in), .ser_in(1'b0),
        .parallel_out(B_out), .ser_out()
    );

    shift_register #(.N(8)) regQ (
        .clk(clk), .rst(rst), .ctrl(regQ_ctrl),
        .parallel_in(regQ_parallel_in), .ser_in(1'b0),
        .parallel_out(Q_out), .ser_out()
    );

    // Counter to iterate 8 times
    logic cnt_load;
    logic cnt_en;
    logic cnt_updown = 1'b0; // count down
    logic [7:0] cnt_in = 8'd8;
    logic [7:0] cnt_out;
    logic cnt_end;

    counter #(.N(8)) iter_cnt (
        .clk(clk), .rst(rst), .load(cnt_load), .en(cnt_en), .up_down(cnt_updown),
        .data_in(cnt_in), .data_out(cnt_out), .end_count(cnt_end)
    );

    // Instantiate the 8-bit ALU to compute A + B combinationally
    wire aeqb, overflow, p, g, c_intermediate;
    ula_8_bits alu (
        .a(A_out),
        .b(B_out),
        .s(4'b1001), // operação A + B
        .m(1'b0),    // modo aritmético
        .c_in(1'b0), // sem carry-in extra
        .f(sum),
        .a_eq_b(aeqb),
        .c_out(c_out),
        .overflow(overflow),
        .p(p),
        .g(g),
        .c_intermediate(c_intermediate)
    );

    // FSM to control the operation
    typedef enum logic [1:0] {S_IDLE=2'b00, S_LOAD=2'b01, S_RUN=2'b10, S_DONE=2'b11} state_t;
    state_t state, next_state;

    // Compute combinational next values for A and Q (one iteration step)
    // If Q_out[0] == 1 -> add then shift; else shift A right with 0 carry
    always_comb begin
        logic q0 = Q_out[0];
        logic [7:0] shiftA_noadd = {1'b0, A_out[7:1]};
        logic [7:0] shiftA_add = {c_out, sum[7:1]};
        logic ser_in_q_noadd = A_out[0];
        logic ser_in_q_add = sum[0];

        if (q0) begin
            A_next = shiftA_add;
            Q_next = {ser_in_q_add, Q_out[7:1]};
        end else begin
            A_next = shiftA_noadd;
            Q_next = {ser_in_q_noadd, Q_out[7:1]};
        end
    end

    // FSM sequential
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_LOAD;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic and control signals
    always_comb begin
        // default controls
        next_state = state;
        cnt_load = 1'b0;
        cnt_en   = 1'b0;
    // default: controls for shift registers
    regA_ctrl = 2'b00; // hold
    regB_ctrl = 2'b00; // hold
    regQ_ctrl = 2'b00; // hold
    // default parallel inputs: use computed next by default
    regA_parallel_in = A_next;
    regB_parallel_in = multiplicand;
    regQ_parallel_in = Q_next;

    // We will set appropriate ctrl and parallel_in per state below

        case (state)
            S_LOAD: begin
                // load registers A=0, B=multiplicand, Q=multiplier, counter=8
                cnt_load = 1'b1;
                cnt_en   = 1'b0;
                // Assert parallel load for all registers to initialize values
                regA_ctrl = 2'b11; regB_ctrl = 2'b11; regQ_ctrl = 2'b11;
                regA_parallel_in = 8'd0; // A <- 0
                regB_parallel_in = multiplicand; // B <- multiplicand
                regQ_parallel_in = multiplier;   // Q <- multiplier
                next_state = S_RUN;
            end
            S_RUN: begin
                cnt_load = 1'b0;
                cnt_en   = 1'b1; // decrement each cycle
                // During run, we want to update A and Q each cycle with the computed A_next/Q_next
                // Do parallel load of A and Q every cycle; keep B held
                regA_ctrl = 2'b11;
                regQ_ctrl = 2'b11;
                regB_ctrl = 2'b00;

                if (cnt_end) begin
                    next_state = S_DONE;
                end else begin
                    next_state = S_RUN;
                end
            end
            S_DONE: begin
                cnt_load = 1'b0;
                cnt_en   = 1'b0;
                // Hold final result
                regA_ctrl = 2'b00; regB_ctrl = 2'b00; regQ_ctrl = 2'b00;
                next_state = S_DONE;
            end
            default: begin
                next_state = S_LOAD;
            end
        endcase
    end

    // Outputs
    assign result = {A_out, Q_out};
    assign end_op = (state == S_DONE);

endmodule
