`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/24 11:03:29
// Design Name: 
// Module Name: D_MEMORY
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


module D_MEMORY(
    input cpu_clk,
    input mem_clk,
    input rst,

    input [31:0] mem_req_addr,
    input [31:0] mem_req_data,
    input mem_req_wen,
    input mem_req_valid,

    output [31:0] mem_resp_data,
    output reg mem_resp_valid //注意时序
    );

    wire mem_write;
    assign mem_write = mem_req_wen && mem_req_valid;
    // assign mem_req_data =  mem_req_valid == 1 ? mem_req_addr : 32'h00000000;
    // always @ (posedge cpu_clk or posedge rst or posedge mem_clk) begin
    //     if(rst == 1) begin
    //         mem_resp_valid <= 0;
    //     end
    //     else begin
    //         if(mem_clk == 1)
    //             mem_resp_valid <= mem_req_valid;
    //         else
    //             mem_resp_valid <= 0;
    //     end
    // end
    
    reg resp_flag;
    always @ (posedge mem_clk or posedge rst or posedge mem_resp_valid) begin
        if(rst == 1) begin
            resp_flag <= 0;
        end
        else begin
            // if(mem_req_valid == 1) resp_flag <= 1;
            // else if(mem_resp_valid == 1) resp_flag <= 0;
            if(mem_resp_valid == 1) resp_flag <= 0;
            else begin
                if(mem_resp_valid == 0) resp_flag <= 1;
            end               
        end
    end
    
    always @ (posedge cpu_clk or posedge rst) begin
        if(rst == 1) begin
            mem_resp_valid <= 0;
        end
        else begin
            if(resp_flag == 1) begin
                mem_resp_valid <= 1;
                // resp_flag <= 0;
            end
            else begin
                mem_resp_valid <= 0;
            end
        end
    end

    D_BRAM Data_memory(
        .addra(mem_req_addr),
        .clka(mem_clk),
        .dina(mem_req_data),
        .douta(mem_resp_data),
        .wea(mem_write)
    );
endmodule