module VGA_PIC
    (
    input wire                                   vga_clk ,                     //输入工作时钟,频率 25MHz
    input wire                                   sys_rst_n ,                   //输入复位信号,低电平有效
    input wire                             [9:0] pix_x ,                       //输入有效显示区域像素点 X 轴坐标
    input wire                             [9:0] pix_y ,                       //输入有效显示区域像素点 Y 轴坐标

    input wire                             [9:0] char_x_start,
    input wire                             [9:0] char_x_end,
    input wire                             [9:0] char_y_start,
    input wire                             [9:0] char_y_end,
    input wire                             [3:0] char_color,

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

//parameter define
parameter CHAR_B_H                     = 10'd192 , //字符开始 X 轴坐标
          CHAR_B_V                     = 10'd208 ; //字符开始 Y 轴坐标

parameter CHAR_W                       = 10'd256 , //字符宽度
          CHAR_H                       = 10'd64 ;  //字符高度


reg    [3:0]     dina;			      //写入的数据
wire   [3:0]     doutb;			      //输出的数据
wire             wea;			        //写有效信号
reg    [3:0]     mem [0:307200];	//定义RAM

integer i;
 initial begin
  for(i = 0; i <= 307200 ; i = i + 1)
    begin
      mem[i] = 4'd7;
    end
end

assign wea = 1'b1;

wire [9:0] input_x;
wire [9:0] input_y;
assign input_x= (pix_x == 10'd1023) ? 10'd640 : pix_x;
assign input_y= (pix_y == 10'd1023) ? 10'd480 : pix_y;

always @*
begin
  dina = dina;
  if(((input_x >= (char_x_start - 1'b1)) && (input_x < (char_x_end -1'b1))) &&
     ((input_y >=  char_y_start        ) && (input_y < (char_y_end      ))))
    dina = char_color;
  else if((input_x == 10'd640) && (input_y == 10'd480))
    dina = 4'd7;
  else
    dina = 4'd7;
end

always@ (posedge vga_clk)
begin
  if(wea == 1'b1)							//写有效时候，把dina写入到addra处
    begin
      mem[input_x + input_y*640] <= dina;
    end
end

assign doutb = mem[input_x + input_y*640];

reg [11:0] color;
always@*
begin
  case(doutb)
    4'd0 : color = RED;
    4'd1 : color = ORANGE;
    4'd2 : color = YELLOW;
    4'd3 : color = GREEN;
    4'd4 : color = CYAN;
    4'd5 : color = BLUE;
    4'd6 : color = PURPPLE ;
    4'd7 : color = BLACK ;
    4'd8 : color = WHITE;
    4'd9 : color = GRAY;
    default : color = BLACK;
  endcase
end

always@(posedge vga_clk or negedge sys_rst_n)
begin
  if(sys_rst_n == 1'b0)
    pix_data <= BLACK;
  else
    pix_data <= color;
end

//pix_data:输出像素点色彩信息,根据当前像素点坐标指定当前像素点颜色数据
//always@(posedge vga_clk or negedge sys_rst_n)
//begin
//  if(sys_rst_n == 1'b0)
//    pix_data <= BLACK;
//  else if(((pix_x >= (CHAR_B_H - 1'b1)) && (pix_x < (CHAR_B_H + CHAR_W -1'b1))) &&
//          ((pix_y >= CHAR_B_V         ) && (pix_y < (CHAR_B_V + CHAR_H      ))))
//    pix_data <= RED;
//  else
//    pix_data <= BLACK;
//end

////pix_data:输出像素点色彩信息,根据当前像素点坐标指定当前像素点颜色数据
//always@(posedge vga_clk or negedge sys_rst_n)
//begin
//  if(sys_rst_n == 1'b0)
//    pix_data <= 16'd0;
//  else if((pix_x >= 0) && (pix_x < (H_VALID/10)*1))
//    pix_data <= RED;
//  else if((pix_x >= (H_VALID/10)*1) && (pix_x < (H_VALID/10)*2))
//    pix_data <= ORANGE;
//  else if((pix_x >= (H_VALID/10)*2) && (pix_x < (H_VALID/10)*3))
//    pix_data <= YELLOW;
//  else if((pix_x >= (H_VALID/10)*3) && (pix_x < (H_VALID/10)*4))
//    pix_data <= GREEN;
//  else if((pix_x >= (H_VALID/10)*4) && (pix_x < (H_VALID/10)*5))
//    pix_data <= CYAN;
//  else if((pix_x >= (H_VALID/10)*5) && (pix_x < (H_VALID/10)*6))
//    pix_data <= BLUE;
//  else if((pix_x >= (H_VALID/10)*6) && (pix_x < (H_VALID/10)*7))
//    pix_data <= PURPPLE;
//  else if((pix_x >= (H_VALID/10)*7) && (pix_x < (H_VALID/10)*8))
//    pix_data <= BLACK;
//  else if((pix_x >= (H_VALID/10)*8) && (pix_x < (H_VALID/10)*9))
//    pix_data <= WHITE;
//  else if((pix_x >= (H_VALID/10)*9) && (pix_x < H_VALID))
//    pix_data <= GRAY;
//  else
//    pix_data <= BLACK;
//end
endmodule
