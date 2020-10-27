`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/12/2019 05:10:37 PM
// Design Name: 
// Module Name: Delay_Calc
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

module Delay_Calc5_serial(
    input wire[23:0] SDATA1,   //麦克风的数据帧（一帧由24bit表示某个采样时间分贝数的相对值）
                     SDATA2,
                     SDATA3,
                     SDATA4,
    input wire enreadframe1,   //代表SDATA1中的麦克风数据帧有效
               enreadframe2,
               enreadframe3,
               enreadframe4,
//    input wire SCK,         //位时钟输入（或采样时钟输入）
    output reg [3:0] Td,                //计算单位时延输出
  output reg [0:0] Thres_30,      //声音超过阈值置1使能PS计算
//    output reg [6:0] Calc_Time_Cost,  
//    output reg [6:0] dB_Ave_Output,\
    output wire [0:0] CALC_FREE //每计算完成一次，此寄存器翻转一次
//    output wire [0:0] Cnttest
    
    );
  
       
    reg [10:0] FrameCnt1,     //单个数据段帧数计数器
              FrameCnt2;
//              Buffer_Cnt1,
//              Buffer_Cnt2;
    reg [6:0] n,m;
    reg [23:0] DATAPack1[0:29],             //数据段，含有时序上的50个数据帧
                DATAPack2[0:29];
    reg [0:0] ENreadsection1,               //代表50个数据段有效
              ENreadsection2;
    wire [0:0] enreadsection;               //代表两个麦克风的数据段都有效
//    wire enreadsection;
    reg [3:0] i;    //计数器
    reg [6:0] j;    //计数器
    reg [24:0] Diff;               //代表
    reg [29:0] DATA_Diff[0:10];    //最大值数组
    reg [29:0] M;    //Min value
    reg [3:0] Tdd;
//    input wire[23:0][99:0] DATApack_in_1,   //数据包输入通道(1-2)
//    reg [23:0] DATApack_in_1[0:49],
//                DATApack_in_2[0:49];
    reg [0:0] Calc_Free,
               Forece_Calc_Free;
 //   reg [1:0] Calc_nFree_cnt;
    wire En_Delay_Calc;
    reg [0:0] CFD,
              CFD1 ,
              CFD2 ;
    reg [0:0] CFDD1,
              CFDD2;
    
            
    always @(posedge enreadframe1 & enreadframe3)//用来缓存一段共50帧音频信号，用来组成数据段。每存储50帧就进入可读状态，后续计算模块计算完成后，本模块重新开始读取50帧
    begin
        CFDD1 = CFD1;
        CFD1 = Calc_Free;
        if (FrameCnt1 == 0)
            begin
                ENreadsection1=0;
                if(Calc_Free)
                DATAPack1[FrameCnt1] = SDATA1;
                else
                DATAPack1[FrameCnt1] = SDATA3;
                FrameCnt1 = FrameCnt1+1;
            end
        else if (FrameCnt1>0 & FrameCnt1 < 30)
            begin
            if(Calc_Free)
            DATAPack1[FrameCnt1] = SDATA1;
            else
            DATAPack1[FrameCnt1] = SDATA3;
            FrameCnt1 = FrameCnt1+1;
            end
        else if (FrameCnt1 == 30)//FIFO填充之后，时差计算使能信号发出
            begin
            ENreadsection1=1;
            FrameCnt1 = FrameCnt1+1;
            end
        else if (FrameCnt1>30)//FIFO填充之后，在非空闲时进入闲置状态，等待计算完成的信号
            FrameCnt1 = FrameCnt1+1;
//        else if (FrameCnt2 == 140)
//            begin
//                //发送数据包并重置
//                FrameCnt2 = 0;
////                for(m=0;m<100;m=m+1)
////                DATAPackOut1[m] <= DATAPack1[m];
//                ENreadsection2=0;
//            end
        else if((CFDD1!=CFD1)|FrameCnt1>500)//当计算完成之后再重新填充FIFO，给计算留出足够的时间
        begin
            FrameCnt1 = 0;
//                for(m=0;m<100;m=m+1)
//                DATAPackOut1[m] <= DATAPack1[m];
            ENreadsection1=0;    
        end
        else
            begin
            FrameCnt1 = FrameCnt1+1;
//            ENreadsection2=0;
//            FrameCnt2 = 0;
            end

    end
    
    always @(posedge enreadframe2 & enreadframe4)
    begin
        CFDD2 = CFD2;
        CFD2 = Calc_Free;
        if (FrameCnt2 == 0)
            begin
                ENreadsection2=0;
//                for(m=0;m<100;m=m+1)
//                DATAPack1[m] = 0;
                if(Calc_Free)
                DATAPack2[FrameCnt2] = SDATA2;
                else
                DATAPack2[FrameCnt2] = SDATA4;
                FrameCnt2 = FrameCnt2+1;
            end
        else if (FrameCnt2>0 & FrameCnt2 < 30)
            begin
            if(Calc_Free)
                DATAPack2[FrameCnt2] = SDATA2;
            else
                DATAPack2[FrameCnt2] = SDATA4;
            FrameCnt2 = FrameCnt2+1;
            end
        else if (FrameCnt2 == 30)
            begin
            ENreadsection2=1;
            FrameCnt2 = FrameCnt2+1;
            end
        else if (FrameCnt2>30 )
            FrameCnt2 = FrameCnt2+1;
//        else if (FrameCnt2 == 140)
//            begin
//                //发送数据包并重置
//                FrameCnt2 = 0;
////                for(m=0;m<100;m=m+1)
////                DATAPackOut1[m] <= DATAPack1[m];
//                ENreadsection2=0;
//            end
        else if((CFDD2!=CFD2)|FrameCnt2>500)
        begin
            FrameCnt2 = 0;
//                for(m=0;m<100;m=m+1)
//                DATAPackOut1[m] <= DATAPack1[m];
            ENreadsection2=0;    
        end
        else
            begin
            FrameCnt2 = FrameCnt2+1;
//            ENreadsection2=0;
//            FrameCnt2 = 0;
            end
    end
    
assign enreadsection = ENreadsection1 & ENreadsection2 ;
////Delay_Calc
// //////////////////////////////////////////////////////////////////////////////////
 



//assign En_Delay_Calc= enreadsection;
////reg [6:0] Max_j;
always @(posedge enreadsection)//通过位移，并逐位相减取绝对值。将绝对值全部相加，可以得到误差值，其中误差值最小的对应的i为时差单位
    begin      
//        for(i=0;i<100;i=i+1)
//            begin
//            DATApack_in_1[i] = DATAPack1[i];
//            DATApack_in_2[i] = DATAPack2[i];
//            end
        M=29'b1_1111_1111_1111_1111_1111_1111_1111;
        //叠加波形,储存波峰图谱
        for (i=0;i<11;i=i+1)//(2*Max_delta_t+1)
            begin
            DATA_Diff[i]=0;
            for (j=0;j<20;j=j+1)  //实际比较的位数(2*Max_delta_t)
            begin
                Diff = (DATAPack1[j+5] > DATAPack2[i+j]) ? DATAPack1[j+5] - DATAPack2[i+j]: DATAPack2[i+j] - DATAPack1[j+5];
                DATA_Diff[i]=DATA_Diff[i]+Diff;            
            end
            if (DATA_Diff[i]<M)
                begin
                M=DATA_Diff[i];
                Tdd=i;
                end
            end
        //标记峰值位置
        Td=Tdd;
//        CFD=Calc_Free;
        Calc_Free=!Calc_Free;//翻转
    end
    reg [6:0] cnt,
              dB30cnt;
    reg [28:0] dB_Total;
    parameter Thres=15'b11_1111_1111_1111;

    
    always @(posedge enreadsection)
    begin
//    dB_Ave_Output=7'b0;
//    dB_Total=29'b0;
    Thres_30=1'b0;
    dB30cnt=7'b0;
//    for (cnt=0;cnt<32;cnt=cnt+1)  //实际比较的位数
//        begin
//        dB_Total=dB_Total+DATAPack1[cnt];
//        end
//    dB_Total=(dB_Total >> 21);      //除以64后舍弃后16位（约为1分贝）
//    for (cnt=0;cnt<7;cnt=cnt+1)
//        dB_Ave_Output[cnt]=dB_Total[cnt];//将分贝测量更新
    for (cnt=0;cnt<20;cnt=cnt+1)  //实际比较的位数
        begin
        if(DATAPack1[cnt]>Thres)
            dB30cnt=dB30cnt+1;
        end
    if (dB30cnt>10)
        Thres_30=1'b1;
    end
    
    assign CALC_FREE =  Calc_Free;
    
endmodule