`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 18:00:28
// Design Name: 
// Module Name: ALU
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


module ALU(
    input [31:0] data_a,
    input [31:0] data_b,
    output reg [31:0] result,
   
    input [3:0] alu_op,
    input b_type
    //output zero
    );
    /////////////////////////
    parameter    
    ADD  = 4'b0000, //auipc
    SUB  = 4'b1000,
    SLL  = 4'b0001,
    SLT  = 4'b0010,
	SLTU = 4'b0011,
	XOR  = 4'b0100,
	SRL  = 4'b0101,
	SRA  = 4'b1101,
	OR   = 4'b0110,
	AND  = 4'b0111,
	LUI  = 4'b1111, //CSRR
    CSR  = 4'b1001;
    /////////////////////////
    //initial begin
        //zero <= 0;
        //result <= 0;
    //end
    /////////////////////////
    wire sign;
    //assign zero = (data_a==data_b)^b_type;
    
    integer i;
    always@(*) begin
        case(alu_op)
            ADD: begin
                result <= data_a + data_b;
            end
            
            SUB: begin
                result <= data_a - data_b;
            end
            
            SLL: begin
                result <= data_a << data_b;
            end
            
            SLT: begin
                if(data_a[31]==1 && data_b[31]==0)
                    result <= 1;
                else if(data_a[31]==0 && data_b[31]==1)
                    result <= 0;
                else if(data_a[31]==1 && data_b[31]==1) begin
                    if(data_a < data_b)
                        result <= 0;
                    else
                        result <= 1;
                end
                else begin
                    if(data_a < data_b)
                        result <= 1;
                    else
                        result <= 0;
                end
            end
            
            SLTU: begin
                if(data_a < data_b)
                    result <= 1;
                else
                    result <= 0;
            end
            
            XOR: begin
                result <= data_a ^ data_b;
            end     
            
            SRL: begin
                result <= data_a >> data_b;
            end
            
            SRA: begin 
                result <= data_a >>> data_b;
            end
            
            OR: begin
                result <= data_a | data_b;
            end
            
            AND: begin
                result <= data_a & data_b;
            end
                
            LUI: begin
                result <= data_b;
            end

            CSR: begin
                result <= data_a;
            end
            
        endcase
    end
            
endmodule

