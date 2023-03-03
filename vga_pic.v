module VGA_PIC
    (
    input wire                                   vga_clk ,                     //输入工作时钟,频率 25MHz
    input wire                                   sys_rst_n ,                   //输入复位信号,低电平有效
    input wire                             [9:0] pix_x ,                       //输入有效显示区域像素点 X 轴坐标
    input wire                             [9:0] pix_y ,                       //输入有效显示区域像素点 Y 轴坐标

    output reg                            [11:0] pix_data                      //输出像素点色彩信息

    );

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define
parameter H_VALID                      = 10'd640 ,                             //行有效数据
          V_VALID                      = 10'd480 ;                             //场有效数据

parameter RED                          = 12'hf00,                             //红色
          ORANGE                       = 12'hf80,                             //橙色
          YELLOW                       = 12'hff0,                             //黄色
          GREEN                        = 12'h0f0,                             //绿色
          CYAN                         = 12'h0ff,                             //青色
          BLUE                         = 12'h00f,                             //蓝色
          PURPPLE                      = 12'hf0f,                             //紫色
          BLACK                        = 12'h000,                             //黑色
          WHITE                        = 12'hfff,                             //白色
          GRAY                         = 12'h444;                             //灰色

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//

//pix_data:输出像素点色彩信息,根据当前像素点坐标指定当前像素点颜色数据
always@(posedge vga_clk or negedge sys_rst_n)
begin
  if(sys_rst_n == 1'b0)
    pix_data <= 16'd0;
  else if((pix_x >= 0) && (pix_x < (H_VALID/10)*1))
    pix_data <= RED;
  else if((pix_x >= (H_VALID/10)*1) && (pix_x < (H_VALID/10)*2))
    pix_data <= ORANGE;
  else if((pix_x >= (H_VALID/10)*2) && (pix_x < (H_VALID/10)*3))
    pix_data <= YELLOW;
  else if((pix_x >= (H_VALID/10)*3) && (pix_x < (H_VALID/10)*4))
    pix_data <= GREEN;
  else if((pix_x >= (H_VALID/10)*4) && (pix_x < (H_VALID/10)*5))
    pix_data <= CYAN;
  else if((pix_x >= (H_VALID/10)*5) && (pix_x < (H_VALID/10)*6))
    pix_data <= BLUE;
  else if((pix_x >= (H_VALID/10)*6) && (pix_x < (H_VALID/10)*7))
    pix_data <= PURPPLE;
  else if((pix_x >= (H_VALID/10)*7) && (pix_x < (H_VALID/10)*8))
    pix_data <= BLACK;
  else if((pix_x >= (H_VALID/10)*8) && (pix_x < (H_VALID/10)*9))
    pix_data <= WHITE;
  else if((pix_x >= (H_VALID/10)*9) && (pix_x < H_VALID))
    pix_data <= GRAY;
  else
    pix_data <= BLACK;
end
endmodule
