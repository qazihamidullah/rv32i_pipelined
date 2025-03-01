//###############################################
// Author:  Qazi Hamid Ullah (hamidullahqazi12@gmail.com)
// Date:	  2/24/2024
// Module:  RISCV32I.sv       
// Description: This is the core top module
//  
//  
//###############################################
import risc_v_core_pkg::*;

module RV_32I(
  input                                       clk                         ,
  output                                      rden_a                      ,
  output                                      rden_b                      ,
  input                                       reset                       ,
  mem_ntv_interface_if                        mem_ntv_interface_imem      ,
  mem_ntv_interface_if                        mem_ntv_interface_dmem 

);
    

  ///Declaring wires 
    logic                 [31:0]              PC_input                    ;
    opcode_t                                  opcode_ID_EX                ;
    instruction_t                             instruction_o               ;
    instruction_t                             instruction_ID_EXE          ;
    instruction_t                             instruction_EXE_MEM         ;
    instruction_t                             instruction_MEM_WB          ;
    Control_signals_t                         controls_o                  ;
    Control_signals_t                         control_ID_EXE              ;
    Control_signals_t                         control_EXE_MEM             ;
    Control_signals_t                         control_MEM_WB              ;
    Control_signals_t                         hazard_mux_out              ;
    logic                 [31:0]              rs1_out                     ;
    logic                 [31:0]              pc_out                      ;
    logic                 [31:0]              imm_data                    ;                   //sign extended immediate data 
    logic                 [31:0]              reg_write_data              ;             //this will be stored in register file
    logic                 [31:0]              data_mem_write_data         ;        //this will be store in data memory                       
    logic                                     branch_flag                 ;                //to select the branch imm data in case of branch in PC input
    logic                 [31:0]              load_data                   ;
    logic                                     PC_en                       ;
    logic                 [31:0]              alu_out                     ;  
    logic                 [31:0]              data_mem_out                ;
    logic                 [31:0]              inst_mem_out                ;
    logic                 [3:0]               byteenable                  ;
    logic                 [31:0]              rs2_out                     ;
    logic                 [31:0]              ALU_out                     ;
    logic                 [31:0]              PC_out                      ;
    logic                 [31:0]              PC_out_reg0                      ;
    logic                 [2:0]               count                       ;
    logic                                     pc_en                       ;                       //coming from hazard mux unit
    logic                 [31:0]              imm_data_ID_EXE             ;
    logic                                     branch_flag_EXE_MEM         ;
    logic                 [63:0]              IF_ID_reg_out               ;
    logic                 [127:0]              ID_EXE_reg_out              ;
    logic                 [95:0]              EXE_MEM_reg_out             ;
    logic                 [95:0]              MEM_WB_reg_out              ;
    logic                 [63:0]              IF_ID_reg_input             ;
    logic                 [31:0]              inst_out_IF_ID       ;
    logic                 [31:0]              rs1_out_ID_EXE        ;
    logic                 [31:0]              rs2_out_ID_EXE        ;
    logic                 [31:0]              ALU_out_EXE_MEM        ;
    logic                 [31:0]              PC_out_reg                  ;
    logic                                     jump                        ;                       //tells whethet to jump in case of jump hazard 
    logic                 [31:0]              Instruction_fetch           ;
    logic                 [31:0]              Instruction_decode          ;
    logic                 [31:0]              Instruction_execute         ;
    logic                 [31:0]              Instruction_memory          ;
    logic                 [31:0]              Instruction_Writeback       ;
    logic                                     jalr                        ;
    logic                 [31:0]              ALU_out_MEM_WB;
    logic                 [31:0]              load_data_MEM_WB;
    logic                 [31:0]              PC_out_IF_ID;
    logic                 [31:0]              PC_out_ID_EXE;
    logic                 [31:0]              rs2_out_EXE_MEM;
    logic                                     flush;
    logic                                     flush_reg;
    logic                 [31:0]              data_mem_out_reg;

    ///////////////////////////////////////////////////////////////
  //assigning values to IMEM
    assign            inst_mem_out                            =   mem_ntv_interface_imem.rdata      ;
    assign            mem_ntv_interface_imem.addr             =   PC_out                            ;
    assign            rden_a                                  =   pc_en                             ;             //read enable for instruction memory 

  //assigning values to DMEM
    assign            mem_ntv_interface_dmem.byteenable       =   byteenable                        ;
    assign            mem_ntv_interface_dmem.wdata            =   rs2_out_ID_EXE                  ;
    assign            mem_ntv_interface_dmem.wren             =   control_ID_EXE.data_mem_wren      ;
    assign            rden_b                                  =   control_ID_EXE.data_mem_r_en      ;
    assign            data_mem_out                            =   mem_ntv_interface_dmem.rdata      ;
    assign            mem_ntv_interface_dmem.addr             =   ALU_out                           ;


    assign flush = jump | jalr | branch_flag;

    always_ff @ (posedge clk or negedge reset) begin
      if(!reset)
        flush_reg <= 0;
      else 
        flush_reg <= flush;
    end


