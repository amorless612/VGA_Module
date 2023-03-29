module VGA_CSR
  # (
    parameter UART_CSR_LOCK_VAL        = 32'h5a5a5a5a,
    parameter ADDR_WIDTH               = 12,
    parameter DATA_WIDTH               = 32
    )
    (
    input                              pclk,
    input                              preset_n,
    input                              psel,
    input                              penable,
    input                              pwrite,
    input             [ADDR_WIDTH-1:0] paddr,
    input             [DATA_WIDTH-1:0] pwdata,
    output reg        [DATA_WIDTH-1:0] prdata,
    output                             pready,
    output reg                         pslverr,

    output                       [9:0] char_x_start,
    output                       [9:0] char_x_end,
    output                       [9:0] char_y_start,
    output                       [9:0] char_y_end,
    output                       [3:0] char_color
    );

//--------------------------------------------------
// Local Parameters
//--------------------------------------------------
localparam VGA_CHAR_X_ADDR                       = 12'h000;//RW
localparam VGA_CHAR_Y_ADDR                       = 12'h004;//RW
localparam VGA_CHAR_COLOR_ADDR                   = 12'h008;//RW

localparam VGA_CHAR_X_DFLT_VAL                   = 20'h00000;
localparam VGA_CHAR_Y_DFLT_VAL                   = 20'h00000;
localparam VGA_CHAR_COLOR_DFLT_VAL               = 4'h0;
//--------------------------------------------------
// Signal Declarations
//--------------------------------------------------
wire                                   wr_en;
wire                                   rd_en;

reg                                    vga_char_x_wr_en;
reg                                    vga_char_y_wr_en;
reg                                    vga_char_color_wr_en;
//--------------------------------------------------
// Main Code
//--------------------------------------------------
// APB wr/rd en
assign wr_en            = psel & (~penable) &   pwrite;
assign rd_en            = psel & (~penable) & (~pwrite);
assign pready           = 1'b1;
assign pslverr          = 1'b0;

always @*
begin : WR_EN_PROC
  vga_char_x_wr_en                               = 1'b0;
  vga_char_y_wr_en                               = 1'b0;
  vga_char_color_wr_en                           = 1'b0;
  if (wr_en == 1'b1)
    case (paddr)
      VGA_CHAR_X_ADDR                  : vga_char_x_wr_en            = 1'b1;
      VGA_CHAR_Y_ADDR                  : vga_char_y_wr_en            = 1'b1;
      VGA_CHAR_COLOR_ADDR              : vga_char_color_wr_en        = 1'b1;
      default                          :
        begin
          vga_char_x_wr_en                       = 1'b0;
          vga_char_y_wr_en                       = 1'b0;
          vga_char_color_wr_en                   = 1'b0;
        end
    endcase
end

VGA_REG_RW
  # (
    .DATA_WIDTH                        (20                                     ),
    .DFLT_VALUE                        (VGA_CHAR_X_DFLT_VAL                    )
    )
  U_VGA_CHAR_X_REG_RW(
    .clk                               (pclk                                   ),
    .rst_n                             (preset_n                               ),

    .wr_en                             (vga_char_x_wr_en                       ),
    .data_in                           (pwdata[19:0]                           ),
    .data_out                          ({char_x_start,char_x_end}              )
  );

VGA_REG_RW
  # (
    .DATA_WIDTH                        (20                                     ),
    .DFLT_VALUE                        (VGA_CHAR_Y_DFLT_VAL                    )
    )
  U_VGA_CHAR_Y_REG_RW(
    .clk                               (pclk                                   ),
    .rst_n                             (preset_n                               ),

    .wr_en                             (vga_char_y_wr_en                       ),
    .data_in                           (pwdata[19:0]                           ),
    .data_out                          ({char_y_start,char_y_end}              )
  );

VGA_REG_RW
  # (
    .DATA_WIDTH                        (4                                      ),
    .DFLT_VALUE                        (VGA_CHAR_COLOR_DFLT_VAL                )
    )
  U_VGA_CHAR_COLOR_REG_RW(
    .clk                               (pclk                                   ),
    .rst_n                             (preset_n                               ),

    .wr_en                             (vga_char_color_wr_en                   ),
    .data_in                           (pwdata[3:0]                            ),
    .data_out                          (char_color                             )
  );

always @(posedge pclk or negedge preset_n)
begin : RD_EN_PROC
  if (preset_n == 1'b0)
    prdata                                       <= {DATA_WIDTH{1'b0}};
  else if (rd_en == 1'b1)
    case (paddr)
      VGA_CHAR_X_ADDR                : prdata    <= {{(DATA_WIDTH-20){1'b0}},char_x_start,char_x_end};
      VGA_CHAR_Y_ADDR                : prdata    <= {{(DATA_WIDTH-20){1'b0}},char_y_start,char_y_end};
      VGA_CHAR_COLOR_ADDR            : prdata    <= {{(DATA_WIDTH-4){1'b0}},char_color};
      default : prdata                           <= {DATA_WIDTH{1'b0}};
    endcase
end

endmodule
