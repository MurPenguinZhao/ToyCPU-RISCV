`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 18:01:00
// Design Name: 
// Module Name: CSR_CONTROL
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


module CSR_CONTROL(
    input clk,
    input rst,
    input [6:0] op_code,
    input [2:0] funct3,
    input [11:0] funct12,
    input [31:0] inst,

    output wire sys_jump,
    output wire csr_we,
    output wire alu_csr_src
    );
    // always @ (*)  begin
    //     if(rst == 1) begin
    //         sys_jump <= 0;
    //         csr_we <= 0;
    //         alu_csr_src <= 0;
    //     end
    //     else if(op_code == 7'b1110011) begin
    //         if(funct12 == 12'h302) begin //mret
    //         // the mret here nedd 
    //             sys_jump <= 1'b1; csr_we <= 1'b0; alu_csr_src <= 1'b0;
    //         end
    //         else if(inst ==  32'hc0001073) begin
    //             sys_jump <= 1'b1; csr_we <= 1'b0; alu_csr_src <= 1'b0;
    //         end
    //         else begin
    //             case(funct3)
    //                 //CSRW
    //                 3'b001: begin sys_jump <= 1'b0; csr_we <= 1'b1; alu_csr_src <= 1'b0; end
    //                 //CSRR
    //                 3'b010: begin sys_jump <= 1'b0; csr_we <= 1'b0; alu_csr_src <= 1'b1; end
    //                 //ECALL
    //                 3'b000: begin sys_jump <= 1'b1; csr_we <= 1'b0; alu_csr_src <= 1'b1; end
    //             endcase
    //         end
    //     end
    // end

    assign sys_jump = (op_code == 7'b1110011) && ((funct12 == 12'h302) || (inst == 32'hc0001073) || (funct3 == 3'b000));
    assign csr_we = (op_code == 7'b1110011) && (funct3 == 3'b001) && (inst != 32'hc0001073);
    assign alu_csr_src = (op_code == 7'b1110011) && (funct3 == 3'b010 || funct3 == 3'b000);
    // assign sys_jump = (funct12 == 12'h302) || (funct12 != 12'h302 && funct3 == 3'b000);
    // assign csr_we = (funct12 != 12'h302 && csr_we == 3'b001);
    // assign alu_csr_src = (funct12 != 12'h302) && (funct3 == 3'b010 || funct3 == 3'b000);

endmodule


