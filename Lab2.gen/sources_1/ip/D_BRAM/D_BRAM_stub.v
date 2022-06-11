// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
// Date        : Thu Mar 31 22:07:20 2022
// Host        : DESKTOP-GFOO3VP running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/Study_in_2022_Spring/Computer_System/Lab_Project/Lab2/Lab2.gen/sources_1/ip/D_BRAM/D_BRAM_stub.v
// Design      : D_BRAM
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-3
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2021.2" *)
module D_BRAM(clka, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[12:0],dina[31:0],douta[31:0]" */;
  input clka;
  input [0:0]wea;
  input [12:0]addra;
  input [31:0]dina;
  output [31:0]douta;
endmodule
