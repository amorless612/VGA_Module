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
parameter PERIOD_CLK                   = 50 ;

// -------------------------------------------------------------------
// Internal Signals Declarations
// -------------------------------------------------------------------
logic  sys_clk;
logic  sys_rst_n;
logic  vsync;
logic  hsync;
logic [11:0]rgb;

logic                                 [9:0] char_x_start;
logic                                 [9:0] char_x_end;
logic                                 [9:0] char_y_start;
logic                                 [9:0] char_y_end;
logic                                 [3:0] char_color;
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
  sys_clk                  = 1'b0;
  sys_rst_n                = 1'b1;
  # 100 sys_rst_n          = 1'b0;
  # 100 sys_rst_n          = 1'b1;
end

always #(PERIOD_CLK/2) sys_clk = ~ sys_clk;

// -------------------------------------------------------------------
// Main Code
// -------------------------------------------------------------------

// -----------------> testcase load
`include "./testcase.sv"

// -----------------> DUT Instance
VGA_TOP U_VGA_TOP
    (
    .sys_clk                           (sys_clk                                ),   //输入工作时钟,频率 50MHz
    .sys_rst_n                         (sys_rst_n                              ),   //输入复位信号,低电平有效
    .hsync                             (hsync                                  ),   //输出行同步信号
    .vsync                             (vsync                                  ),   //输出场同步信号
    .rgb                               (rgb                                    ),   //输出像素信息
    .char_x_start                      (char_x_start                           ),
    .char_x_end                        (char_x_end                             ),
    .char_y_start                      (char_y_start                           ),
    .char_y_end                        (char_y_end                             ),
    .char_color                        (char_color                             )
    );
// -------------------------------------------------------------------
// Assertion Declarations
// -------------------------------------------------------------------
`ifdef SOC_ASSERT_ON

`endif
endmodule
