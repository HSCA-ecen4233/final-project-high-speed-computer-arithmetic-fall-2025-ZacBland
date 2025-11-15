// fma16.sv
// David_Harris@hmc.edu 26 February 2022

// Operation: general purpose multiply, add, fma, with optional negation
//   If mul=1, p = x * y.  Else p = x.
//   If add=1, result = p + z.  Else result = p.
//   If negr or negz = 1, negate result or z to handle negations and subtractions
//   fadd: mul = 0, add = 1, negr = negz = 0
//   fsub: mul = 0, add = 1, negr = 0, negz = 1
//   fmul: mul = 1, add = 0, negr = 0, negz = 0
//   fmadd:  mul = 1, add = 1, negr = 0, negz = 0
//   fmsub:  mul = 1, add = 1, negr = 0, negz = 1
//   fnmadd: mul = 1, add = 1, negr = 1, negz = 0
//   fnmsub: mul = 1, add = 1, negr = 1, negz = 1

module fma16 (x, y, z, mul, add, negr, negz,
	      roundmode, result, flags, clk);
      
      input logic [15:0]  x, y, z;   
      input logic 	       mul, add, negr, negz;
      input logic [1:0]   roundmode;
      input logic         clk;

      output logic [15:0] result;
      output logic [3:0]  flags;

      logic [4:0] 	       Xe, Ye, Ze;
      logic [10:0] 	       Xm, Ym, Zm;
      logic 	       Xs, Ys, Zs;

      logic              XZero, YZero, ZZero;

      // stubbed ideas for instantiation ideas

      unpack unpackX(
            .X(x),
            .SgnX(Xs),
            .ExpX(Xe),
            .ManX(Xm),
            .XNaN(),
            .XSNaN(),
            .XZero(XZero),
            .XInf(),
            .XExpMax(),
            .XSubnorm()
      );

      unpack unpackY(
            .X(y),
            .SgnX(Ys),
            .ExpX(Ye),
            .ManX(Ym),
            .XNaN(),
            .XSNaN(),
            .XZero(YZero),
            .XInf(),
            .XExpMax(),
            .XSubnorm()
      );

      unpack unpackZ(
            .X(z),
            .SgnX(Zs),
            .ExpX(Ze),
            .ManX(Zm),
            .XNaN(),
            .XSNaN(),
            .XZero(ZZero),
            .XInf(),
            .XExpMax(),
            .XSubnorm()
      );

      logic [5:0] Pe;
      logic Ps, As, InvA;

      fmasign sign(
            .OpCtrl({mul, add}), // simplified OpCtrl
            .Xs(Xs),
            .Ys(Ys),
            .Zs(Zs),
            .Ps(Ps),
            .As(As),
            .InvA(InvA)
      );

      fmaexpadd expadd(
            .Xe(Xe),
            .Ye(Ye),
            .XZero(XZero),
            .YZero(YZero),
            .Pe(Pe)
      );

      logic [10:0] Pm;

      fmamult mult(
            .Xm(Xm),
            .Ym(Ym),
            .Pm(Pm)
      );

      logic [47:0] Am;
      logic        ASticky1, KillProd1;
      

      fmaalign align(
            .Ze(Ze),
            .Zm(Zm),
            .XZero(XZero),
            .YZero(YZero),
            .ZZero(ZZero),
            .Pe(Pe),
            .Am(Am),
            .ASticky(ASticky1),
            .KillProd(KillProd1)
      );

      assign ASticky = 0; // to be connected
      assign KillProd = 0; // to be connected

      logic PmKilled;

      logic Ss;
      logic [5:0] Se;
      logic [34:0] Sm;

      fmaadd sadd(
            .Am(Am),
            .Pm(Pm),
            .Ze(Ze),
            .Pe(Pe),
            .Ps(Ps),
            .KillProd(KillProd),
            .ASticky(ASticky),
            .InvA(InvA),
            .Sm(Sm),
            .Se(Se),
            .Ss(Ss)
      );

      logic signed [4:0] NormCnt;

      fmalzc lzc (
            .Sm(Sm),
            .NormCnt(NormCnt)
      );

      fmanorm normalize(
            .Ss(Ss),
            .Se(Se),
            .Sm(Sm),
            .NormCnt(NormCnt),
            .Mf(result)
      );

      // Debug display
      always @(negedge clk) begin
            $display("FMA16 Operation Debug:");
            $display("Pe %d", Pe - 6'd15);
            $display("Pm: %b", Pm);
            $display("Xm: %b, Ym: %b, Zm: %b", Xm, Ym, Zm);
            #10;
            $display("Ss: %b", Ss);
            $display("Se: %d", Se - 6'd15);
            $display("Sm: %b.%b", Sm[34:10], Sm[9:0]);

            $display("NormCnt: %d", NormCnt);
            $display("Result: %b", result);

            $display("--------------------------------");
      end
      
endmodule