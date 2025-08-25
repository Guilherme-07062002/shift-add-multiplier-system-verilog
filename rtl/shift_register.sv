
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

	logic [N-1:0] reg_data;

	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
			reg_data <= '0;
		end else begin
			case (ctrl)
				2'b11: reg_data <= parallel_in; // Carregamento paralelo
				2'b10: reg_data <= {reg_data[N-2:0], ser_in}; // Shift left
				2'b01: reg_data <= {ser_in, reg_data[N-1:1]}; // Shift right
				default: reg_data <= reg_data; // Manutenção
			endcase
		end
	end

	assign parallel_out = reg_data;
	assign ser_out = (ctrl == 2'b10) ? reg_data[N-1] : // MSB no shift left
					 (ctrl == 2'b01) ? reg_data[0]   : // LSB no shift right
					 1'b0; // Caso manutenção ou carregamento

endmodule
