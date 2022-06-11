`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 18:00:08
// Design Name: 
// Module Name: CORE
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


module CORE(
    input  wire        clk,
    input  wire        aresetn,
    input  wire        step,
    input  wire        debug_mode,
    input  wire [4:0]  debug_reg_addr, 
    input  wire [8:0]  debug_cache_addr,
    
    output wire [31:0] chip_debug_out0,
    output wire [31:0] chip_debug_out1,
    output wire [31:0] chip_debug_out2,
    output wire [31:0] chip_debug_out3
    // output wire [31:0] chip_debug_out4,
    // output wire [31:0] chip_debug_out5,
    // output wire [31:0] chip_debug_out6,
    // output wire [31:0] chip_debug_out7
    );

    wire        rst, cpu_clk;
    wire        mem_clk;
    wire [31:0] inst, address, pc_out;
    wire [31:0] register [0:31];
    wire [39:0] cache_memory [0:511];
    reg  [31:0] clk_div;
    wire [31:0] gp;
    assign rst = ~aresetn;

    SCPU cpu(
        .cpu_clk(cpu_clk),
        .mem_clk(mem_clk),
        .rst(rst),
        .step(step),
        .inst(inst),
        .address(address),        
        .pc_out(pc_out),
        .register(register),
        .cache_memory(cache_memory)
    );

    always @(posedge clk) begin
        if(rst) clk_div <= 32'h00000000;
        else clk_div <= clk_div + 1;
    end
    // always @ (*) begin
    //     if(rst == 1) mem_clk <= 0;
    //     else mem_clk = ~clk_div[3]; 
    // end
    assign mem_clk = clk_div[3];
    assign cpu_clk = debug_mode ? clk_div[0] : step;
    reg [31:0] chip_debug_reg;
    
    always @(*) begin
        chip_debug_reg <= register[debug_reg_addr];
    end
    
    assign chip_debug_out0 = pc_out; // current pc 
    assign chip_debug_out1 = chip_debug_reg; // register
    assign chip_debug_out2 = cache_memory[debug_cache_addr][31:0]; //cacheline data
    assign chip_debug_out3 = {24'b00000000000000000000000000, cache_memory[debug_cache_addr][39:32]}; // cacheline 

endmodule

