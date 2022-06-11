`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/27 11:14:02
// Design Name: 
// Module Name: D_CACHE
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


module D_CACHE(
    input cpu_clk,
    input mem_clk,
    input rst,
    input [31:0] cur_pc,
///////////////////////////////////////////SCPU
    input [31:0] cache_req_addr,
    input [31:0] cache_req_data,
    input cache_req_wen,
    input cache_req_valid,
    
    output reg [31:0] cache_resp_data,
    output     cache_resp_stall_d,
//////////////////////////////////////////MEMORY
    output reg [31:0] mem_req_addr,
    output reg [31:0] mem_req_data,
    output reg mem_req_wen,
    output reg mem_req_valid,
    
    input [31:0] mem_resp_data,
    input mem_resp_valid,
//////////////////////////////////////////CACHE
    output reg [39:0] cache_memory_output [0:511]
    );
    integer i;
    reg [39:0] cache_memory [0:511]; //offset tag dirty valid data
    reg [31:0] cache_pc;
    reg [2:0] cache_state;  
    parameter
    S_IDLE = 3'b000,
    S_BACK = 3'b001,
    S_BACK_WAIT = 3'b010,
    S_FILL = 3'b011,
    S_FILL_WAIT = 3'b100; 
    
    wire cache_write; 
    wire [5:0] tag;
    wire dirty, valid;
    // wire [8:0] index;
    wire [8:0] index;
    // assign index = cache_req_addr[8:0];
    assign index = {cache_req_addr[6:0], 2'b00};
    // assign tag = cache_memory[index][37:34];
    assign tag = cache_memory[index][39:34];
    assign dirty = cache_memory[index][33];
    assign valid = cache_memory[index][32];
    assign cache_write = ((tag == cache_req_addr[12:7] || valid == 0) && cache_req_wen && cache_req_valid);
////////////////////////////////////////
//Cache Control Unit//////////////////////////////////////////////////////////////////
always@(posedge cpu_clk or posedge rst) begin
    if(rst == 1) begin
        for(i = 0; i < 512; i = i + 1) begin
            cache_memory[i] <= 0;
        end
        cache_resp_data <= 0;
        // cache_resp_stall <= 0;
        mem_req_addr <= 0;
        mem_req_data <= 0;
        mem_req_wen <= 0;
        mem_req_valid <= 0;

        cache_state <= S_IDLE;
        cache_pc <= 0;
    end
    else begin
        // if(cache_req_addr[12:9] == tag && dirty == 0 && cache_req_valid == 1)
        // begin
        //     cache_state <= S_IDLE;
            
        //     if(cache_write == 1) begin
        //         cache_memory[cache_req_addr[8:0]][37:34] <= cache_req_addr[12:9];
        //         cache_memory[cache_req_addr[8:0]][33] <= 1;
        //         cache_memory[cache_req_addr[8:0]][32] <= 1;
        //         cache_memory[cache_req_addr[8:0]][31:0] <= cache_req_data;
        //     end
        //     if(valid == 1) begin
        //         cache_resp_data <= cache_memory[index][31:0];
        //     end
        // end

        // S_IDLE
        // if(cache_state == S_IDLE) begin
        //     if(cache_pc != cur_pc || cache_pc == 0) begin
        //         // cache read
        //         cache_pc <= cur_pc;
        //         if(cache_req_wen == 0 && cache_req_valid == 1) begin
        //             if(cache_req_addr[12:9] == tag && dirty == 0 && valid == 1) begin
        //                 cache_resp_data <= cache_memory[index][31:0];
        //             end
        //             // else if(cache_req_addr[12:9] != tag && dirty == 1 && valid == 1) begin
        //             //     cache_state <= S_BACK;
        //             // end
        //             else if((cache_req_addr[12:9] != tag && dirty == 0 && valid == 1) || valid == 0) begin
        //                 cache_state <= S_FILL;
        //             end
        //         end 
        //         // cache write
        //         if(cache_req_wen == 1 && cache_req_valid == 1) begin
        //             if(cache_write == 1 && cache_req_addr[12:9] == tag && dirty == 0) begin
        //                 cache_memory[cache_req_addr[8:0]][37:34] <= cache_req_addr[12:9];
        //                 cache_memory[cache_req_addr[8:0]][33] <= 1;
        //                 cache_memory[cache_req_addr[8:0]][32] <= 1;
        //                 cache_memory[cache_req_addr[8:0]][31:0] <= cache_req_data;                   
        //             end
        //             else if(cache_write == 1 && cache_req_addr[12:9] == tag && dirty == 1) begin
        //                 cache_state <= S_BACK;
        //             end
        //         end
        //     end
        // end
        if(cache_state == S_IDLE) begin
            if(cache_req_wen == 0 && cache_req_valid == 1 && cache_req_addr[12:9] == tag && valid == 1) begin
                cache_resp_data <= cache_memory[index][31:0];
            end
            if(cache_req_wen == 1 && cache_req_valid == 1 && cache_write == 1 && dirty == 0) begin
                // cache_memory[cache_req_addr[8:0]][37:34] <= cache_req_addr[12:9];
                // cache_memory[cache_req_addr[8:0]][33] <= 1;
                // cache_memory[cache_req_addr[8:0]][32] <= 1;
                // cache_memory[cache_req_addr[8:0]][31:0] <= cache_req_data; 
                cache_memory[index][39:34] <= cache_req_addr[12:7];
                cache_memory[index][33] <= 1;
                cache_memory[index][32] <= 1;
                cache_memory[index][31:0] <= cache_req_data;                                   
            end
            else begin
                if(cache_pc != cur_pc || cache_pc == 0) begin
                    cache_pc <= cur_pc;
                    if(cache_req_wen == 0 && cache_req_valid == 1) begin
                        if((cache_req_addr[12:7] != tag && dirty == 0 && valid == 1) || valid == 0)
                            cache_state <= S_FILL;
                        else if(cache_req_addr[12:7] != tag && dirty == 1 && valid == 1)
                            cache_state <= S_BACK;
                    end
                    if(cache_req_wen == 1 && cache_req_valid == 1) begin
                        // if(cache_write == 1 && cache_req_addr[12:9] == tag && dirty == 0) begin
                        //     cache_memory[cache_req_addr[8:0]][37:34] <= cache_req_addr[12:9];
                        //     cache_memory[cache_req_addr[8:0]][33] <= 1;
                        //     cache_memory[cache_req_addr[8:0]][32] <= 1;
                        //     cache_memory[cache_req_addr[8:0]][31:0] <= cache_req_data;                   
                        // end
                        if(cache_req_addr[12:7] != tag && dirty == 1) begin
                            cache_state <= S_BACK;
                        end
                    end
                end
            end
        end

        // S_BACK
        // if(cache_state == S_IDLE && cache_req_addr[12:9] != tag && dirty == 1 && cache_req_valid == 1)
        // begin
        //     cache_state <= S_BACK;
            
        //     mem_req_valid <= 1;
        //     mem_req_wen <= 1;
        //     mem_req_data <= cache_memory[cache_req_addr[8:0]][31:0];
        //     mem_req_addr <= cache_req_addr;

        //     cache_memory[index][33] <= 1'b0;
        // end
        if(cache_state == S_BACK) begin
            mem_req_valid <= 1;
            mem_req_wen <= 1;
            mem_req_data <= cache_memory[index][31:0];
            mem_req_addr <= {19'b0000000000000000000, tag, cache_req_addr[6:0]};

            cache_state <= S_BACK_WAIT;
            cache_pc <= cache_pc;
        end

        // S_BACK_WAIT
        if(cache_state == S_BACK_WAIT) begin
            if(mem_resp_valid == 1) begin
                mem_req_valid <= 0;
                cache_state <= S_FILL;
                cache_memory[index][33] <= 0;
                cache_memory[index][32] <= 0;

                if(cache_req_wen == 1)
                    cache_state <= S_IDLE;
                else 
                    cache_state <= S_FILL;
                cache_pc <= cache_pc;
            end
            // cache_resp_stall <= 1;
        end
        
        // S_FILL
        // if((cache_state == S_IDLE && cache_req_addr[12:9] != tag && dirty == 0 && cache_req_valid == 1) || cache_state == S_FILL)
        // begin
        //     cache_state <= S_FILL;
            
        //     mem_req_valid <= 1;
        //     mem_req_wen <= 0;
        //     mem_req_addr <= cache_req_addr;
        //     // cache_resp_stall <= 1;
        // end
        if(cache_state == S_FILL) begin
            mem_req_valid <= 1;
            mem_req_wen <= 0;
            mem_req_addr <= cache_req_addr;

            cache_state <= S_FILL_WAIT;
            cache_pc <= cache_pc;
        end

        // S_FILL_WAIT
        // if(cache_state == S_FILL) begin
        //     if(mem_resp_valid == 1) begin
        //         cache_memory[index][37:34] <= cache_req_addr[12:9];
        //         cache_memory[index][33] <= 0;
        //         cache_memory[index][21] <= 1;
        //         cache_memory[index][31:0] <= mem_resp_data;
                
        //         cache_state <= S_IDLE;
        //     end
        // end
        if(cache_state == S_FILL_WAIT) begin
            if(mem_resp_valid == 1) begin
                // cache_memory[index][37:34] <= cache_req_addr[12:9];
                cache_memory[index][39:34] <= cache_req_addr[12:7];               
                cache_memory[index][33] <= 0; // dirty 位讲道理是 0 什么时候改成1的? 改掉之后没有问题
                cache_memory[index][32] <= 1;
                cache_memory[index][31:0] <= mem_resp_data;

                mem_req_valid <= 0;
                cache_state <= S_IDLE; 
                cache_pc <= cache_pc;              
            end
        end
    end
end

    assign cache_resp_stall_d = (cache_state == S_IDLE) ? 0 : 1;
//////////////////////////////////////////////////////////////////////////////////////
    integer j;
    always @ (*) begin
        for(j = 0; j < 512; j = j + 1) begin
            cache_memory_output[j] = cache_memory[j];
        end
    end
//////////////////////////////////////////////////////////////////////////////////////
endmodule
