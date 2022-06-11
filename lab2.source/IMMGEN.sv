`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 18:02:16
// Design Name: 
// Module Name: IMMGEN
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


module IMMGEN(
    input [31:0] inst,
    input [2:0] ext_op,
    output reg [31:0] imm
    );

    reg [6:0] ins;
    always@(*) begin
        ins <= inst[6:0];
     end
     
     always@(*) begin
        case(ext_op)
            3'b000: begin // ori lw immI
                imm <= {{20{inst[31]}} , inst[31:20]};
            end
            
            3'b001: begin // lui,auipc immU 
                imm <= {inst[31:12], 12'b0};
            end
            
            3'b010: begin // sw immS
                if(ins == 7'b0100011) begin
                imm <= {{20{inst[31]}},inst[31:25], inst[11:7]};
                end
                else if(ins == 7'b0000011) begin
                imm <= {{20{inst[31]}}, inst[31:20]};
                end
            end
            
            3'b011: begin // beq immB
                imm <= {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            end
            
            3'b100: begin // jal immJ
                imm <= {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; // the process of left shifting has been conpleted
            end
            
            3'b101: begin // jalr immJ
                if(inst[31] == 1) imm <= {20'hffff, inst[31:20]};
                else imm <= {20'h0000, inst[31:20]};
            end
                        
            default: begin
            end
        
        endcase
    end
       
endmodule

