module fmanorm(Ss, Se, Sm, NormCnt, Mf);
    input logic       Ss;
    input logic [5:0]  Se;
    input logic [34:0] Sm;
    input logic signed [4:0] NormCnt;
    output logic [15:0] Mf;

    logic [34:0] SmNorm;
    logic [4:0]   SeNorm;

    always_comb begin

        if (NormCnt > 0) begin
            SmNorm = Sm << NormCnt;
            SeNorm = Se - NormCnt;
        end else if (NormCnt < 0) begin
            SmNorm = Sm >> -NormCnt;
            SeNorm = Se + -NormCnt;
        end else begin
            SmNorm = Sm;
        end
        
        // get first index of 1 in SmNorm for rounding
        $display("%b", SmNorm);

        Mf = {Ss, SeNorm, SmNorm[9:0]};
    end

endmodule