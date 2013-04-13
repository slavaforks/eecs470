/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.v                                          //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline.                                //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
/***
*
* These are the abbreviations to make it easier to reference:
*
*    IF  = Instruction Fetch
*    ID  = Instruction Decode     
*    MT  = Map Table
*    REG = Register File
*    ROB = Reorder Buffer
*    RS  = Reservation Station
*    EX  = Execute
*    CM  = Complete
*     
***/
`timescale 1ns/100ps

module pipeline (// Inputs
                 clock,
                 reset,
                 mem2proc_response,
                 mem2proc_data,
                 mem2proc_tag,
                 
                 // Outputs
                 proc2mem_command,
                 proc2mem_addr,
                 proc2mem_data,

                 pipeline_completed_insts,
                 pipeline_error_status,
                 pipeline_commit_wr_data,
                 pipeline_commit_wr_idx,
                 pipeline_commit_wr_en,
                 pipeline_commit_NPC,


                 // testing hooks (these must be exported so we can test
                 // the synthesized version) data is tested by looking at
                 // the final values in memory
                 if_NPC_out,
                 if_IR_out,
                 if_valid_inst_out,
                 if_id_NPC,
                 if_id_IR,
                 if_id_valid_inst,
                 id_ex_NPC,
                 id_ex_IR,
                 id_ex_valid_inst,
                 ex_mem_NPC,
                 ex_mem_IR,
                 ex_mem_valid_inst,
                 mem_wb_NPC,
                 mem_wb_IR,
                 mem_wb_valid_inst
                );

  input         clock;             // System clock
  input         reset;             // System reset
  input  [3:0]  mem2proc_response; // Tag from memory about current request
  input  [63:0] mem2proc_data;     // Data coming back from memory
  input  [3:0]  mem2proc_tag;      // Tag from memory about current reply

  output [1:0]  proc2mem_command;  // command sent to memory
  output [63:0] proc2mem_addr;     // Address sent to memory
  output [63:0] proc2mem_data;     // Data sent to memory

  output [3:0]  pipeline_completed_insts;
  output [3:0]  pipeline_error_status;
  output [4:0]  pipeline_commit_wr_idx;
  output [63:0] pipeline_commit_wr_data;
  output        pipeline_commit_wr_en;
  output [63:0] pipeline_commit_NPC;

  output [63:0] if_NPC_out;
  output [31:0] if_IR_out;
  output        if_valid_inst_out;
  output [63:0] if_id_NPC;
  output [31:0] if_id_IR;
  output        if_id_valid_inst;
  output [63:0] id_ex_NPC;
  output [31:0] id_ex_IR;
  output        id_ex_valid_inst;
  output [63:0] ex_mem_NPC;
  output [31:0] ex_mem_IR;
  output        ex_mem_valid_inst;
  output [63:0] mem_wb_NPC;
  output [31:0] mem_wb_IR;
  output        mem_wb_valid_inst;

  // Pipeline register enables
  wire   if_id_enable, id_ex_enable, ex_mem_enable, mem_wb_enable;

 // Outputs from IF-Stage
  wire [63:0] if_NPC1_out;
  wire [31:0] if_IR1_out;
  wire        if_valid_inst1_out;

  wire [63:0] if_NPC2_out;
  wire [31:0] if_IR2_out;
  wire        if_valid_inst2_out;
  

// Outputs from IF/ID Pipeline Register
  reg  [63:0] if_id_NPC1;
  reg  [31:0] if_id_IR1;
  reg         if_id_valid_inst1;
 
  reg  [63:0] if_id_NPC2;
  reg  [31:0] if_id_IR2;
  reg         if_id_valid_inst2;

//Outputs from ID Stage 
  wire  [4:0] id_rega_out_1, id_regb_out_1, id_dest_reg_out_1;
  wire  [1:0] id_opa_select_out_1, id_opb_select_out_1;
  wire  [4:0] id_alu_func_out_1;
  wire        id_rd_mem_out_1;
  wire        id_wr_mem_out_1;
  wire        id_cond_branch_out_1;
  wire        id_uncond_branch_out_1;
  wire        id_halt_out_1;
  wire        id_illegal_out_1;
  wire        id_valid_inst_out_1; 
  
  wire  [4:0] id_rega_out_2, id_regb_out_2, id_dest_reg_out_2;
  wire  [1:0] id_opa_select_out_2, id_opb_select_out_2;
  wire  [4:0] id_alu_func_out_2;
  wire        id_rd_mem_out_2;
  wire        id_wr_mem_out_2;
  wire        id_cond_branch_out_2;
  wire        id_uncond_branch_out_2;
  wire        id_halt_out_2;
  wire        id_illegal_out_2;
  wire        id_valid_inst_out_2;  
  
//Outputs from ID / [MT/REG] Pipeline Regsiter

  //MT Pipeline Registers
  reg  [4:0] mt_rega_1, mt_regb_1;
 
  reg  [4:0] mt_rega_2, mt_regb_2; 


  //REG Pipeline Registers 
  reg  [4:0] reg_inst1_rega;
  reg  [4:0] reg_inst1_regb;
  reg  [4:0] reg_inst2_rega;
  reg  [4:0] reg_inst2_regb;
   
  reg  [4:0] reg_inst1_dest;
  reg  [4:0] reg_inst2_dest;
  reg [63:0] reg_inst1_value;
  reg [63:0] reg_inst2_value;
  
  //FF Pipeline Registers
  reg  [4:0] ff_dest_reg_1;
  reg  [1:0] ff_opa_select_1, ff_opb_select_1;
  reg  [4:0] ff_alu_func_1;
  reg        ff_rd_mem_1;
  reg        ff_wr_mem_1;
  reg        ff_cond_branch_1;
  reg        ff_uncond_branch_1;
  reg        ff_halt_1;
  reg        ff_illegal_1;
  reg        ff_valid_inst_1; 

  reg  [4:0] ff_dest_reg_2;  
  reg  [1:0] ff_opa_select_out_2, ff_opb_select_2;
  reg  [4:0] ff_alu_func_2;
  reg        ff_rd_mem_2;
  reg        ff_wr_mem_2;
  reg        ff_cond_branch_2;
  reg        ff_uncond_branch_2;
  reg        ff_halt_2;
  reg        ff_illegal_2;
  reg        ff_valid_inst_2;  

//Outputs from MT
   wire [7:0] mt_inst1_taga_out, mt_inst1_tagb_out;
   wire [7:0] mt_inst2_taga_out, mt_inst2_tagb_out;

//Outputs from [MT/REG] / [RS/ROB] Pipeline Register
   reg        rob_inst1_valid;
   reg        rob_inst2_valid;
   reg  [4:0] rob_inst1_dest;
   reg  [4:0] rob_inst2_dest;

   reg  [7:0] rob_inst1_rega_tag;
   reg  [7:0] rob_inst1_regb_tag;
   reg  [7:0] rob_inst2_rega_tag;
   reg  [7:0] rob_inst2_regb_tag;
   
   reg [63:0] rs_inst1_rega_value_in, rs_inst1_regb_value_in;
   reg [7:0]  rs_inst1_rega_tag_in, rs_inst1_regb_tag_in;
   reg [4:0]  rs_inst1_dest_reg_in;
   reg [7:0]  rs_inst1_dest_tag_in;
   reg [1:0]  rs_inst1_opa_select_in, rs_inst1_opb_select_in;
   reg [4:0]  rs_inst1_alu_func_in;
   reg        rs_inst1_rd_mem_in, rs_inst1_wr_mem_in;
   reg        rs_inst1_cond_branch_in, rs_inst1_uncond_branch_in;
   reg [63:0] rs_inst1_NPC_in;
   reg [31:0] rs_inst1_IR_in;
   reg        rs_inst1_valid;
   
   reg [63:0] rs_inst2_rega_value_in, rs_inst2_regb_value_in;
   reg [7:0]  rs_inst2_rega_tag_in, rs_inst2_regb_tag_in;
   reg [4:0]  rs_inst2_dest_reg_in;
   reg [7:0]  rs_inst2_dest_tag_in;
   reg [1:0]  rs_inst2_opa_select_in, rs_inst2_opb_select_in;
   reg [4:0]  rs_inst2_alu_func_in;
   reg        rs_inst2_rd_mem_in, rs_inst2_wr_mem_in;
   reg        rs_inst2_cond_branch_in, rs_inst2_uncond_branch_in;
   reg [63:0] rs_inst2_NPC_in;
   reg [31:0] rs_inst2_IR_in;
   reg        rs_inst2_valid;

   reg [63:0] inst1_rega_rob_value_in;
   reg [63:0] inst1_regb_rob_value_in;
   reg [63:0] inst2_rega_rob_value_in;
   reg [63:0] inst2_regb_rob_value_in;


//Outputs from ROB
   wire [7:0] rob_inst1_tag_out;
   wire [7:0] rob_inst2_tag_out;

   wire [63:0] rob_inst1_rega_value_out;
   wire [63:0] rob_inst1_regb_value_out;
   wire [63:0] rob_inst2_rega_value_out;
   wire [63:0] rob_inst2_regb_value_out;

   wire [4:0]  rob_inst1_dest_out;
   wire [63:0] rob_inst1_value_out;
   wire [4:0]  rob_inst2_dest_out;
   wire [63:0] rob_inst2_value_out;

   wire rob_inst1_mispredicted_out;
   wire rob_inst2_mispredicted_out;

   wire rob_rob_full;
   
//Outputs from RS
   wire [63:0] rs_inst1_rega_value_out, rs_inst1_regb_value_out;
   wire [1:0]  rs_inst1_opa_select_out, rs_inst1_opb_select_out;
   wire [4:0]  rs_inst1_alu_func_out;
   wire        rs_inst1_rd_mem_out, rs_inst1_wr_mem_out;
   wire        rs_inst1_cond_branch_out, rs_inst1_uncond_branch_out;
   wire [63:0] rs_inst1_NPC_out;
   wire [31:0] rs_inst1_IR_out;
   wire        rs_inst1_valid_out;
   wire [4:0]  rs_inst1_dest_reg_out;
   wire [7:0]  rs_inst1_dest_tag_out;

   wire [63:0] rs_inst2_rega_value_out, rs_inst2_regb_value_out;
   wire [1:0]  rs_inst2_opa_select_out, rs_inst2_opb_select_out;
   wire [4:0]  rs_inst2_alu_func_out;
   wire        rs_inst2_rd_mem_out, rs_inst2_wr_mem_out;
   wire        rs_inst2_cond_branch_out, rs_inst2_uncond_branch_out;
   wire [63:0] rs_inst2_NPC_out;
   wire [31:0] rs_inst2_IR_out;
   wire        rs_inst2_valid_out;
   wire [4:0]  rs_inst2_dest_reg_out;
   wire [7:0]  rs_inst2_dest_tag_out;
   
//Outputs from [RS/ROB] / EX Pipeline Register  
  reg  [63:0] ex_NPC_1;         // incoming instruction PC+4
  reg  [63:0] ex_PPC_1;		 // Predicted PC for branches
  reg  [31:0] ex_IR_1;          // incoming instruction
  reg   [4:0] ex_dest_reg_1;	 // destination register
  reg  [63:0] ex_rega_1;        // register A value from reg file
  reg  [63:0] ex_regb_1;        // register B value from reg file
  reg   [1:0] ex_opa_select_1;  // opA mux select from decoder
  reg   [1:0] ex_opb_select_1;  // opB mux select from decoder
  reg   [4:0] ex_alu_func_1;    // ALU function select from decoder
  reg         ex_cond_branch_1;   // is this a cond br? from decoder
  reg         ex_uncond_branch_1; // is this an uncond br? from decoder

  reg  [63:0] ex_NPC_2;         // incoming instruction PC+4
  reg  [63:0] ex_PPC_2;		 // Predicted PC for branches
  reg  [31:0] ex_IR_2;          // incoming instruction
  reg   [4:0] ex_dest_reg_2;	 // destination register
  reg  [63:0] ex_rega_2;        // register A value from reg file
  reg  [63:0] ex_regb_2;        // register B value from reg file
  reg   [1:0] ex_opa_select_2;  // opA mux select from decoder
  reg   [1:0] ex_opb_select_2;  // opB mux select from decoder
  reg   [4:0] ex_alu_func_2;    // ALU function select from decoder
  reg         ex_cond_branch_2;   // is this a cond br? from decoder
  reg         ex_uncond_branch_2; // is this an uncond br? from decoder  
   
//Outputs from EX-Stage
  wire        stall_bus_1;	     // Should input bus 1 stall?
  wire		    stall_bus_2;	     // Should input bus 2 stall?
  wire        ex_branch_taken;  // is this a taken branch?
  
  // Bus 1
  wire  [4:0] ex_dest_reg_out_1;	 // Destination Reg
  wire [63:0] ex_result_out_1;	 // Bus 1 Result
  wire	    	ex_valid_out_1;		 // Valid Output
  wire        ex_mispredict_out_1;
  
  // Bus 2
  wire  [4:0] ex_dest_reg_out_2;   // Desitnation Reg
  wire [63:0] ex_result_out_2;	 // Bus 2 result
  wire	    	ex_valid_out_2;		 // Valid Output
  wire        ex_mispredict_out_2;

   
  wire  [4:0] LSQ_tag_out_1;
  wire [63:0] LSQ_address_out_1;
  wire [63:0] LSQ_value_out_1;

  wire  [4:0] LSQ_tag_out_2;
  wire [63:0] LSQ_address_out_2;
  wire [63:0] LSQ_value_out_2;

//Outputs from Register File
   wire [63:0] reg_inst1_rega_out;
   wire [63:0] reg_inst1_regb_out;
   wire [63:0] reg_inst2_rega_out;
   wire [63:0] reg_inst2_regb_out;
   wire [31:0] reg_clear_entries;


//Outputs from Complete Stage
  wire  [7:0] cm_tag_1;
  wire [63:0] cm_value_1
  wire  [7:0] cm_tag_2;
  wire [63:0] cm_value_2;  
  /**********************************/
  /**********************************/
  /**********************************/

  // Memory interface/arbiter wires
  wire [63:0] proc2Dmem_addr, proc2Imem_addr;
  wire [1:0]  proc2Dmem_command, proc2Imem_command;
  wire [3:0]  Imem2proc_response, Dmem2proc_response;

  // Icache wires
  wire [63:0] cachemem_data;
  wire        cachemem_valid;
  wire  [6:0] Icache_rd_idx;
  wire [21:0] Icache_rd_tag;
  wire  [6:0] Icache_wr_idx;
  wire [21:0] Icache_wr_tag;
  wire        Icache_wr_en;
  wire [63:0] Icache_data_out, proc2Icache_addr;
  wire        Icache_valid_out;

  assign pipeline_completed_insts = {3'b0, mem_wb_valid_inst};
  assign pipeline_error_status = 
    mem_wb_illegal ? `HALTED_ON_ILLEGAL
                   : mem_wb_halt ? `HALTED_ON_HALT
                                 : `NO_ERROR;

  assign pipeline_commit_wr_idx = wb_reg_wr_idx_out;
  assign pipeline_commit_wr_data = wb_reg_wr_data_out;
  assign pipeline_commit_wr_en = wb_reg_wr_en_out;
  assign pipeline_commit_NPC = mem_wb_NPC;

  assign proc2mem_command =
           (proc2Dmem_command==`BUS_NONE)?proc2Imem_command:proc2Dmem_command;
  assign proc2mem_addr =
           (proc2Dmem_command==`BUS_NONE)?proc2Imem_addr:proc2Dmem_addr;
  assign Dmem2proc_response = 
      (proc2Dmem_command==`BUS_NONE) ? 0 : mem2proc_response;
  assign Imem2proc_response =
      (proc2Dmem_command==`BUS_NONE) ? mem2proc_response : 0;


  ///***  MAKE D-CACHE  ***///

  // Actual cache (data and tag RAMs)
  cache cachememory (// inputs
                              .clock(clock),
                              .reset(reset),
                              .wr1_en(Icache_wr_en),
                              .wr1_idx(Icache_wr_idx),
                              .wr1_tag(Icache_wr_tag),
                              .wr1_data(mem2proc_data),
                              
                              .rd1_idx(Icache_rd_idx),
                              .rd1_tag(Icache_rd_tag),

                              // outputs
                              .rd1_data(cachemem_data),
                              .rd1_valid(cachemem_valid)
                             );

  // Cache controller
  icache icache_0(// inputs 
                  .clock(clock),
                  .reset(reset),

                  .Imem2proc_response(Imem2proc_response),
                  .Imem2proc_data(mem2proc_data),
                  .Imem2proc_tag(mem2proc_tag),

                  .proc2Icache_addr(proc2Icache_addr),
                  .cachemem_data(cachemem_data),
                  .cachemem_valid(cachemem_valid),

                   // outputs
                  .proc2Imem_command(proc2Imem_command),
                  .proc2Imem_addr(proc2Imem_addr),

                  .Icache_data_out(Icache_data_out),
                  .Icache_valid_out(Icache_valid_out),
                  .current_index(Icache_rd_idx),
                  .current_tag(Icache_rd_tag),
                  .last_index(Icache_wr_idx),
                  .last_tag(Icache_wr_tag),
                  .data_write_enable(Icache_wr_en)
                 );


  //////////////////////////////////////////////////
  //                                              //
  //                  IF-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  if_stage if_stage_0 (// Inputs
                       .clock (clock),
                       .reset (reset),
                       .mem_wb_valid_inst(mem_wb_valid_inst),
                       .ex_mem_take_branch(ex_mem_take_branch),
                       .ex_mem_target_pc(ex_mem_alu_result),
                       .Imem2proc_data(Icache_data_out),
                       .Imem_valid(Icache_valid_out),
                       
                       // Outputs
                       .if_NPC_out(if_NPC_out), 
                       .if_IR_out(if_IR_out),
                       .proc2Imem_addr(proc2Icache_addr),
                       .if_valid_inst_out(if_valid_inst_out)
                      );


  //////////////////////////////////////////////////
  //                                              //
  //            IF/ID Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  always @(posedge clock)
  begin
    if(reset)
    begin
      id_NPC_1        <= `SD 0;
      id_IR_1         <= `SD `NOOP_INST;
      id_valid_inst_1 <= `SD `FALSE;
      
      id_NPC_2        <= `SD 0;
      id_IR_2         <= `SD `NOOP_INST;
      id_valid_inst_2 <= `SD `FALSE;
    end // if (reset)
    else
      begin
      id_NPC_1        <= `SD if_NPC_1;
      id_IR_1         <= `SD if_IR_1;
      id_valid_inst_1 <= `SD if_valid_inst_1;
      
      id_NPC_2        <= `SD if_NPC_2;
      id_IR_2         <= `SD if_IR_2;
      id_valid_inst_2 <= `SD if_valid_inst_2;
      end // if (if_id_enable)
  end // always

   
  //////////////////////////////////////////////////
  //                                              //
  //                  ID-Stage                    //
  //                                              //
  //////////////////////////////////////////////////

  
  id_stage id_stage0(
                      // Inputs
                      .clock(clock),
                      .reset(reset),
                      if_id_IR_1(id_IR_1),
                      if_id_valid_inst_1(id_valid_inst_1),

                      if_id_IR_2(if_IR_2),
                      if_id_valid_inst_2(id_valid_inst_2),



                      // Outputs
                      .id_opa_select_out_1(id_opa_select_out_1),
                      .id_opb_select_out_1(id_opb_select_out_1),
                      .id_alu_func_out_1(id_alu_func_out_1),
                      .id_rd_mem_out_1(id_rd_mem_out_1),
                      .id_wr_mem_out_1(id_wr_mem_out_1),
                      .id_cond_branch_out_1(id_cond_branch_out_1),
                      .id_uncond_branch_out_1(id_uncond_branch_out_1),
                      .id_halt_out_1(id_halt_out_1),
                      .id_illegal_out_1(id_illegal_out_1),
                      .id_valid_inst_out_1(id_valid_inst_out_1),
                      
                      .ra_idx_1(id_rega_out_1),
                      .rb_idx_1(id_regb_out_1),
                      .id_dest_reg_idx_out_1,

                      .id_opa_select_out_2(id_opa_select_out_2),
                      .id_opb_select_out_2(id_opb_select_out_2),
                      .id_alu_func_out_2(id_alu_func_out_2),
                      .id_rd_mem_out_2(id_rd_mem_out_2),
                      .id_wr_mem_out_2(id_wr_mem_out_2),
                      .id_cond_branch_out_2(id_cond_branch_out_2),
                      .id_uncond_branch_out_2(id_uncond_branch_out_2),
                      .id_halt_out_2(id_halt_out_2),
                      .id_illegal_out_2(id_halt_out_2,
                      .id_valid_inst_out_2,
                      
                      .ra_idx_2(id_rega_out_2),
                      .rb_idx_2(id_regb_out_2),
                      .id_dest_reg_idx_out_2
                      
                      );
  // Note: Decode signals for load-lock/store-conditional and "get CPU ID"
  //  instructions (id_{ldl,stc}_mem_out, id_cpuid_out) are not connected
  //  to anything because the provided EX and MEM stages do not implement
  //  these instructions.  You will have to implement these instructions
  //  if you plan to do a multicore project.
  
  
  
  //////////////////////////////////////////////////
  //                                              //
  //         ID/[MT/REG] Pipeline Register        //
  //                                              //
  //////////////////////////////////////////////////

  //Map Table Synchonous
  always @(posedge clock)
  begin
    if(reset)
    begin
      mt_rega_1 <= `SD 0;
      mt_regb_1 <= `SD 0;
      
      mt_rega_2 <= `SD 0;
      mt_regb_2 <= `SD 0;
    end
    else
    begin 
      mt_rega_1 <= `SD id_rega_out_1;
      mt_regb_1 <= `SD id_regb_out_1;
      
      mt_rega_2 <= `SD id_rega_out_1;
      mt_regb_2 <= `SD id_regb_out_1;      
    end
  end
  
  //REG synchronous
  always @(posedge clock)
  begin
    if(reset)
    begin
    
    reg_inst1_rega <= `SD 0;
    reg_inst1_regb <= `SD 0;
    reg_inst1_dest <= `SD 0;
    reg_inst1_value <= `SD 0;

    reg_inst2_rega <= `SD 0;
    reg_inst2_regb <= `SD 0;
    reg_inst2_dest <= `SD 0;
    reg_inst2_value <= `SD 0;
    
    
    end
    else
    begin
    
    //comes from decode
    reg_inst1_rega  <= `SD id_rega_out_1;
    reg_inst1_regb  <= `SD id_regb_out_1;
    
    //comes from ROB
    reg_inst1_dest  <= `SD rob_inst1_dest_out;
    reg_inst1_value <= `SD rob_inst1_value_out;
    

    reg_inst2_rega  <= `SD id_rega_out_2;
    reg_inst2_regb  <= `SD id_regb_out_2;
    
    reg_inst2_dest  <= `SD rob_inst2_dest_out;
    reg_inst2_value <= `SD rob_inst2_dest_out;
    
    end
  end
  
  //Fast Forward Synchonous  
  always @(posedge clock)
  begin 
    if(reset)
    begin
      ff_dest_reg_1       <= `SD 0;
      ff_opa_select_1     <= `SD 0;
      ff_alu_func_1       <= `SD 0;
      ff_rd_mem_1         <= `SD 0;
      ff_wr_mem_1         <= `SD 0;
      ff_cond_branch_1    <= `SD 0;
      ff_uncond_branch_1  <= `SD 0;
      ff_halt_1           <= `SD 0;
      ff_illegal_1        <= `SD 0;
      ff_valid_inst_1     <= `SD 0;
  
      ff_dest_reg_2       <= `SD 0;
      ff_opa_select_2     <= `SD 0;
      ff_alu_func_2       <= `SD 0;
      ff_rd_mem_2         <= `SD 0;
      ff_wr_mem_2         <= `SD 0;
      ff_cond_branch_2    <= `SD 0;
      ff_uncond_branch_2  <= `SD 0;
      ff_halt_2           <= `SD 0;
      ff_illegal_2        <= `SD 0;
      ff_valid_inst_2     <= `SD 0;
    end
    else
    begin
      ff_dest_reg_1       <= `SD id_dest_reg_out_1;
      ff_opa_select_1     <= `SD id_opa_select_out_1;
      ff_alu_func_1       <= `SD id_alu_func_out_1;
      ff_rd_mem_1         <= `SD id_rd_mem_out_1;
      ff_wr_mem_1         <= `SD id_wr_mem_out_1;
      ff_cond_branch_1    <= `SD id_cond_branch_1;
      ff_uncond_branch_1  <= `SD id_uncond_branch_1;
      ff_halt_1           <= `SD id_halt_1;
      ff_illegal_1        <= `SD id_illegal_1;
      ff_valid_inst_1     <= `SD id_valid_inst_1;
      
      ff_dest_reg_2       <= `SD id_dest_reg_2;
      ff_opa_select_2     <= `SD id_opa_select_2;
      ff_alu_func_2       <= `SD id_alu_func_2;
      ff_rd_mem_2         <= `SD id_rd_mem_2;
      ff_wr_mem_2         <= `SD id_wr_mem_2;
      ff_cond_branch_2    <= `SD id_cond_branch_2;
      ff_uncond_branch_2  <= `SD id_uncond_branch_2;
      ff_halt_2           <= `SD id_halt_2;
      ff_illegal_2        <= `SD id_illegal_2;
      ff_valid_inst_2     <= `SD id_valid_inst_2;        
    end
  end   
      
       
  

  //////////////////////////////////////////////////
  //                                              //
  //                [MT/REG] Stage                //
  //                                              //
  ////////////////////////////////////////////////// 
   map_table map_table_0 (//Inputs
  
                           .clock(clock), .reset(reset), .clear_entries(clear_entries),


                           // instruction 1 access inputs //
                           //THESE COME FROM DECODE
                           .inst1_rega_in(mt_rega_1),
                           .inst1_regb_in(mt_regb_1),
                           
                           //THESE COME FROM ROB
                           .inst1_dest_in,
                           .inst1_tag_in,

                           // instruction 2 access inputs //
                           .inst2_rega_in(mt_rega_2),
                           .inst2_regb_in(mt_regb_2),
                           
                           .inst2_dest_in,
                           .inst2_tag_in,

                           // cdb inputs //
                           .cdb1_tag_in(cm_tag_1),
                           .cdb2_tag_in(cm_tag_2),
                          
                           // tag outputs //
                           .inst1_taga_out(mt_inst1_taga), .inst1_tagb_out(mt_inst1_tagb),
                           .inst2_taga_out(mt_inst2_taga), .inst2_tagb_out(mt_inst2_tagb)  
                           
                           );      
                           


  register_file register_file0(//Inputs
                      
                               .clock(clock), .reset(reset),

                               //COMES FROM DECODE
                               // input busses: register indexes and values in // 
                               .inst1_rega_in, .inst1_regb_in, 
                               .inst2_rega_in, .inst2_regb_in,
                               
                               //Destination and Value to write
                               .inst1_dest_in(reg_inst1_dest), .inst1_value_in(reg_inst1_value),
                               .inst2_dest_in(reg_inst2_dest), .inst2_value_in(reg_inst2_value),

                               // output busses: register values out //
                               .inst1_rega_out(reg_inst1_rega_out), .inst1_regb_out(reg_inst1_regb_out),
                               .inst2_rega_out(reg_inst2_regb_out), .inst2_regb_out(reg_inst2_regb_out),

                               // ouput signals: tell the map table when to clear //
                               .clear_entries(clear_entries)
                               );



  //////////////////////////////////////////////////
  //                                              //
  //    [MT/REG] / [RS/ROB] Pipeline Register     //
  //                                              //
  //////////////////////////////////////////////////    

  //ROB Synchronous
  always @(posedge clock)
  begin
    if(reset)
    begin
      rob_inst1_valid <= `SD 0;
      rob_inst1_dest <= `SD 0;
      rob_inst1_rega_tag <= `SD 0;
      rob_inst1_regb_tag <= `SD 0;
    
      rob_inst2_valid <= `SD 0;
      rob_inst2_dest <= `SD 0;
      rob_inst2_rega_tag <= `SD 0;
      rob_inst2_regb_tag <= `SD 0;
    end
    else
    begin

      rob_inst1_valid <= `SD ff_valid_inst_1;
      rob_inst1_dest <= `SD ff_dest_reg_1;
      
      rob_inst1_rega_tag <= `SD 0;
      rob_inst1_regb_tag <= `SD 0;
    
      rob_inst2_valid <= `SD ff_valid_inst_2;
      rob_inst2_dest <= `SD ff_dest_reg_2;
      
      rob_inst2_rega_tag <= `SD 0;
      rob_inst2_regb_tag <= `SD 0;
    
    end
  end
  
  //RS Synchronous
  always @(posedge clock)
  begin
    if(reset)
    begin
    
    
    end
    else
    begin
    
    
    end
  end

  //////////////////////////////////////////////////
  //                                              //
  //               [RS/ROB] Stage                 //
  //                                              //
  //////////////////////////////////////////////////             
                                      
  reservation_station reservation_station_0(//Inputs
                  
                                           // signals and busses in for inst 1 (from id1) //
                                           //Values from ROB
                                           .inst1_rega_value_in(inst1_rega_value),
                                           .inst1_regb_value_in(inst1_regb_value),
                                        
                                           //Tags from Map Table
                                           .inst1_rega_tag_in(mt_inst1_taga_out),
                                           .inst1_regb_tag_in(mt_inst1_tagb_out),


                                           //Tag from ROB                           
                                           .inst1_dest_tag_in(inst1_tag), 
                                           
                                           
                                           
                                           //Instruction signals from Decode                         
                                           .inst1_dest_reg_in(),
                                           .inst1_opa_select_in(),
                                           .inst1_opb_select_in(),
                                           .inst1_alu_func_in,
                                           .inst1_rd_mem_in,
                                           .inst1_wr_mem_in,
                                           .inst1_cond_branch_in,
                                           .inst1_uncond_branch_in,
                                           .inst1_valid,

                                           // signals and busses in for inst 2 (from id2) //
                                           //Values from DECODE
                                           .inst2_rega_value_in(),
                                           .inst2_regb_value_in(),
                                           
                                           //Tags from Map Table
                                           .inst2_rega_tag_in(mt_inst2_taga_out),
                                           .inst2_regb_tag_in(mt_inst2_tagb_out),
                                           
                                           //Tag from ROB
                                           .inst2_dest_tag_in(inst2_tag),
                                           
                                           //Instruction signals from Decode
                                           .inst2_dest_reg_in,
                                           .inst2_opa_select_in,
                                           .inst2_opb_select_in,
                                           .inst2_alu_func_in,
                                           .inst2_rd_mem_in,
                                           .inst2_wr_mem_in,
                                           .inst2_cond_branch_in,
                                           .inst2_uncond_branch_in,
                                           .inst2_valid,

                                           // cdb inputs //
                                           .cdb1_tag_in(cm_tag_1),
                                           .cdb2_tag_in(cm_tag_2),
                                           .cdb1_value_in(cm_value_1),
                                           .cdb2_value_in(cm_value_2),

                                           // inputs from the ROB //
                                           .inst1_rega_rob_value_in(rob_inst1_rega_value),
                                           .inst1_regb_rob_value_in(rob_inst1_regb_value),
                                           .inst2_rega_rob_value_in(rob_inst2_rega_value),
                                           .inst2_regb_rob_value_in(rob_inst2_regb_value),


                                           /*** OUTPUTS ***/
                                           // signals and busses out for inst1 to the ex stage
                                           .inst1_rega_value_out(rs_inst1_rega_value_out),
                                           .inst1_regb_value_out(rs_inst1_rega_value_out),
                                           
                                           .inst1_opa_select_out(rs_inst1_opa_select_out),
                                           .inst1_opb_select_out(rs_inst1_opb_select_out),
                                           .inst1_alu_func_out(rs_alu_func_out),
                                           .inst1_rd_mem_out(rs_inst1_rd_mem_out), 
                                           .inst1_wr_mem_out(rs_inst1_wr_mem_out),
                                           .inst1_cond_branch_out(rs_inst1_cond_branch_out),
                                           .inst1_uncond_branch_out(rs_inst1_uncond_branch_out),
                                           .inst1_NPC_out(rs_inst1_NPC_out),
                                           .inst1_IR_out(rs_inst1_IR_out),
                                           .inst1_valid_out(rs_inst1_valid_out),
                                           .inst1_dest_reg_out(rs_inst1_dest_reg_out),
                                           .inst1_dest_tag_out(rs_inst1_dest_tag_out),

                                           // signals and busses out for inst2 to the ex stage
                                           .inst2_rega_value_out(rs_inst2_rega_value_out),
                                           .inst2_regb_value_out(rs_inst2_rega_value_out),
                                           
                                           .inst2_opa_select_out(rs_inst2_opa_select_out),
                                           .inst2_opb_select_out(rs_inst2_opb_select_out),
                                           .inst2_alu_func_out(rs_alu_func_out),
                                           .inst2_rd_mem_out(rs_inst2_rd_mem_out), 
                                           .inst2_wr_mem_out(rs_inst2_wr_mem_out),
                                           .inst2_cond_branch_out(rs_inst2_cond_branch_out),
                                           .inst2_uncond_branch_out(rs_inst2_uncond_branch_out),
                                           .inst2_NPC_out(rs_inst2_NPC_out),
                                           .inst2_IR_out(rs_inst2_IR_out),
                                           .inst2_valid_out(rs_inst2_valid_out),
                                           .inst2_dest_reg_out(rs_inst2_dest_reg_out),
                                           .inst2_dest_tag_out(rs_inst2_dest_tag_out),

                                           // signal outputs //
                                           .dispatch(stall_RS),
                                         
                                           // outputs for debugging //
                                           .first_empties, .second_empties, .states_out, .fills, .issue_first_states, .issue_second_states, .ages_out
                                           
                                           );
  
  
  
  reorder_buffer reorder_buffer_0 (//Inputs
  
                                          .clock(clock), .reset(reset),
                                          
                                          /*these will come from decode*/
                                          .inst1_valid_in,
                                          .inst1_dest_in,

                                          .inst2_valid_in,
                                          .inst2_dest_in,

                                          // tags for reading from the rs // 
                                          .inst1_rega_tag_in(inst1_taga_out),
                                          .inst1_regb_tag_in(inst1_tagb_out),
                                          .inst2_rega_tag_in(inst2_taga_out),
                                          .inst2_regb_tag_in(inst2_tagb_out),

                                          // cdb inputs //
                                          .cdb1_tag_in(cm_tag_1),
                                          .cdb1_value_in(cm_value_1),
                                          .cdb2_tag_in(cm_tag_2),
                                          .cdb2_value_in(cm_value_2), 

                                          // outputs //
                                          
                                          //outputs to RS
                                          .inst1_tag_out(inst1_tag),
                                          .inst2_tag_out(inst2_tag),

                                          // values out to the rs //
                                          .inst1_rega_value_out(rob_inst1_rega_value),
                                          .inst1_regb_value_out(rob_inst1_regb_value),
                                          .inst2_rega_value_out(rob_inst2_rega_value),
                                          .inst2_regb_value_out(rob_inst2_regb_value),     

                                          // outputs to write directly to the reg file //
                                          .inst1_dest_out(inst1_dest_out), .inst1_value_out(inst1_value_out),
                                          .inst2_dest_out(inst2_dest_out), .inst2_value_out(inst2_value_out),
                                          
                                           // outputs to indicate a mispredicted branch //
                                           inst1_mispredicted_out, inst2_mispredicted_out,


                                          // signals out //
                                          .rob_full(rob_full), .rob_empty(rob_empty)
                                      );
  

  
  //////////////////////////////////////////////////
  //                                              //
  //        [RS/ROB] / EX Pipeline Register       //
  //                                              //
  //////////////////////////////////////////////////
  always @(posedge clock)
  begin
  
    if(reset)
    begin
    
      ex_NPC_1           <= `SD 0;
      ex_PPC_1           <= `SD 0;
      ex_IR_1            <= `SD 0;
      ex_dest_reg_1      <= `SD 0;
      ex_rega_1          <= `SD 0;
      ex_regb_1          <= `SD 0;
      ex_opa_select_1    <= `SD 0;
      ex_opb_select_1    <= `SD 0;
      ex_alu_func_1      <= `SD 0;
      ex_cond_branch_1   <= `SD 0;
      ex_uncond_branch_1 <= `SD 0;
      
      ex_NPC_2           <= `SD 0;
      ex_PPC_2           <= `SD 0;
      ex_IR_2            <= `SD 0;
      ex_dest_reg_2      <= `SD 0;
      ex_rega_2          <= `SD 0;
      ex_regb_2          <= `SD 0;
      ex_opa_select_2    <= `SD 0;
      ex_opb_select_2    <= `SD 0;
      ex_alu_func_2      <= `SD 0;
      ex_cond_branch_2   <= `SD 0;
      ex_uncond_branch_2 <= `SD 0;
     
    end
    else
    begin
    
      ex_NPC_1           <= `SD ;
      ex_PPC_1           <= `SD ;
      ex_IR_1            <= `SD ;
      ex_dest_reg_1      <= `SD ;
      ex_rega_1          <= `SD ;
      ex_regb_1          <= `SD ;
      ex_opa_select_1    <= `SD ;
      ex_opb_select_1    <= `SD ;
      ex_alu_func_1      <= `SD ;
      ex_cond_branch_1   <= `SD ;
      ex_uncond_branch_1 <= `SD ;
      
      ex_NPC_2           <= `SD ;
      ex_PPC_2           <= `SD ;
      ex_IR_2            <= `SD ;
      ex_dest_reg_2      <= `SD ;
      ex_rega_2          <= `SD ;
      ex_regb_2          <= `SD ;
      ex_opa_select_2    <= `SD ;
      ex_opb_select_2    <= `SD ;
      ex_alu_func_2      <= `SD ;
      ex_cond_branch_2   <= `SD ;
      ex_uncond_branch_2 <= `SD ;

  end
  //////////////////////////////////////////////////
  //                                              //
  //                  EX-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
   ex_stage ex_stage_0(// Inputs
                          .clock(clock),
                          .reset(reset),
                          
				        // Input Bus 1 (contains branch logic)
                id_ex_NPC_1,
				        id_ex_PPC_1,
                id_ex_IR_1,
                id_ex_dest_reg_1,
                id_ex_rega_1,
                id_ex_regb_1,
                id_ex_opa_select_1,
                id_ex_opb_select_1,
                id_ex_alu_func_1,
                id_ex_cond_branch_1,
                id_ex_uncond_branch_1,

				        // Input Bus 2
				        id_ex_NPC_2,
				        id_ex_PPC_2,
				        id_ex_IR_2,
				        id_ex_dest_reg_2,
				        id_ex_rega_2,
				        id_ex_regb_2,
				        id_ex_opa_select_2,
				        id_ex_opb_select_2,
				        id_ex_alu_func_2,
                id_ex_cond_branch_2,
                id_ex_uncond_branch_2,
				
                // From Mem Access
                MEM_tag_in,
                MEM_value_in,
                MEM_valid_in,
                
			          // Outputs
				        stall_bus_1,
				        stall_bus_2,
				        // Bus 1
				        .ex_dest_reg_out_1,
				        .ex_result_out_1,
				        .ex_valid_out_1,
				        .mispredict_1,
				        // Bus 2
				        .ex_dest_reg_out_2,
				        .ex_result_out_2,
				        .ex_valid_out_2,
				        .mispredict_2,



                // To LSQ
                LSQ_tag_out_1,
                LSQ_address_out_1,
                LSQ_value_out_1,
		            LSQ_valid_out_1,
		
		            // why are value and valid almost the same word!? 
		            // we need them both but they're hard to seperate!

                LSQ_tag_out_2,
                LSQ_address_out_2,
                LSQ_value_out_2,
		            LSQ_valid_out_2
                       );


  //////////////////////////////////////////////////
  //                                              //
  //       EX / Complete Pipeline Register        //
  //                                              //
  //////////////////////////////////////////////////

  //Synchronous Execute to Complete Register  
  always @(posedge clock)
  begin
    if(reset)
    begin
      cm_tag_1 <= `SD 7'b0;
      cm_value_1 <= `SD 63'b0;
      cm_valid_1 <= `SD 1'b0;
      cm_mispredict_1 <= `SD 1'b0;
      
      cm_tag_2 <= `SD 7'b0;
      cm_value_2 <= `SD 63'b0;
      cm_valid_2 <= `SD 1'b0;
      cm_mispredict_2 <= `SD 1'b0;

    end
    else
    begin
      cm_tag_1 <= `SD ex_tag_out_1;
      cm_value_1 <= `SD ex_value_out_1;
      cm_valid_1 <= `SD ex_valid_out_1;
      cm_mispredict_1 <= `SD ex_mispredict_out_1;
      
      cm_tag_2 <= `SD ex_tag_out_2;
      cm_value_2 <= `SD ex_value_out_2;
      cm_valid_2 <= `SD ex_valid_out_2;
      cm_mispredict_1 <= `SD ex_mispredict_out_2
      
    end
    
  end

  //////////////////////////////////////////////////
  //                                              //
  //               Complete Stage                 //
  //                                              //
  //////////////////////////////////////////////////
  
  //MISPREDICT NOT ADDED YET
  //WAITING ON SCOTT
  cm_stage cm_stage_0(// Inputs

		                  ex_cm_tag_1(cm_tag_1),
		                  ex_cm_result_1(cm_value_1),
		                  ex_cm_valid_1(cm_valid_1),
		
		                  ex_cm_tag_2(cm_tag_1),
		                  ex_cm_result_2(cm_value_1),
		                  ex_cm_valid_2(cm_valid_1),
		                  
		
		                  // Outputs
		                  .cdb_tag_1(cm_tag_1),
		                  .cdb_value_1(cm_value_1),

		                  .cdb_tag_2(cm_tag_2),
		                  .cdb_value_2(cm_value_2)
		                  );   


endmodule  // module verisimple
