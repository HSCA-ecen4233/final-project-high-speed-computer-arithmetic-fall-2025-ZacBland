module fmaadd(Am, Pm, Ze, Pe, Ps, KillProd, ASticky, InvA, Sm, Se, Ss);

    input logic [47:0] Am;
    input logic [11:0] Pm;
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
    logic [47:0] PreSum;
    logic [47:0] NegPreSum;
    logic        NegSum;
    logic [11:0] PmKilled;
    logic [47:0] AmInv;

    always_comb begin

        AmInv = ~InvA ? Am : ~Am;
        PmKilled = Pm & ~KillProd;

        PreSum = PmKilled + AmInv + ((~ASticky | ~KillProd) & InvA);
        NegPreSum = Am | ~PmKilled | (~ASticky | ~KillProd);

        NegSum = PreSum[47];

        Ss = Ps ^ NegSum;
        Se = ~KillProd ? Pe : Ze;
        Sm = ~NegSum ? PreSum[47:0] : NegPreSum[47:0];

      //  $display("PmKilled: %b.%b", PmKilled[11:10], PmKilled[10:0]);
    //    $display("AmInv: %b", AmInv);
    //    $display("PreSum: %b", PreSum);
    //    $display("Ss: %b", Ss);
      //  $display("Se: %d", Se - 6'd15);
      //  $display("Se: %b", Se);
      //  $display("Sm: %b.%b", Sm[34:10], Sm[9:0]);
    end

endmodule

