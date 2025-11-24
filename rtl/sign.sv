module fmasign(OpCtrl, Xs, Ys, Zs, Ps, As, InvA);

    input logic [1:0] OpCtrl;
    input logic      Xs, Ys, Zs;
    output logic     Ps;
    output logic     As;
    output logic     InvA;

    logic mul, add;
    assign mul = OpCtrl[1];
    assign add = OpCtrl[0];

    always_comb begin
        assign Ps = Xs ^ Ys;
        assign As = Zs ^ ~add;
        assign InvA = Ps ^ As;

        $display("Sign: Ps=%b As=%b InvA=%b", Ps, As, InvA);
    end

endmodule