module VGA_TOP
  # (
    parameter ADDR_WIDTH               = 12,
    parameter DATA_WIDTH               = 32
    )
    (
    input                                        pclk,
    input                                        preset_n,
    input                                        psel,
    input                                        penable,
    input                                        pwrite,
    input                       [ADDR_WIDTH-1:0] paddr,
    input                       [DATA_WIDTH-1:0] pwdata,
    output reg                  [DATA_WIDTH-1:0] prdata,
    output                                       pready,
    output reg                                   pslverr,

    output wire                                  hsync,                        //输出行同步信�?
    output wire                                  vsync,                        //输出场同步信�?
    output wire                           [11:0] rgb                           //输出像素信息
    );
//********************************************************************//
//****************** Parameter and Internal Signal *******************//       //640*480@60
//********************************************************************//
//wire define
wire                                             sys_clk;                      //输入工作时钟,频率 50MHz
wire                                             sys_rst_n;                    //输入复位信号,低电平有�?

wire                                             clk;
wire                                             vga_clk ;                     //VGA 工作时钟,频率 25MHz
wire                                             locked ;                      //PLL locked 信号
wire                                             rst_n ;                       //VGA 模块复位信号
wire                                       [9:0] pix_x ;                       //VGA 有效显示区域 X 轴坐�?
wire                                       [9:0] pix_y ;                       //VGA 有效显示区域 Y 轴坐�?
wire                                      [11:0] pix_data;                     //VGA 像素点色彩信�?

wire                                       [9:0] char_x_start;
wire                                       [9:0] char_x_end;
wire                                       [9:0] char_y_start;
wire                                       [9:0] char_y_end;
wire                                       [3:0] char_color;

wire                                       [9:0] char_x_start_in;
wire                                       [9:0] char_x_end_in;
wire                                       [9:0] char_y_start_in;
wire                                       [9:0] char_y_end_in;
wire                                       [3:0] char_color_in;

// ------------------------------------------------------------------
parameter FIFO_DEPTH               = 8;
parameter FIFO_DATA_WIDTH          = 44;
parameter CDC_DLY                  = 2;
parameter REG_OUT                  = 1;
parameter NO_RST                   = 0;
parameter FIFO_ADDR_WIDTH          = (FIFO_DEPTH > 1) ? (ceilLog2(FIFO_DEPTH) + 1) : 2; // automatically obtained
parameter CNT_WIDTH                = ceilLog2(FIFO_DEPTH + 1'b1) ;   // automatically obtained

// ceilLog2 function
function integer ceilLog2 (input integer n);
begin : CEILOG2
  integer m;
  m                   = n - 1;
  for (ceilLog2 = 0; m > 0; ceilLog2 = ceilLog2 + 1)
    m                 = m >> 1;
end
endfunction

wire                                             src_vld;
wire                                             src_rdy;
wire    [FIFO_DATA_WIDTH-1:0]                    src_data;
wire    [CNT_WIDTH-1:0]                          afull_th;
wire                                             afull;
wire    [CNT_WIDTH-1:0]                          src_cnt;

wire                                             dst_vld;
wire                                             dst_rdy;
wire    [FIFO_DATA_WIDTH-1:0]                    dst_data;
wire    [CNT_WIDTH-1:0]                          aempty_th;
wire                                             aempty;
wire    [CNT_WIDTH-1:0]                          dst_cnt;
// -----------------------------------------------------------------

assign sys_clk           = pclk;
assign sys_rst_n         = preset_n;

//rst_n:VGA 模块复位信号
assign rst_n             = sys_rst_n;
//assign rst_n            = (sys_rst_n & locked);
//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//

//------------- clk_gen_inst -------------
//clk_wiz_0 clk_gen_inst
//    (
//    .resetn                            (sys_rst_n                              ), //输入复位信号,高电平有�?,1bit
//    .clk_in1                           (sys_clk                                ), //输入 50MHz 晶振时钟,1bit
//
//    .clk_out1                          (clk                                    ),
//    .clk_out2                          (vga_clk                                ), //输出 VGA 工作时钟,频率 25MHz,1bit
//    .locked                            (locked                                 )  //输出 pll locked 信号,1bit
//    );


reg clk_div;
assign rst_n            = sys_rst_n;
assign vga_clk          = clk_div;

always @ (posedge sys_clk or posedge rst_n)
begin
  if(rst_n == 1'b0)
    clk_div             <= 1'b0;     // 复位置零
  else
    clk_div             <= ~ clk_div; // 否则q信号翻转
end

//------------- vga_ctrl_inst -------------
VGA_CTRL U_VGA_CTRL
    (
    .vga_clk                           (vga_clk                                ), //输入工作时钟,频率 25MHz,1bit
    .sys_rst_n                         (rst_n                                  ), //输入复位信号,低电平有�?,1bit
    .pix_data                          (pix_data                               ), //输入像素点色彩信�?,12bit

    .pix_x                             (pix_x                                  ), //输出 VGA 有效显示区域像素�? X 轴坐�?,10bit
    .pix_y                             (pix_y                                  ), //输出 VGA 有效显示区域像素�? Y 轴坐�?,10bit
    .hsync                             (hsync                                  ), //输出行同步信�?,1bit
    .vsync                             (vsync                                  ), //输出场同步信�?,1bit
    .rgb                               (rgb                                    )  //输出像素点色彩信�?,12bit
    );

//------------- vga_pic_inst -------------
VGA_PIC U_VGA_PIC
    (
    .vga_clk                           (vga_clk                                ), //输入工作时钟,频率 25MHz,1bit
    .sys_rst_n                         (rst_n                                  ), //输入复位信号,低电平有�?,1bit
    .pix_x                             (pix_x                                  ), //输入 VGA 有效显示区域像素�? X 轴坐�?,10bit
    .pix_y                             (pix_y                                  ), //输入 VGA 有效显示区域像素�? Y 轴坐�?,10bit
    .char_x_start                      (char_x_start                           ),
    .char_x_end                        (char_x_end                             ),
    .char_y_start                      (char_y_start                           ),
    .char_y_end                        (char_y_end                             ),
    .char_color                        (char_color                             ),
    .pix_data                          (pix_data                               )  //输出像素点色彩信�?,12bit
    );

//------------- vga_csr ------------------
VGA_CSR
   #(
    .ADDR_WIDTH                        (ADDR_WIDTH                             ),
    .DATA_WIDTH                        (DATA_WIDTH                             )
    )
    U_VGA_CSR
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

    .char_x_start                      (char_x_start_in                        ),
    .char_x_end                        (char_x_end_in                          ),
    .char_y_start                      (char_y_start_in                        ),
    .char_y_end                        (char_y_end_in                          ),
    .char_color                        (char_color_in                          )
    );

