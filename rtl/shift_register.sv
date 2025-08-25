
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

	// Control signal encoding for clarity
	localparam HOLD          = 2'b00;
	localparam SHIFT_RIGHT   = 2'b01;
	localparam SHIFT_LEFT    = 2'b10;
	localparam PARALLEL_LOAD = 2'b11;

	logic [N-1:0] reg_data;

	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
			reg_data <= '0;
		end else begin
			// The case statement defines the register's behavior based on the control signal.
			case (ctrl)
				PARALLEL_LOAD: reg_data <= parallel_in;                  // Parallel load
				SHIFT_LEFT:    reg_data <= {reg_data[N-2:0], ser_in};    // Shift left, ser_in becomes LSB
				SHIFT_RIGHT:   reg_data <= {ser_in, reg_data[N-1:1]};    // Shift right, ser_in becomes MSB
				default:       reg_data <= reg_data;                     // Hold value
			endcase
		end
	end

	assign parallel_out = reg_data;

	// ser_out is the bit being shifted out of the register.
	// For a left shift, it's the MSB. For a right shift, it's the LSB.
	assign ser_out = (ctrl == SHIFT_LEFT)  ? reg_data[N-1] :
					 (ctrl == SHIFT_RIGHT) ? reg_data[0]   :
					 1'b0; // Default output for non-shift operations

endmodule
