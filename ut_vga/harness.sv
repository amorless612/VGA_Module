// *****************************************************************************
// (c) Copyright 2022-2032 , Inc. All rights reserved.
// Module Name  :
// Design Name  :
// Project Name :
// Create Date  : 2022-12-21
// Description  :
//
// *****************************************************************************

module harness;

// -------------------------------------------------------------------
// Constant Parameter
// -------------------------------------------------------------------
parameter PERIOD_CLK                   = 50;
parameter ADDR_WIDTH                   = 12;
parameter DATA_WIDTH                   = 32;
// -------------------------------------------------------------------
// Internal Signals Declarations
// -------------------------------------------------------------------
logic                                       pclk;
logic                                       preset_n;
logic                                       psel;
logic                                       penable;
logic                                       pwrite;
logic                      [ADDR_WIDTH-1:0] paddr;
logic                      [DATA_WIDTH-1:0] pwdata;
logic                      [DATA_WIDTH-1:0] prdata;
logic                                       pready;
logic                                       pslverr;

logic                                       hsync;
logic                                       vsync;
logic                                [11:0] rgb;
// -------------------------------------------------------------------
// fadb wave
// -------------------------------------------------------------------
initial begin
  $fsdbDumpfile("harness.fsdb");
  $fsdbDumpvars(0,"harness");
  $fsdbDumpSVA(0,"harness");
  $fsdbDumpMDA(0,"harness");

end

// -------------------------------------------------------------------
// clock & reset
// -------------------------------------------------------------------
initial begin
  pclk                    = 1'b0;
  preset_n                = 1'b1;
  # 100 preset_n          = 1'b0;
  # 100 preset_n          = 1'b1;
end

always #(PERIOD_CLK/2) pclk = ~ pclk;

// -------------------------------------------------------------------
// Main Code
// -------------------------------------------------------------------

// -----------------> testcase load
`include "./testcase.sv"

// -----------------> DUT Instance
VGA_TOP
  # (
    .ADDR_WIDTH                        (ADDR_WIDTH                             ),
    .DATA_WIDTH                        (DATA_WIDTH                             )
    )
    U_VGA_TOP
    (
    .pclk                              (pclk                                   ),
    .preset_n                          (preset_n                               ),
    .psel                              (psel                                   ),
    .penable                           (penable                                ),
    .pwrite                            (pwrite                                 ),
    .paddr                             (paddr                                  ),
    .pwdata                            (pwdata                                 ),
    .prdata                            (prdata                                 ),
    .pready                            (pready                                 ),
    .pslverr                           (pslverr                                ),

    .hsync                             (hsync                                  ),   //输出行同步信�?
    .vsync                             (vsync                                  ),   //输出场同步信�?
    .rgb                               (rgb                                    )    //输出像素信息
    );
// -------------------------------------------------------------------
// Assertion Declarations
// -------------------------------------------------------------------
`ifdef SOC_ASSERT_ON

`endif
endmodule
