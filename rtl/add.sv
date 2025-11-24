module fmaadd(Am, Pm, Ze, Pe, Ps, KillProd, ASticky, InvA, Sm, Se, Ss);

    input logic [35:0] Am;
    input logic [21:0] Pm;
    input logic [4:0]  Ze;
    input logic [5:0]  Pe;
    input logic        Ps;
    input logic        KillProd;
    input logic        ASticky;
    input logic        InvA;
    output logic [35:0] Sm;
    output logic [5:0]  Se;
    output logic        Ss;

    logic [3:0] Mcnt;
    logic [36:0] PreSum;
    logic [36:0] NegPreSum;
    logic        NegSum;
    logic [21:0] PmKilled;
    logic [21:0] PmKilled_inv;
    logic [23:0] PmExt;
    logic [37:0] AmExt;
    logic [35:0] AmInv;
    logic        carry_in;

    logic [36:0] term1;
    logic [2:0] term2;

    always_comb begin
      AmInv = (InvA) ? ~Am & ((1 << 36) - 1) : Am;

      PmKilled = KillProd ? 22'b0 : Pm;
      PmExt = {PmKilled, 2'b0}; // Align Pm to match Am's LSB
      AmExt = (InvA << 36) | (AmInv & ((1 << 36) - 1)); // Extend Am to match Pm's MSB

      carry_in = (~ASticky | KillProd) & InvA;

      PreSum = PmExt + AmExt + carry_in;
      NegSum = PreSum[36];
      PreSum = PreSum & ((1 << 36) - 1);

      PmKilled_inv = ~PmKilled & ((1 << 22) - 1);

      term1 = (('hFFF << (22+2)) | (PmKilled_inv << 2));
      term2 = ((~ASticky | ~KillProd) & 'b1) << 2;
      NegPreSum = (Am + term1 + term2) & ((1 << 36) - 1);

      Sm = (NegSum) ? NegPreSum : PreSum;
      Ss = NegSum ^ Ps;
      Se = KillProd ? Ze : Pe;
      $display("Add: Sm=0x%h Se=0x%h Ss=%b", Sm, Se, Ss);
    end

endmodule

