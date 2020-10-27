/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "ov7670/ov7670.h"
#include "sccb/sccb_ctrl.h"
#include "xaxivdma.h"
#include "sleep.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "test_pspl.h"
#include "xparameters.h"
#include "math.h"

#define VIDEO_HORISIZE 640
#define VIDEO_VERTSIZE 480
#define VIDEO_HORISTRIKE VIDEO_HORISIZE*4

#define VIDEO_FRAMESIZE VIDEO_HORISIZE*VIDEO_VERTSIZE
#define Slope_A 0.3812		//实践所测的摄像头水平方向张角斜率
#define Slope_B 0.2799		//实践所测的摄像头垂直方向张角斜率


u32 destAddr = (XPAR_PS7_DDR_0_S_AXI_BASEADDR + 0x10000000);



static XAxiVdma vdma;
XAxiVdma_Config *vdmaCfg;
XAxiVdma_DmaSetup *vdamSetup;

int vdmaInit(){
	int status = 0;
	vdmaCfg = XAxiVdma_LookupConfig(XPAR_AXI_VDMA_0_DEVICE_ID);
	if(vdmaCfg == NULL){
		printf("No vdma device found!\n");
		return -1;
	}
	status = XAxiVdma_CfgInitialize(&vdma,vdmaCfg,vdmaCfg->BaseAddress);
	if(status != XST_SUCCESS){
		printf("Vdma initialization failed!\n");
		return XST_FAILURE;
	}

	vdamSetup->HoriSizeInput = VIDEO_HORISIZE * 3;//(vdmaCfg->Mm2SStreamWidth>>3);
	vdamSetup->VertSizeInput = VIDEO_VERTSIZE;

	vdamSetup->Stride =  VIDEO_HORISIZE * 4;
	vdamSetup->FrameDelay = 0;

	vdamSetup->EnableCircularBuf = 1;
	vdamSetup->EnableSync = 1;

	vdamSetup->PointNum = 0;
	vdamSetup->EnableFrameCounter = 0;

	vdamSetup->FixedFrameStoreAddr = 0;
	vdamSetup->FrameStoreStartAddr[0] = destAddr;

	status = XAxiVdma_DmaConfig(&vdma, XAXIVDMA_WRITE, vdamSetup);
	if (status != XST_SUCCESS) {
		printf("Write channel config failed %d\r\n", status);
		return XST_FAILURE;
	}
    status = XAxiVdma_DmaConfig(&vdma, XAXIVDMA_READ, vdamSetup);
	if (status != XST_SUCCESS) {
		printf("Read channel config failed %d\r\n", status);
		return XST_FAILURE;
	}

	u32 Addr = destAddr;
	for(int i = 0; i < vdmaCfg->MaxFrameStoreNum ; ++i ){
		vdamSetup->FrameStoreStartAddr[i] = Addr;
		Addr += (vdamSetup->Stride) * (vdamSetup->VertSizeInput);
	}

	status = XAxiVdma_DmaSetBufferAddr(&vdma,XAXIVDMA_WRITE,vdamSetup->FrameStoreStartAddr);
	if (status != XST_SUCCESS) {
		printf("Write channel set buffer address failed %d\r\n",status);
		return XST_FAILURE;
	}
    status = XAxiVdma_DmaSetBufferAddr(&vdma,XAXIVDMA_READ,vdamSetup->FrameStoreStartAddr);
	if (status != XST_SUCCESS) {
		printf("Write channel set buffer address failed %d\r\n",status);
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

void bkgInit(){//整个画面上色
	u8* addr = (u8*)destAddr;
	for(int j = 0;j<480;j++){
		addr += 640*4;
		for(int i = 0;i<640*3;i+=3){
				addr[i+2] = 0x00;//r
				addr[i+1] = 0xff;//g
				addr[i] = 0xff;//b
			}
	}
	printf("init data\n");
    Xil_DCacheFlushRange((INTPTR)destAddr, VIDEO_FRAMESIZE*4*sizeof(u8));
}

void label(){//测试label打印
    int x;//声源横坐标归一到屏幕*从左到右*的像素点的位置
    int y;//声源纵坐标归一到屏幕*从上到下*的像素点的位置
    int dB;//声音的大小

    x=100;y=200;dB=60;


    int top=(y-10),bottom=(y+10),left=(x-10),right=(x+10);//将label限制在一帧以内
    if (x>640||x<0||y<0||y>480) dB=0;
    if(top<0) top=0;
    if(bottom>480) bottom=0;
    if(left<0) left=0;
    if(right>480) right=0;


    u8* addr = (u8*)destAddr;
        if(dB>=20)                                      //如果声音超过阈值再画图
        {                                                //画一帧
            addr += 640*4*(top-1);
            for(int j = 0;j<(20+1);j++)
            {
                if(j==(10-1)||j==(10)||j==(10+1))
                {
                for(int k = 3*left;k<3*left+(20+1)*3;k+=3)
                    {
                        addr[k+2] = 0xff;//r
                        addr[k+1] = 0xff;//g
                        addr[k] = 0xff ;//b
                    }
                }
              //  else

                for(int i = 3*(x-1);i<3*(x-1)+3*3;i+=3)
                    {
                        addr[i+2] = 0xff;//r
                        addr[i+1] = 0xff;//g
                        addr[i] = 0xff ;//b
                    }

                addr += 640*4;
            }
        addr += 640*4*(480-bottom+1);
        printf("label data\n");
        }
        Xil_DCacheFlushRange((INTPTR)destAddr, VIDEO_FRAMESIZE*4*sizeof(u8));
}

void setPicClr(int f,int x,int y,u8 r,u8 g,u8 b)//对某个像素点上色
{
	u8* addr = (u8*)destAddr;
	int i = f*VIDEO_VERTSIZE*VIDEO_HORISTRIKE + y*VIDEO_HORISTRIKE + 3*x;
	addr[i] = b;
	addr[i+1] = g;
	addr[i+2] = r;
}

void Pixel(int T[], int Pix[])
{
	float ta,tb;		//横向和纵向相邻麦克风时延
	float d=0.1;			//麦克风间距
	float sina,sinb;	//横向和纵向声源与Z轴夹角的正弦值
	float v=340;			//声速
	float a,b;			//参数方程系数
	int s_hori,s_vert;  //声源所在的直线对应的像素点的序数
	float Delta_t=1.0/48000;


	ta=(T[0]-5)*Delta_t;
	tb=(T[1]-5)*Delta_t;		//时延处理

	sina=ta*v/d;
	sinb=tb*v/d;							 //计算夹角

	a=sina/sqrt(1-sina*sina-sinb*sinb);
	b=sinb/sqrt(1-sina*sina-sinb*sinb);		//计算映射斜率

	s_hori=(int)(VIDEO_HORISIZE*(Slope_A+a)/(2*Slope_A));
	s_vert=(int)(VIDEO_VERTSIZE*(Slope_B-b)/(2*Slope_B));	    //计算映射呈像坐标
	if(s_hori>640||s_hori<0)//防止像素点位置溢出
		s_hori=0;
	if(s_vert>480||s_vert<0)
		s_vert=0;
	Pix[0]=s_hori;
	Pix[1]=s_vert;

}

void drawlabel(int f,int x,int y,int dB,u8 R,u8 G,u8 B)
{
	int r;
	r = ceil(dB/10);
    int top=(y-r),bottom=(y+r),left=(x-r),right=(x+r);//将label限制在一帧以内
    int p = f*VIDEO_VERTSIZE*VIDEO_HORISTRIKE;
    if (x>640||x<0||y<0||y>480) dB=0;
    if(top<0) top=0;
    if(bottom>480) bottom=0;
    if(left<0) left=0;
    if(right>480) right=0;
	u8* addr = (u8*)destAddr;
	addr +=p;
    if(dB>=20)                                      //如果声音超过阈值再画图
    {                                                //画一帧
        addr += 640*4*(top-1);
        for(int j = 0;j<(2*r+1);j++)
        {
            if(j==(r-1)||j==(r)||j==(r+1))
            {
            for(int k = 3*left;k<3*left+(2*r+1)*3;k+=3)
                {
                    addr[k+2] = 0xff;//r
                    addr[k+1] = 0xff;//g
                    addr[k] = 0xff ;//b
                }
            }
          //  else

            for(int i = 3*(x-1);i<3*(x-1)+3*3;i+=3)
                {
                    addr[i+2] = 0xff;//r
                    addr[i+1] = 0xff;//g
                    addr[i] = 0xff ;//b
                }

            addr += 640*4;
        }
    addr += 640*4*(480-bottom+1);
//    printf("label data\n");
    }
    Xil_DCacheFlushRange((INTPTR)destAddr, VIDEO_FRAMESIZE*4*sizeof(u8));
}

int main()
{
    init_platform();
    EMIO_SCCB_init();
//    bkgInit();
//    label();
    OV7670_Init();

    vdmaInit();

//    int x;//声源横坐标归一到屏幕*从左到右*的像素点的位置
//    int y;//声源纵坐标归一到屏幕*从上到下*的像素点的位置
    u32 n;
    int dB;//声音的大小
    float N;//(int)N;
    int t[6];
    int En_30dB;
//    int Cost;
    int pixel[2]={0,0};
    int Bit;

//    int r=4;
//    x=200;y=200;
    dB=60;

    int status = 0;
    status = XAxiVdma_DmaStart(&vdma, XAXIVDMA_WRITE);
	if(status){
		printf("vdma write start error %d !\n",status);
		return -1 ;
	}
    status = XAxiVdma_DmaStart(&vdma, XAXIVDMA_READ);
	if(status){
		printf("vdma read start error %d !\n",status);
		return -1 ;
	}
	Xil_DCacheInvalidateRange((INTPTR)destAddr, VIDEO_FRAMESIZE*4*sizeof(u8));

	u8* addr = (u8*)destAddr;
	for(int j = 0;j<10;j++){
		addr += 640*4;
		for(int i = 0;i<640*3;i+=3){
			//printf("%02x%02x%02x \t",addr[i],addr[i+1],addr[i+2]);
			//if(i%9==0&&i) printf("\n");
			//if(i%9==0) printf("addr:%d - %d\n",640*j+i+3,640*j+i+5);
		}
		//printf("init data\n");
	}


	   while(1)
	    {
	    	n=Xil_In32(XPAR_TEST_PSPL_0_S00_AXI_BASEADDR);//最低24位为计算出的6个时延，
	//		n=(unsigned int)N;
			En_30dB=(unsigned long)(n-2*floor(n/2));
			printf("%u %u\n Below 30dB\n",n,En_30dB);
			n=floor(n/2);
			Bit=4;
			if(En_30dB)
			{
			for(int i=0;i<2;i++)
			{
				t[i]=(int)(n-(pow(2,Bit))*floor(n/pow(2,Bit)));//将5位时延分别取出，类型转换后赋值给t[i]
				n=floor(n/pow(2,Bit));                  //将取出的部分
					printf("%u %u\n",t[i],n);
			}
//			Bit=7;										//取出计算耗时
//			Cost=n-(pow(2,Bit))*floor(n/pow(2,Bit));
			Pixel(t,pixel);

			if(pixel[0]&&pixel[1])
			{
				drawlabel(0,(640-pixel[0]),(480-pixel[1]),dB,0xff,0xff,0xff);//第一帧，并将像素点镜像对称
				drawlabel(1,(640-pixel[0]),(480-pixel[1]),dB,0xff,0xff,0xff);//第二帧
				drawlabel(2,(640-pixel[0]),(480-pixel[1]),dB,0xff,0xff,0xff);//第三帧
				Xil_DCacheFlushRange((INTPTR)destAddr, 3*VIDEO_FRAMESIZE*4*sizeof(u8));
			}
//	    	printf("%d %d %f\n",pixel[0],pixel[1],Cost);
		}
		else
			printf("Below 30dB\n");
//    	for(int i=-r+1;i<r;i++){
//    	for(int j=-r+1;j<r;j++){
//    		setPicClr(0,x+i,y+j,0xff,0xff,0xff);
//    		setPicClr(1,x+i,y+j,0xff,0xff,0xff);
//    		setPicClr(2,x+i,y+j,0xff,0xff,0xff);
//    		}
//    	}
//        printf("WRITE status:%x\n",(uint)XAxiVdma_GetStatus(&vdma,XAXIVDMA_WRITE));
//        printf("READ status:%x\n",(uint)XAxiVdma_GetStatus(&vdma,XAXIVDMA_READ));
//        sleep(1);
    }
    print("Hello World\n\r");

    cleanup_platform();
    return 0;
}
