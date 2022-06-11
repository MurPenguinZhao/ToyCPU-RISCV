`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 18:01:19
// Design Name: 
// Module Name: CSR_REG
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


module CSR_REG(
    input clk,
    input rst,
    input csr_we,
    input [6:0] op_code,
    input [31:0] inst,
    input [11:0] funct12,
    input [2:0] funct3, 

    input [31:0] pc_in,
    input [31:0] write_data,
    input [11:0] write_addr,
    
    output [31:0] pc_out,
    output [31:0] read_data
    );
    // reg [31:0] csr [0:1023];
    
    reg [31:0] mtvec;
    reg [31:0] mstatus;
    reg [31:0] mepc;
    reg [31:0] mcause;
    reg [31:0] read_data_reg;


    assign read_data = read_data_reg;
    assign pc_out = (funct12 == 12'h302 && inst != 32'hc0001073) ? mepc : mtvec;

    always@(*) begin
        if(rst == 1) read_data_reg <= 0;
        else begin
            case(funct12) 
                // mstatus
                12'h300: begin read_data_reg <= mstatus; end
                // mtvec
                12'h305: begin read_data_reg <= mtvec; end
                // mepc
                12'h341: begin read_data_reg <= mepc; end
                // mcause
                12'h342: begin read_data_reg <= mcause; end                
            endcase
        end
    end

    // always@(*) begin  //
    //     case(funct12)
    //         // mstatus
    //         12'h300: begin mstatus <= write_data; end
    //         // mtvec
    //         12'h305: begin mtvec <= write_data; end
    //         // mepc
    //         12'h341: begin mepc <= write_data; end
    //         // mcause
    //         12'h342: begin mcause <= write_data; end
    //     endcase       
    // end 

    always @ (negedge clk or posedge rst) begin
        if(rst == 1) begin
            mtvec <= 0;
            mstatus <= 0;
            mepc <= 0;
            mcause <= 0;
        end
        else begin
            if(op_code == 7'b1110011 && funct3 == 3'b000 && funct12 != 12'h302) begin //ECALL
                mstatus <= mstatus | 32'h00001000;
                mepc <= pc_in;
                mcause <= 32'h0000000b;
            end
            else if(inst == 32'hc0001073) begin//UNIMP
                mstatus <= mstatus | 32'h00001000;
                mepc <= pc_in;
                mcause <= 32'h00000002;                
            end
            else if(funct12 == 12'h302) begin //MRET
                mstatus <= mstatus & 32'hffffefff;
            end
            else if(csr_we == 1) begin //csr[funct12] <= write_data;
                case(write_addr)
                    // mstatus
                    12'h300: begin mstatus <= write_data; end
                    // mtvec
                    12'h305: begin mtvec <= write_data; end
                    // mepc
                    12'h341: begin mepc <= write_data; end
                    // mcause
                    // 12'h342: begin mcause <= write_data; end
                endcase
            end    
        end
    end

endmodule

