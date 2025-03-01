//###############################################
// Author:  Qazi Hamid Ullah (hamidullahqazi12@gmail.com)
// Date:    2/24/2024
// Module:  ALU.v       
// Description: This is an ALU Module which performs
//  all the operations like +,-,*,/
//  
//###############################################
module ALU (
  input         [31:0]    input_1,
  input         [31:0]    input_2,
  input         [4:0]     ALU_sel,              //will determine which operation ALU will perform. This wil come from Decoder
  output reg              branch_flag,
  output reg    [31:0]    ALU_out           
);

      wire [4:0]  shamt;
      reg [63:0] mulh_temp;
      reg [63:0] mulsu_temp;

      assign shamt = input_2[4:0];
    //Declaring Paramteres 
      parameter add = 5'd0, sub = 5'd1, xor_ = 5'd2, and_ = 5'd3, or_ = 5'd4;
      parameter sll = 5'd5, srl = 5'd6, sra  = 5'd7, slt  = 5'd8, sltu= 7'd9;
      parameter beq = 5'd10, bne =5'd11, blt = 5'd12, bge = 5'd13, bltu = 5'd14, bgeu = 5'd15, lui = 5'd16, auipc = 5'd17, slli = 5'd18, srli = 5'd19, srai = 5'd20; 
      parameter mul = 5'd21, mulh = 5'd22, mulsu = 5'd23, mulu = 5'd24, div = 5'd25, divu = 5'd26, rem = 5'd27, remu = 5'd28;
  //ALU Operations     
    always @(*) begin
		branch_flag = 1'b0; ALU_out = 32'd0;
      case (ALU_sel)
      //R and I type 
        add:    ALU_out = input_1 + input_2;
        sub:    ALU_out = input_1 - input_2;
        xor_:   ALU_out = input_1 ^ input_2;
        and_:   ALU_out = input_1 & input_2;
        or_:    ALU_out = input_1 | input_2;
        sll:    ALU_out = input_1 << input_2;
        slli:   ALU_out = input_1 << shamt;
        srl:    ALU_out = input_1 >> input_2;
        srli:   ALU_out = input_1 >> shamt;
        sra:    ALU_out = $signed(input_1) >>> input_2;                                        //MSB extends
        srai:   ALU_out = $signed(input_1) >>> shamt;
        slt:    ALU_out = ($signed(input_1) < $signed(input_2)) ? 1:0;
        sltu:   ALU_out = (input_1 < input_2) ? 1:0;   
                                       //zero extended output  
      //RV32M support 
        mul:    ALU_out = $signed(input_1) * $signed(input_2);
        mulh:   begin 
                mulh_temp = $signed(input_1) * $signed(input_2);
                ALU_out   = mulh_temp[63:32];
        end
        mulsu:  begin
                mulsu_temp = $signed(input_1) * input_2;
                ALU_out    = mulsu_temp[63:32];
        end
        mulu:   ALU_out = input_1 * input_2;
        div:    ALU_out = $signed(input_1)/$signed(input_2);
        divu:   ALU_out = input_1/input_2;
        rem:    ALU_out = $signed(input_1) % $signed(input_2);
        remu:   ALU_out = input_1 % input_2;
      //Branch type   
        beq:    branch_flag = (input_1 == input_2) ? 1'b1 : 1'b0;
        bne:    branch_flag = (input_1 != input_2) ? 1'b1 : 1'b0;
        blt:    branch_flag = (input_1 < input_2) ? 1'b1 : 1'b0;
        bge:    branch_flag = (input_1 >= input_2) ? 1'b1 : 1'b0;
        bltu:   branch_flag = (input_1 < input_2) ? 1'b1 : 1'b0;                      //zero extended
        bgeu:   branch_flag = (input_1 >= input_2) ? 1'b1 : 1'b0;                     //zero extended
      //U type 
        lui:    ALU_out = input_2 ;
        auipc:  ALU_out = input_1 + input_2;
                
        
        default: begin ALU_out = 32'd0;branch_flag = 1'b0; end            //default value zero 
      endcase
    end

endmodule