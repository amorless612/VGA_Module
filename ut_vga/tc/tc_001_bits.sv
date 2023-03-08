// *****************************************************************************
// (c) Copyright 2022-2032 , Inc. All rights reserved.
// Module Name  :
// Design Name  :
// Project Name :
// Create Date  : 2022-12-21
// Description  :
//
// *****************************************************************************
`define write(addr,data) \
  repeat(2)@(posedge pclk);    \
  #1 psel = 1'b1;              \
  pwrite = 1'b1;               \
  pwdata = data;               \
  paddr  = addr;               \
  repeat(1)@(posedge pclk);    \
  #1 penable = 1'b1;           \
  repeat(1)@(posedge pclk);    \
	#1 penable = 1'b0;           \
  pwrite = 1'b0;               \
  pwdata = 32'b0;              \
  paddr  = 12'b0;              \
  psel   = 1'b0;


`define read(addr)             \
  #1 psel = 1'b1;              \
  pwrite = 1'b0;               \
  paddr  = addr;               \
  repeat(1)@(posedge pclk);    \
  #1 penable = 1'b1;           \
  repeat(1)@(posedge pclk);    \
	#1 penable = 1'b0;           \
  pwrite = 1'b0;               \
  paddr  = 12'b0;              \
  psel   = 1'b0;
// -------------------------------------------------------------------
// Constant Parameter
// -------------------------------------------------------------------

// -------------------------------------------------------------------
// Internal Signals Declarations
// -------------------------------------------------------------------

// -------------------------------------------------------------------
// initial
// -------------------------------------------------------------------
initial begin
  psel    = 1'b0;
  penable = 1'b0;
  pwrite  = 1'b0;
  paddr   = 12'b0;
  pwdata  = 32'b0;
  repeat(100)@(posedge pclk);
  #1
  `write(12'h000,20'h32190) //x start 200 end 400
  `write(12'h004,20'h32190) //y start 200 end 400
  `write(12'h008,4'd1)
   #100000000

  `write(12'h000,20'h1d0fa) //x start 100 end 250
  `write(12'h004,20'h1d0fa) //y start 100 end 250
  `write(12'h008,4'd2)

   #100000000
  `write(12'h000,20'h3e95e) //x start 250 end 350
  `write(12'h004,20'h3e95e) //y start 250 end 350
  `write(12'h008,4'd3)

   #100000000
  `write(12'h000,20'h38513) //x start 225 end 275
  `write(12'h004,20'h38513) //y start 225 end 275
  `write(12'h008,4'd4)

   #100000000
   `write(12'h000,20'h44d2c) //x start 275 end 300
   `write(12'h004,20'h44d2c) //y start 275 end 300
   `write(12'h008,4'd5)
   #100000000

  $finish;
end

// -------------------------------------------------------------------
// Main Code
// -------------------------------------------------------------------

// -------------------------------------------------------------------
// Assertion Declarations
// -------------------------------------------------------------------
`ifdef SOC_ASSERT_ON

`endif
