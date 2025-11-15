module fmaexpadd(
    Xe, Ye, XZero, YZero,
    Pe
);

    input logic [4:0] Xe;
    input logic [4:0] Ye;
    input logic       XZero;
    input logic       YZero;
    output logic [5:0] Pe;

    logic [5:0] exp_sum;
    logic [5:0] exp_adjusted;
    
    // Exponent addition
    assign exp_sum = Xe + Ye;

    // Adjust for bias (bias = 15 for 5-bit exponent)
    assign exp_adjusted = exp_sum - 6'd15;
    assign Pe = exp_adjusted;

endmodule