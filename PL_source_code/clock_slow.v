`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2019 02:57:28 PM
// Design Name: 
// Module Name: clock_slow
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


module clk_slow(clk_in, clk_48khz, clk_3052khz);
   input      clk_in;
   output     clk_48khz;
//   output     clk_no48khz;
   output     clk_3052khz;
  
   wire       clk_sig;
   reg [18:0] clk_cntr;
   
   
   always @(posedge clk_in)
   begin: count
         clk_cntr <= (clk_cntr + 1);
   end
   assign clk_48khz = clk_cntr[9];
//  assign clk_no48khz = clk_cntr[18];
   assign clk_3052khz = clk_cntr[3];
   
endmodule

