module fmaexpadd(
    Xe, Ye, XZero, YZero,
    Pe, PeOverflow
);

    input logic [4:0] Xe;
    input logic [4:0] Ye;
    input logic       XZero;
    input logic       YZero;
    output logic [10:0] Pe;
    output logic       PeOverflow;

    logic [5:0] exp_sum;
    logic [5:0] exp_adjusted;
    
    // Exponent addition
    assign exp_sum = Xe + Ye;
    
    // Handle zero inputs
    always_comb begin
        if (exp_sum < 6'd15) begin
            exp_adjusted = 6'd0; // Underflow to zero
        end else begin
            exp_adjusted = exp_sum - 6'd15;
        end
        
        if (XZero | YZero) begin
            Pe = 11'd0; // Result is zero
            PeOverflow = 1'b0;
        end else if (exp_adjusted > 6'd30) begin
            Pe = 11'd31; // Set to max exponent (infinity)
            PeOverflow = 1'b1;
        end else begin
            Pe = {1'b0, exp_adjusted[4:0]}; // Normal case
            PeOverflow = 1'b0;
        end
    end

endmodule