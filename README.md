# Pipelined-CPU-RISCV

### Part 1: 软硬件协同的尝试

#### 1. 功能设计

#### 1.1 kernel编译和COE生成

本次实现使用含有`unimp`指令识别以及`scause`寄存器的Advanced Kernel进行编译. 生成的.coe文件放入Rom的初始化文件中

#### 1.2 CSR寄存器

在模块`CSR_REG`, 中,设计了`mtvec`, `mstatus`, `mepc`以及`mcause`四个寄存器

主要有CSR数据读取, CSR置位以及CSR数据写入三个功能模块

1. CSR数据读取
   按照funct12, 也就是`inst[31:20]`的内容,对不同的寄存器进行数据读取,将数据放入`read_data_reg`

   数据将会在`IDEX`段间寄存器之前与正常的ID阶段操作数A进行一次选择,因此可以适配原有的Forwarding系统,此部分的控制信号为CSR_CONTROL模块产生的控制信号alu_csr_src, 用来在CSR读取指令对寄存器来源的选择

   ```verilog
   assign ID_data_a = (alu_csr_src == 1) ? ID_data_csr : ID_data_a_pre;
   ```

2. CSR数据写入
   由CSR_CONTROL输出的写使能信号`csr_we`(此时正常寄存器的写使能`we`置0, 写回信号仅流入CSR寄存器组)控制是否对寄存器进行写入, 写入的数据来源源于原流水线CPU的在WB阶段的写回线. 数据的写入和普通寄存器组都是在时钟下降沿进行.

   写入的时候由`funct12`生成的`write_addr`对对应的CSR寄存器进行写入.

3. CSR数据置位与指令流控制

   涉及到数据置位的情况主要有三种, 分别是`ecall`指令, `unimp`异常指令以及特权态返回`mret`指令. 数据置位的实现通过`op_code`,`funct3`以及`funct12`进行判定

   1. `ecall`指令
      涉及到`ecall`指令时将`mstatus`的`mie`位进行置位, 将当前的`pc`(`pc_in`)写入`mepc`寄存器, 同时将`mcause`置位为`0xb`

   2. `unimp`指令

      当检测到`unimp`指令的时候的操作和`ecall`指令类似, 都是进入特权指令处理段, 但是此时`mcause`会置位为`0x2`

   3. `mret`指令

      当检测到`mret`指令时,将`mstatus`的`mie`位恢复为0

#### 1.3 特权指令与异常处理的跳转控制

涉及到特权指令跳转的指令主要是`ecall`(以及`unimp`)以及`mret`指令, 这里的实现是将`pc`从`mepc`寄存器中读出(读出的结果在CPU中表示为`sys_pc`)然后写入下一阶段的`pc`, 这里涉及到的控制信号是`CSR_CONTROL`模块中生成的`sys_jump`信号来进行控制. 

```verilog
// 当涉及到ecall, unimp以及mret指令的时候确定调转到trap_handler段
assign sys_jump = (op_code == 7'b1110011) && ((funct12 == 12'h302) || (inst == 32'hc0001073) || (funct3 == 3'b000));
/*******************************************************/
//IF阶段取指令的相关内容
if(sys_jump == 1) begin //写入特权程序段跳转地址
	if_4_reg <= sys_pc;
end
else begin //原来的正常pc写入
	if(MWB_pc_src[1] == 1) begin
    	if_4_reg <= ex_5;
    end
    else begin
    	if(MWB_pc_src[0] == 0) if_4_reg <= if_3;
         else if_4_reg <= EX_pc_branch;
    end
end
```

#### 1.4 Forwarding实现补充

在本次实验, 针对Forwarding的一些其他情况做了一些补充, 从而使得CPU可以应对更多种类的指令组合. 

#### 1.4.1 branch类指令Forwarding优化

为了在branch类指令中避免出现STALL的情况, 指令的比较判定阶段设置在了ID阶段(IFID阶段上升沿处), 因此就可以在下一个时钟下降沿, 也就是下一条指令的IF阶段实现数据的读取.

因此如果前一条/两条/三条运算类(I类, R类)的指令的目标寄存器和branch类的指令中的某个操作数重合, 此时就会出现数据冲突, 因此需要从CPU后面的段间寄存器提前发送前面指令的运结果. 因此对应的Forwarding有从IDEX段, EXMEM段以及MWB段的段间寄存器写回的内容. 

```verilog
// 控制Forwarding段间寄存器的信号对应关系:
// Forward_b_3 -> MWB_result
// Forward_b_2 -> EXM_result
// Forward_b   -> IDEX_result
assign operand_A = Forward_b_A_3 ? MWB_result : (Forward_b_A_2 ? EXM_result : (Forward_b_A? ex_5:ID_data_a));
assign operand_B = Forward_b_B_3 ? MWB_result : (Forward_b_B_2 ? EXM_result : (Forward_b_B? ex_5:ID_data_b));
```

这些信号从Forwarding信号生成模块发出, 模块会对应的指令收集指令序列信号, 按照前面的规则生成对应内容

#### 1.4.2 S类指令Forwarding优化

