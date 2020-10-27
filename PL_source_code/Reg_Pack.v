`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/16/2019 12:11:04 AM
// Design Name: 
// Module Name: Reg_Pack
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


module Reg_Pack(
input wire SCK,
input wire CALC_FREE,
input wire[0:0] Thres,
input wire[3:0] Td0,
//input wire[3:0] Td0,
//                Td1,
//                Td2,
//                Td3,
//                Td4,
//                Td5,
//input wire[6:0] Calc_Time_Cost,
//                dB_Ave_Output,
output wire[31:0] DATA
    );
    reg[31:0]Data,
            Datapre;
    reg[4:0] cnt,
             cnt1;
    reg [0:0] RD,RDD;
    reg [0:0] En_Reg_Pack;
    
    always@(posedge SCK)
    begin
    RDD = RD;
    RD = CALC_FREE;
    En_Reg_Pack = RD^RDD;
    end
always@(posedge En_Reg_Pack)
begin
    if(!CALC_FREE)
        begin
        Datapre=32'b0;
        Datapre=Datapre+Td0;
        Datapre=(Datapre<<1)+Thres;
        end
    else
        begin
        Data=32'b0;
        Data=Td0;
        Data=Datapre+(Data<<5);
        end

end
assign DATA=Data;
endmodule
