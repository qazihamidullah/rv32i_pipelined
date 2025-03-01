//###############################################
// Author:  Qazi Hamid Ullah (hamidullahqazi12@gmail.com)
// Date:	  2/24/2024
// Module:  PC_update.v       
// Description: Calculate the value of next PC 
//  
//  
//###############################################
module PC_update(
  input         [31:0]        PC_out,
  input                       jump,
  input                       jalr,
  input         [31:0]        rs1_out_exe,
  input         [31:0]        imm_data_from_exe,
  input         [31:0]        PC_out_exe,
  output reg       [31:0]        PC_input

);



    always @(*) begin
      if (jump)
        PC_input = PC_out_exe + imm_data_from_exe;
      else if (jalr)
        PC_input = rs1_out_exe + imm_data_from_exe;
      else
        PC_input = PC_out + 4;
      end
       


endmodule