//###############################################
// Author:  Qazi Hamid Ullah (hamidullahqazi12@gmail.com)
// Date:    2/24/2024
// Module:  execute.v       
// Description: This is execute stage where ALU do 
//  the calculations and the inputs of ALU are selected
//  
//###############################################
module execute(
  input       [4:0]       rs1_ID_EX,
  input                   EX_MEM_reg_file_w_en,
  input                   MEM_WB_reg_file_w_en,
  input       [31:0]      ALU_EXE_MEM,
  input       [4:0]       rs2_ID_EX,
  input       [4:0]       rd_EX_MEM,
  input       [4:0]       rd_MEM_WB,
  input       [31:0]      reg_write_data,
  input       [31:0]      rs1_out,
  input       [31:0]      PC_out,
  input       [31:0]      rs2_out,
  input       [31:0]      imm_data,
  input                   ALU_A_sel,
  input       [1:0]       ALU_B_sel,
  input       [4:0]       ALU_operation,
  output  reg [31:0]      ALU_out,
  output                  branch_flag
);

    wire      [31:0]      in1;
    reg       [31:0]      in2;
    wire      [31:0]      forward_A_out;
    wire      [31:0]      forward_B_out;
    wire      [1:0]       Forward_mux_A_sel;
    wire      [1:0]       Forward_mux_B_sel;

  //forwarding unit that will generate the mux control signals 
    forwarding_unit forwarding_unit_inst(
                                  .EX_MEM_reg_file_w_en(EX_MEM_reg_file_w_en),
                                  .MEM_WB_reg_file_w_en(MEM_WB_reg_file_w_en),
                                  .rd_EX_MEM(rd_EX_MEM),   
                                  .rs1_ID_EX(rs1_ID_EX), 
                                  .rs2_ID_EX(rs2_ID_EX), 
                                  .rd_MEM_WB(rd_MEM_WB),   
                                  .Forward_mux_A(Forward_mux_A_sel),                                     //mux A select line
                                  .Forward_mux_B(Forward_mux_B_sel)                                      //mux B select line
    );


  //forwarding mux A 
    mux3x1 forwarding_mux_A(
                .mux_in1(rs1_out),                                                          //coming from ALU_mux_A
                .mux_in2(reg_write_data),
                .mux_in3(ALU_EXE_MEM),
                .mux_sel(Forward_mux_A_sel),
                .mux_out(forward_A_out)
    );

  //forwarding mux B 
    mux3x1 forwarding_mux_B(
                .mux_in1(rs2_out),
                .mux_in2(reg_write_data),
                .mux_in3(ALU_EXE_MEM),
                .mux_sel(Forward_mux_B_sel),
                .mux_out(forward_B_out)
    );




  //ALU MUX A
    assign in1 = (ALU_A_sel) ? PC_out   : forward_A_out;
  //ALU MUX B
    always @(*) begin
      case (ALU_B_sel)
        2'd0:         in2 = forward_B_out;
        2'd1:         in2 = imm_data;
        2'd2:         in2 = 32'd4;
        default:      in2 = 32'd4;
      endcase
    end
    
  //ALU 
    ALU ALU_inst(
                .input_1(in1),
                .input_2(in2),
                .ALU_sel(ALU_operation),
                .branch_flag(branch_flag),
                .ALU_out(ALU_out)
    ); 

  
endmodule