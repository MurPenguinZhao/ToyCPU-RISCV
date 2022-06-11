`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 18:03:13
// Design Name: 
// Module Name: STALL
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


module STALL(
    input wire clk,
    input wire rst,
    input wire EXMEM_mem_to_reg,
    input wire [4:0] EXMEM_RegisterRd,
    input wire [4:0] IDEX_RegisterRs1,
    input wire [4:0] IDEX_RegisterRs2,
    input wire branch,
    input wire jump,
    
    input [31:0] IFID_inst,
    input [31:0] IDEX_inst,

    output wire stall_req,
    output reg [1:0] stall_count
    );
    //always@(*) begin
        //if(rst == 1) begin
            //stall_req <= 1'b0;
        //end     
        //else begin
            //if(branch == 1 || jump == 1) begin
                //stall_req <= 2'b10;
            //end
            //if(EXMEM_mem_to_reg == 1 && (EXMEM_RegisterRd == IDEX_RegisterRs1 || EXMEM_RegisterRd == IDEX_RegisterRs2)) begin
                //stall_req <= 1'b1;
            //end
            //else stall_req <= 1'b0;
        //end
    //end
    
    assign stall_req = (EXMEM_mem_to_reg == 1 && (EXMEM_RegisterRd == IDEX_RegisterRs1 || EXMEM_RegisterRd == IDEX_RegisterRs2));
    
    always@(*) begin
        if(rst == 0) stall_count <= 0;
        else begin
        if(EXMEM_mem_to_reg == 1 && (EXMEM_RegisterRd == IDEX_RegisterRs1 || EXMEM_RegisterRd == IDEX_RegisterRs2))
            stall_count <= 2'b01;
        else if((IFID_inst[6:0] == 7'b1110011 && IDEX_inst[6:0] == 1)) // unfinished
            stall_count <= 2'b11;
        end
    end
endmodule

