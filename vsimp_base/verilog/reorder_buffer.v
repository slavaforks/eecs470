////////////////////////////////////////////////////////////////
// This file houses modules for the inner workings of the ROB //
//
// This ROB will have 32 entries. We can decide to add or     //
// subtract entries as we see fit.
// ROB consists of 32 ROB Entries                             //
////////////////////////////////////////////////////////////////

/***
*     TODO:  Combinaional logic
***/

// parameters //
`define ROB_ENTRIES 32
`define ROB_ENTRY_AVAILABLE 1
`define NO_ROB_ENTRY 0
`define SD = 1;


// rob main module //

module rob(clock, reset, rob_full, dest_reg, output_value);


    /*** Leaving this in here but Matt is working on restructure ***/

module rob(clock,reset);


  /***  inputs  ***/


  /***  internals ***/

  //Keep track of the tail
  reg  [4:0]  tail, n_tail;
  reg  [4:0]  head, n_head;
    


  /***  outputs ***/
  //what outputs do we need
  output reg  [64:0] value1_out, value2_out;
  output reg  [4:0] register1_out, register2_out;

  //initialize rob entries
  rob_entry[31:0](
   

  //we need to set each rob entries' write_enable
  always@ *
  begin
    



  end

   

always @(posedge clock)
begin
   if(reset)
   begin

   end

   else
   begin
         
   

endmodule 


/***
*   Each ROB Entry needs:
*       Instruction     
*       Valid bit       (Whether or not the entry is valid)
*       Value           (To know when to retire)
*       Register        (Output REgister
*       Complete bit    (To know if it is ready to retire) 
***/
module rob_entry(
                  //inputs
                  clock, reset,
                  instruction_in1, valid_in1, head_in1, tail_in1, value_in1, complete_in1, register_in1, 
                  instruction_in2, valid_in2, head_in2, tail_in2, value_in2, complete_in2, register_in2,

                  //outputs
                  instruction_out, valid_out, head_out, tail_out, value_out, register_out, complete_out,
                 );


  /***  inputs  ***/
  input wire        reset;
  input wire        clock;

  input wire [31:0] instruction_in;
  input wire        valid_in;
  input wire [63:0] value_in;
  input wire        complete_in;
  input wire  [4:0] register_in;

  /***  internals  ***/
  reg [31:0]  n_instruction;
  reg         n_valid;
  reg [63:0]  n_value;
  reg         n_complete;
  reg  [4:0]  n_register;

  reg write_enable1, write_enable2;
  reg n_write_enable1, n_write_enable2;

  /***  outputs  ***/
  output reg [31:0] instruction_out;
  output reg        valid_out;
  output reg [63:0] value_out;
  output reg        complete_out;
  output reg  [4:0] register_out;


  // combinational assignments //  
  always @*
  begin
    if (write_enable_1)
    begin
      n_instruction = instruction_in1;
      n_valid = valid_in1;
      n_value = 64'b0;
      n_register = register_in1;
      n_complete = 1'b0;
    end
    else if (write_enable_2)
      begin
      n_instruction = instruction_in2;
      n_valid = valid_in2;
      n_value = 64'b0;
      n_register = register_in2;
      n_complete = 1'b0;
    end
    else
    begin 
      n_instruction = instruction_out;
      n_valid = valid_out;
      n_value = value_out;
      n_register = register_out;
      n_complete = complete_out;
    end

  end


  // combinational logic to next state //


  // clock synchronous events //
  always@(posedge clock)
  begin
     if (reset)
     begin
        instruction_out <= `SD 32'd0;
        valid_out <= `SD 1'b0;
        value_out <= `SD 64'h0;
        register_out <= `SD 5'b0;
        complete_out <= `SD 1'b0;
     end
     else
     begin
        instruction_out <= `SD n_instruction;
        valid_out <= `SD n_valid;
        value_out <= `SD n_value;
        register_out <= `SD n_exception;
        complete_out <= `SD n_complete;
     end


endmodule
