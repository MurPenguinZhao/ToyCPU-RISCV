`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 18:01:45
// Design Name: 
// Module Name: FORWARDING
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


module FORWARDING(
    input rst,
    input wire [1:0] IDEX_RegWrite,
    input wire EXMEM_RegWrite,
    input wire MEMWB_RegWrite,
    input wire IDEX_mem_write, //
    input wire IDEX_alu_src_a,
    input wire IDEX_alu_src_b,
    input wire [4:0] IDEX_RegisterRd, //
    input wire [4:0] EXMEM_RegisterRd,
    input wire [4:0] MEMWB_RegisterRd,
    input wire [4:0] IDEX_RegisterRs1,
    input wire [4:0] IDEX_RegisterRs2,
    input wire [4:0] EXMEM_RegisterRs2,
    input wire MEMWB_mem_to_reg,
    input wire zero,
    input wire branch,
    input wire jump,
    
    output wire [1:0] ForwardA,
    output wire [1:0] ForwardB,
    output wire ForwardPC,
    
    input wire [31:0] IFID_inst,
    input wire [31:0] IDEX_inst,
    input wire [31:0] EXM_inst,
    input wire [31:0] MWB_inst,
    input wire Forward_branch,
    input wire [4:0] Forward_RegisterRd_3,
    input wire [4:0] Forward_RegisterRd_2,
    input wire [4:0] Forward_RegisterRd,
    input wire [4:0] Forward_RegisterRs1,
    input wire [4:0] Forward_RegisterRs2,
    output wire Forward_b_A,
    output wire Forward_b_B,
    output wire Forward_b_A_2,
    output wire Forward_b_B_2,
    output wire Forward_b_A_3,
    output wire Forward_b_B_3,

    output wire Forward_ram,

    output wire Forward_ram_writeEXM,
    output wire Forward_ram_writeMWB,

    output wire Extreme_HarzardA,
    output wire Extreme_HarzardB,

    output wire Forward_LoadSave,

    output wire Forward_LoadBranch
    );

    //initial begin
        //ForwardA <= 2'b00;
        //ForwardB <= 2'b00;
        //ForwardPC <= 1'b0;
    //end
    
    //always@(*) begin      
        //if(rst == 1) begin
            //ForwardA <= 2'b00;
            //ForwardB <= 2'b00;
            //ForwardPC <= 1'b0;        
        //end  
        
        //else begin
        
            //if((EXMEM_RegWrite == 1) && (EXMEM_RegisterRd != 0) && (EXMEM_RegisterRd == IDEX_RegisterRs1) && (IDEX_alu_src_a == 1)) begin
                //ForwardA <= 2'b10;
                //ForwardB <= 2'b00;
            //end
            //else begin
                //ForwardA <= 2'b00;
            //end
        
            //if((EXMEM_RegWrite == 1) && (EXMEM_RegisterRd != 0) && (EXMEM_RegisterRd == IDEX_RegisterRs2) && (IDEX_alu_src_b == 0)) begin
                //ForwardA <= 2'b00;
                //ForwardB <= 2'b10;
            //end
            //else begin
                //ForwardB <= 2'b00;
            //end
        
            //if((MEMWB_RegWrite == 1) && (MEMWB_RegisterRd != 0) && (MEMWB_RegisterRd == IDEX_RegisterRs1) && (IDEX_alu_src_a == 1)) begin
                //ForwardA <= 2'b01;
                //ForwardB <= 2'b00;
            //end
            //else begin
                //ForwardA <= 2'b00;
            //end
        
            //if((MEMWB_RegWrite == 1) && (MEMWB_RegisterRd != 0) && (MEMWB_RegisterRd == IDEX_RegisterRs2) && (IDEX_alu_src_b == 0)) begin
                //ForwardA <= 2'b00;
                //ForwardB <= 2'b01;
            //end
            //else begin
                //ForwardB <= 2'b00;
            //end
        
            //mimd that there still has ld inst's foewarding that needs to complete
            //if(EXMEM_mem_to_reg == 1 && (EXMEM_RegisterRd == IDEX_RegisterRs2)) begin
                //ForwardA <= 2'b00;
                //ForwardB <= 2'b11;
            //end
            //else begin
                //ForwardB <= 2'b00;
            //end
        
            //if(EXMEM_mem_to_reg == 1 && (EXMEM_RegisterRd == IDEX_RegisterRs1)) begin
                //ForwardA <= 2'b00;
                //ForwardA <= 2'b11;
            //end
            //else begin
                //ForwardA <= 2'b0;
            //end
        
            //if(branch == 1 || jump == 1) begin
                //ForwardPC <= 1'b1;
            //end
            //else begin
                //ForwardPC <= 1'b0;
            //end
        
        //end
     
    //end    
    wire flag;
    // assign flag = (IDEX_inst != 32'h00000013 && EXM_inst != 32'h00000013 && MWB_inst != 32'h00000013) &&(IDEX_inst[7:0] != 7'b1101111 && EXM_inst[7:0] != 7'b1101111 && MWB_inst[7:0] != 7'b1101111); 
    assign flag = (IDEX_inst[7:0] != 7'b1101111 && EXM_inst[7:0] != 7'b1101111); 
    assign ForwardPC = (branch && zero) || jump;
    assign Forward_LoadSave = (IDEX_inst[6:0] == 7'b0100011) && MEMWB_mem_to_reg == 1 && (MEMWB_RegisterRd == IDEX_RegisterRs2);
    assign ForwardA = {((EXMEM_RegWrite == 1) && (EXMEM_RegisterRd != 0) && (EXMEM_RegisterRd == IDEX_RegisterRs1) && (IDEX_alu_src_a == 1)) || (IDEX_inst[6:0] != 7'b0100011 && MEMWB_mem_to_reg == 1 && (MEMWB_RegisterRd == IDEX_RegisterRs1)),
                       ((MEMWB_RegWrite == 1) && (MEMWB_RegisterRd != 0) && (MEMWB_RegisterRd == IDEX_RegisterRs1) && (IDEX_alu_src_a == 1)) || (IDEX_inst[6:0] != 7'b0100011 && MEMWB_mem_to_reg == 1 && (MEMWB_RegisterRd == IDEX_RegisterRs1))};
    assign ForwardB = {((EXMEM_RegWrite == 1) && (EXMEM_RegisterRd != 0) && (EXMEM_RegisterRd == IDEX_RegisterRs2) && (IDEX_alu_src_b == 0)) || (IDEX_inst[6:0] != 7'b0100011 && MEMWB_mem_to_reg == 1 && (MEMWB_RegisterRd == IDEX_RegisterRs2)),
                       ((MEMWB_RegWrite == 1) && (MEMWB_RegisterRd != 0) && (MEMWB_RegisterRd == IDEX_RegisterRs2) && (IDEX_alu_src_b == 0)) || (IDEX_inst[6:0] != 7'b0100011 && MEMWB_mem_to_reg == 1 && (MEMWB_RegisterRd == IDEX_RegisterRs2))};
    assign Forward_b_A = Forward_branch & (Forward_RegisterRd == Forward_RegisterRs1) && flag && IDEX_inst[6:0] != 7'b0000011;
    assign Forward_b_B = Forward_branch & (Forward_RegisterRd == Forward_RegisterRs2) && flag && IDEX_inst[6:0] != 7'b0000011;

    assign Forward_b_A_2 = Forward_branch & (Forward_RegisterRd_2 == Forward_RegisterRs1) && flag && EXM_inst[6:0] != 7'b0000011;
    assign Forward_b_B_2 = Forward_branch & (Forward_RegisterRd_2 == Forward_RegisterRs2) && flag && EXM_inst[6:0] != 7'b0000011;

    assign Forward_b_A_3 = Forward_branch & (Forward_RegisterRd_3 ==Forward_RegisterRs1) && flag && MWB_inst[6:0] != 7'b0000011;
    assign Forward_b_B_3 = Forward_branch & (Forward_RegisterRd_3 ==Forward_RegisterRs2) && flag && MWB_inst[6:0] != 7'b0000011;

    assign Forward_ram = (EXMEM_RegisterRd == IDEX_RegisterRs1);

    assign Forward_ram_writeEXM = (IDEX_mem_write == 1 && IDEX_RegisterRs2 == EXMEM_RegisterRd && EXM_inst[6:0] != 7'b0100011 && EXM_inst[6:0] !=7'b1100011);
    assign Forward_ram_writeMWB = (IDEX_mem_write == 1 && IDEX_RegisterRs2 == MEMWB_RegisterRd && MWB_inst[6:0] != 7'b0100011 && MWB_inst[6:0] !=7'b1100011);

    assign Extreme_HarzardA = (IDEX_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011 && IDEX_RegWrite[0] == 1 && Forward_RegisterRd == Forward_RegisterRs1);
    assign Extreme_HarzardB = (IDEX_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011 && IDEX_RegWrite[0] == 1 && Forward_RegisterRd == Forward_RegisterRs2);

    assign Forward_LoadBranch = (Forward_RegisterRs1 == Forward_RegisterRd && IDEX_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011) || (Forward_RegisterRs1 == Forward_RegisterRd_2 && EXM_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011) || (Forward_RegisterRs1 == Forward_RegisterRd_3 && MWB_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011) || 
                                (Forward_RegisterRs2 == Forward_RegisterRd && IDEX_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011) || (Forward_RegisterRs2 == Forward_RegisterRd_2 && EXM_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011) || (Forward_RegisterRs2 == Forward_RegisterRd_3 && MWB_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011);
    //wire cond1;
        //assign cond1 = ((EXMEM_RegWrite == 1) && (EXMEM_RegisterRd != 0) && (EXMEM_RegisterRd == IDEX_RegisterRs1) && (IDEX_alu_src_a == 1)) || (EXMEM_mem_to_reg == 1 && (EXMEM_RegisterRd == IDEX_RegisterRs1));
    //wire cond2;
        //assign cond2 = ((MEMWB_RegWrite == 1) && (MEMWB_RegisterRd != 0) && (MEMWB_RegisterRd == IDEX_RegisterRs1) && (IDEX_alu_src_a == 1)) || (EXMEM_mem_to_reg == 1 && (EXMEM_RegisterRd == IDEX_RegisterRs1));
    //wire cond3;
        //assign cond3 = (IDEX_alu_src_b == 0);
    //wire cond4;
        //assign cond4 = (MEMWB_RegWrite == 1) && (MEMWB_RegisterRd != 0) && (MEMWB_RegisterRd == IDEX_RegisterRs2) && (IDEX_alu_src_b == 0);
endmodule

