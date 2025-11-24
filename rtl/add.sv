module fmaadd(Am, Pm, Ze, Pe, Ps, KillProd, ASticky, InvA, Sm, Se, Ss);

    input logic [34:0] Am;
    input logic [21:0] Pm;
    input logic [4:0]  Ze;
    input logic [5:0]  Pe;
    input logic        Ps;
    input logic        KillProd;
    input logic        ASticky;
    input logic        InvA;
    output logic [34:0] Sm;
    output logic [5:0]  Se;
    output logic        Ss;

    logic [3:0] Mcnt;
    logic [34:0] PreSum;
    logic [34:0] NegPreSum;
    logic        NegSum;
    logic [21:0] PmKilled;
    logic [23:0] PmExt;
    logic [37:0] AmExt;
    logic [34:0] AmInv;
    logic        carry_in;

    always_comb begin
      AmInv = (InvA) ? ~Am & ((1 << 36) - 1) : Am;

      PmKilled = KillProd ? 22'b0 : Pm;
      PmExt = {PmKilled, 2'b0}; // Align Pm to match Am's LSB
      AmExt = (InvA << 36) | (AmInv & ((1 << 36) - 1)); // Extend Am to match Pm's MSB

      carry_in = (~ASticky | KillProd) & InvA;

      PreSum = PmExt + AmExt + carry_in;
      NegSum = (PreSum >> 36) & 'b1;
      PreSum = PreSum & ((1 << 36) - 1);

      Sm = PreSum;
      Ss = 0;
      Se = KillProd ? Ze : Pe;

      //$display("Add: Sm=0x%h Se=0x%h Ss=%b", Sm, Se, Ss);
    end

endmodule