// ------------------------------------------------------------------
assign afull_th         = 7;
assign aempty_th        = 1;

wire vga_input_flag;
reg src_vld_dly;
reg [43:0] vga_data;
reg [43:0] dst_data_dly;

assign vga_input_flag   = ((psel & penable & pwrite) & (paddr == 12'h008)) ? 1'b1 : 1'b0;

always @(posedge pclk or negedge preset_n)
begin : VGA_INPUT_PROC
  if (preset_n == 1'b0)
    vga_data            <= 44'b0;
  else if (vga_input_flag == 1'b1)
    vga_data            <= {char_x_start_in,char_x_end_in,char_y_start_in,char_y_end_in,char_color_in};
end

always @(posedge pclk or negedge preset_n)
begin : SRC_VLD_DLY_PROC
  if (preset_n == 1'b0)
    src_vld_dly         <= 1'b0;
  else
    src_vld_dly         <= vga_input_flag;
end

assign src_vld          = src_vld_dly;
assign src_data         = vga_data;

always @(posedge vga_clk or negedge preset_n)
begin : VSYNC_DLY_PROC
  if (preset_n == 1'b0)
    dst_data_dly           <= 1'b0;
  else if(dst_rdy == 1'b1)
    dst_data_dly           <= dst_data;
end

assign dst_rdy          = vsync & dst_vld;
assign char_x_start     = dst_data_dly[43:34];
assign char_x_end       = dst_data_dly[33:24];
assign char_y_start     = dst_data_dly[23:14];
assign char_y_end       = dst_data_dly[13:4];
assign char_color       = dst_data_dly[3:0];

VGA_AFIFO
   #(
    .FIFO_DEPTH                        (FIFO_DEPTH                             ),
    .DATA_WIDTH                        (FIFO_DATA_WIDTH                        ),
    .CDC_DLY                           (CDC_DLY                                ),
    .REG_OUT                           (REG_OUT                                ),
    .NO_RST                            (NO_RST                                 ),
    .ADDR_WIDTH                        (FIFO_ADDR_WIDTH                        ),   // automatically obtained
    .CNT_WIDTH                         (CNT_WIDTH                              )    // automatically obtained
    ) U_AFIFO
    (
    .src_clk                           (pclk                                   ),
    .src_rst_n                         (preset_n                               ),
    .src_vld                           (src_vld                                ),
    .src_rdy                           (src_rdy                                ),
    .src_data                          (src_data                               ),
    .afull_th                          (afull_th                               ),
    .afull                             (afull                                  ),
    .src_cnt                           (src_cnt                                ),

    .dst_clk                           (vga_clk                                ),
    .dst_rst_n                         (preset_n                               ),
    .dst_vld                           (dst_vld                                ),
    .dst_rdy                           (dst_rdy                                ),
    .dst_data                          (dst_data                               ),
    .aempty_th                         (aempty_th                              ),
    .aempty                            (aempty                                 ),
    .dst_cnt                           (dst_cnt                                )
    );

endmodule
