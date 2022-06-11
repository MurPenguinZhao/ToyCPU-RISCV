`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 18:02:55
// Design Name: 
// Module Name: SCPU
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
    module SCPU(
    input         cpu_clk,
    input         mem_clk,
    input         rst,
    input         step,
    output [31:0] inst,
    output [31:0] pc_out,   // connect to instruction memory
    output [31:0] address, // data memory address
    output [31:0] register [0:31],
    output [39:0] cache_memory [0:511]
    );
    //////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////

    //Control lines
    wire [1:0] reg_write;
    wire alu_src_a;
    wire alu_src_b;
    wire alu_csr_src; //
    wire [3:0] alu_op;
    wire mem_to_reg;
    wire mem_write;
    wire branch;
    wire jump;
    wire [2:0] ExtOp;
    wire sys_jump; //
    wire csr_we; //
    
    //registers in IFID segment////////////////////////////////////////
    reg [31:0]  IFID_pc;
    reg [31:0]  IFID_pc_add_4;
    reg [31:0]  IFID_inst;
    //registers in IDEX segment////////////////////////////////////////
    reg [31:0]  IDEX_inst;
    reg [4:0]   IDEX_RegisterRs1;
    reg [4:0]   IDEX_RegisterRs2;
    reg [31:0]  IDEX_data_a;
    reg [31:0]  IDEX_data_b;
    reg [4:0]   IDEX_reg_addr;
    reg         IDEX_mem_to_reg; 
    reg [31:0]  IDEX_imm;
    reg [1:0]   IDEX_reg_write;
    reg [31:0]  IDEX_pc;
    reg [31:0]  IDEX_pc_add_4;
    reg [31:0]  IDEX_data_csr;
    reg [11:0]  IDEX_funct12;
    reg         IDEX_cache_req_valid;
    //EX
    //reg         IDEX_ForwardPC;
    reg [3:0]   IDEX_alu_op;
    reg         IDEX_alu_src_a;
    reg [1:0]   IDEX_alu_src_b;
    reg         IDEX_alu_csr_src;
    reg [3:0]   IDEX_alu_control;
    reg         IDEX_zero;
    //M
    reg         IDEX_mem_write;
    reg         IDEX_branch;
    reg         IDEX_jump;
    reg         IDEX_b_type;
    reg [1:0]   IDEX_pc_src;   
    //WB
    reg         IDEX_csr_we;
    //registers in EXM segment///////////////////////////////////////
    reg [31:0]  EXM_pc;
    reg [31:0]  EXM_inst;
    reg         EXM_mem_to_reg;
    reg [31:0]  EXM_pc_branch;
    reg [31:0]  EXM_result;
    reg [1:0]   EXM_reg_write;
    reg [4:0]   EXM_reg_addr;    
    reg [31:0]  EXM_ram_data;
    reg [31:0]  EXM_pc_add_4;
    reg         EXM_mem_write;
    reg [1:0]   EXM_pc_src;
    reg [4:0]   EXM_RegisterRs2;  
    reg         EXM_csr_we;
    reg [11:0]  EXM_funct12;
    reg         EXM_cache_req_valid;
    //registers in MWB segment///////////////////////////////////////
    reg [31:0]  MWB_inst;
    wire [1:0]  MWB_pc_src; //register in the MWB;
    reg [4:0]   MWB_reg_addr;
    reg [1:0]   MWB_reg_write;
    reg [31:0]  MWB_read_data;
    reg [31:0]  MWB_result;
    reg [31:0]  MWB_ram_data;
    reg         MWB_mem_to_reg;
    reg [31:0]  MWB_pc_add_4;
    reg         MWB_csr_we;
    reg [11:0]  MWB_funct12;
    //////////////////////////////////////////
    reg [31:0]  Extra_Data;

    //registers in stall 
    wire stall_req;
    //registers in forwarding
    reg ForwardPC;
    wire Forward_b_A, Forward_b_B;
    wire Forward_ram_writeEXM, Forward_ram_writeMWB;
    wire Extreme_HarzardA, Extreme_HarzardB;
    wire Extreme_Harzard;
    wire Forward_LoadSave;
    wire Forward_LoadBranch;
    wire Stall_FromCache_D;
    wire Stall_FromCache_I;
    reg stall_cache;
    reg [31:0] Target_pc;

    wire cache_req_valid;
    //Instruction Fetch///////////////////////////////////////////////////////
    reg [31:0]  if_4_reg;
    reg [1:0]   pc_src; //signal in the IF

    wire [31:0] cur_pc;
    wire [31:0] sys_pc;
    wire [31:0] ex_5;
    wire [31:0] if_1, if_2, if_3;
    wire [31:0] wb_1, wb_2, wb_6; //the write back wire is set there
    wire [31:0] EX_pc_branch;

    integer stall_count;
    integer stall_count_cache;

    // always @ (*) begin
    //     stall_cache <= Stall_FromCache_D || Stall_FromCache_I;
    // end
    always @ (posedge Stall_FromCache_D or posedge Stall_FromCache_I or posedge rst or posedge cpu_clk) begin
        if(rst == 1)  stall_count_cache = 0;
        else begin
            if(Stall_FromCache_D || Stall_FromCache_I) begin
                stall_count_cache <= 2;
            end
            // else if(ForwardPC == 1) begin
            //     stall_count_cache <= stall_count_cache;
            // end
            else begin
                if(stall_count_cache != 0) stall_count_cache <= stall_count_cache - 1;
            end
        end
    end
    
    assign pc_out = cur_pc;
    assign pc_branch_out = EXM_pc_branch;
    reg [2:0] count;
    always @ (negedge cpu_clk or posedge rst) begin
    // always @ (posedge cpu_clk or posedge rst) begin
    if(rst == 1) begin
        if_4_reg <= 0;
        count <= 0;
    end
    else if(stall_count != 0 || stall_count_cache != 0) begin
        if_4_reg <= if_4_reg;
    end
    else begin
        if(stall_req == 1 || (Extreme_HarzardA == 1 || Extreme_HarzardB == 1) || (Stall_FromCache_D || Stall_FromCache_I)) begin
            if_4_reg <= if_4_reg;
        end
        else begin //need add a situation
            if(sys_jump == 1) begin
                if_4_reg <= sys_pc;
                // sys_jump <= 0;
            end
            else begin
                if(MWB_pc_src[1] == 1) begin
                    if_4_reg <= ex_5;
                end
                else begin
                    if(MWB_pc_src[0] == 0) if_4_reg <= if_3;
                    else if_4_reg <= EX_pc_branch;
                end
            end
         end
    end
    end
    //2'b00 nomal
    //2'b01 branched pc
    //2'b10 forwarding pc
    //2'b11 imme+pc(auipc)
    assign cur_pc = if_4_reg;
    
    //the double bump, the orginal version is negedge clk or posedge rst
    assign if_1 = cur_pc >> 2;
    assign if_3 = cur_pc + 4;

    wire [31:0] mem_req_addr_i;
    wire [31:0] mem_req_data_i;
    wire [31:0] mem_resp_data_i;

    I_CACHE Instruction_cache(
        .cpu_clk(cpu_clk),
        .mem_clk(mem_clk),
        .rst(rst),
        .cur_pc(cur_pc),

        .cache_req_addr(if_1), // this line is not sure
        .cache_req_data(32'b00000000),
        .cache_req_wen(1'b0),
        .cache_req_valid(1'b1),

        .cache_resp_data(if_2),
        .cache_resp_stall_i(Stall_FromCache_I),

        .mem_req_addr(mem_req_addr_i),
        .mem_req_data(mem_req_data_i),
        .mem_req_wen(mem_req_wen_i),
        .mem_req_valid(mem_req_valid_i),

        .mem_resp_data(mem_resp_data_i),
        .mem_resp_valid(mem_resp_valid_i)
    );
    I_MEMORY Instruction_memory(
        .cpu_clk(cpu_clk),
        .mem_clk(mem_clk),
        .rst(rst),

        .mem_req_addr(mem_req_addr_i),
        .mem_req_data(mem_req_data_i),
        .mem_req_wen(mem_req_wen_i),
        .mem_req_valid(mem_req_valid_i),

        .mem_resp_data(mem_resp_data_i),
        .mem_resp_valid(mem_resp_valid_i)
    );
    assign inst = if_2;
    //registers between IF and ID/////////////////////////////////////////////
    always @ (posedge cpu_clk or posedge rst) begin
        if(rst == 1) begin
            IFID_pc <= 0;
            IFID_pc_add_4 <= 0;
            IFID_inst <= 0;

        end
        else begin
                if(stall_count != 0) begin
                    IFID_pc <= IFID_pc;
                    IFID_pc_add_4 <= IFID_pc_add_4;
                    if(stall_count == 1) IFID_inst <= if_2;
                    else IFID_inst <= 32'h00000013;
                    // IFID_inst <= 32'h00000013;
                end
                else if(stall_count_cache != 0) begin
                    IFID_pc <= IFID_pc;
                    IFID_pc_add_4 <= IFID_pc_add_4;
                    IFID_inst <= IFID_inst;
                end
                else begin
                    if(ForwardPC == 1) begin 
                        IFID_inst <= 32'h00000013;
                        IFID_pc <= IFID_pc;
                        IFID_pc_add_4 <= IFID_pc_add_4;
                    end
                    else begin
                        IFID_pc <= cur_pc;
                        IFID_pc_add_4 <= if_3;
                        IFID_inst <= if_2;
                    end
                end
            // end
        end
    end
    
    //Instruction Decode//////////////////////////////////////////////////////    
    wire [31:0] id_1, id_4, id_5;
    wire [31:0] ID_data_a;
    wire [31:0] ID_data_a_pre;
    wire [31:0] ID_data_b;
    wire [31:0] ID_data_csr; 
    wire [31:0] ID_csr;
    wire [11:0] ID_funct12;
    wire ID_cache_req_valid;
    
    wire ID_zero;
    wire [1:0] wb_3; //wire in the write back stage, the control signal
    
    assign id_1 = IFID_inst;
    // assign ID_funct12 = inst[31:20];
    wire stall_flag;
    assign stall_flag = Extreme_Harzard == 1 || Extreme_HarzardA == 1 || Extreme_HarzardB == 1 || Forward_LoadBranch == 1;
    assign Extreme_Harzard = IFID_inst == 32'h34151073 && inst == 32'h30200073;
    // assign stall_sign = Extreme_Harzard == 1 || Extreme_HarzardA == 1 || Extreme_HarzardB == 1 || Forward_LoadBranch == 1;
    always@(posedge stall_flag or posedge cpu_clk or posedge rst) begin
        if(rst == 1) 
            stall_count <= 0;
        else begin
            if(stall_flag == 1)
                stall_count <= 4;
            else if(stall_count_cache != 0) 
                stall_count <= stall_count;
            else begin
                if(stall_count != 0) stall_count <= stall_count - 1;
            end
        end
    end
    
    CONTROL Control(
        .clk(cpu_clk),
        .rst(rst),
        .op_code(id_1[6:0]),
        .funct3(id_1[14:12]),
        .funct7_5(id_1[30]),
        .funct12(id_1[31:20]),
            
        .reg_write(reg_write), 
        .alu_src_a(alu_src_a),   
        .alu_src_b(alu_src_b),  
        .alu_op(alu_op),         
        .mem_to_reg(mem_to_reg), 
        .mem_write(mem_write),   
        .branch(branch),   
        .jump(jump),      
        .b_type(b_type),        
        .ExtOp(ExtOp),
        .pc_src(pc_src),
        .cache_req_valid(ID_cache_req_valid)
    );
    
    assign id_5 = (wb_3[1] == 0) ? wb_1 : wb_6;
    REGISTER Register(
        .clk(cpu_clk),
        .rst(rst),
        .we(wb_3),
        .read_addr_1(id_1[19:15]),
        .read_addr_2(id_1[24:20]),
        .write_data(id_5),
        .write_addr(wb_2),
        .read_data_1(ID_data_a_pre),
        .read_data_2(ID_data_b),
        .registers(register),
        .gp(gp)
    );

    CSR_CONTROL Csr_control(
        .clk(cpu_clk),
        .rst(rst),
        .op_code(id_1[6:0]),
        .funct3(id_1[14:12]),
        .funct12(id_1[31:20]),
        .inst(id_1),

        .sys_jump(sys_jump),
        .csr_we(IDEX_csr_we),
        .alu_csr_src(alu_csr_src)
    );
    CSR_REG Csr_reg(
        .clk(cpu_clk),
        .rst(rst),
        .csr_we(MWB_csr_we),
        .op_code(id_1[6:0]),
        .funct3(id_1[14:12]),
        .funct12(id_1[31:20]),
        .inst(id_1),

        .pc_in(cur_pc),
        .pc_out(sys_pc),
        .write_data(wb_1),
        .write_addr(MWB_funct12),
        .read_data(ID_data_csr)
    );
    assign ID_data_a = (alu_csr_src == 1) ? ID_data_csr : ID_data_a_pre;

    // part of whether branch or not
    wire [31:0] operand_A;
    wire [31:0] operand_B;
    wire [31:0] operand_A_ex;
    wire [31:0] operand_B_ex;
    assign operand_A = Forward_b_A_3 ? MWB_result : (Forward_b_A_2 ? EXM_result : (Forward_b_A? ex_5:ID_data_a));
    assign operand_B = Forward_b_B_3 ? MWB_result : (Forward_b_B_2 ? EXM_result : (Forward_b_B? ex_5:ID_data_b));
    assign operand_A_ex = Extreme_HarzardA ? MWB_read_data : operand_A;
    assign operand_B_ex = Extreme_HarzardB ? MWB_read_data : operand_B;
    // assign ID_zero = (id_1[14:12] == 3'b111) ? (operand_A_ex>=operand_B_ex):((operand_A_ex==operand_B_ex) ^ b_type);
    assign ID_zero = (id_1[14:12] == 3'b111) ? (operand_A>=operand_B):((operand_A==operand_B) ^ b_type);
    
    wire [31:0] check1 = Forward_b_A? ex_5:ID_data_a;
    wire [31:0] check2 = Forward_b_B? ex_5:ID_data_b;
    IMMGEN ImmGen(
        .inst(id_1),
        .ext_op(ExtOp),
        .imm(id_4)
    );
    
    STALL Stall(
        .clk(cpu_clk),
        .rst(rst),
        .EXMEM_mem_to_reg(IDEX_mem_to_reg),
        .EXMEM_RegisterRd(IDEX_reg_addr),
        .IDEX_RegisterRs1(id_1[19:15]),
        .IDEX_RegisterRs2(id_1[24:20]),
        .branch(branch),
        .jump(jump),
        .stall_req(stall_req)
    );
    //registers between ID and EX/////////////////////////////////////////////    
    always @ (posedge cpu_clk or posedge rst) begin
        if(rst == 1 || stall_req == 1) begin
            IDEX_data_a <= 0;
            IDEX_data_b <= 0;
            IDEX_imm <= 0;
            IDEX_reg_addr <= 0;
            IDEX_pc <= 0;
            IDEX_pc_add_4 <= 0;
            IDEX_RegisterRs1 <= 0;
            IDEX_RegisterRs2 <= 0;
            IDEX_data_csr <= 0;
            IDEX_funct12 <= 0;
        
            IDEX_alu_op <= 0;
            IDEX_alu_src_a <= 0;
            IDEX_alu_src_b <= 0;
            IDEX_alu_csr_src <= 0;
            IDEX_mem_write <= 0;
            IDEX_branch <= 0;
            IDEX_jump <= 0;
            IDEX_b_type <= 0;
            IDEX_pc_src <= 0;
            IDEX_mem_to_reg <= 0;
            IDEX_reg_write <= 0;
            IDEX_alu_control <= 0;
            IDEX_zero <= 0;
            // IDEX_csr_we <= 0;
            IDEX_inst <= 0;
            //IDEX_ForwardPC <= 0;
            IDEX_cache_req_valid <= 0;
        end
        else if(stall_count_cache != 0) begin
            IDEX_data_a <= IDEX_data_a;
            IDEX_data_b <= IDEX_data_b;
            IDEX_imm <= IDEX_imm;
            IDEX_reg_addr <= IDEX_reg_addr;
            IDEX_pc <= IDEX_pc;
            IDEX_pc_add_4 <= IDEX_pc_add_4;
            IDEX_RegisterRs1 <= IDEX_RegisterRs1;
            IDEX_RegisterRs2 <= IDEX_RegisterRs2;
            IDEX_data_csr <= IDEX_data_csr;
            IDEX_funct12 <= IDEX_funct12;
        
            IDEX_alu_op <= IDEX_alu_op;
            IDEX_alu_src_a <= IDEX_alu_src_a;
            IDEX_alu_src_b <= IDEX_alu_src_b;
            IDEX_alu_csr_src <= IDEX_alu_csr_src;
            IDEX_mem_write <= IDEX_mem_write;
            IDEX_branch <= IDEX_branch;
            IDEX_jump <= IDEX_jump;
            IDEX_b_type <= IDEX_b_type;
            IDEX_pc_src <= IDEX_pc_src;
            IDEX_mem_to_reg <= IDEX_mem_to_reg;
            IDEX_reg_write <= IDEX_reg_write;
            IDEX_alu_control <= IDEX_alu_control;
            IDEX_zero <= IDEX_zero;
            // IDEX_csr_we <= 0;
            IDEX_inst <= IDEX_inst;
            //IDEX_ForwardPC <= 0;
            IDEX_cache_req_valid <= IDEX_cache_req_valid;
        end
        else begin
            if(Extreme_HarzardA == 1 || Extreme_HarzardB == 1 || Forward_LoadBranch == 1 || Extreme_Harzard == 1) begin
                IDEX_data_a <= 0;
                IDEX_data_b <= 0;
                IDEX_imm <= 0;
                IDEX_reg_addr <= 0;
                IDEX_pc <= IDEX_pc;
                IDEX_pc_add_4 <= IDEX_pc_add_4;
                IDEX_RegisterRs1 <= 0;
                IDEX_RegisterRs2 <= 0;
                IDEX_data_csr <= 0;
                IDEX_funct12 <= 0;
                IDEX_inst <= 0;

                IDEX_alu_op <= 0;
                IDEX_alu_src_a <= 0;
                IDEX_alu_src_b <= 0;
                IDEX_alu_csr_src <= 0;
                IDEX_mem_write <= 0;
                IDEX_branch <= 0;
                IDEX_jump <= 0;
                IDEX_b_type <= 0;
                IDEX_pc_src <= 0;
                IDEX_mem_to_reg <= 0;
                IDEX_reg_write <= 0;
                IDEX_alu_control <= 0;
                IDEX_zero <= 0;
                IDEX_cache_req_valid <= 0;
                // IDEX_ForwardPC <= ForwardPC; //时序可能有问�?
                // IDEX_csr_we <= csr_we;                
            end
            else begin
                IDEX_data_a <= ID_data_a;
                IDEX_data_b <= ID_data_b;
                IDEX_imm <= id_4;
                IDEX_reg_addr <= id_1[11:7];
                IDEX_pc <= IFID_pc;
                IDEX_pc_add_4 <= IFID_pc_add_4;
                IDEX_RegisterRs1 <= id_1[19:15];
                IDEX_RegisterRs2 <= id_1[24:20];
                IDEX_data_csr <= ID_data_csr;
                IDEX_funct12 <= inst[31:20];
                IDEX_inst <= IFID_inst;

                IDEX_alu_op <= alu_op;
                IDEX_alu_src_a <= alu_src_a;
                IDEX_alu_src_b <= alu_src_b;
                IDEX_alu_csr_src <= alu_csr_src;
                IDEX_mem_write <= mem_write;
                IDEX_branch <= branch;
                IDEX_jump <= jump;
                IDEX_b_type <= b_type;
                IDEX_pc_src <= pc_src;
                IDEX_mem_to_reg <= mem_to_reg;
                IDEX_reg_write <= reg_write;
                IDEX_alu_control <= {id_1[31], id_1[14:12]};
                IDEX_zero <= ID_zero;
                IDEX_cache_req_valid <= ID_cache_req_valid;
                // IDEX_ForwardPC <= ForwardPC; //时序可能有问�?
                // IDEX_csr_we <= csr_we;
            end
        end
    end

    //Execute/////////////////////////////////////////////////////////////////
    wire [31:0] ex_3, ex_8;
    wire [1:0] ForwardA, ForwardB;
    reg [31:0] ex_1, ex_4;
    reg [31:0] EX_ram_data; //ex_2
    
    assign ex_8 = IDEX_data_a;
    // assign ex_2 = IDEX_data_b;
    assign ex_3 = IDEX_imm;
    
    always@(*) begin
        if(Forward_ram_writeEXM == 1) EX_ram_data <= EXM_result;
        else if(Forward_ram_writeMWB == 1) EX_ram_data <= MWB_result;
        else EX_ram_data <= IDEX_data_b;
    end
    
    //the Forward Control Unit
    FORWARDING Forwarding(
        .rst(rst),
        .branch(branch),
        .jump(jump),
        .zero(ID_zero),
        .MEMWB_mem_to_reg(MWB_mem_to_reg),
        .IDEX_RegWrite(IDEX_reg_write),
        .EXMEM_RegWrite(EXM_reg_write),
        .MEMWB_RegWrite(MWB_reg_write),
        .IDEX_mem_write(IDEX_mem_write),
        .IDEX_alu_src_a(IDEX_alu_src_a),
        .IDEX_alu_src_b(IDEX_alu_src_b),
        .EXMEM_RegisterRd(EXM_reg_addr),
        .MEMWB_RegisterRd(MWB_reg_addr),
        .IDEX_RegisterRs1(IDEX_RegisterRs1),
        .IDEX_RegisterRs2(IDEX_RegisterRs2),
        .EXMEM_RegisterRs2(EXM_RegisterRs2),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .ForwardPC(ForwardPC),
        
        // for the comparison forwarding
        .IFID_inst(IFID_inst),
        .IDEX_inst(IDEX_inst),
        .EXM_inst(EXM_inst),
        .MWB_inst(MWB_inst),
        .Forward_branch(branch),
        .Forward_RegisterRd_3(MWB_reg_addr),
        .Forward_RegisterRd_2(EXM_reg_addr),
        .Forward_RegisterRd(IDEX_reg_addr),
        .Forward_RegisterRs1(id_1[19:15]),
        .Forward_RegisterRs2(id_1[24:20]),
        .Forward_b_A(Forward_b_A),
        .Forward_b_B(Forward_b_B),
        .Forward_b_A_2(Forward_b_A_2),
        .Forward_b_B_2(Forward_b_B_2),
        .Forward_b_A_3(Forward_b_A_3),
        .Forward_b_B_3(Forward_b_B_3),

        .Forward_ram(Forward_ram),

        .Forward_ram_writeEXM(Forward_ram_writeEXM),
        .Forward_ram_writeMWB(Forward_ram_writeMWB),

        .Extreme_HarzardA(Extreme_HarzardA),
        .Extreme_HarzardB(Extreme_HarzardB),

        .Forward_LoadSave(Forward_LoadSave),
        .Forward_LoadBranch(Forward_LoadBranch)
    );
    always @ (negedge cpu_clk or posedge rst) begin
        if(rst == 1) begin
            Target_pc <= 0;
        end
        else begin
            if(Forward_LoadBranch == 1) begin
                Target_pc <= cur_pc + 8;
            end
            if(cur_pc == Target_pc + 8) begin
                Target_pc <= 0;
            end
        end
    end
    
    // mux to the alu_src_b
    wire [31:0] special_pc;
    assign special_pc = 32'h0000007c;
    always@(*) begin
        // if(stall_count_cache != 0) begin
        //     ex_4 <= ex_4;
        // end
        // else begin
        if(Target_pc == cur_pc || Target_pc == cur_pc - 4) begin
            ex_4 <= (IDEX_alu_src_b == 0) ? IDEX_data_b : ex_3;
        end
        else begin
            if(ForwardB == 2'b11) begin
                ex_4 <= MWB_read_data;
            end
            if(ForwardB == 2'b10) begin
                ex_4 <= EXM_result;
            end
            if(ForwardB == 2'b01) begin
                ex_4 <= MWB_result;
            end
            if(ForwardB == 2'b00) begin
                ex_4 <= (IDEX_alu_src_b == 0) ? IDEX_data_b : ex_3;
            end
        end
        // end
    end
    //mux to the alu_src_a
    always@(*) begin
        //here may exists data hazard concerning CSR
        //fix is needed
        // if(IDEX_alu_csr_src == 1) begin
        //     ex_1 <= IDEX_data_csr;
        // end
        // else begin
        // if(stall_count_cache == 0) begin
        if(Target_pc == cur_pc || Target_pc == cur_pc - 4) begin
            ex_1 <= (IDEX_alu_src_a == 0) ? IDEX_pc : ex_8;
        end
        else begin
            if(ForwardA == 2'b11) begin
                ex_1 <= MWB_read_data;
            end
            if((ForwardA == 2'b10 || Forward_ram == 1)) begin
                ex_1 <= EXM_result;
            end
            if(ForwardA == 2'b01) begin
                ex_1 <= MWB_result;
            end
            if(ForwardA == 2'b00) begin
                ex_1 <= (IDEX_alu_src_a == 0) ? IDEX_pc : ex_8;
            end
        end
        // end
        // end
    end

    ALU Alu(
        .data_a(ex_1),
        .data_b(ex_4),
        .alu_op(IDEX_alu_op),
        .b_type(IDEX_b_type),
        .result(ex_5)
    );
    
    assign EX_pc_branch = IDEX_imm + IDEX_pc;
    assign MWB_pc_src = {IDEX_pc_src[1] ,(IDEX_branch & IDEX_zero)|IDEX_jump};

    reg [31:0] Forward_LoadSave_Reg;
    always @ (posedge cpu_clk or posedge rst) begin
        if(rst == 1) begin
            EXM_pc <= 0;
            EXM_inst <= 0;
            EXM_result <= 0;
            EXM_reg_addr <= 0;
            EXM_pc_branch <= 0;
            EXM_ram_data <= 0;
            EXM_pc_add_4 <= 0;
            EXM_RegisterRs2 <= 0;
        
            EXM_mem_write <= 0;
            EXM_pc_src <= 0;
            EXM_reg_write <= 0;
            EXM_mem_to_reg <= 0;
            EXM_csr_we <= 0;
            EXM_funct12 <= 0;
            EXM_cache_req_valid <= 0;

            Forward_LoadSave_Reg <= 0;
        end
        else if(stall_count_cache != 0) begin
            EXM_pc <= EXM_pc;
            EXM_inst <= EXM_inst;
            EXM_result <= EXM_result;
            EXM_reg_addr <= EXM_reg_addr;
            EXM_pc_branch <= EXM_pc_branch;
            EXM_ram_data <= EXM_ram_data;
            EXM_pc_add_4 <= EXM_pc_add_4;
            EXM_RegisterRs2 <= EXM_RegisterRs2;
        
            EXM_mem_write <= EXM_mem_write;
            EXM_pc_src <= EXM_pc_src;
            EXM_reg_write <= EXM_reg_write;
            EXM_mem_to_reg <= EXM_mem_to_reg;
            EXM_csr_we <= EXM_csr_we;
            EXM_funct12 <= EXM_funct12;
            EXM_cache_req_valid <= EXM_cache_req_valid;

            Forward_LoadSave_Reg <= Forward_LoadSave_Reg;
        end
        else begin
            EXM_pc <= IDEX_pc;
            EXM_inst <= IDEX_inst;
            EXM_result <= ex_5;
            EXM_reg_addr <= IDEX_reg_addr;
            EXM_pc_branch <= EX_pc_branch;
            EXM_ram_data <= EX_ram_data; 
            EXM_pc_add_4 <= IDEX_pc_add_4;
            EXM_RegisterRs2 <= IDEX_RegisterRs2;
            EXM_cache_req_valid <= IDEX_cache_req_valid;
        
            EXM_mem_write <= IDEX_mem_write;
            EXM_pc_src <= IDEX_pc_src;
            EXM_reg_write <= IDEX_reg_write;
            EXM_mem_to_reg <= IDEX_mem_to_reg;
            EXM_csr_we <= IDEX_csr_we;
            EXM_funct12 <= IDEX_funct12;

            Forward_LoadSave_Reg <= Forward_LoadSave;
        end
    end
    //Memory Access///////////////////////////////////////////////////////////
    wire [31:0] m_2, m_5;
    wire [13:0] m_1;
    wire [31:0] MEM_read_data;
    wire m_8;
    
    assign m_1 = EXM_result[12:0];
    // assign m_1 = (MWB_Forward_ram == 1) ? MWB_result : EXM_result;
    wire check0;
    assign check0 = EXM_mem_write == 1 && MWB_reg_addr == EXM_RegisterRs2;
    assign m_2 = Forward_LoadSave_Reg == 1 ? Extra_Data : (EXM_mem_write == 1 && MWB_reg_addr == EXM_RegisterRs2 && MWB_inst[6:0] != 7'b0100011 && MWB_inst[6:0] !=7'b1100011) ? MWB_result : EXM_ram_data;
    
    assign address = EXM_result;
    
    wire [31:0] mem_req_addr_d;
    wire [31:0] mem_req_data_d;
    wire [31:0] mem_resp_data_d;  
    // wire [37:0] cache_memory [0: 511];
    D_CACHE Data_cache(
        .cpu_clk(cpu_clk),
        .mem_clk(mem_clk),
        .rst(rst),
        .cur_pc(EXM_pc),
//////////////////////////////////////////////SCPU
        .cache_req_addr(address),
        .cache_req_data(m_2),
        .cache_req_wen(EXM_mem_write),
        .cache_req_valid(EXM_cache_req_valid), //where is the signal, maybe is converned with STALL

        .cache_resp_data(MEM_read_data),
        .cache_resp_stall_d(Stall_FromCache_D),
//////////////////////////////////////////////MEMORY
        .mem_req_addr(mem_req_addr_d),
        .mem_req_data(mem_req_data_d),
        .mem_req_wen(mem_req_wen_d),
        .mem_req_valid(mem_req_valid_d),
        
        .mem_resp_data(mem_resp_data_d),
        .mem_resp_valid(mem_resp_valid_d),
//////////////////////////////////////////////Output cache info
        .cache_memory_output(cache_memory)
    );
    

    D_MEMORY Data_memory(
        .cpu_clk(cpu_clk),
        .mem_clk(mem_clk),
        .rst(rst),

        .mem_req_addr(mem_req_addr_d),
        .mem_req_data(mem_req_data_d),
        .mem_req_wen(mem_req_wen_d),
        .mem_req_valid(mem_req_valid_d),
        
        .mem_resp_data(mem_resp_data_d),
        .mem_resp_valid(mem_resp_valid_d)
    );
    
    always @ (posedge cpu_clk or posedge rst) begin
        if(rst == 1) begin
            MWB_result <= 0;
            MWB_reg_addr <= 0;
            MWB_read_data <= 0;
            MWB_pc_add_4 <= 0;
            //MWB_pc_src <= 0;
            MWB_inst <= 0;
        
            MWB_mem_to_reg <= 0;  
            MWB_reg_write <= 0;  
            MWB_csr_we <= 0;     
            MWB_funct12 <= 0;
        end
        else if(stall_count_cache != 0) begin
            MWB_result <= MWB_result;
            MWB_reg_addr <= MWB_reg_addr;
            MWB_read_data <= MWB_read_data;
            MWB_pc_add_4 <= MWB_pc_add_4;
            MWB_inst <= MWB_inst;
        
            MWB_mem_to_reg <= MWB_mem_to_reg;  
            MWB_reg_write <= MWB_reg_write;  
            MWB_csr_we <= MWB_csr_we;     
            MWB_funct12 <= MWB_funct12;
        end
        else begin
            MWB_result <= m_1;
            MWB_reg_addr <= EXM_reg_addr;
            //MWB_read_data <= m_3;
            MWB_read_data <= MEM_read_data;
            MWB_pc_add_4 <= EXM_pc_add_4;
            //MWB_pc_src <= {EXM_pc_src[1], m_8};
            MWB_inst <= EXM_inst;
        
            MWB_mem_to_reg <= EXM_mem_to_reg;
            MWB_reg_write <= EXM_reg_write;
            MWB_csr_we <= EXM_csr_we;
            MWB_funct12 <= EXM_funct12;
       end
    end
   
    //Write Back//////////////////////////////////////////////////////////////
    wire [31:0] wb_4, wb_5;
    //wire [31:0] wb_1;
    assign wb_2 = MWB_reg_addr;
    assign wb_3 = MWB_reg_write;
    assign wb_4 = MWB_read_data;
    assign wb_5 = MWB_result;
    assign wb_6 = MWB_pc_add_4;
    assign reg_data = MWB_result;
    
    //a mux to write back to the registers;
    assign wb_1 = (MWB_mem_to_reg == 0) ? wb_5 : wb_4;

    always@(posedge cpu_clk or posedge rst) begin
        if(rst == 1) Extra_Data <= 0;
        else if(stall_count_cache) Extra_Data <= Extra_Data;
        else Extra_Data <= MWB_read_data; //原来从ram里读取的数据也要进段间寄存器
    end
  
endmodule
