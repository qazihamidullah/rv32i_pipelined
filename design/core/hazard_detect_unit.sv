//###############################################
// Author:  Qazi Hamid Ullah (hamidullahqazi12@gmail.com)
// Date:	  2/24/2024
// Module:  hazard_detect_unit.sv       
// Description: This is hazard block for 
//  pipeling which generates flush signal and stall signal
//  
//###############################################
module  hazard_detect_unit(
  input     logic                 ID_EX_mem_read,                         //checks wether it is a load instruction or not
  input     logic   [4:0]         rd_ID_EX,
  input     logic   [4:0]         rs1_IF_ID,
  input     logic   [4:0]         rs2_IF_ID,
  output    logic                 hazard_mux_sel,
  output    logic                 pc_en

);

  always_comb begin
    if( ID_EX_mem_read                &&
        ((rd_ID_EX == rs1_IF_ID)      ||
        (rd_ID_EX == rs2_IF_ID) )  
    ) begin
        //stall the pipeline
      hazard_mux_sel  = 1'b1;               //all control signals equal to 0
      pc_en = 0;                            //PC stops 
    end
    else begin
      hazard_mux_sel  = 1'b0;               //normal control signals
      pc_en           = 1;                    
    end           
  end
  
endmodule