//This is the Instruction Fetch stage             STAGE:  IF  
  
  //PC update unit 
    PC_update         PC_update_inst(

                                .PC_out             (PC_out)                       ,                                //comes from PC
                                .PC_out_exe         (PC_out_ID_EXE)                ,        
                                .jalr               (jalr)                         ,                                //registered PC_out
                                .jump               (jump | branch_flag)           ,
                                .rs1_out_exe        (rs1_out_ID_EXE)               ,                                //comes from register file
                                .imm_data_from_exe  (imm_data_ID_EXE)              ,                                //comes from mux
                                .PC_input           (PC_input)                                                      //goes to PC
          );

  //Program Counter 
    PC                PC_inst(
                                .clk              (clk)                         ,
                                .reset            (reset)                       ,
                                .in1              (PC_input)                    ,                                   //comes from PC_update
                                .PC_en            (pc_en)                       ,                                   //comes from decoder
                                .PC_out           (PC_out)                                                          //Goes to PC_update, ALU input
    );



    assign Instruction_fetch = inst_mem_out;                                                                        //from memory
    assign Instruction_decode = inst_out_IF_ID;                                                                     //from 
    assign inst_out_IF_ID =  IF_ID_reg_out[31:0];
    assign PC_out_IF_ID = IF_ID_reg_out[63:32];
    assign  rs1_out_ID_EXE = ID_EXE_reg_out[31:0];
    assign  rs2_out_ID_EXE = ID_EXE_reg_out[63:32];
    assign  PC_out_ID_EXE = ID_EXE_reg_out[95:64];
    assign load_data_MEM_WB = MEM_WB_reg_out[63:32];
    assign ALU_out_MEM_WB =   MEM_WB_reg_out[31:0];
    assign  ALU_out_EXE_MEM  =   EXE_MEM_reg_out[31:0];
    assign rs2_out_EXE_MEM = EXE_MEM_reg_out[63:32];

// temp
  always_ff @(posedge clk or negedge reset) begin
    if(!reset)
        PC_out_reg0 <='d0;
    else 
        PC_out_reg0 <=  PC_out;
  end


  //mux in case when branch flag is 1 then NOP instruction should be generated
    always_comb begin
      case(branch_flag)
        1'd0:     IF_ID_reg_input = {PC_out_reg0,inst_mem_out};
        1'd1:     IF_ID_reg_input = 64'h00000000;
        default:  IF_ID_reg_input = {PC_out_reg0,inst_mem_out};
    endcase
    end

  //PIPELINE REGISTER FOR INSTRUCTION FETCH IF
    pipeline_reg  IF_ID_reg(
                        .clk(clk),
                        .en(pc_en),  
                        .flush(flush | flush_reg),                                                                             //disable reg when hazard detected
                        .reset(reset),                                                                            //when branch flag is 1 theb nop instruction will go
                        .in(IF_ID_reg_input),                                                                     //PC_out, inst_out
                        .out(IF_ID_reg_out)                                                    
      );  defparam  IF_ID_reg.width = 64;

