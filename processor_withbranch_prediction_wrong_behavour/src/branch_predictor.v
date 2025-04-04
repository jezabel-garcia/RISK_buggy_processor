`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:21:40 04/04/2025 
// Design Name:    uDarkRISC with Branch Prediction
// Module Name:    branch_predictor 
// Project Name:   uDarkRISC
// Target Devices: 
// Tool versions: 
// Description:    Branch predictor module for uDarkRISC processor
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: Based on gshare branch predictor from Prob153_gshare.v
//
//////////////////////////////////////////////////////////////////////////////////

module branch_predictor(
    input               CLK,        // Clock input
    input               RES,        // Reset input
    
    // Prediction interface
    input               predict_valid,      // Valid prediction request
    input      [15:0]   predict_pc,         // PC for prediction
    output              predict_taken,      // Prediction result (taken or not)
    output     [7:0]    predict_history,    // Current branch history
    
    // Training interface
    input               train_valid,        // Valid training request
    input               train_taken,        // Actual branch outcome
    input               train_mispredicted, // Whether prediction was wrong
    input      [7:0]    train_history,      // Branch history at time of prediction
    input      [15:0]   train_pc            // PC of the branch being trained
);
    
    // Define parameters for the two-bit saturating counter
    parameter STRONGLY_NOT_TAKEN = 2'b00;
    parameter WEAKLY_NOT_TAKEN = 2'b01;
    parameter WEAKLY_TAKEN = 2'b10;
    parameter STRONGLY_TAKEN = 2'b11;
    
    // Pattern History Table (PHT) - 256 entries of 2-bit saturating counters
    // Using 8 bits for indexing (more appropriate for 16-bit architecture)
    reg [1:0] pht [0:255];
    
    // Global Branch History Register (BHR) - 8 bits for 16-bit architecture
    reg [7:0] branch_history;
    
    // Compute indices for prediction and training
    // Use lower 8 bits of PC XORed with branch history
    wire [7:0] predict_index = predict_pc[7:0] ^ branch_history;
    wire [7:0] train_index = train_pc[7:0] ^ train_history;
    
    // Output the current branch history for prediction
    assign predict_history = branch_history;
    
    // Determine if the branch is predicted taken based on the PHT entry
    // If the most significant bit of the counter is 1, the branch is predicted taken
    assign predict_taken = predict_valid ? pht[predict_index][1] : 1'b0;
    
    // Initialize the PHT and BHR on reset
    integer i;
    always @(posedge CLK) begin
        if(!RES) begin
            // Reset the branch history register
            branch_history <= 8'b0;
            
            // Reset all PHT entries to WEAKLY_NOT_TAKEN
            for (i = 0; i < 256; i = i + 1) begin
                pht[i] <= WEAKLY_NOT_TAKEN;
            end
        end
        else begin
            // Update the branch history register
            if (train_valid && train_mispredicted) begin
                // If there's a misprediction, recover the branch history register
                // to the state immediately after the mispredicting branch completes execution
                branch_history <= {train_history[6:0], train_taken};
            end
            else if (predict_valid && !(train_valid && train_mispredicted)) begin
                // Update the branch history register with the predicted outcome
                // Only if there's no misprediction training in the same cycle
                branch_history <= {branch_history[6:0], predict_taken};
            end
            
            // Update the PHT entry for training
            if (train_valid) begin
                case (pht[train_index])
                    STRONGLY_NOT_TAKEN: pht[train_index] <= train_taken ? WEAKLY_NOT_TAKEN : STRONGLY_NOT_TAKEN;
                    WEAKLY_NOT_TAKEN: pht[train_index] <= train_taken ? WEAKLY_TAKEN : STRONGLY_NOT_TAKEN;
                    WEAKLY_TAKEN: pht[train_index] <= train_taken ? STRONGLY_TAKEN : WEAKLY_NOT_TAKEN;
                    STRONGLY_TAKEN: pht[train_index] <= train_taken ? STRONGLY_TAKEN : WEAKLY_TAKEN;
                endcase
            end
        end
    end
    
endmodule
