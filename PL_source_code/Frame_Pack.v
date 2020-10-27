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
    input wire WS,      //INMP441��˷����ݷ���ѡͨʱ�ӣ�Ӳ����Ҫ
    input wire SD,
//    input wire RST,
    output reg[23:0] SDATA,   //��˷��I2S����
    output wire enreadframe //����һ��ģ���ȡһ�����ڵ�����֡

    );
    
    reg [5:0] SDcnt;        //����λ������
    reg [0:0] En;
    reg [0:0] WSD = 1'b0;
    reg [0:0] WSDD = 1'b0;
    
    always @(negedge BCLK)
    begin
      WSDD = WSD;
      WSD = WS;
    end

//    wire wsp = WSD ^ WSDD;
    always@(posedge BCLK) //Ϊ����SDcnt��ws���ú󲻱�if������©����ʹ��posedge
    begin
        if (WSD<WSDD)        //SDcnt��w�½�������
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
            En[0] = 1'b1;      //ʱ������SDATA�ڱ���ȡ֮ǰ��ɴ洢
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
    
    assign enreadframe = En;    //assign��always��ʹ��
    
endmodule