在S类指令, 对于写入的数据而言, 如果想要写入的源寄存器是前面指令的计算结果, 此时需要对写入的数据进行Forwarding操作

Forwarding的信号从Forwarding模块中的`Forward_LoadSave`发出, 因为信号在EX阶段产生,因此需要保留一个时钟周期传到MEM阶段的寄存器 `Forward_LoadSave_reg`来产生作用. 当信号置位1时, 数据从MWB阶段Forwarding, 但是因为时序因素, MWB阶段的数据需要延迟一个时钟周期输入(这里如果不Forwarding输入的时`MWB_result`前一刻的数据), 它由`Extra_Data`来进行存储.

另外两种Forwarding情况, 是对MWB段间寄存器的数据以及EXM阶段的`EXM_ram_data`(因为这一部分的数据可能也是从前面Forwarding过来的), 逻辑叙述如下: 

```c
if(Forward_LoadSave == 1)
    ram_input <- EXtra_Data(MWB_result delay a clock cycle);
if(EXM_mem_write == 1 && MWB_reg_addr == EXM_RegisterRs2 && MWB_inst[6:0] != 7'b0100011 && MWB_inst[6:0] !=7'b1100011)
    ram_imput <- MWB_result;
else
    ram_imput <- EXM_ram_data;
```

而对EXM_ram_data的常规Forwarding, 也就是从之前的运算类指令进行提前写入, 则是由信号`Forward_ram_writeEXM`和信号`Forward_ram_writeMWB`来进行控制. 这里同样也要对指令序列进行监测然后发出对应的控制信号.

`Forward_ramwriteEXM`从EXM的result段Forwarding到写入ram的数据, `Forward_ramwriteMWB`从MWB的result段Forwarding到写入ram的数据.

```verilog
if(Forward_ram_writeEXM == 1) 
    EX_ram_data <= EXM_result;
else if(Forward_ram_writeMWB == 1) 
    EX_ram_data <= MWB_result;
else 
    EX_ram_data <= IDEX_data_b;
```

#### 1.5 流水线插入空泡

在一些数据冲突困难极大的情况, Forwarding方法已经不能够维持CPU的正常运转. 此时需要通过在指令之后插入空泡来解决. 在kernel中主要涉及到情况有一下两种.

因为几种情况插入空泡的操作一致, 因此在这里介绍对应的信号生成之后对CPU运行进行的操作:

1. 在ID阶段前期生成对应的插入空泡信号
2. 在IDEX阶段的段间寄存器, flush掉本条指令的对应内容
3. 启动`stall_count`计数, 计数置为4, 也就是插入4个空泡
4. `stall_count`计数大于0期间, pc不变, `IFID_inst`输出`nop`指令
5. 在`stall_count`计数为1时, 将指令内容从IFID段放出执行, 在其计数为0时pc恢复更新

#### 1.5.1 计算之后Branch

在程序中, 出现了计算结果之后随即将之进行比较进行跳转的情况, 此时会启动控制信号`Extreme_HarzardA`和`Extreme_HarzardB`, 分别对应由操作数a和操作数b产生的冲突.

#### 1.5.2 Load之后Branch或者跳转

在程序段`_mret`处, 出现了`mepc`寄存器执行`csrw`操作之后直接进行`mret`的极端情况, 此时写回和读取的数据相差四个时钟周期. 此时会启动控制信号`Extreme_Harzard`

```verilog
// 因为指令序列中没有出现lw或者运算指令后随即对同类指令进行jalr的情况, 所以此种信号仅覆盖了这一种极端情况
assign Extreme_Harzard = IFID_inst == 32'h34151073 && inst == 32'h30200073;
```

同时在指令中如果出现了Load之后使用其目标寄存器进行比较的情况, 因为前者在MEM后期生成结果, 后者在ID阶段前期生成结果, 因此也需要进行插入空泡操作, 此时会启动信号`Forward_LoadBranch`, 此时相差一条, 两条或者三条指令都会出发该信号. 两个操作数每个三种情况, 因此有六种情况.

```verilog
assign Forward_LoadBranch = (Forward_RegisterRs1 == Forward_RegisterRd && IDEX_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011) 
    || (Forward_RegisterRs1 == Forward_RegisterRd_2 && EXM_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011) 
    || (Forward_RegisterRs1 == Forward_RegisterRd_3 && MWB_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011) 
    || 
                                
    (Forward_RegisterRs2 == Forward_RegisterRd && IDEX_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011) 
    || (Forward_RegisterRs2 == Forward_RegisterRd_2 && EXM_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011) 
    || (Forward_RegisterRs2 == Forward_RegisterRd_3 && MWB_inst[6:0] == 7'b0000011 && IFID_inst[6:0] == 7'b1100011);
```

#### 1.5.3 Load之后Save

在`_swtich_to`等程序段中出现了load出某个值之后随即将其指令s类指令的情况,此时读取和提取的数据相差三个时钟周期, 此时会启动控制指令`Forward_LoadSave`

```verilog
assign Forward_LoadSave = (IDEX_inst[6:0] == 7'b0100011) && MEMWB_mem_to_reg == 1 && (MEMWB_RegisterRd == IDEX_RegisterRs2);
```

