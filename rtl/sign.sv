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

        $display("Xs: %b, Ys: %b, Zs: %b", Xs, Ys, Zs);
        $display("Ps: %b, As: %b, InvA: %b", Ps, As, InvA);
    end

endmodule

// 53ff * 3e00 + 43ff
// 0101001111111111  63.96875
// 0011111000000000  1.5
// 0100001111111111  3.998046875


// 53ff * 3c01 + 3bff

// 0101001111111111  63.96875
// 0011110000000001  1.0009765625
//                   0.99951171875