//###############################################
// Author:  Qazi Hamid Ullah (hamidullahqazi12@gmail.com)
// Date:	  2/24/2024
// Module:  forwarding_unit.sv       
// Description: This is the forwarding block 
//  for pipelining
//  
//###############################################

module forwarding_unit(
    input       logic               EX_MEM_reg_file_w_en,
    input       logic               MEM_WB_reg_file_w_en,
    input       logic  [4:0]        rd_EX_MEM,  
    input       logic  [4:0]        rs1_ID_EX,
    input       logic  [4:0]        rs2_ID_EX,
    input       logic  [4:0]        rd_MEM_WB,  
    output      logic  [1:0]        Forward_mux_A,
    output      logic  [1:0]        Forward_mux_B

);

  //Execution Hazards and Memory Hazards 
    always_comb begin
      if (EX_MEM_reg_file_w_en && rd_EX_MEM != 0 && rd_EX_MEM == rs1_ID_EX) 
        Forward_mux_A = 2'b10;                                            //in case of Execution 
      else if ( MEM_WB_reg_file_w_en      && 
                rd_MEM_WB != 0            && 
                !(EX_MEM_reg_file_w_en    && 
                rd_EX_MEM != 0            && 
                rd_EX_MEM == rs1_ID_EX)   && 
                rd_MEM_WB == rs1_ID_EX) 
        Forward_mux_A = 2'b01;                                            //in case of memory hazards                                          
      else  
        Forward_mux_A = 2'b00;
  
      if (EX_MEM_reg_file_w_en && rd_EX_MEM != 0 && rd_EX_MEM == rs2_ID_EX)
        Forward_mux_B = 2'b10;                                            //in case of execution hazards
      else if ( MEM_WB_reg_file_w_en      && 
                rd_MEM_WB != 0            && 
                !(EX_MEM_reg_file_w_en    && 
                rd_EX_MEM != 0            && 
                rd_EX_MEM == rs2_ID_EX)   && 
                rd_MEM_WB == rs2_ID_EX)
        Forward_mux_B = 2'b01;                                            //in case of memory hazards
      else 
        Forward_mux_B = 2'b00;
      end





endmodule