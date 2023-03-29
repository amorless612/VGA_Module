// ---====================================================================------
// All Rights Reserved
// Project Name :
// File Name    : cm_rs_vr.v
// Author       : Liyaoyao
// Email        :
// Date         : 2023/01/12
// Abstract     :
// ---====================================================================------
`ifndef CM_RS_VR__V
`define CM_RS_VR__V

module CM_RS_VR
   #(
    parameter NO_RST                   = 1'b1,                                 // register can not reset
    parameter PLD_WIDTH                = 8,                                    // payload bit wide
    parameter VR_MODE                  = 2'b10                                 // 2'b00 BYP_MODE
    )
    (
    input                                        clk,
    input                                        rst_n,
    input                                        src_vld,
    input                        [PLD_WIDTH-1:0] src_pld,
    output                                       src_rdy,
    output                                       dst_vld,
    output                       [PLD_WIDTH-1:0] dst_pld,
    input                                        dst_rdy
    );
//--------------------------------------------------------------------
// parameter declaration
localparam BYP_MODE                    = 2'b00;                                // Bypass Mode
localparam FWD_MODE                    = 2'b01;                                // Forward registered Mode
localparam BWD_MODE                    = 2'b11;                                // Backward registered mode
localparam FUL_MODE                    = 2'b10;                                // Full registered mode
localparam FWD_STEP                    = ((VR_MODE == FWD_MODE) || (VR_MODE == FUL_MODE)) ? 1'b1 : 1'b0;
localparam BWD_STEP                    = ((VR_MODE == BWD_MODE) || (VR_MODE == FUL_MODE)) ? 1'b1 : 1'b0;
//--------------------------------------------------------------------
// io declaration
wire                                             fwd_src_vld;
wire                             [PLD_WIDTH-1:0] fwd_src_pld;
wire                                             fwd_src_rdy;
wire                                             fwd_dst_vld;
wire                             [PLD_WIDTH-1:0] fwd_dst_pld;
wire                                             fwd_dst_rdy;
wire                                             bwd_src_vld;
wire                             [PLD_WIDTH-1:0] bwd_src_pld;
wire                                             bwd_src_rdy;
wire                                             bwd_dst_vld;
wire                             [PLD_WIDTH-1:0] bwd_dst_pld;
wire                                             bwd_dst_rdy;
reg                              [PLD_WIDTH-1:0] fwd_reg_pld;
reg                                              fwd_reg_pld_full;

