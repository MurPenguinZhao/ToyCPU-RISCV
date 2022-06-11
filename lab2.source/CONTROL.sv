`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 18:07:49
// Design Name: 
// Module Name: CONTROL
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


module CONTROL(
    input clk, 
    input rst,
    input [6:0] op_code,
    input [2:0] funct3,
    input funct7_5,
    input [11:0] funct12,
    
    output reg [1:0] pc_src,
    output reg [1:0] reg_write,
    output reg alu_src_b,
    output reg alu_src_a,
    output reg [3:0] alu_op,
    output reg mem_to_reg,
    output reg mem_write,
    output reg branch,
    output reg jump,
    output reg b_type,
    output reg [2:0] ExtOp,
    output reg cache_req_valid
    );
    
    always @ (*) begin
        if(rst == 1) begin
            //pc_src <= 0;    
            reg_write <= 0;
            alu_src_a <= 0;
            alu_src_b <= 0;
            alu_op <= 0;
            mem_to_reg <= 0;
            mem_write <= 0;
            branch <= 0;
            jump <= 0;
            b_type <= 0;
            ExtOp <= 0;
            pc_src <= 0;
            cache_req_valid <= 0;
        end
        else begin
            case(op_code)
                //R
                7'b0110011: begin reg_write <= 2'b01; mem_to_reg <= 1'b0; alu_src_a <= 1;  alu_src_b <= 0; mem_write <= 0; branch <= 0; jump <= 0;  ExtOp <= 3'b000; b_type <= 0;alu_op <= {funct7_5, funct3}; pc_src <= 2'b00; cache_req_valid <= 1'b0; end
                //I
                7'b0010011: begin reg_write <= 2'b01; mem_to_reg <= 1'b0; alu_src_a <= 1; alu_src_b <= 1; mem_write <= 0; branch <= 0; jump <= 0; ExtOp <= 3'b000; b_type <= 0;alu_op <= {1'b0, funct3}; pc_src <= 2'b00; cache_req_valid <= 1'b0;end
                //S
                7'b0100011: begin reg_write <= 2'b00; mem_to_reg <= 1'b0; alu_src_a <= 1; alu_src_b <= 1; mem_write <= 1; branch <= 0; jump <= 0; ExtOp <= 3'b010; b_type <= 0;alu_op <= 4'b0000; pc_src <= 2'b00; cache_req_valid <= 1'b1; end
                //L
                7'b0000011: begin reg_write <= 2'b01; mem_to_reg <= 1'b1; alu_src_a <= 1; alu_src_b <= 1; mem_write <= 0; branch <= 0; jump <= 0; ExtOp <= 3'b010; b_type <= 0;alu_op <= 4'b0000; pc_src <= 2'b00; cache_req_valid <= 1'b1; end
                //B
                7'b1100011: begin reg_write <= 2'b00; mem_to_reg <= 1'b0; alu_src_a <= 1; alu_src_b <= 0; mem_write <= 0; branch <= 1; jump <= 0; ExtOp <= 3'b011; b_type <= funct3;alu_op <= {funct7_5, funct3}; pc_src <= 2'b00; cache_req_valid <= 1'b0;end
                //JAL
                7'b1101111: begin reg_write <= 2'b11; mem_to_reg <= 1'b0; alu_src_a <= 0; alu_src_b <= 0; mem_write <= 0; branch <= 1; jump <= 1; ExtOp <= 3'b100; b_type <= 1;alu_op <= {4'b0000}; pc_src <= 2'b00; cache_req_valid <= 1'b0;end
                //JALR
                7'b1100111: begin reg_write <= 2'b11; mem_to_reg <= 1'b0; alu_src_a <= 1; alu_src_b <= 0; mem_write <= 0; branch <= 1; jump <= 1; ExtOp <= 3'b101; b_type <= 1;alu_op <= {1'b0, funct3}; pc_src <= 2'b10; cache_req_valid <= 1'b0;end
                //U
                7'b0110111: begin reg_write <= 2'b01; mem_to_reg <= 1'b0; alu_src_a <= 1; alu_src_b <= 1; mem_write <= 0; branch <= 0; jump <= 0; ExtOp <= 3'b001; b_type <= 0;alu_op <= 4'b1111; pc_src <= 2'b00; cache_req_valid <= 1'b0;end //lui
                7'b0010111: begin reg_write <= 2'b01; mem_to_reg <= 1'b0; alu_src_a <= 0; alu_src_b <= 1; mem_write <= 0; branch <= 0; jump <= 0; ExtOp <= 3'b001; b_type <=0; alu_op <= 4'b0000; pc_src <= 2'b00; cache_req_valid <= 1'b0;end //auipc
                //CSR
                7'b1110011: begin
                    if(funct12 == 12'h302) begin //mret
                        
                    end
                    else begin 
                        case(funct3)
                            3'b000: begin //ECALL

                            end
                            3'b001: begin //CSRW
                                reg_write <= 2'b00; mem_to_reg <= 1'b0; alu_src_a <= 1'b1; alu_src_b <= 1'b0; mem_write <= 1'b0; branch <= 1'b0; jump <= 1'b0; ExtOp <= 3'b000; b_type <= 0; alu_op <= 4'b1001; pc_src <= 2'b00;
                            end
                            3'b010: begin //CSRR
                                reg_write <= 2'b01; mem_to_reg <= 1'b0; alu_src_a <= 1'b1; alu_src_b <= 1'b0; mem_write <= 1'b0; branch <= 1'b0; jump <= 1'b0; ExtOp <= 3'b000; b_type <= 0; alu_op <= 4'b1001; pc_src <= 2'b00;
                            end
                        endcase
                    end
                end
            endcase
        end
    end

endmodule


