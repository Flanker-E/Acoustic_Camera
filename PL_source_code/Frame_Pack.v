`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/07 10:44:46
// Design Name: 
// Module Name: Frame_Pack
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Frame_Pack(
    input wire BCLK,
    input wire WS,      //INMP441麦克风数据发送选通时钟，硬件需要
    input wire SD,
//    input wire RST,
    output reg[23:0] SDATA,   //麦克风的I2S数据
    output wire enreadframe //让下一个模块读取一个周期的数据帧

    );
    
    reg [5:0] SDcnt;        //数据位计数器
    reg [0:0] En;
    reg [0:0] WSD = 1'b0;
    reg [0:0] WSDD = 1'b0;
    
    always @(negedge BCLK)
    begin
      WSDD = WSD;
      WSD = WS;
    end

//    wire wsp = WSD ^ WSDD;
    always@(posedge BCLK) //为了让SDcnt被ws重置后不被if条件遗漏，故使用posedge
    begin
        if (WSD<WSDD)        //SDcnt被w下降沿重置
            begin
            SDcnt=0;    
            En[0] = 1'b0;
            end
        if (SDcnt == 0)
            SDcnt = SDcnt+1;
        else if (SDcnt>0 && SDcnt < 24)
            begin
            SDATA[SDcnt-1] = SD;
            SDcnt = SDcnt+1;
            end
        else if (SDcnt ==24)
            begin
            SDATA[SDcnt-1] = SD;
            En[0] = 1'b1;      //时序上让SDATA在被读取之前完成存储
            SDcnt = SDcnt+1;
            end
        else if (SDcnt <63)
            SDcnt = SDcnt+1;
        else
            En[0] = 1'b0;
                    
      end
    
//    always@(negedge WS or negedge RST)
//    begin
//        SDcnt <= 5'd0;
//        SDATA <= 24'd0;
//        En[0] <= 1'b0;
//    end
    
    assign enreadframe = En;    //assign在always外使用
    
endmodule
