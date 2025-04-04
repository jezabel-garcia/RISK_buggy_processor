`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:21:40 02/14/2015
// Design Name:   core
// Module Name:   Z:/Users/marcelo/Documents/Verilog/RISCv2/src/system.v
// Project Name:  RISCv2
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: core
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module system;

	// Inputs
	reg CLK;
	reg RES;

	// Outputs
	wire        RD;
	wire        WR;
	wire [15:0] ADDR;

	// Bidirs
	wire [15:0] DATA;

	// Instantiate the Unit Under Test (UUT)
	core uut (
		.CLK(CLK), 
		.RES(RES), 
		.RD(RD), 
		.WR(WR), 
		.ADDR(ADDR), 
		.DATA(DATA)
	);
	
	// Branch prediction signals for monitoring
	wire predict_taken;
	wire [7:0] predict_history;
	reg predict_valid = 0;
	reg train_valid = 0;
	reg train_taken = 0;
	reg train_mispredicted = 0;
	reg [7:0] train_history = 0;
	reg [15:0] train_pc = 0;

    // Memory system
    reg [15:0] MEM [0:1023]; // Combined memory for both instructions and data
    reg [15:0] DATAO = 0;
    
    integer j;
    
    // Initialize memory
    initial begin
        for(j=0; j!=1024; j=j+1) begin
            MEM[j] = 0;
        end
        
        // Load ROM data - Enhanced test program to exercise branch prediction
        // This program includes more branches to test the branch predictor
        MEM[0] = 16'h0000; // NOP
        MEM[1] = 16'ha000; // IMM 0 %d0  - Counter
        MEM[2] = 16'ha101; // IMM 1 %d1  - Increment
        MEM[3] = 16'ha20a; // IMM 10 %d2 - Loop limit
        MEM[4] = 16'ha300; // IMM 0 %d3  - Sum
        MEM[5] = 16'ha400; // IMM 0 %d4  - Temp
        MEM[6] = 16'ha500; // IMM 0 %d5  - Result
        
        // Main loop - Count from 0 to 9
        MEM[7] = 16'h2201; // ADD %d0 %d1 - Increment counter
        MEM[8] = 16'h2302; // ADD %d3 %d0 - Add to sum
        
        // Check if counter is even or odd
        MEM[9] = 16'ha401; // IMM 1 %d4
        MEM[10] = 16'h6040; // AND %d0 %d4 - Check LSB
        MEM[11] = 16'hc003; // BRA +3 if result is 0 (even)
        
        // Odd path
        MEM[12] = 16'h2503; // ADD %d5 %d3 - Add sum to result
        MEM[13] = 16'hc002; // BRA +2 to skip even path
        
        // Even path
        MEM[14] = 16'h3503; // SUB %d5 %d3 - Subtract sum from result
        
        // Check if we've reached the loop limit
        MEM[15] = 16'h3020; // SUB %d0 %d2 - Compare counter to limit
        MEM[16] = 16'hc002; // BRA +2 if result is 0 (equal)
        MEM[17] = 16'hc0f0; // BRA -16 to loop start
        
        // End of program
        MEM[18] = 16'h0000; // NOP
        MEM[19] = 16'h0000; // NOP
        
        // Additional branch-heavy code to test prediction
        MEM[20] = 16'ha010; // IMM 16 %d0 - New counter
        MEM[21] = 16'ha101; // IMM 1 %d1  - Decrement
        
        // Countdown loop with alternating branch patterns
        MEM[22] = 16'h3010; // SUB %d0 %d1 - Decrement counter
        MEM[23] = 16'h6040; // AND %d0 %d4 - Check LSB
        MEM[24] = 16'hc002; // BRA +2 if result is 0 (even)
        MEM[25] = 16'hc002; // BRA +2 to skip
        MEM[26] = 16'hc001; // BRA +1 to continue
        MEM[27] = 16'h0000; // NOP
        MEM[28] = 16'hf0f9; // LOP %d0 -7 - Loop until counter is 0
        MEM[29] = 16'h0000; // NOP
        MEM[30] = 16'h0000; // NOP
    end
    
    // Memory read/write logic
    assign DATA = RD ? DATAO : 16'hzzzz;
    
    always@(posedge CLK) begin
        if(RD) begin
            DATAO <= MEM[ADDR[9:0]]; // Use only 10 bits of address for 1K memory
        end
        
        if(WR) begin
            MEM[ADDR[9:0]] <= DATA;
        end
    end
    
    integer i;

	initial begin
		// Initialize Inputs
		CLK = 0;
		RES = 0;

        // Generate VCD file for waveform viewing
        $dumpfile("system.vcd");
        $dumpvars(0, system);
        
        // Monitor branch prediction performance
        $monitor("Time=%t, PC=%h, Predict=%b, History=%h, Mispredict=%b", 
                 $time, uut.PC, uut.predict_taken, uut.predict_history, 
                 uut.train_mispredicted);

        for(i=0;i!=10000;i=i+1)
        begin
            #10 CLK = !CLK;
            if(i>10)
            begin
                RES = 1;
            end
        end 
	end
      
endmodule
