module rom(input CLK, input [9:0] ADDR, output reg [15:0] DATA);

  reg [15:0] ROM [0:1023];

  integer i;

  initial
  begin
    for(i=0;i!=1024;i=i+1)
    begin
      ROM[i] = 0;
    end

    // Enhanced test program to exercise branch prediction
    ROM[0] = 16'h0000; // NOP
    ROM[1] = 16'ha000; // IMM 0 %d0  - Counter
    ROM[2] = 16'ha101; // IMM 1 %d1  - Increment
    ROM[3] = 16'ha20a; // IMM 10 %d2 - Loop limit
    ROM[4] = 16'ha300; // IMM 0 %d3  - Sum
    ROM[5] = 16'ha400; // IMM 0 %d4  - Temp
    ROM[6] = 16'ha500; // IMM 0 %d5  - Result
    
    // Main loop - Count from 0 to 9
    ROM[7] = 16'h2201; // ADD %d0 %d1 - Increment counter
    ROM[8] = 16'h2302; // ADD %d3 %d0 - Add to sum
    
    // Check if counter is even or odd
    ROM[9] = 16'ha401; // IMM 1 %d4
    ROM[10] = 16'h6040; // AND %d0 %d4 - Check LSB
    ROM[11] = 16'hc003; // BRA +3 if result is 0 (even)
    
    // Odd path
    ROM[12] = 16'h2503; // ADD %d5 %d3 - Add sum to result
    ROM[13] = 16'hc002; // BRA +2 to skip even path
    
    // Even path
    ROM[14] = 16'h3503; // SUB %d5 %d3 - Subtract sum from result
    
    // Check if we've reached the loop limit
    ROM[15] = 16'h3020; // SUB %d0 %d2 - Compare counter to limit
    ROM[16] = 16'hc002; // BRA +2 if result is 0 (equal)
    ROM[17] = 16'hc0f0; // BRA -16 to loop start
    
    // End of program
    ROM[18] = 16'h0000; // NOP
    ROM[19] = 16'h0000; // NOP
    
    // Additional branch-heavy code to test prediction
    ROM[20] = 16'ha010; // IMM 16 %d0 - New counter
    ROM[21] = 16'ha101; // IMM 1 %d1  - Decrement
    
    // Countdown loop with alternating branch patterns
    ROM[22] = 16'h3010; // SUB %d0 %d1 - Decrement counter
    ROM[23] = 16'h6040; // AND %d0 %d4 - Check LSB
    ROM[24] = 16'hc002; // BRA +2 if result is 0 (even)
    ROM[25] = 16'hc002; // BRA +2 to skip
    ROM[26] = 16'hc001; // BRA +1 to continue
    ROM[27] = 16'h0000; // NOP
    ROM[28] = 16'hf0f9; // LOP %d0 -7 - Loop until counter is 0
    ROM[29] = 16'h0000; // NOP
    ROM[30] = 16'h0000; // NOP
  end

  always@(posedge CLK) DATA <= ROM[ADDR];
endmodule