//This stage is the Instruction Decode Stage      STAGE:  ID
  //Instruction Decoder and Controller
    Instruction_reg   Instrution_reg_Inst(
                                  .instruction    (inst_out_IF_ID)                ,                               //instruction
                                  .branch_flag    (branch_flag)                   ,
                                  .instruction_o  (instruction_o)                 ,
                                  .controls_o     (controls_o) 
    );

  //Hazard Detection unit which will detect any hazard and make all the control signal 0 whenever hazards detected
    hazard_detect_unit  hazard_detect_unit_inst(
                                  .ID_EX_mem_read(instruction_ID_EXE.opcode == load_type),                                     //checks whether instruction is load 
                                  .rd_ID_EX(instruction_ID_EXE.rd_addr),
                                  .rs1_IF_ID(instruction_o.rs1_addr),
                                  .rs2_IF_ID(instruction_o.rs2_addr),
                                  .hazard_mux_sel(hazard_mux_sel),
                                  .pc_en(pc_en)
    );
    always_ff @ (posedge clk or negedge reset) begin
      if(!reset) begin
        opcode_ID_EX <= opcode_t'(7'd0);
      end
      else begin 
        opcode_ID_EX    <= instruction_o.opcode;
        
      end
    end
    assign  hazard_mux_out   =    (hazard_mux_sel) ? '{default:0} : controls_o ;

  //Register file containging 32 GPRs
    register_file     register_file_inst(
                                  .clk            (clk)                           ,
                                  .reset          (reset)                         ,
                                  .write_data     (reg_write_data)                ,
                                  .rs1            (instruction_o.rs1_addr)        ,                                       //address of rs1 reg
                                  .rs2            (instruction_o.rs2_addr)        ,                                       //address of rs2 reg
                                  .rd             (instruction_MEM_WB.rd_addr)    ,
                                  .rs1_out        (rs1_out)                       ,
                                  .rs2_out        (rs2_out)                       ,
                                  .we             (control_MEM_WB.reg_file_wren)                                          //comes from decoder
    );

  //Immediate Extender 
    Imm_extender      Imm_extender_inst(
                                .instruction_o    (instruction_o)               ,
                                .imm_mux_sel      (controls_o.imm_mux_sel)      ,
                                .imm_data         (imm_data)
  );

  //PIPELINE REGISTER FOR INSTRUCTION FETCH ID/EXE
    pipeline_reg  ID_EXE_reg(
                        .clk(clk),
                        .en(pc_en),         
                        .flush(flush),                                                                              //from hazard mux unit 
                        .reset(reset),
                        .in({Instruction_decode,PC_out_IF_ID,rs2_out,rs1_out}),                                                      //PC,rs2_out,rs1_out
                        .out(ID_EXE_reg_out)
    );  defparam  ID_EXE_reg.width = 128;

    assign Instruction_execute = ID_EXE_reg_out[127:96];



    always_ff @ (posedge clk or negedge reset) begin
      if(!reset | flush ) begin 
        control_ID_EXE <= 0;
        instruction_ID_EXE <= 0;
        imm_data_ID_EXE <= 0;
      end
      else begin
        control_ID_EXE <= hazard_mux_out;
        instruction_ID_EXE <= instruction_o;
        imm_data_ID_EXE <= imm_data;
    end
    end

