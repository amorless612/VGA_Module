module VGA_AFIFO
   #(
    parameter FIFO_DEPTH               = 16,
    parameter DATA_WIDTH               = 32,
    parameter CDC_DLY                  = 2,
    parameter REG_OUT                  = 1,
    parameter NO_RST                   = 0,
    parameter ADDR_WIDTH               = (FIFO_DEPTH > 1) ? (ceilLog2(FIFO_DEPTH) + 1) : 2, // automatically obtained
    parameter CNT_WIDTH                = ceilLog2(FIFO_DEPTH + 1'b1)                        // automatically obtained
    )
    (
    input                                        src_clk,
    input                                        src_rst_n,
    input                                        src_vld,
    output reg                                   src_rdy,
    input      [DATA_WIDTH-1:0]                  src_data,
    input      [CNT_WIDTH-1:0]                   afull_th,
    output reg                                   afull,
    output reg [CNT_WIDTH-1:0]                   src_cnt,

    input                                        dst_clk,
    input                                        dst_rst_n,
    output                                       dst_vld,
    input                                        dst_rdy,
    output     [DATA_WIDTH-1:0]                  dst_data,
    input      [CNT_WIDTH-1:0]                   aempty_th,
    output reg                                   aempty,
    output reg [CNT_WIDTH-1:0]                   dst_cnt
    );

// -----------------------------------------------------------------------------
// Constant Parameter
// -----------------------------------------------------------------------------
localparam PTR_MAX                     = (1 << (ADDR_WIDTH - 1)) + FIFO_DEPTH - 1;
localparam PTR_MIN                     = (1 << (ADDR_WIDTH - 1)) - FIFO_DEPTH;
localparam PTR_MIN_GRAY                = PTR_MIN[ADDR_WIDTH-1:0] ^ (PTR_MIN[ADDR_WIDTH-1:0]>>1);

// ceilLog2 function
function integer ceilLog2 (input integer n);
begin : CEILOG2
  integer m;
  m                   = n - 1;
  for (ceilLog2 = 0; m > 0; ceilLog2 = ceilLog2 + 1)
    m                 = m >> 1;
end
endfunction

// -----------------------------------------------------------------------------
// Internal Signals Declarations
// -----------------------------------------------------------------------------
wire                                             valid_write;
wire                                             valid_read_rs;
wire                                             src_rdy_nxt;
wire                                             afull_nxt;
wire [ADDR_WIDTH-1:0]                            wptr_gray_nxt;
wire [ADDR_WIDTH-1:0]                            rptr_gray_nxt;
wire [ADDR_WIDTH-2:0]                            wptr_bin_true;
wire [ADDR_WIDTH-2:0]                            rptr_bin_rs_true;
wire                                             dst_vld_rs;
wire                                             dst_rdy_rs;
wire [DATA_WIDTH-1:0]                            dst_data_rs;
reg  [CNT_WIDTH-1:0]                             src_cnt_nxt;
reg  [ADDR_WIDTH-1:0]                            src_cnt_nxt_mid;
reg  [CNT_WIDTH:0]                               src_cnt_nxt_mid1;
reg  [CNT_WIDTH-1:0]                             dst_cnt_rs;
reg  [ADDR_WIDTH-1:0]                            wptr_bin;
reg  [ADDR_WIDTH-1:0]                            wptr_bin_nxt;
reg  [ADDR_WIDTH-1:0]                            wptr_gray;
reg  [ADDR_WIDTH-1:0]                            wptr_gray_to_dst_clk_syn;
reg  [ADDR_WIDTH-1:0]                            wptr_gray_to_dst_clk_syn_1;
reg  [ADDR_WIDTH-1:0]                            wptr_gray_to_dst_clk_syn_2;
reg  [ADDR_WIDTH-1:0]                            wptr_bin_to_dst_clk;
reg  [ADDR_WIDTH-1:0]                            rptr_bin_rs;
reg  [ADDR_WIDTH-1:0]                            rptr_bin_rs_nxt;
reg  [ADDR_WIDTH-1:0]                            rptr_bin;
reg  [ADDR_WIDTH-1:0]                            rptr_bin_nxt;
reg  [ADDR_WIDTH-1:0]                            rptr_gray;
reg  [ADDR_WIDTH-1:0]                            rptr_gray_to_src_clk_syn;
reg  [ADDR_WIDTH-1:0]                            rptr_gray_to_src_clk_syn_1;
reg  [ADDR_WIDTH-1:0]                            rptr_gray_to_src_clk_syn_2;
reg  [ADDR_WIDTH-1:0]                            rptr_bin_to_src_clk;
reg  [DATA_WIDTH-1:0]                            fifo_mem     [FIFO_DEPTH-1:0]  ;
reg  [DATA_WIDTH-1:0]                            fifo_mem_nxt [FIFO_DEPTH-1:0]  ;

