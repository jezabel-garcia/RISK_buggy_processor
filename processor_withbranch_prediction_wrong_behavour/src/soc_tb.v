`timescale 1ns / 1ps

module soc_tb;

    // Inputs
    reg CLK;
    reg RES;
    reg [11:0] IN0;
    reg [11:0] IN1;
    reg [11:0] IN2;
    reg [11:0] IN3;

    // Outputs
    wire [11:0] OUT0;
    wire [11:0] OUT1;
    wire [11:0] OUT2;
    wire [11:0] OUT3;

    // Instantiate the Unit Under Test (UUT)
    soc uut (
        .CLK(CLK), 
        .RES(RES), 
        .IN0(IN0), 
        .IN1(IN1), 
        .IN2(IN2), 
        .IN3(IN3), 
        .OUT0(OUT0), 
        .OUT1(OUT1), 
        .OUT2(OUT2), 
        .OUT3(OUT3)
    );

    integer i;

    initial begin
        // Initialize Inputs
        CLK = 0;
        RES = 0;
        IN0 = 0;
        IN1 = 0;
        IN2 = 0;
        IN3 = 0;

        // Generate VCD file for waveform viewing
        $dumpfile("soc.vcd");
        $dumpvars(0, soc_tb);
        
        // Monitor branch prediction performance for core0
        $monitor("Time=%t, PC=%h, Predict=%b, History=%h, Mispredict=%b", 
                 $time, uut.core0.PC, uut.core0.predict_taken, 
                 uut.core0.predict_history, uut.core0.train_mispredicted);

        for(i=0; i!=10000; i=i+1) begin
            #10 CLK = !CLK;
            if(i>10) begin
                RES = 1;
            end
        end
    end
      
endmodule
