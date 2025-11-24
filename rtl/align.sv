
module fmaalign(
    input logic [4:0] Xe,
    input logic [4:0] Ye,
    input  logic [4:0] Ze,
    input  logic [10:0] Zm,      // unused for current alignment (kept for pipeline context)
    input  logic       XZero,
    input  logic       YZero,
    input  logic       ZZero,
    output logic [35:0] Am,      // aligned mantissa output
    output logic       ASticky,
    output logic       KillProd
);
    
    logic signed [6:0] Acnt;
    logic      KillZ;
    logic [45:0]      ZmPreshifted;
    logic [45:0]      ZmShifted;
    logic [6:0]       shift_amt;

    always_comb begin
        Acnt = (Xe + Ye) - 15 + 13 - Ze; // 12 is for guard, round, sticky bits
        KillZ = (Acnt > 7'd33); // If shift count exceeds mantissa bits + GRS bits
        ZmPreshifted = {Zm, 35'b0}; // Shift left to make space for GRS bits
        KillProd = (Acnt < 0) | XZero | YZero;
        if (KillProd) begin
            ZmShifted = (Zm << 22) & ((1 << 48) - 1);
            ASticky = ~(XZero | YZero);
        end else if (KillZ) begin
            ZmShifted = 44'b0;
            ASticky = ~ZZero;
        end else begin
            shift_amt = (Acnt > 0) ? Acnt : 7'd0;
            ZmShifted = ZmPreshifted >> shift_amt;
            ASticky = |(ZmPreshifted[9:0]);
        end

        Am = (ZmShifted >> 10) & ((1 << 36) - 1);

        $display("Align: Am=%h ASticky=%b KillProd=%b", Am, ASticky, KillProd);

    end
    
endmodule