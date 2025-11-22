
module fmaalign(
    input  logic [4:0] Ze,
    input  logic [10:0] Zm,      // unused for current alignment (kept for pipeline context)
    input  logic       XZero,
    input  logic       YZero,
    input  logic       ZZero,
    input  logic [5:0] Pe,      // Exponent Product
    output logic [47:0] Am,      // aligned mantissa output
    output logic       ASticky,
    output logic       KillProd
);
    
    logic [6:0] Acnt;
    logic      KillZ;
    logic [33:0]      ZmPreshifted;
    logic [43:0]      ZmShifted;

    logic signed [6:0] t_Acnt;
    always_comb begin
        Acnt = (Pe - Ze) + 7'd11 + 7'd2; // 12 is for guard, round, sticky bits
        KillZ = (Acnt > 7'd33); // If shift count exceeds mantissa bits + GRS bits
        ZmPreshifted = Zm << 13; // Shift left to make space for GRS bits

        KillProd = (Acnt < 0) | XZero | YZero;

        
        if (KillProd) begin
            ZmShifted = Zm;
            ASticky = ~(XZero | YZero);
        end else if (KillZ) begin
            ZmShifted = 44'b0;
            ASticky = ~ZZero;
        end else begin
            ZmShifted = ZmPreshifted >> Acnt;
            ASticky = |(ZmPreshifted[11-1:0]);
        end

        Am = ZmShifted; // Take upper 34 bits for Am
        
       // $display("Pe: %d", Pe - 6'd15);
       // $display("Zm : %b", Zm);
       // $display("Acnt: %d", Acnt);
       // $display("KillZ: %b", KillZ);
       // $display("t_KillProd: %b", KillProd);
       // $display("t_ASticky: %b", ASticky);
       // $display("ZmPreshifted: %b", ZmPreshifted);
       // $display("ZmShifted: %b", ZmShifted);
       // $display("Am: %b.%b", Am[47:10], Am[9:0]);

    end
    
endmodule