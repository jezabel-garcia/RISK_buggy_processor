`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:21:40 02/14/2015 
// Design Name:    uDarkRISC with Branch Prediction
// Module Name:    core 
// Project Name:   uDarkRISC
// Target Devices: 
// Tool versions: 
// Description:    16-bit RISC processor core with branch prediction
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: Modified to include gshare branch predictor
//
//////////////////////////////////////////////////////////////////////////////////

module core(
    input               CLK,    // Clock input
    input               RES,    // Reset input
    output reg          RD,     // Read signal
    output reg          WR,     // Write signal
    output reg [15:0]   ADDR,   // Address bus
    inout      [15:0]   DATA    // Data bus
    );

    // Program Counter
    reg [15:0] PC = 0;
    
    // Register Bank
    reg [15:0] REG [0:15];
    
    // Instruction Register
    reg [15:0] IR = 0;
    
    // Instruction Fields
    wire [3:0] OPCODE = IR[15:12];  // Instruction opcode
    wire [3:0] DREG   = IR[11:8];   // Destination register
    wire [3:0] SREG   = IR[7:4];    // Source register
    wire [3:0] OPTS   = IR[3:0];    // Instruction options
    wire [7:0] IMM    = IR[7:0];    // Immediate value (8-bit)
    
    // Pipeline Stage (0 = Fetch, 1 = Execute)
    reg STAGE = 0;
    
    // Data Output Register
    reg [15:0] DOUT = 0;
    
    // Memory Access State
    reg MEM_ACCESS = 0;
    reg [15:0] MEM_ADDR = 0;
    reg [15:0] MEM_DATA = 0;
    
    // Tri-state buffer for DATA bus
    assign DATA = WR ? DOUT : 16'hzzzz;
    
    // Instruction Execution Results
    reg [15:0] RESULT [0:15];
    
    // Next PC Value
    reg [15:0] NEXT_PC;
    
    // Branch Prediction Signals
    reg predict_valid = 0;
    wire predict_taken;
    wire [7:0] predict_history;
    reg train_valid = 0;
    reg train_taken = 0;
    reg train_mispredicted = 0;
    reg [7:0] train_history = 0;
    reg [15:0] train_pc = 0;
    
    // Previous branch prediction information
    reg [15:0] prev_pc = 0;
    reg [7:0] prev_history = 0;
    reg prev_prediction = 0;
    reg is_branch = 0;
    reg [15:0] branch_target = 0;
    reg [15:0] next_sequential_pc = 0;
    
    // Branch predictor instance
    branch_predictor bp(
        .CLK(CLK),
        .RES(RES),
        .predict_valid(predict_valid),
        .predict_pc(PC),
        .predict_taken(predict_taken),
        .predict_history(predict_history),
        .train_valid(train_valid),
        .train_taken(train_taken),
        .train_mispredicted(train_mispredicted),
        .train_history(train_history),
        .train_pc(train_pc)
    );
    
    // Initialize registers
    integer i;
    initial begin
        for(i=0; i<16; i=i+1) begin
            REG[i] = 0;
        end
    end
    
    always @(posedge CLK) begin
        if(!RES) begin
            // Reset state
            PC <= 0;
            IR <= 0;
            RD <= 0;
            WR <= 0;
            STAGE <= 0;
            MEM_ACCESS <= 0;
            predict_valid <= 0;
            train_valid <= 0;
            train_taken <= 0;
            train_mispredicted <= 0;
            train_history <= 0;
            train_pc <= 0;
            prev_pc <= 0;
            prev_history <= 0;
            prev_prediction <= 0;
            is_branch <= 0;
            branch_target <= 0;
            next_sequential_pc <= 0;
        end else begin
            // Default state for memory signals
            RD <= 0;
            WR <= 0;
            train_valid <= 0;
            
            if(MEM_ACCESS) begin
                // Memory access in progress
                if(OPCODE == 8) begin // LOD
                    // Load operation
                    REG[DREG] <= DATA;
                end
                MEM_ACCESS <= 0;
                STAGE <= 0; // Go back to fetch stage
            end else begin
                case(STAGE)
                    0: begin
                        // Fetch instruction
                        ADDR <= PC;
                        RD <= 1;
                        IR <= DATA;
                        STAGE <= 1;
                        
                        // Request branch prediction for the next instruction
                        predict_valid <= 1;
                        
                        // Train the branch predictor if the previous instruction was a branch
                        if(is_branch) begin
                            train_valid <= 1;
                            train_pc <= prev_pc;
                            train_history <= prev_history;
                            train_taken <= (PC != next_sequential_pc);
                            train_mispredicted <= (prev_prediction != (PC != next_sequential_pc));
                            is_branch <= 0;
                        end else begin
                            train_valid <= 0;
                        end
                    end
                    
                    1: begin
                        // Execute instruction
                        predict_valid <= 0;
                        
                        // Calculate all possible results in parallel
                        // ROR - Right rotate
                        case(OPTS)
                            4'd0: RESULT[0] = REG[SREG]; // No rotation
                            4'd1: RESULT[0] = {REG[SREG][0], REG[SREG][15:1]};
                            4'd2: RESULT[0] = {REG[SREG][1:0], REG[SREG][15:2]};
                            4'd3: RESULT[0] = {REG[SREG][2:0], REG[SREG][15:3]};
                            4'd4: RESULT[0] = {REG[SREG][3:0], REG[SREG][15:4]};
                            4'd5: RESULT[0] = {REG[SREG][4:0], REG[SREG][15:5]};
                            4'd6: RESULT[0] = {REG[SREG][5:0], REG[SREG][15:6]};
                            4'd7: RESULT[0] = {REG[SREG][6:0], REG[SREG][15:7]};
                            4'd8: RESULT[0] = {REG[SREG][7:0], REG[SREG][15:8]};
                            4'd9: RESULT[0] = {REG[SREG][8:0], REG[SREG][15:9]};
                            4'd10: RESULT[0] = {REG[SREG][9:0], REG[SREG][15:10]};
                            4'd11: RESULT[0] = {REG[SREG][10:0], REG[SREG][15:11]};
                            4'd12: RESULT[0] = {REG[SREG][11:0], REG[SREG][15:12]};
                            4'd13: RESULT[0] = {REG[SREG][12:0], REG[SREG][15:13]};
                            4'd14: RESULT[0] = {REG[SREG][13:0], REG[SREG][15:14]};
                            4'd15: RESULT[0] = {REG[SREG][14:0], REG[SREG][15]};
                            default: RESULT[0] = REG[SREG];
                        endcase
                        
                        // ROL - Left rotate
                        case(OPTS)
                            4'd0: RESULT[1] = REG[SREG]; // No rotation
                            4'd1: RESULT[1] = {REG[SREG][14:0], REG[SREG][15]};
                            4'd2: RESULT[1] = {REG[SREG][13:0], REG[SREG][15:14]};
                            4'd3: RESULT[1] = {REG[SREG][12:0], REG[SREG][15:13]};
                            4'd4: RESULT[1] = {REG[SREG][11:0], REG[SREG][15:12]};
                            4'd5: RESULT[1] = {REG[SREG][10:0], REG[SREG][15:11]};
                            4'd6: RESULT[1] = {REG[SREG][9:0], REG[SREG][15:10]};
                            4'd7: RESULT[1] = {REG[SREG][8:0], REG[SREG][15:9]};
                            4'd8: RESULT[1] = {REG[SREG][7:0], REG[SREG][15:8]};
                            4'd9: RESULT[1] = {REG[SREG][6:0], REG[SREG][15:7]};
                            4'd10: RESULT[1] = {REG[SREG][5:0], REG[SREG][15:6]};
                            4'd11: RESULT[1] = {REG[SREG][4:0], REG[SREG][15:5]};
                            4'd12: RESULT[1] = {REG[SREG][3:0], REG[SREG][15:4]};
                            4'd13: RESULT[1] = {REG[SREG][2:0], REG[SREG][15:3]};
                            4'd14: RESULT[1] = {REG[SREG][1:0], REG[SREG][15:2]};
                            4'd15: RESULT[1] = {REG[SREG][0], REG[SREG][15:1]};
                            default: RESULT[1] = REG[SREG];
                        endcase
                        RESULT[2]  = REG[DREG] + (SREG ? REG[SREG] : OPTS);                   // ADD
                        RESULT[3]  = REG[DREG] - (SREG ? REG[SREG] : OPTS);                   // SUB
                        RESULT[4]  = REG[DREG] & REG[SREG];                                   // AND
                        RESULT[5]  = REG[DREG] | REG[SREG];                                   // OR
                        RESULT[6]  = REG[DREG] ^ REG[SREG];                                   // XOR
                        RESULT[7]  = ~REG[DREG];                                              // NOT
                        RESULT[8]  = DATA;                                                    // LOD
                        RESULT[9]  = REG[DREG];                                               // STO
                        RESULT[10] = {REG[DREG][15:8], IMM};                                  // IMM
                        RESULT[11] = (REG[DREG] * REG[SREG]) >> OPTS;                         // MUL
                        RESULT[12] = PC;                                                      // BRA
                        RESULT[13] = PC + 1;                                                  // BSR (save PC+1)
                        RESULT[14] = REG[DREG];                                               // RET
                        RESULT[15] = REG[DREG] - 1;                                           // LOP
                        
                        // Update register based on opcode
                        if(OPCODE != 9 && OPCODE != 12) begin // Not STO or BRA
                            REG[DREG] <= RESULT[OPCODE];
                        end
                        
                        // Calculate next PC
                        case(OPCODE)
                            12: begin // BRA: PC + sign-extended IMM
                                NEXT_PC = PC + {{8{IMM[7]}}, IMM};
                                is_branch <= 1;
                                prev_pc <= PC;
                                prev_history <= predict_history;
                                prev_prediction <= predict_taken;
                                branch_target <= PC + {{8{IMM[7]}}, IMM};
                                next_sequential_pc <= PC + 1;
                            end
                            13: begin // BSR: PC + sign-extended IMM
                                NEXT_PC = PC + {{8{IMM[7]}}, IMM};
                                is_branch <= 1;
                                prev_pc <= PC;
                                prev_history <= predict_history;
                                prev_prediction <= predict_taken;
                                branch_target <= PC + {{8{IMM[7]}}, IMM};
                                next_sequential_pc <= PC + 1;
                            end
                            14: begin // RET: PC = REG[DREG]
                                NEXT_PC = REG[DREG];
                                is_branch <= 1;
                                prev_pc <= PC;
                                prev_history <= predict_history;
                                prev_prediction <= predict_taken;
                                branch_target <= REG[DREG];
                                next_sequential_pc <= PC + 1;
                            end
                            15: begin
                                // LOP: test, decrement and branch
                                // If REG[DREG] > 0, decrement it and branch to PC + IMM
                                // Otherwise, just increment PC
                                if(REG[DREG] > 0) begin
                                    NEXT_PC = PC + {{8{IMM[7]}}, IMM};
                                end else begin
                                    NEXT_PC = PC + 1;
                                end
                                is_branch <= 1;
                                prev_pc <= PC;
                                prev_history <= predict_history;
                                prev_prediction <= predict_taken;
                                branch_target <= PC + {{8{IMM[7]}}, IMM};
                                next_sequential_pc <= PC + 1;
                            end
                            default: begin
                                NEXT_PC = PC + 1;             // Default: PC + 1
                                is_branch <= 0;
                            end
                        endcase
                        
                        // Memory operations
                        if(OPCODE == 8 || OPCODE == 9) begin
                            // LOD or STO
                            ADDR <= REG[SREG];
                            if(OPCODE == 8) begin // LOD
                                RD <= 1;
                            end else begin // STO
                                WR <= 1;
                                DOUT <= REG[DREG];
                            end
                            MEM_ACCESS <= 1;
                        end else begin
                            // Update PC for next instruction
                            // For branch instructions, use the branch predictor's prediction
                            if((OPCODE == 12 || OPCODE == 13 || OPCODE == 15) && predict_valid) begin
                                if(predict_taken) begin
                                    PC <= branch_target;
                                end else begin
                                    PC <= PC + 1;
                                end
                            end else begin
                                PC <= NEXT_PC;
                            end
                            STAGE <= 0; // Go back to fetch stage
                        end
                    end
                endcase
            end
        end
    end

endmodule
