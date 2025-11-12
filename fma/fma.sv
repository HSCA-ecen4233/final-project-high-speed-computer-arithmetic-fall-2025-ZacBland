module fma16 (x, y, z, mul, add, negr, negz,
	      roundmode, result, flags);
   
   input logic [15:0]  x, y, z;   
   input logic 	       mul, add, negr, negz;
   input logic [1:0]   roundmode;
   
   output logic [15:0] result;
   output logic [3:0]  flags;

   logic [4:0] 	       Xe, Ye, Ze;
   logic [9:0] 	       Xm, Ym, Zm;
   logic 	       Xs, Ys, Zs;

   // stubbed ideas for instantiation ideas
   
   // fmaexpadd expadd(.Xe, .Ye, .XZero, .YZero, .Pe);
   // fmamult mult(.Xm, .Ym, .Pm);
   // fmasign sign(.OpCtrl, .Xs, .Ys, .Zs, .Ps, .As, .InvA);
   // fmaalign align(.Ze, .Zm, .XZero, .YZero, .ZZero, .Xe, .Ye, .Am, .ASticky, .KillProd);
   // fmaadd add(.Am, .Pm, .Ze, .Pe, .Ps, .KillProd, .ASticky, .AmInv, .PmKilled, .InvA, .Sm, .Se, .Ss);
   // fmalza lza (.A(AmInv), .Pm(PmKilled), .Cin(InvA & (~ASticky | KillProd)), .sub(InvA), .SCnt);

 
endmodule