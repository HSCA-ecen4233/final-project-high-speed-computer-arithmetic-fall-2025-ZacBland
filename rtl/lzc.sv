module fmalzc (Sm, NormCnt);

    input logic [35:0] Sm;
    output logic signed [5:0] NormCnt;

    always_comb begin
        for (int i = 35; i >= 0; i--) begin
            if (Sm[i] == 1'b1) begin
                NormCnt = 35 - i; 
                break;
            end
        end
    end

endmodule