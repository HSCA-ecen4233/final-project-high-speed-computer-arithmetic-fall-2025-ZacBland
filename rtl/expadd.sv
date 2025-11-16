module fmaexpadd(
    Xe, Ye, XZero, YZero, Pe
);

    input logic [4:0] Xe;
    input logic [4:0] Ye;
    input logic       XZero;
    input logic       YZero;
    output logic [5:0] Pe;

    logic [5:0] exp_sum;
    logic [5:0] exp_adjusted;
    
    always_comb begin
        exp_sum = Xe + Ye;
        exp_adjusted = exp_sum - 6'd15;
        if (XZero || YZero) begin
            Pe = 6'd0;
        end else begin
            Pe = exp_adjusted;
        end
    end

endmodule