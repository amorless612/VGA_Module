module VGA_TOP
    (
    input  wire                                  sys_clk ,                     //输入工作时钟,频率 50MHz
    input  wire                                  sys_rst_n ,                   //输入复位信号,低电平有�?
    output wire                                  hsync ,                       //输出行同步信�?
    output wire                                  vsync ,                       //输出场同步信�?
    output wire                           [11:0] rgb                           //输出像素信息
    );
//********************************************************************//
//****************** Parameter and Internal Signal *******************//       //640*480@60
//********************************************************************//
//wire define
wire                                             clk;
wire                                             vga_clk ;                     //VGA 工作时钟,频率 25MHz
wire                                             locked ;                      //PLL locked 信号
wire                                             rst_n ;                       //VGA 模块复位信号
wire                                       [9:0] pix_x ;                       //VGA 有效显示区域 X 轴坐�?
wire                                       [9:0] pix_y ;                       //VGA 有效显示区域 Y 轴坐�?
wire                                      [11:0] pix_data;                     //VGA 像素点色彩信�?

//rst_n:VGA 模块复位信号
assign rst_n            = (sys_rst_n & locked);
//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//

//------------- clk_gen_inst -------------
clk_wiz_0 clk_gen_inst
    (
    .resetn                            (sys_rst_n                              ), //输入复位信号,高电平有�?,1bit
    .clk_in1                           (sys_clk                                ), //输入 50MHz 晶振时钟,1bit

    .clk_out1                          (clk                                    ),
    .clk_out2                          (vga_clk                                ), //输出 VGA 工作时钟,频率 25MHz,1bit
    .locked                            (locked                                 )  //输出 pll locked 信号,1bit
    );


//reg clk_div;
//assign rst_n            = sys_rst_n;
//assign vga_clk          = clk_div;

//always @ (posedge sys_clk or posedge rst_n)
//begin
//  if(rst_n == 1'b0)
//    clk_div             <= 1'b0;     // 复位置零
//  else
//    clk_div             <= ~ clk_div; // 否则q信号翻转
//end

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

    .pix_data                          (pix_data                               )  //输出像素点色彩信�?,12bit
    );

 endmodule
