module shift_add_multiplier (
    input  logic clk,
    input  logic rst,
    input  logic [7:0] multiplicand, // B
    input  logic [7:0] multiplier,   // Q
    output logic [15:0] result,
    output logic end_op
);

    // Use the provided shift_register and counter modules structurally.
    // Three 8-bit shift registers: A (accumulator), B (multiplicand), Q (multiplier)
    // One 8-bit counter to count iterations (synchronous load, decrement)

    // Wires to connect to registers
    logic [7:0] A_parallel_in, B_parallel_in, Q_parallel_in;
    logic [7:0] A_out, B_out, Q_out;
    logic A_ser_in, B_ser_in, Q_ser_in;
    logic A_ser_out, B_ser_out, Q_ser_out;
    logic [1:0] A_ctrl, B_ctrl, Q_ctrl; // 11=parallel load,10=shift left,01=shift right,00=hold

    // Counter signals
    logic cnt_load, cnt_en, cnt_up_down;
    logic [7:0] cnt_data_in, cnt_data_out;
    logic cnt_end;

    // Instantiate registers
    shift_register #(.N(8)) regA (
        .clk(clk), .rst(rst), .ctrl(A_ctrl), .parallel_in(A_parallel_in), .ser_in(A_ser_in),
        .parallel_out(A_out), .ser_out(A_ser_out)
    );

    shift_register #(.N(8)) regB (
        .clk(clk), .rst(rst), .ctrl(B_ctrl), .parallel_in(B_parallel_in), .ser_in(B_ser_in),
        .parallel_out(B_out), .ser_out(B_ser_out)
    );

    shift_register #(.N(8)) regQ (
        .clk(clk), .rst(rst), .ctrl(Q_ctrl), .parallel_in(Q_parallel_in), .ser_in(Q_ser_in),
        .parallel_out(Q_out), .ser_out(Q_ser_out)
    );

    // Instantiate counter
    counter #(.N(8)) iter_cnt (
        .clk(clk), .rst(rst), .load(cnt_load), .en(cnt_en), .up_down(cnt_up_down),
        .data_in(cnt_data_in), .data_out(cnt_data_out), .end_flag(cnt_end)
    );

    // ALU for A + B (combinational)
    logic [7:0] sum;
    logic c_out;
    // ula_8_bits ports: (a,b,s,m,cin,f,cout)
    ula_8_bits alu (
        .a(A_out), .b(B_out), .s(4'b1001), .m(1'b0), .cin(1'b0),
        .f(sum), .cout(c_out)
    );

    // FSM states (use Verilog-compatible localparam and reg for wider tool support)
    localparam [2:0] S_LOAD        = 3'b000;
    localparam [2:0] S_LOAD_WAIT   = 3'b001; // give synchronous loads a cycle to settle
    localparam [2:0] S_RUN_COMPUTE = 3'b010; // compute next A/Q based on Q[0]
    localparam [2:0] S_RUN_LOAD    = 3'b011; // assert parallel load with precomputed values
    localparam [2:0] S_DONE        = 3'b100;
    reg [2:0] state, next_state;

    // Default ties for serial inputs (we use parallel loads every iteration)
    assign A_ser_in = 1'b0;
    assign B_ser_in = 1'b0;
    assign Q_ser_in = 1'b0;

    // Combinational next-value logic for A and Q (depends on current A_out,B_out,Q_out and ALU)
    logic [7:0] A_next_comb;
    logic [7:0] Q_next_comb;
    // temp registers to hold computed values between compute and load states
    logic [7:0] tempA, tempQ;
    // Combinational next-value logic for A and Q (depends on current A_out,B_out,Q_out and ALU)
    // Use always @* for broader simulator compatibility
    always @* begin
        if (Q_out[0]) begin
            // add then shift right: new A = {c_out, sum[7:1]}; new Q = {sum[0], Q_out[7:1]}
            A_next_comb = {c_out, sum[7:1]};
            Q_next_comb = {sum[0], Q_out[7:1]};
        end else begin
            // no add, shift right without add: new A = {1'b0, A_out[7:1]}; new Q = {A_out[0], Q_out[7:1]}
            A_next_comb = {1'b0, A_out[7:1]};
            Q_next_comb = {A_out[0], Q_out[7:1]};
        end
    end

    // Control and datapath signals generation (combinational from state)
    // local iteration counter used to control number of runs (keeps decision local and deterministic)
    integer iterations_left;

    // Use always @* for combinational control logic
    always @* begin
        // defaults
        A_ctrl = 2'b00;
        B_ctrl = 2'b00;
        Q_ctrl = 2'b00;
        A_parallel_in = 8'd0;
        B_parallel_in = 8'd0;
        Q_parallel_in = 8'd0;
        cnt_load = 1'b0;
        cnt_en = 1'b0;
        cnt_up_down = 1'b0;
        cnt_data_in = 8'd0;

        case (state)
            S_LOAD: begin
                // assert parallel loads for A,B,Q and load counter
                A_ctrl = 2'b11; B_ctrl = 2'b11; Q_ctrl = 2'b11;
                A_parallel_in = 8'd0;
                B_parallel_in = multiplicand;
                Q_parallel_in = multiplier;
                cnt_load = 1'b1;
                cnt_data_in = 8'd8; // number of iterations
                cnt_up_down = 1'b0; // we'll use down mode
            end
            S_LOAD_WAIT: begin
                // nothing: wait for registers to capture
            end
            S_RUN_COMPUTE: begin
                // compute next values and store into temp registers (assigned in sequential block)
                B_ctrl = 2'b00; // hold B
            end
            S_RUN_LOAD: begin
                // perform the parallel load with precomputed tempA/tempQ and decrement the counter
                A_ctrl = 2'b11;
                Q_ctrl = 2'b11;
                B_ctrl = 2'b00; // hold B
                A_parallel_in = tempA;
                Q_parallel_in = tempQ;
                // enable counter for structural counter to decrement in sync with our local iteration decrement
                cnt_en = 1'b1;
                cnt_up_down = 1'b0; // decrement
            end
            S_DONE: begin
                // hold
                A_ctrl = 2'b00; B_ctrl = 2'b00; Q_ctrl = 2'b00;
            end
            default: begin end
        endcase
    end

    // Sequential state update and tempA/tempQ/iterations_left management
    // Use classic always block for compatibility
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_LOAD;
            tempA <= 8'd0;
            tempQ <= 8'd0;
            iterations_left <= 0;
        end else begin
            state <= next_state;
            case (state)
                S_LOAD: begin
                    // when loading initial values, set local iterations counter
                    iterations_left <= 8;
                end
                S_LOAD_WAIT: begin
                    // nothing
                end
                S_RUN_COMPUTE: begin
                    // latch computed combinational next values into temps
                    tempA <= A_next_comb;
                    tempQ <= Q_next_comb;
                end
                S_RUN_LOAD: begin
                    // after performing the parallel load, decrement our local counter
                    if (iterations_left > 0) iterations_left <= iterations_left - 1;
                end
                S_DONE: begin
                    // hold
                end
            endcase
        end
    end

    // Next-state logic (combinational)
    always @* begin
        next_state = state;
        case (state)
            S_LOAD:      next_state = S_LOAD_WAIT; // give one cycle to capture loads
            S_LOAD_WAIT: next_state = S_RUN_COMPUTE;
            S_RUN_COMPUTE: next_state = S_RUN_LOAD;
            S_RUN_LOAD:  next_state = (iterations_left <= 1) ? S_DONE : S_RUN_COMPUTE;
            S_DONE:      next_state = S_DONE;
            default:     next_state = S_LOAD;
        endcase
    end

    assign result = {A_out, Q_out};
    assign end_op = (state == S_DONE);

endmodule
