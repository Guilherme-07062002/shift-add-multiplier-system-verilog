
// Registrador de deslocamento universal parametrizável.
// ctrl: 00=mantém, 01=shift direita, 10=shift esquerda, 11=carga paralela.
module shift_register #(
	parameter N = 8
) (
	input  logic clk,
	input  logic rst,
	input  logic [1:0] ctrl,
	input  logic [N-1:0] parallel_in,
	input  logic ser_in,
	output logic [N-1:0] parallel_out,
	output logic ser_out
);

	// Codificação dos comandos
	localparam HOLD          = 2'b00;
	localparam SHIFT_RIGHT   = 2'b01;
	localparam SHIFT_LEFT    = 2'b10;
	localparam PARALLEL_LOAD = 2'b11;

	logic [N-1:0] reg_data;

	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
			reg_data <= '0;
		end else begin
			case (ctrl)
				PARALLEL_LOAD: reg_data <= parallel_in;                  // carga
				SHIFT_LEFT:    reg_data <= {reg_data[N-2:0], ser_in};    // desloca esquerda
				SHIFT_RIGHT:   reg_data <= {ser_in, reg_data[N-1:1]};    // desloca direita
				default:       reg_data <= reg_data;                     // mantém
			endcase
		end
	end

	assign parallel_out = reg_data;

	// Bit expelido no deslocamento.
	assign ser_out = (ctrl == SHIFT_LEFT)  ? reg_data[N-1] :
					 (ctrl == SHIFT_RIGHT) ? reg_data[0]   :
					 1'b0;

endmodule