#### 1.6 指令扩展

本次实验要求CPU增加对指令`auipc`和指令`bgeu`的支持, 对`auipc`指令.

在CPU的Control译码模块已经实现了对该指令的兼容.

对`bgeu`指令, 扩展了在ID阶段的判定模块, 根据其编码特点`funct3`进行不同的判定操作

```verilog
assign ID_zero = (id_1[14:12] == 3'b111) ? (operand_A>=operand_B):((operand_A==operand_B) ^ b_type);
```

-----

## Part 2: Cache

#### 2.1 Cache设计

在cache的数据存放方面, 使用寄存器堆来实现

```verilog
reg [37:0] cache_memory [0:511];
//37  34    33     32   31                   0
//|_tag_|_dirty_|_valid_|________data________|
```

每一个Block总共设置38位, 其中: 

- Block Memory大小为8192KB, 因此总共有13位地址线, 而cache中有512个Block, 因此在cache中寻址的index有9位, 用于标定cache的tag总共有4位
- 标定cache block的dirty位和valid位总共两位
- 数据位32位

在cache的状态切换部分, 设计与实验文档略有不同, 状态机设计如下, 不同点在于: 

- 当S_BACK_WAIT完成之后, 如果执行的是Save操作, 回到S_IDLE状态进行正常写操作
- 当S_BACK_WAIT完成之后, 如果执行的是Load操作, 进入S_FILL状态等待内存读取数据

![figure2](C:\Users\LuoyuanNi\Desktop\figure2.png)

本Project将cache_memory模块的操作与CMU状态机的运转合并, 在状态转换的同时直接对cache_memory进行操作, 因此D-Cache模块的伪代码如下:

```verilog
module D_CACHE(
    input cache_req....
    output cache_resp_data,
    output cache_resp_stall,
    
    output mem_req...,
    input mem_resp_data,
    input mem_resp_valid
);
    reg [37:0] cache_memory [0:511];
    reg [2:0] cache_state;
    always @ (posedge cpu_clk or posedge rst) begin
        if(rst == 1) cache_state <= S_IDLE;
        else begin
            if(cache_state == S_IDLE) begin
                if(data is valid when reading) hit, read data from cache;
                if(is allowed when writing) hit, write data from datapath;
                else begin
                    if(data is not valid but clean when reading) cache_state <= S_FILL;
                    if(data is dirty when writing || data is dirty and not valid when reading) cache_state <= S_BACK;
                end
            end
            
            if(cache_state == S_BACK) begin
                send write request and data to memory;
                cache_state <= S_BACK_WAIT;
            end
            
            if(cache_state ==  S_BACK_WAIT) begin
                if(mem_resp_valid) begin
                    if(read) cache_state <= S_FILL;
                    if(wirte) cache_state <= S_IDLE;
                end
            end
            
            if(cache_state == S_FILL) begin
                send read request to memory;
                cache_state <= S_FILL_WAIT;
            end
            
            if(cache_state == S_FILL_WAIT) begin
                if(mem_resp_valid) begin
                    write cache memory;
                    cache_state <= S_IDLE;
                end
            end
        end
    end

endmodule
```

I-CACHE模块因为只涉及到读操作, 因此模块设计为D-CACHE中的S_IDLE, S_FILL以及S_FILL_BACK部分, 模块的详细内容与D-Cache一致

#### 2.2 Memory设计

Memory的设计主要涉及到`mem_resp_valid`信号的回传模块

`mem_resp_valid`信号要求在Block Memory返回数据或者写回完毕之后置位为1, 在本模块中实现为在接收到`mem_req_valid`信号后一个`mem_clk`时钟周期返回

模块设计代码如下:

```verilog
	reg resp_flag;
	//实现一个mem_clk延迟的标定信号resp_flag
    always @ (posedge mem_clk or posedge rst or posedge mem_resp_valid) begin
        if(rst == 1) begin
            resp_flag <= 0;
        end
        else begin
            if(mem_resp_valid == 1) resp_flag <= 0;
            //当mem_resp_valid为0的时候才可以置1
            else if(mem_resp_valid == 0) resp_flag <= 1;      
        end
    end
    //mem_resp_valid根据resp_flag的取值来进行相应, 因为已经有resp_flag的延迟作用, 所以使用cpu_clk
    always @ (posedge cpu_clk or posedge rst) begin
        if(rst == 1) mem_resp_valid <= 0;
        else begin
            if(resp_flag == 1) mem_resp_valid <= 1;
            else mem_resp_valid <= 0;
        end
    end
```

#### 2.3 Stall 实现

除了cache的`S_IDLE`状态之外, cache处于运行或者等待时, 都需要流水线进行暂停, 因此对流水线的输出信号`cache_resp_stall`的赋值如下:

```verilog
assign cache_resp_stall_i = (cache_state == S_IDLE) ? 0 : 1;
```

在`cache_resp_stall`置1期间, 整个流水线暂停两个时钟周期, 同时插入空泡的计数寄存器`stall_count`也同时暂停, 只有当stall_count_cache置为0的时候, 也就是当cache恢复读取的时候, 整个流水线才能够恢复运行