//This stage is the Instruction Execute stage     STAGE:  EXE
  //This contains ALU and the ALU input muxes 
    execute           execute_inst(
                                  .MEM_WB_reg_file_w_en (control_MEM_WB.reg_file_wren)            ,
                                  .EX_MEM_reg_file_w_en (control_EXE_MEM.reg_file_wren)           ,  
                                  .ALU_EXE_MEM          (ALU_out_EXE_MEM)                         ,                             //ALU out registered
                                  .reg_write_data       (reg_write_data)                          ,                             //load data registered
                                  .rs1_ID_EX            (instruction_ID_EXE.rs1_addr)             ,
                                  .rs2_ID_EX            (instruction_ID_EXE.rs2_addr)             ,        
                                  .rd_EX_MEM            (instruction_EXE_MEM.rd_addr)             , 
                                  .rd_MEM_WB            (instruction_MEM_WB.rd_addr)              ,            
                                  .rs1_out              (rs1_out_ID_EXE)                          ,                             //comes from register file
                                  .PC_out               (PC_out_ID_EXE)                           ,                             //comes from PC after being registered
                                  .rs2_out              (rs2_out_ID_EXE)                          ,                             //comes from register file
                                  .imm_data             (imm_data_ID_EXE)                         ,                             //comes from mux
                                  .ALU_A_sel            (control_ID_EXE.ALU_A_sel)                ,                             //comes from decoder
                                  .ALU_B_sel            (control_ID_EXE.ALU_B_sel)                ,                             //comes from decoder
                                  .ALU_operation        (control_ID_EXE.ALU_op)                   ,                             //comes from decoder
                                  .ALU_out              (ALU_out)                                 ,                             //goes to data mem, Load store unit 
                                  .branch_flag          (branch_flag)                                                           //goes to PC_update
  );

    always_comb begin
      if(instruction_ID_EXE.opcode == J_type ) begin
        jalr = 0;
        jump = 1; end
      else if(instruction_ID_EXE.opcode == jalr_type ) begin
        jump = 0;
        jalr = 1; end
      else begin
        jump = 0;
        jalr = 0;
      end
    end

  //PIPELINE REGISTER FOR INSTRUCTION FETCH EXE/MEM
    pipeline_reg  EXE_MEM_reg(
                                  .clk(clk),
                                  .en(1),
                                  .reset(reset),
                                  .in({Instruction_execute,rs2_out_ID_EXE, ALU_out}),                                                                                   //ALU_out
                                  .out(EXE_MEM_reg_out)
    );defparam  EXE_MEM_reg.width = 96;

    
    assign Instruction_memory = EXE_MEM_reg_out[95:64];

    always_ff @ (posedge clk or negedge reset) begin
      if(!reset) begin
        control_EXE_MEM <= 0;
        instruction_EXE_MEM <= 0;
        branch_flag_EXE_MEM <= 0;
        data_mem_out_reg <= 0;
      end
      else begin
        control_EXE_MEM <= control_ID_EXE;
        instruction_EXE_MEM <= instruction_ID_EXE;
        branch_flag_EXE_MEM <= branch_flag;
        data_mem_out_reg <= data_mem_out;
      end
    end

//This stage is the Memory stage                  STAGE:  MEM
  //This module takes data mem out and load reg file according to LB , LH and LW
    Load_Store_unit   Load_Store_unit_inst(
                                  .ALU_out        (ALU_out_MEM_WB)               ,                                             //ALU_out
                                  .data_mem_out   (data_mem_out_reg)                  ,
                                  .func3          (instruction_MEM_WB.funct3)    ,
                                  .byteenable     (byteenable)                    ,                                             //output
                                  .load_data      (load_data)                                                                   //output
  );

  //PIPELINE REGISTER FOR INSTRUCTION FETCH MEM/WB
  pipeline_reg  MEM_WB_reg(
                        .clk(clk),
                        .en(1),
                        .reset(reset),
                        .in({Instruction_memory,load_data,ALU_out_EXE_MEM}),                                                                        //load data, registered ALU input
                        .out(MEM_WB_reg_out)                                                                                     //load data,ALU
  );defparam  MEM_WB_reg.width = 96;

    assign Instruction_Writeback = MEM_WB_reg_out[95:64];


    always_ff @ (posedge clk or negedge reset) begin
      if(!reset) begin
        control_MEM_WB <= 0;
        instruction_MEM_WB <= 0;
      end
      else begin
        control_MEM_WB <= control_EXE_MEM;
        instruction_MEM_WB <= instruction_EXE_MEM;
      end
    end

  //This is the writeback mux which selects between the ALU out and Load data coming from dmem
    assign            reg_write_data   =   (control_MEM_WB.reg_write_data_sel) ? load_data : ALU_out_MEM_WB  ;
//The last stage Writeback Stage                  STAGE:  WB

//to exit questa sim 
    always_comb begin
      if(instruction_MEM_WB == 7'b1110011 )
        $quit;
    end


endmodule