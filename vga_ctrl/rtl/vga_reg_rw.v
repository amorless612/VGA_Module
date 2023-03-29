module VGA_REG_RW
   #(
    parameter DATA_WIDTH          = 32,
    parameter DFLT_VALUE          = {DATA_WIDTH{1'b0}}
    )
    (
    input                              clk,
    input                              rst_n,

    input                              wr_en,
    input             [DATA_WIDTH-1:0] data_in,
    output reg        [DATA_WIDTH-1:0] data_out
    );

// -----------------------------------------------------------------------------
// Constant Parameter
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Internal Signals Declarations
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Main Code
// -----------------------------------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
  if (rst_n == 1'b0)
    data_out            <= DFLT_VALUE;
  else if (wr_en == 1'b1)
    data_out            <= data_in;
end

endmodule

