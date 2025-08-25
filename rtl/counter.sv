
module counter #(
	parameter N = 8
) (
	input  logic clk,
	input  logic rst,
	input  logic load,
	input  logic en,
	input  logic up_down, // 1 = up, 0 = down
	input  logic [N-1:0] data_in,
	output logic [N-1:0] data_out,
	// NOTE: 'end' é palavra reservada em SystemVerilog; usar 'end_count'
	output logic end_count
);

	logic [N-1:0] reg_data;

	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
			reg_data <= '0;
		end else begin
			if (load) begin
				reg_data <= data_in; // carregamento síncrono
			end else if (en) begin
				if (up_down)
					reg_data <= reg_data + 1; // incrementa
				else
					reg_data <= reg_data - 1; // decrementa
			end else begin
				reg_data <= reg_data; // mantém
			end
		end
	end

	assign data_out = reg_data;
	// end_count = 1 quando contador chegar a zero (permanece 1 enquanto reg_data == 0)
	assign end_count = (reg_data == '0);

endmodule