reg                              [PLD_WIDTH-1:0] bwd_reg_pld;
reg                                              bwd_reg_rdy;
reg                                              bwd_reg_pld_full;
// main code
//FWD_MODE
generate
  if (FWD_STEP == 1'b1)
  begin : FWD_VR_BRCH

    //judge fwd_reg_pld is full or empty
    always @(posedge clk or negedge rst_n)
    begin : FWD_REG_PLD_FULL_PROC
      if (rst_n == 1'b0)
        fwd_reg_pld_full     <= 1'b0;
      else if ((fwd_src_vld == 1'b1) && (fwd_src_rdy == 1'b1))
        fwd_reg_pld_full     <= 1'b1;
      else if ((fwd_dst_vld == 1'b1) && (fwd_dst_rdy == 1'b1))
        fwd_reg_pld_full     <= 1'b0;
    end
    //write data to fwd_dst_vld
    assign fwd_dst_vld       = fwd_reg_pld_full;

    //write fwd_src_pld to fwd_reg_pld
    if (NO_RST == 1'b0)
    begin : FWD_RST_BRCH
      always @(posedge clk or negedge rst_n)
      begin : FWD_REG_PLD_PROC
        if (rst_n == 1'b0)
          fwd_reg_pld        <= {PLD_WIDTH{1'b0}};
        else if ((fwd_src_vld == 1'b1) && (fwd_src_rdy == 1'b1))
          fwd_reg_pld        <= fwd_src_pld;
      end
    end

    else
    begin : FWD_NORST_BRCH
      always @(posedge clk)
      begin : FWD_REG_PLD_PROC
        if ((fwd_src_vld == 1'b1) && (fwd_src_rdy == 1'b1))
          fwd_reg_pld        <= fwd_src_pld;
      end
    end
    //write fwd_reg_pld to fwd_dst_pld
    assign fwd_dst_pld       = fwd_reg_pld;

    //write dst_rdy to src_rdy
    assign fwd_src_rdy       = ((fwd_reg_pld_full == 1'b0) || (fwd_dst_rdy == 1'b1)) ? 1'b1 : 1'b0;
  end
endgenerate

//BWD_MODE
generate
  if (BWD_STEP == 1'b1)
  begin : BWD_VR_BRCH
    //judge bwd_reg_pld is full or empty
    always @(posedge clk or negedge rst_n)
    begin : BWD_REG_PLD_FULL_PROC
      if (rst_n == 1'b0)
        bwd_reg_pld_full     <= 1'b0;
      else if ((bwd_dst_vld == 1'b1) && (bwd_dst_rdy == 1'b1))
        bwd_reg_pld_full     <= 1'b0;
      else if ((bwd_src_vld == 1'b1) && (bwd_src_rdy == 1'b1))
        bwd_reg_pld_full     <= 1'b1;
    end
    //write data to bwd_dst_vld
    assign bwd_dst_vld       = ((bwd_reg_pld_full == 1'b1) || (bwd_src_vld == 1'b1))? 1'b1 : 1'b0;

    //write data to bwd_reg_pld
    if (NO_RST == 1'b0)
    begin : BWD_RST_BRCH
      always @(posedge clk or negedge rst_n)
      begin : BWD_REG_PLD_PROC
        if (rst_n == 1'b0)
          bwd_reg_pld        <= {PLD_WIDTH{1'b0}};
        else if ((bwd_src_vld == 1'b1) && (bwd_src_rdy == 1'b1))
          bwd_reg_pld        <= bwd_src_pld;
      end
    end
    else
    begin : BWD_NORST_BRCH
      always @(posedge clk )
      begin : BWD_REG_PLD_PROC
        if ((bwd_src_vld == 1'b1) && (bwd_src_rdy == 1'b1))
          bwd_reg_pld        <= bwd_src_pld;
      end
    end

    //write data to bwd_dst_pld
    assign bwd_dst_pld       = (bwd_reg_pld_full == 1'b0)? bwd_src_pld : bwd_reg_pld;

    //write data to bwd_reg_rdy
    always @(posedge clk or negedge rst_n)
    begin : BWD_REG_RDY_PROC
      if (rst_n == 1'b0)
        bwd_reg_rdy          <= 1'b0;
      else if (|(bwd_reg_rdy^bwd_dst_rdy) == 1'b1)
        bwd_reg_rdy          <= bwd_dst_rdy;
    end

    //write data to bwd_src_rdy
    assign bwd_src_rdy       = ((bwd_reg_rdy == 1'b1) || (bwd_reg_pld_full == 1'b0)) ? 1'b1 : 1'b0;
  end
endgenerate

generate
  //ByPass Mode
  if (VR_MODE == BYP_MODE)
  begin : BYP_BRCH
    assign dst_vld           = src_vld;
    assign dst_pld           = src_pld;
    assign src_rdy           = dst_rdy;
  end

  //Forward registered
  else if (VR_MODE == FWD_MODE)
  begin : FWD_BRCH
    assign fwd_src_vld       = src_vld;
    assign fwd_src_pld       = src_pld;
    assign fwd_dst_rdy       = dst_rdy;
    assign dst_vld           = fwd_dst_vld;
    assign dst_pld           = fwd_dst_pld;
    assign src_rdy           = fwd_src_rdy;
  end

  //Backward registered
  else if (VR_MODE == BWD_MODE)
  begin : BWD_BRCH
    assign bwd_src_vld       = src_vld;
    assign bwd_src_pld       = src_pld;
    assign bwd_dst_rdy       = dst_rdy;
    assign dst_vld           = bwd_dst_vld;
    assign dst_pld           = bwd_dst_pld;
    assign src_rdy           = bwd_src_rdy;
  end

  //Full registered
  else if (VR_MODE == FUL_MODE)
  begin : FUL_BRCH
    assign bwd_src_vld       = src_vld;
    assign bwd_src_pld       = src_pld;
    assign fwd_dst_rdy       = dst_rdy;
    assign fwd_src_vld       = bwd_dst_vld;
    assign fwd_src_pld       = bwd_dst_pld;
    assign bwd_dst_rdy       = fwd_src_rdy;
    assign dst_vld           = fwd_dst_vld;
    assign dst_pld           = fwd_dst_pld;
    assign src_rdy           = bwd_src_rdy;
  end
endgenerate
// -------------------------------------------------------------------
// Assertion Declarations
// -------------------------------------------------------------------
`ifdef SOC_ASSERT_ON
`endif
endmodule
`endif

//========Modify Logs===========================================================
// Initial Version By host
// 01/12/23 16:32:22
//==============================================================================
