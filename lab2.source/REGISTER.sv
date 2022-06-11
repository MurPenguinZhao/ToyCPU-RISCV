`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 18:02:35
// Design Name: 
// Module Name: REGISTER
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


module REGISTER(
    input clk,
    input rst,
    input [1:0] we,
    
    input [4:0] read_addr_1,
    input [4:0] read_addr_2,
    output wire [31:0] read_data_1,
    output wire [31:0] read_data_2,
    output wire [31:0] registers[0:31],
    output wire [31:0] gp,
    
    input [4:0] write_addr,
    input [31:0] write_data
    );
    integer i, j;
    reg [31:0] register_reg [0:31];
    ////////////////////////////////////
    assign gp = register_reg[3];
    assign read_data_1 = (read_addr_1 == 0) ? 0 : register_reg[read_addr_1];
    assign read_data_2 = (read_addr_2 == 0) ? 0 : register_reg[read_addr_2];
    ////////////////////////////////////
    always@(negedge clk or posedge rst) begin
        if(rst == 1) begin
            for(i = 0; i < 32; i = i + 1) register_reg[i] <= 0;
        end
        else if(we[0] == 1 && write_addr != 0) register_reg[write_addr] <= write_data;
    end
    //////////////////////////////////
    assign registers[0] = register_reg[0];
    assign registers[1] = register_reg[1];
    assign registers[2] = register_reg[2];
    assign registers[3] = register_reg[3];
    assign registers[4] = register_reg[4];
    assign registers[5] = register_reg[5];
    assign registers[6] = register_reg[6];
    assign registers[7] = register_reg[7];
    assign registers[8] = register_reg[8];
    assign registers[9] = register_reg[9];
    assign registers[10] = register_reg[10];
    assign registers[11] = register_reg[11];
    assign registers[12] = register_reg[12];
    assign registers[13] = register_reg[13];
    assign registers[14] = register_reg[14];
    assign registers[15] = register_reg[15];
    assign registers[16] = register_reg[16];
    assign registers[17] = register_reg[17];
    assign registers[18] = register_reg[18];
    assign registers[19] = register_reg[19];
    assign registers[20] = register_reg[20];
    assign registers[21] = register_reg[21];
    assign registers[22] = register_reg[22];
    assign registers[23] = register_reg[23];
    assign registers[24] = register_reg[24];
    assign registers[25] = register_reg[25];
    assign registers[26] = register_reg[26];
    assign registers[27] = register_reg[27];
    assign registers[28] = register_reg[28];
    assign registers[29] = register_reg[29];
    assign registers[30] = register_reg[30];
    assign registers[31] = register_reg[31];

endmodule

