
`define RSTAG_NULL 8'd0

// general case testbench module //
module testbench;

	// internal wires/registers //
	reg correct;
	integer i = 0;

       // wires and stuff //
        reg clock;
        reg reset;
        reg [4:0] inst1_rega_in;
        reg [4:0] inst1_regb_in;
        reg [4:0] inst2_rega_in;
        reg [4:0] inst2_regb_in;
        reg [4:0] inst1_dest_in;
        reg [4:0] inst2_dest_in;
        reg [63:0] inst1_value_in;
        reg [63:0] inst2_value_in;
   
        wire [63:0] inst1_rega_out;
        wire [63:0] inst1_regb_out;
        wire [63:0] inst2_rega_out;
        wire [63:0] inst2_regb_out;
        wire [31:0] clear_entries;


    // register file module //
    register_file rf(.clock(clock),.reset(reset),  // input signals in

                     .inst1_rega_in(inst1_rega_in),.inst1_regb_in(inst1_regb_in),
                     .inst2_rega_in(inst2_rega_in),.inst2_regb_in(inst2_regb_in),
                     .inst1_dest_in(inst1_dest_in),.inst1_value_in(inst1_value_in),
                     .inst2_dest_in(inst2_dest_in),.inst2_value_in(inst2_value_in),
                     .inst1_rega_out(inst1_rega_out),.inst1_regb_out(inst1_regb_out),
                     .inst2_rega_out(inst2_rega_out),.inst2_regb_out(inst2_regb_out),

                     .clear_entries(clear_entries)   );


   // run the clock //
   always
   begin 
      #5; //clock "interval" ... AKA 1/2 the period
      clock=~clock; 
   end 

   // task to exit if there is an error //
   task exit_on_error;
   begin
      $display("@@@ Incorrect at time %4.0f", $time);
      $display("@@@ Time:%4.0f clock:%b reset:%h ", $time, clock, reset   );
      $display("ENDING TESTBENCH : ERROR !");
      $finish;
   end
   endtask


   // exit if not correct //
   always@(posedge clock)
   begin
      #2
      if(!correct)
         exit_on_error();
   end 

   // task to check correctness of the module state currently // 
   task CHECK_CORRECT;
      input [1:0] tb_state;
      begin
         if( tb_state == 2'b00 ) correct = 1;
         else                    correct = 0;
      end
   endtask


   // displays the current state of all wires //
   `define PRECLOCK  1'b1
   `define POSTCLOCK 1'b0
   task DISPLAY_STATE;
      input preclock;
   begin
      if (preclock==`PRECLOCK)
         $display("  preclock: reset=%b i1_rega_out=%h i1_regb_out=%h i2_rega_out=%h i2_regb_out=%h clear_entries=%b", reset, inst1_rega_out,inst1_regb_out,inst2_rega_out,inst2_regb_out,clear_entries);
      else
         $display(" postclock: reset=%b i1_rega_out=%h i1_regb_out=%h i2_rega_out=%h i2_regb_out=%h clear_entries=%b", reset, inst1_rega_out,inst1_regb_out,inst2_rega_out,inst2_regb_out,clear_entries);
   end
   endtask

   // runs the clock once and displays output before and after //
   task CLOCK_AND_DISPLAY;
   begin
      DISPLAY_STATE(`PRECLOCK);
      @(posedge clock);
      @(negedge clock);
      DISPLAY_STATE(`POSTCLOCK);
      $display("");
   end
   endtask

   // testing segment //
   initial
   begin 

	$display("STARTING TESTBENCH!\n");

	// initial state //
        clock = 1;
        reset = 1;
        inst1_rega_in = 5'd0;
        inst1_regb_in = 5'd0;
        inst2_rega_in = 5'd0;
        inst2_regb_in = 5'd0;
        inst1_dest_in = 5'd0;
        inst2_dest_in = 5'd0;
        inst1_value_in = 64'd0;
        inst2_value_in = 64'd0;


        // TRANSITION TESTS //

	reset = 1;

        CLOCK_AND_DISPLAY();

        reset = 0;

        CLOCK_AND_DISPLAY();

        inst1_rega_in = 5'd1;
        inst1_regb_in = 5'd2;
        inst1_dest_in = 5'd1;
        inst2_dest_in = 5'd2;
        inst1_value_in = 64'hAAAAAAAAAAAAAAAA;
        inst2_value_in = 64'hBBBBBBBBBBBBBBBB;

        CLOCK_AND_DISPLAY();
      
        inst1_dest_in = 5'd0;
        inst1_dest_in = 5'd0;
        inst1_regb_in = 5'd1;
        inst1_value_in = 64'hCCCCCCCCCCCCCCCC;
        inst2_value_in = 64'hCCCCCCCCCCCCCCCC;

        CLOCK_AND_DISPLAY();

        inst1_dest_in = 5'd3;
        inst2_dest_in = 5'd4;
        inst1_value_in = 64'hDDDDDDDDDDDDDDDD;
        inst2_value_in = 64'hEEEEEEEEEEEEEEEE;

        CLOCK_AND_DISPLAY();

        inst1_dest_in = 5'd0;
        inst2_dest_in = 5'd0;
        inst1_rega_in = 5'd3;
        inst1_regb_in = 5'd3;
        inst2_rega_in = 5'd4;
        inst2_regb_in = 5'd4;

        CLOCK_AND_DISPLAY();

        inst1_dest_in = 5'd5;
        inst2_dest_in = 5'd5;
        inst1_value_in = 64'hABABABABABABABAB;
        inst2_value_in = 64'hCDCDCDCDCDCDCDCD;
        inst1_rega_in = 5'd5;

        CLOCK_AND_DISPLAY();

        inst1_dest_in = 5'd6;
        inst2_dest_in = 5'd0;
        inst1_value_in = 64'hFFFFFFFFFFFFFFFF;
        inst1_rega_in = 5'd6;

        CLOCK_AND_DISPLAY();

        reset = 1;

        CLOCK_AND_DISPLAY();

	// SUCCESSFULLY END TESTBENCH //
	$display("ENDING TESTBENCH : SUCCESS !\n");
	$finish;
	
   end

endmodule

