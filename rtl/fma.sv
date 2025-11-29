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

      logic XNaN, XInf, XSNaN, XExpMax;
      logic YNaN, YInf, YSNaN, YExpMax;
      logic ZNaN, ZInf, ZSNaN, ZExpMax;

      // stubbed ideas for instantiation ideas

      unpack unpackX(
            .X(x),
            .SgnX(Xs),
            .ExpX(Xe),
            .ManX(Xm),
            .XNaN(XNaN),
            .XSNaN(XSNaN),
            .XZero(XZero),
            .XInf(XInf),
            .XExpMax(XExpMax),
            .XSubnorm()
      );

      unpack unpackY(
            .X(y),
            .SgnX(Ys),
            .ExpX(Ye),
            .ManX(Ym),
            .XNaN(YNaN),
            .XSNaN(YSNaN),
            .XZero(YZero),
            .XInf(YInf),
            .XExpMax(YExpMax),
            .XSubnorm()
      );

      unpack unpackZ(
            .X(z),
            .SgnX(Zs),
            .ExpX(Ze),
            .ManX(Zm),
            .XNaN(ZNaN),
            .XSNaN(ZSNaN),
            .XZero(ZZero),
            .XInf(ZInf),
            .XExpMax(ZExpMax),
            .XSubnorm()
      );

      logic [6:0] Pe;
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

      logic [22:0] Pm;

      fmamult mult(
            .Xm(Xm),
            .Ym(Ym),
            .Pm(Pm)
      );

      logic [35:0] Am;
      logic ASticky;
      logic KillProd;

      fmaalign align(
            .Xe(Xe),
            .Ye(Ye),
            .Ze(Ze),
            .Zm(Zm),
            .XZero(XZero),
            .YZero(YZero),
            .ZZero(ZZero),
            .Am(Am),
            .ASticky(ASticky),
            .KillProd(KillProd)
      );

      logic PmKilled;

      logic Ss;
      logic [5:0] Se;
      logic [35:0] Sm;
      fmaadd sadd(
            .Am(Am),
            .As(As),
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
      
      logic [15:0] result_normalized;
      logic inexact;
      logic overflow;
      fmanorm normalize(
            .Ss(Ss),
            .Se(Se),
            .Sm(Sm),
            .ASticky(ASticky),
            .roundmode(roundmode),
            .result(result_normalized),
            .inexact(inexact),
            .overflow(overflow)
      );

      always_comb begin
            flags = {4{1'b0}}; // Clear all flags initially
            if ((XInf & YZero) | (YInf & XZero)) begin
                  result = 16'h7e00;
                  flags[3] = 1; // Invalid operation
            end else if (XNaN | YNaN | ZNaN) begin
                  result = 16'h7e00; // Quiet NaN
                  if ((XSNaN | YSNaN | ZSNaN)) begin
                        flags[3] = 1; // Invalid operation
                  end
            end else if (XInf | YInf | ZInf) begin 
                  if ((XInf | YInf) & ZInf & Ps != Zs) begin
                        result = 16'h7e00; // Quiet NaN
                        flags[3] = 1; // Invalid operation
                  end else if (XInf | YInf & ~ZInf) begin
                        result = {Ps, 15'h7c00};
                  end else begin
                        result = {Zs, 15'h7c00};
                  end
            end else begin
                  result = result_normalized;
                  if (^inexact === 1'bx) begin
                        flags[0] = 1'b0;
                  end else begin
                        flags[0] = inexact;
                  end
                  if (Se[5] | (&result[14:10]) | overflow) begin
                        flags[2] = 1; //Overflow
                        flags[0] = 1; // Inexact
                        if (roundmode == 2'b01) begin
                              result = {Ps, 5'b11111, 10'b0000000000}; // Inf
                        end else if (roundmode == 2'b11) begin
                              if (Ps == 1'b1) begin
                                    result = {Ps, 5'b11110, 10'b1111111111}; // Max normal
                              end else begin
                                    result = {Ps, 5'b11111, 10'b0000000000}; // Inf
                              end
                        end else if (roundmode == 2'b10) begin
                              if (Ps == 1'b0) begin
                                    result = {Ps, 5'b11110, 10'b1111111111}; // Max normal
                              end else begin
                                    result = {Ps, 5'b11111, 10'b0000000000}; // -Inf
                              end
                        end else begin
                              result = {Ps, 5'b11110, 10'b1111111111}; // Max normal
                        end
                  end else if (~|result[14:0]) begin
                        if (roundmode == 2'b10) begin
                              result = {Ps | Zs, 15'b0}; // -0
                        end else begin 
                              result = {As & Ps, result[14:0]}; // Force to even
                        end
                  end
            end
            
      end
      
endmodule