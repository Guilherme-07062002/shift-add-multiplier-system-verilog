// Multiplicador sequencial 8x8 (Shift-Add).
// A acumula somas condicionais (Q0?B); após cada soma desloca (carry_reg,A,Q) à direita.
// Ao final de 8 ciclos: result = {A,Q}; end_op=1.
module shift_add_multiplier (
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  multiplicand, // B
    input  logic [7:0]  multiplier,   // Q
    output logic [15:0] result,
    output logic        end_op
);

    // Registradores
    logic [7:0] A_parallel_in, B_parallel_in, Q_parallel_in;
    logic [7:0] A_out, B_out, Q_out;
    logic       A_ser_in, B_ser_in, Q_ser_in;
    logic       A_ser_out, B_ser_out, Q_ser_out;
    logic [1:0] A_ctrl, B_ctrl, Q_ctrl; // 00 hold, 01 shift right, 10 shift left, 11 load

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

    // Contador
    logic       cnt_load, cnt_en, cnt_up_down;
    logic [7:0] cnt_data_in, cnt_data_out;
    logic       cnt_end; // não usado diretamente para transição (utilizamos valor do contador)
    counter #(.N(8)) iter_cnt (
        .clk(clk), .rst(rst), .load(cnt_load), .en(cnt_en), .up_down(cnt_up_down),
        .data_in(cnt_data_in), .data_out(cnt_data_out), .end_flag(cnt_end)
        // Porta \end do contador não conectada explicitamente aqui; end_flag já é usado.
    );

    // ULA
    logic [7:0] sum;
    logic       c_out;
    logic [7:0] addend;
    assign addend = Q_out[0] ? B_out : 8'd0;
    ula_8_bits alu (
        .a(A_out), .b(addend), .s(4'b1001), .m(1'b0), .cin(1'b0),
        .f(sum), .cout(c_out)
    );

    // FSM
    localparam [2:0] S_LOAD  = 3'd0,
                     S_ADD   = 3'd1,
                     S_SHIFT = 3'd2,
                     S_DONE  = 3'd3;
    logic [2:0] state, next_state;

    // Carry entre ADD e SHIFT
    logic carry_reg;

    // Controle combinacional
    always @* begin
        // Defaults
        A_ctrl = 2'b00; B_ctrl = 2'b00; Q_ctrl = 2'b00;
        A_parallel_in = '0; B_parallel_in = '0; Q_parallel_in = '0;
        cnt_load = 1'b0; cnt_en = 1'b0; cnt_up_down = 1'b0; cnt_data_in = '0;
        A_ser_in = 1'b0; Q_ser_in = 1'b0; B_ser_in = 1'b0; // B não desloca após carga inicial

        case (state)
            S_LOAD: begin
                A_ctrl = 2'b11; A_parallel_in = 8'd0;
                B_ctrl = 2'b11; B_parallel_in = multiplicand;
                Q_ctrl = 2'b11; Q_parallel_in = multiplier;
                cnt_load = 1'b1; cnt_data_in = 8'd8; cnt_up_down = 1'b0;
            end
            S_ADD: begin
                // Soma condicional (addend=0 se Q0=0)
                A_ctrl = 2'b11; A_parallel_in = sum;
            end
            S_SHIFT: begin
                A_ctrl = 2'b01; Q_ctrl = 2'b01;
                A_ser_in = carry_reg;
                Q_ser_in = A_ser_out;
                cnt_en = 1'b1; cnt_up_down = 1'b0;
            end
            S_DONE: begin end
        endcase
    end

    // Próximo estado
    always @* begin
        next_state = state;
        case (state)
            S_LOAD:  next_state = S_ADD;
            S_ADD:   next_state = S_SHIFT;
            S_SHIFT: next_state = (cnt_data_out == 8'd1) ? S_DONE : S_ADD;
            S_DONE:  next_state = S_DONE;
            default: next_state = S_LOAD;
        endcase
    end

    // Sequencial
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_LOAD;
            carry_reg <= 1'b0;
        end else begin
            state <= next_state;
            // Captura carry
            if (state == S_ADD) begin
                carry_reg <= c_out;
            end else if (state == S_SHIFT) begin
                // Limpa após SHIFT
                carry_reg <= 1'b0;
            end
        end
    end

    // Saídas
    assign result = {A_out, Q_out};
    assign end_op = (state == S_DONE);

endmodule
