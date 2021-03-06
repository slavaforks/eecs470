
`define RSTAG_NULL 8'd0

// general case testbench module //
module testbench;

	// internal wires/registers //
	reg correct;
	integer i = 0;

	// wires for testing the module //
	reg clock;
	reg reset;
        reg inst1_write_tag;
        reg inst2_write_tag;
        reg [4:0] inst1_rega_in;
        reg [4:0] inst1_regb_in;
        reg [4:0] inst1_dest_in;
        reg [7:0] inst1_tag_in;
        reg [4:0] inst2_rega_in;
        reg [4:0] inst2_regb_in;
        reg [4:0] inst2_dest_in;
        reg [7:0] inst2_tag_in;
        reg [31:0] clear_entries;
        wire [7:0] inst1_taga_out;
        wire [7:0] inst1_tagb_out;
        wire [7:0] inst2_taga_out;
        wire [7:0] inst2_tagb_out;

        // module to be tested //	
        map_table mt(.clock(clock),.reset(reset),.clear_entries(clear_entries),
                 
                 .inst1_rega_in(inst1_rega_in),
                 .inst1_regb_in(inst1_regb_in),
                 .inst1_dest_in(inst1_dest_in),
                 .inst1_tag_in(inst1_tag_in),

                 .inst2_rega_in(inst2_rega_in),
                 .inst2_regb_in(inst2_regb_in),
                 .inst2_dest_in(inst2_dest_in),
                 .inst2_tag_in(inst2_tag_in),
                 
                 .inst1_taga_out(inst1_taga_out),.inst1_tagb_out(inst1_tagb_out),
                 .inst2_taga_out(inst2_taga_out),.inst2_tagb_out(inst2_tagb_out)
                                                                                  );

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
         $display("  preclock: reset=%b i1_taga_out=%h i1_tagb_out=%h i2_taga_out=%h i2_tagb_out=%h", reset, inst1_taga_out,inst1_tagb_out,inst2_taga_out,inst2_tagb_out);
      else
         $display("  postclock: reset=%b i1_taga_out=%h i1_tagb_out=%h i2_taga_out=%h i2_tagb_out=%h", reset, inst1_taga_out,inst1_tagb_out,inst2_taga_out,inst2_tagb_out);
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
        correct = 1;
        clock   = 0;
        reset   = 1;
        inst1_write_tag = 0;
        inst2_write_tag = 0;
        inst1_rega_in = 5'd0;
        inst1_regb_in = 5'd0;
        inst2_rega_in = 5'd0;
        inst2_regb_in = 5'd0;
        inst1_dest_in = 5'd0;
        inst2_dest_in = 5'd0;
        inst2_tag_in = `RSTAG_NULL; 
        inst2_tag_in = `RSTAG_NULL;
        clear_entries = 32'd0;

        // TRANSITION TESTS //

	reset = 1;

        CLOCK_AND_DISPLAY();

        reset = 0;

        CLOCK_AND_DISPLAY();

        inst1_write_tag = 1;
        inst1_dest_in   = 5'd4;
        inst1_tag_in    = 8'hAB;

        CLOCK_AND_DISPLAY();
      
        inst1_write_tag = 0;
        inst1_rega_in = 5'd4;

        CLOCK_AND_DISPLAY();

        inst1_regb_in = 5'd4;
        inst2_rega_in = 5'd4;
        inst2_regb_in = 5'd4;

        CLOCK_AND_DISPLAY();

        inst1_write_tag = 1;
        inst2_write_tag = 1;
        inst1_dest_in = 5'd4;
        inst2_dest_in = 5'd5;
        inst1_tag_in = 8'hCD;
        inst2_tag_in = 8'hEF;
        inst2_rega_in = 5'd5;
        inst2_regb_in = 5'd5;

        CLOCK_AND_DISPLAY();

        inst1_dest_in = 5'd4;
        inst2_dest_in = 5'd4;
        inst1_tag_in = 8'h11;
        inst2_tag_in = 8'h22;

        CLOCK_AND_DISPLAY();

        inst1_tag_in = 8'h33;
        inst2_tag_in = 8'h00;

        CLOCK_AND_DISPLAY();

        reset = 1;

        CLOCK_AND_DISPLAY();

	// SUCCESSFULLY END TESTBENCH //
	$display("ENDING TESTBENCH : SUCCESS !\n");
	$finish;
	
   end

endmodule