// -----------------------------------------------------------------------------
// Main Code
// -----------------------------------------------------------------------------
assign valid_write      = src_rdy & src_vld;
assign valid_read_rs    = dst_rdy_rs & dst_vld_rs;

// write side
// wptr control logic
always @(*)
begin : WPTR_NXT_PROC
  wptr_bin_nxt          = wptr_bin;
  if ((valid_write == 1'b1) && (wptr_bin == PTR_MAX[ADDR_WIDTH-1:0]))
    wptr_bin_nxt        = PTR_MIN[ADDR_WIDTH-1:0];
  else if (valid_write == 1'b1)
    wptr_bin_nxt        = wptr_bin + 1'b1;
end
always @(posedge src_clk or negedge src_rst_n)
begin : DFF_PROC_WPTR
  if (src_rst_n == 1'b0)
    wptr_bin            <= PTR_MIN[ADDR_WIDTH-1:0];
  else
    wptr_bin            <= wptr_bin_nxt;
end

// wptr bin to gray
assign wptr_gray_nxt    = wptr_bin_nxt ^ (wptr_bin_nxt>>1);
always @(posedge src_clk or negedge src_rst_n)
begin : DFF_PROC_WPTR_BIN_TO_GRAY
  if (src_rst_n == 1'b0)
    wptr_gray           <= PTR_MIN_GRAY;
  else
    wptr_gray           <= wptr_gray_nxt;
end

// wptr synchronizate to dst_clk
generate
  if (CDC_DLY == 2)
  begin : SRC_CDC_DLY_2_BRANCH
    always @(posedge dst_clk or negedge dst_rst_n)
    begin : SRC_CDC_DLY_2_PRO
      if (dst_rst_n == 1'b0)
      begin
        wptr_gray_to_dst_clk_syn_1 <= PTR_MIN_GRAY;
        wptr_gray_to_dst_clk_syn   <= PTR_MIN_GRAY;
      end
      else
      begin
        wptr_gray_to_dst_clk_syn_1 <= wptr_gray;
        wptr_gray_to_dst_clk_syn   <= wptr_gray_to_dst_clk_syn_1;
      end
    end
  end
  else if (CDC_DLY == 3)
  begin : SRC_CDC_DLY_3_BRANCH
    always @(posedge dst_clk or negedge dst_rst_n)
    begin : SRC_CDC_DLY_3_PRO
      if (dst_rst_n == 1'b0)
      begin
        wptr_gray_to_dst_clk_syn_2 <= PTR_MIN_GRAY;
        wptr_gray_to_dst_clk_syn_1 <= PTR_MIN_GRAY;
        wptr_gray_to_dst_clk_syn   <= PTR_MIN_GRAY;
      end
      else
      begin
        wptr_gray_to_dst_clk_syn_2 <= wptr_gray;
        wptr_gray_to_dst_clk_syn_1 <= wptr_gray_to_dst_clk_syn_2;
        wptr_gray_to_dst_clk_syn   <= wptr_gray_to_dst_clk_syn_1;
      end
    end
  end
endgenerate

// wptr gray to bin
always @(*)
begin : WPTR_GRAY_TO_BIN
  integer i;
  for (i = 0;i < (ADDR_WIDTH);i = i + 1)
    wptr_bin_to_dst_clk[i]  = ^(wptr_gray_to_dst_clk_syn >> i);
end

// write side output
assign src_rdy_nxt      = (src_cnt_nxt < FIFO_DEPTH[CNT_WIDTH-1:0]);
assign afull_nxt        = (src_cnt_nxt >= afull_th);
always @(*)
begin : SRC_CNT_PRO
  if (wptr_bin_nxt >= rptr_bin_to_src_clk)
  begin
    src_cnt_nxt_mid     = wptr_bin_nxt - rptr_bin_to_src_clk;
    src_cnt_nxt         = src_cnt_nxt_mid[CNT_WIDTH-1:0];
  end
  else
  begin
    src_cnt_nxt_mid     = rptr_bin_to_src_clk - wptr_bin_nxt;
    src_cnt_nxt_mid1    = (FIFO_DEPTH[CNT_WIDTH:0]<<1) - src_cnt_nxt_mid;
    src_cnt_nxt         = src_cnt_nxt_mid1[CNT_WIDTH-1:0];
  end
end
always @(posedge src_clk or negedge src_rst_n)
begin : WRITE_OUTPUT_PRO
  if (src_rst_n == 1'b0)
  begin
    src_rdy             <= 1'b1;
    afull               <= 1'b0;
    src_cnt             <= {CNT_WIDTH{1'b0}};
  end
  else
  begin
    src_rdy             <= src_rdy_nxt;
    afull               <= afull_nxt;
    src_cnt             <= src_cnt_nxt;
  end
end

// read side
// rptr_bin_rs control logic
always @(*)
begin : RPTR_RS_NXT_PROC
  rptr_bin_rs_nxt          = rptr_bin_rs;
  if ((valid_read_rs == 1'b1) && (rptr_bin_rs == PTR_MAX[ADDR_WIDTH-1:0]))
    rptr_bin_rs_nxt        = PTR_MIN[ADDR_WIDTH-1:0];
  else if (valid_read_rs == 1'b1)
    rptr_bin_rs_nxt        = rptr_bin_rs + 1'b1;
end
always @(posedge dst_clk or negedge dst_rst_n)
begin : DFF_PROC_RPTR
  if (dst_rst_n == 1'b0)
    rptr_bin_rs         <= PTR_MIN[ADDR_WIDTH-1:0];
  else
    rptr_bin_rs         <= rptr_bin_rs_nxt;
end

// rptr bin to gray
generate
  if (REG_OUT == 1'b1)
  begin : RPTR_TO_GRAY_REG_OUT
    wire                                         valid_read;
    assign valid_read       = dst_rdy & dst_vld;
    always @(*)
    begin : RPTR_NXT_PROC
      rptr_bin_nxt          = rptr_bin;
      if ((valid_read == 1'b1) && (rptr_bin == PTR_MAX[ADDR_WIDTH-1:0]))
        rptr_bin_nxt        = PTR_MIN[ADDR_WIDTH-1:0];
      else if (valid_read == 1'b1)
        rptr_bin_nxt        = rptr_bin + 1'b1;
    end
    always @(posedge dst_clk or negedge dst_rst_n)
    begin : DFF_PROC_RPTR
      if (dst_rst_n == 1'b0)
        rptr_bin            <= PTR_MIN[ADDR_WIDTH-1:0];
      else
        rptr_bin            <= rptr_bin_nxt;
    end
    assign rptr_gray_nxt    = rptr_bin_nxt ^ (rptr_bin_nxt >> 1);
  end
  else
  begin : RPTR_TO_GRAY_NO_REG_OUT
    assign rptr_gray_nxt    = rptr_bin_rs_nxt ^ (rptr_bin_rs_nxt >> 1);
  end
endgenerate

always @(posedge dst_clk or negedge dst_rst_n)
begin : DFF_PROC_RPTR_BIN_TO_GRAY
  if (dst_rst_n == 1'b0)
    rptr_gray           <= PTR_MIN_GRAY;
  else
    rptr_gray           <= rptr_gray_nxt;
end

// rptr synchronization to src_clk
generate
  if (CDC_DLY == 2)
  begin : DST_CDC_DLY_2_BRANCH
    always @(posedge src_clk or negedge src_rst_n)
    begin : DST_CDC_DLY_2_PRO
      if (src_rst_n == 1'b0)
      begin
        rptr_gray_to_src_clk_syn_1 <= PTR_MIN_GRAY;
        rptr_gray_to_src_clk_syn   <= PTR_MIN_GRAY;
      end
      else
      begin
        rptr_gray_to_src_clk_syn_1 <= rptr_gray;
        rptr_gray_to_src_clk_syn   <= rptr_gray_to_src_clk_syn_1;
      end
    end
  end
  else if (CDC_DLY == 3)
  begin : DST_CDC_DLY_3_BRANCH
    always @(posedge src_clk or negedge src_rst_n)
    begin : DST_CDC_DLY_3_PRO
      if (src_rst_n == 1'b0)
      begin
        rptr_gray_to_src_clk_syn_2 <= PTR_MIN_GRAY;
        rptr_gray_to_src_clk_syn_1 <= PTR_MIN_GRAY;
        rptr_gray_to_src_clk_syn   <= PTR_MIN_GRAY;
      end
      else
      begin
        rptr_gray_to_src_clk_syn_2 <= rptr_gray;
        rptr_gray_to_src_clk_syn_1 <= rptr_gray_to_src_clk_syn_2;
        rptr_gray_to_src_clk_syn   <= rptr_gray_to_src_clk_syn_1;
      end
    end
  end
endgenerate

// rptr gray to bin
always @(*)
begin : RPTR_GRAY_TO_BIN
  integer i;
  for (i = 0; i < (ADDR_WIDTH); i = i + 1)
    rptr_bin_to_src_clk[i]  = ^(rptr_gray_to_src_clk_syn >> i);
end

// output to cm_rs_vr module
assign dst_data_rs      = fifo_mem[rptr_bin_rs_true];
generate
  if (REG_OUT == 1'b1)
  begin : OUT_TO_RS_VR_REG_OUT
    assign dst_vld_rs       = (wptr_bin_to_dst_clk != rptr_bin_rs);
  end
  else
  begin : OUT_TO_RS_VR_NO_REG_OUT
    reg  [ADDR_WIDTH-1:0]                        dst_cnt_mid_rs;
    reg  [CNT_WIDTH:0]                           dst_cnt_mid1_rs;
    assign dst_vld_rs       = (dst_cnt_rs > {CNT_WIDTH{1'b0}});
    always @(*)
    begin : DST_CNT_RS_PRO
      if (wptr_bin_to_dst_clk >= rptr_bin_rs)
      begin
        dst_cnt_mid_rs      = wptr_bin_to_dst_clk - rptr_bin_rs;
        dst_cnt_rs          = dst_cnt_mid_rs[CNT_WIDTH-1:0];
      end
      else
      begin
        dst_cnt_mid_rs      = rptr_bin_rs - wptr_bin_to_dst_clk;
        dst_cnt_mid1_rs     = (FIFO_DEPTH[CNT_WIDTH:0] << 1) - dst_cnt_mid_rs;
        dst_cnt_rs          = dst_cnt_mid1_rs[CNT_WIDTH-1:0];
      end
    end
  end
endgenerate

// FIFO_MEM
assign wptr_bin_true    = (wptr_bin[ADDR_WIDTH-1] == 1'b1) ? wptr_bin[ADDR_WIDTH-2:0] : (wptr_bin[ADDR_WIDTH-2:0] - PTR_MIN[ADDR_WIDTH-2:0]);
assign rptr_bin_rs_true = (rptr_bin_rs[ADDR_WIDTH-1] == 1'b1) ? rptr_bin_rs[ADDR_WIDTH-2:0] : (rptr_bin_rs[ADDR_WIDTH-2:0] - PTR_MIN[ADDR_WIDTH-2:0]);
genvar addr;
generate
  for(addr = 0; addr < FIFO_DEPTH; addr = addr + 1)
  begin : FIFO_MEM_NXT_LOOP
    always @(*)
    begin : FIFO_MEM_NXT_PRO
      fifo_mem_nxt[addr] = fifo_mem[addr];
      if ((valid_write == 1'b1) && (addr[ADDR_WIDTH-2:0] == wptr_bin_true))
        fifo_mem_nxt[addr] = src_data;
    end
  end
endgenerate

// select whether to reset fifo_mem
generate
  if (NO_RST == 1'b0)
  begin : MEM_RESET_BRANCH
    for (addr = 0; addr < FIFO_DEPTH; addr = addr + 1)
    begin : MEM_RESET_LOOP
      always @(posedge src_clk or negedge src_rst_n)
      begin : MEM_RESET_PRO
        if (src_rst_n == 1'b0)
          fifo_mem[addr] <= {DATA_WIDTH{1'b0}};
        else
          fifo_mem[addr] <= fifo_mem_nxt[addr];
      end
    end
  end
  else
  begin : MEM_NO_RESET_BRANCH
    for (addr = 0; addr < FIFO_DEPTH; addr = addr + 1)
    begin : MEM_NO_RESET_LOOP
      always @(posedge src_clk)
      begin : MEM_NO_RESET_PRO
        fifo_mem[addr] <= fifo_mem_nxt[addr];
      end
    end
  end
endgenerate

// select whether to register output
CM_RS_VR
#(
.NO_RST                            ( 1'b0                                  ),   // register can not reset
.PLD_WIDTH                         ( DATA_WIDTH                            ),   // payload bit wide
.VR_MODE                           ( {1'b0,REG_OUT[0]}                     )    // 2'b00 BYP_MODE
 )
 RS_VR (
.clk                               ( dst_clk                               ),
.rst_n                             ( dst_rst_n                             ),
.src_vld                           ( dst_vld_rs                            ),
.src_pld                           ( dst_data_rs                           ),
.src_rdy                           ( dst_rdy_rs                            ),
.dst_vld                           ( dst_vld                               ),
.dst_pld                           ( dst_data                              ),
.dst_rdy                           ( dst_rdy                               )
);
generate
  if (REG_OUT == 1'b1)
  begin : REG_OUT_BRANCH
    // output to read side
    wire                                         aempty_nxt;
    reg  [CNT_WIDTH-1:0]                         dst_cnt_nxt;
    reg  [ADDR_WIDTH-1:0]                        dst_cnt_mid;
    reg  [CNT_WIDTH:0]                           dst_cnt_mid1;
    assign aempty_nxt       = (dst_cnt_nxt <= aempty_th);
    always @(*)
    begin : DST_CNT_PRO
      if (wptr_bin_to_dst_clk >= rptr_bin_nxt)
      begin
        dst_cnt_mid         = wptr_bin_to_dst_clk - rptr_bin_nxt;
        dst_cnt_nxt         = dst_cnt_mid[CNT_WIDTH-1:0];
      end
      else
      begin
        dst_cnt_mid         = rptr_bin_nxt - wptr_bin_to_dst_clk;
        dst_cnt_mid1        = (FIFO_DEPTH[CNT_WIDTH:0] << 1) - dst_cnt_mid;
        dst_cnt_nxt         = dst_cnt_mid1[CNT_WIDTH-1:0];
      end
    end
    always @(posedge dst_clk or negedge dst_rst_n)
    begin : REG_OUT_PRO
      if (dst_rst_n == 1'b0)
      begin
        aempty              <= 1'b1;
        dst_cnt             <= {CNT_WIDTH{1'b0}};
      end
      else
      begin
        aempty              <= aempty_nxt;
        dst_cnt             <= dst_cnt_nxt;
      end
    end
  end
  else
  begin : NO_REG_OUT_BRANCH
    wire                                         aempty_rs;
    assign aempty_rs         = (dst_cnt_rs <= aempty_th);
    always @(*)
    begin : NO_REG_OUT_PRO
      aempty                 = aempty_rs;
      dst_cnt                = dst_cnt_rs;
    end
  end
endgenerate

// -------------------------------------------------------------------
// Assertion Declarations
// -------------------------------------------------------------------
`ifdef SOC_ASSERT_ON

`endif
endmodule
