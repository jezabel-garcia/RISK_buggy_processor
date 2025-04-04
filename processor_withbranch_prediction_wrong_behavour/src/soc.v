`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:48:56 02/14/2015 
// Design Name: 
// Module Name:    soc 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module soc(
    input               CLK,
    input               RES,
    input      [11:0]   IN0,
    input      [11:0]   IN1,
    input      [11:0]   IN2,
    input      [11:0]   IN3,
    output reg [11:0]   OUT0 = 0,
    output reg [11:0]   OUT1 = 0,
    output reg [11:0]   OUT2 = 0,
    output reg [11:0]   OUT3 = 0
    );

    wire [15:0] ADDR0;
    wire [15:0] DATA0;
    wire RD0,WR0;

    // Core 0 with branch prediction
    core core0(
        .CLK(CLK),
        .RES(RES),
        .RD(RD0),
        .WR(WR0),
        .ADDR(ADDR0),
        .DATA(DATA0)
    );

    wire [15:0] ADDR1;
    wire [15:0] DATA1;
    wire RD1,WR1;

    // Core 1 with branch prediction
    core core1(
        .CLK(CLK),
        .RES(RES),
        .RD(RD1),
        .WR(WR1),
        .ADDR(ADDR1),
        .DATA(DATA1)
    );

    wire [15:0] ADDR2;
    wire [15:0] DATA2;
    wire RD2,WR2;

    // Core 2 with branch prediction
    core core2(
        .CLK(CLK),
        .RES(RES),
        .RD(RD2),
        .WR(WR2),
        .ADDR(ADDR2),
        .DATA(DATA2)
    );

    wire [15:0] ADDR3;
    wire [15:0] DATA3;
    wire RD3,WR3;

    // Core 3 with branch prediction
    core core3(
        .CLK(CLK),
        .RES(RES),
        .RD(RD3),
        .WR(WR3),
        .ADDR(ADDR3),
        .DATA(DATA3)
    );

    // Memory for each core
    reg [15:0] MEM0 [0:1023];
    reg [15:0] MEM1 [0:1023];
    reg [15:0] MEM2 [0:1023];
    reg [15:0] MEM3 [0:1023];
    
    // Data output registers
    reg [15:0] DATAO0 = 0;
    reg [15:0] DATAO1 = 0;
    reg [15:0] DATAO2 = 0;
    reg [15:0] DATAO3 = 0;
    
    // Initialize memory
    integer j;
    initial begin
        for(j=0; j!=1024; j=j+1) begin
            MEM0[j] = 0;
            MEM1[j] = 0;
            MEM2[j] = 0;
            MEM3[j] = 0;
        end
        
        // Load ROM data - Enhanced test program to exercise branch prediction
        // Core 0 - This program includes more branches to test the branch predictor
        MEM0[0] = 16'h0000; // NOP
        MEM0[1] = 16'ha000; // IMM 0 %d0  - Counter
        MEM0[2] = 16'ha101; // IMM 1 %d1  - Increment
        MEM0[3] = 16'ha20a; // IMM 10 %d2 - Loop limit
        MEM0[4] = 16'ha300; // IMM 0 %d3  - Sum
        MEM0[5] = 16'ha400; // IMM 0 %d4  - Temp
        MEM0[6] = 16'ha500; // IMM 0 %d5  - Result
        
        // Main loop - Count from 0 to 9
        MEM0[7] = 16'h2201; // ADD %d0 %d1 - Increment counter
        MEM0[8] = 16'h2302; // ADD %d3 %d0 - Add to sum
        
        // Check if counter is even or odd
        MEM0[9] = 16'ha401; // IMM 1 %d4
        MEM0[10] = 16'h6040; // AND %d0 %d4 - Check LSB
        MEM0[11] = 16'hc003; // BRA +3 if result is 0 (even)
        
        // Odd path
        MEM0[12] = 16'h2503; // ADD %d5 %d3 - Add sum to result
        MEM0[13] = 16'hc002; // BRA +2 to skip even path
        
        // Even path
        MEM0[14] = 16'h3503; // SUB %d5 %d3 - Subtract sum from result
        
        // Check if we've reached the loop limit
        MEM0[15] = 16'h3020; // SUB %d0 %d2 - Compare counter to limit
        MEM0[16] = 16'hc002; // BRA +2 if result is 0 (equal)
        MEM0[17] = 16'hc0f0; // BRA -16 to loop start
        
        // End of program
        MEM0[18] = 16'h0000; // NOP
        MEM0[19] = 16'h0000; // NOP
        
        // Additional branch-heavy code to test prediction
        MEM0[20] = 16'ha010; // IMM 16 %d0 - New counter
        MEM0[21] = 16'ha101; // IMM 1 %d1  - Decrement
        
        // Countdown loop with alternating branch patterns
        MEM0[22] = 16'h3010; // SUB %d0 %d1 - Decrement counter
        MEM0[23] = 16'h6040; // AND %d0 %d4 - Check LSB
        MEM0[24] = 16'hc002; // BRA +2 if result is 0 (even)
        MEM0[25] = 16'hc002; // BRA +2 to skip
        MEM0[26] = 16'hc001; // BRA +1 to continue
        MEM0[27] = 16'h0000; // NOP
        MEM0[28] = 16'hf0f9; // LOP %d0 -7 - Loop until counter is 0
        MEM0[29] = 16'h0000; // NOP
        MEM0[30] = 16'h0000; // NOP
        
        // Copy the same program to other cores
        for(j=0; j!=31; j=j+1) begin
            MEM1[j] = MEM0[j];
            MEM2[j] = MEM0[j];
            MEM3[j] = MEM0[j];
        end
    end
    
    // Memory read/write logic for each core
    always@(posedge CLK) begin
        // Core 0
        if(RD0) begin
            DATAO0 <= MEM0[ADDR0[9:0]];
        end
        if(WR0) begin
            MEM0[ADDR0[9:0]] <= DATA0;
            OUT0 <= DATA0[11:0]; // Output the lower 12 bits
        end
        
        // Core 1
        if(RD1) begin
            DATAO1 <= MEM1[ADDR1[9:0]];
        end
        if(WR1) begin
            MEM1[ADDR1[9:0]] <= DATA1;
            OUT1 <= DATA1[11:0];
        end
        
        // Core 2
        if(RD2) begin
            DATAO2 <= MEM2[ADDR2[9:0]];
        end
        if(WR2) begin
            MEM2[ADDR2[9:0]] <= DATA2;
            OUT2 <= DATA2[11:0];
        end
        
        // Core 3
        if(RD3) begin
            DATAO3 <= MEM3[ADDR3[9:0]];
        end
        if(WR3) begin
            MEM3[ADDR3[9:0]] <= DATA3;
            OUT3 <= DATA3[11:0];
        end
    end
    
    // Connect memory to cores
    assign DATA0 = RD0 ? DATAO0 : 16'hzzzz;
    assign DATA1 = RD1 ? DATAO1 : 16'hzzzz;
    assign DATA2 = RD2 ? DATAO2 : 16'hzzzz;
    assign DATA3 = RD3 ? DATAO3 : 16'hzzzz;

endmodule
