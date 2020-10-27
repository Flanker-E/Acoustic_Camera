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
    input wire[23:0] SDATA1,   //��˷������֡��һ֡��24bit��ʾĳ������ʱ��ֱ��������ֵ��
                     SDATA2,
                     SDATA3,
                     SDATA4,
    input wire enreadframe1,   //����SDATA1�е���˷�����֡��Ч
               enreadframe2,
               enreadframe3,
               enreadframe4,
//    input wire SCK,         //λʱ�����루�����ʱ�����룩
    output reg [3:0] Td,                //���㵥λʱ�����
  output reg [0:0] Thres_30,      //����������ֵ��1ʹ��PS����
//    output reg [6:0] Calc_Time_Cost,  
//    output reg [6:0] dB_Ave_Output,\
    output wire [0:0] CALC_FREE //ÿ�������һ�Σ��˼Ĵ�����תһ��
//    output wire [0:0] Cnttest
    
    );
  
       
    reg [10:0] FrameCnt1,     //�������ݶ�֡��������
              FrameCnt2;
//              Buffer_Cnt1,
//              Buffer_Cnt2;
    reg [6:0] n,m;
    reg [23:0] DATAPack1[0:29],             //���ݶΣ�����ʱ���ϵ�50������֡
                DATAPack2[0:29];
    reg [0:0] ENreadsection1,               //����50�����ݶ���Ч
              ENreadsection2;
    wire [0:0] enreadsection;               //����������˷�����ݶζ���Ч
//    wire enreadsection;
    reg [3:0] i;    //������
    reg [6:0] j;    //������
    reg [24:0] Diff;               //����
    reg [29:0] DATA_Diff[0:10];    //���ֵ����
    reg [29:0] M;    //Min value
    reg [3:0] Tdd;
//    input wire[23:0][99:0] DATApack_in_1,   //���ݰ�����ͨ��(1-2)
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
    
            
    always @(posedge enreadframe1 & enreadframe3)//��������һ�ι�50֡��Ƶ�źţ�����������ݶΡ�ÿ�洢50֡�ͽ���ɶ�״̬����������ģ�������ɺ󣬱�ģ�����¿�ʼ��ȡ50֡
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
        else if (FrameCnt1 == 30)//FIFO���֮��ʱ�����ʹ���źŷ���
            begin
            ENreadsection1=1;
            FrameCnt1 = FrameCnt1+1;
            end
        else if (FrameCnt1>30)//FIFO���֮���ڷǿ���ʱ��������״̬���ȴ�������ɵ��ź�
            FrameCnt1 = FrameCnt1+1;
//        else if (FrameCnt2 == 140)
//            begin
//                //�������ݰ�������
//                FrameCnt2 = 0;
////                for(m=0;m<100;m=m+1)
////                DATAPackOut1[m] <= DATAPack1[m];
//                ENreadsection2=0;
//            end
        else if((CFDD1!=CFD1)|FrameCnt1>500)//���������֮�����������FIFO�������������㹻��ʱ��
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
//                //�������ݰ�������
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
always @(posedge enreadsection)//ͨ��λ�ƣ�����λ���ȡ����ֵ��������ֵȫ����ӣ����Եõ����ֵ���������ֵ��С�Ķ�Ӧ��iΪʱ�λ
    begin      
//        for(i=0;i<100;i=i+1)
//            begin
//            DATApack_in_1[i] = DATAPack1[i];
//            DATApack_in_2[i] = DATAPack2[i];
//            end
        M=29'b1_1111_1111_1111_1111_1111_1111_1111;
        //���Ӳ���,���沨��ͼ��
        for (i=0;i<11;i=i+1)//(2*Max_delta_t+1)
            begin
            DATA_Diff[i]=0;
            for (j=0;j<20;j=j+1)  //ʵ�ʱȽϵ�λ��(2*Max_delta_t)
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
        //��Ƿ�ֵλ��
        Td=Tdd;
//        CFD=Calc_Free;
        Calc_Free=!Calc_Free;//��ת
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
//    for (cnt=0;cnt<32;cnt=cnt+1)  //ʵ�ʱȽϵ�λ��
//        begin
//        dB_Total=dB_Total+DATAPack1[cnt];
//        end
//    dB_Total=(dB_Total >> 21);      //����64��������16λ��ԼΪ1�ֱ���
//    for (cnt=0;cnt<7;cnt=cnt+1)
//        dB_Ave_Output[cnt]=dB_Total[cnt];//���ֱ���������
    for (cnt=0;cnt<20;cnt=cnt+1)  //ʵ�ʱȽϵ�λ��
        begin
        if(DATAPack1[cnt]>Thres)
            dB30cnt=dB30cnt+1;
        end
    if (dB30cnt>10)
        Thres_30=1'b1;
    end
    
    assign CALC_FREE =  Calc_Free;
    
endmodule