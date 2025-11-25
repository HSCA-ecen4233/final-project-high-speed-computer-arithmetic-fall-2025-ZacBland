module unpack(X, SgnX, ExpX, ManX, XNaN, XSNaN, XZero, XInf, XExpMax, XSubnorm);

    input logic [15:0] X;
    output logic SgnX;
    output logic [4:0] ExpX;
    output logic [10:0] ManX;
    output logic XNaN;
    output logic XSNaN;
    output logic XZero;
    output logic XInf;
    output logic XExpMax;
    output logic XSubnorm;

    logic [9:0] XFrac;
    logic XFracZero;
    logic ExpNonZero;

    assign SgnX = X[15];
    assign XFrac = X[9:0];
    assign ExpX = X[14:10];
    assign ExpNonZero = |X[14:10];
    assign ManX = {ExpNonZero, XFrac};
    assign XExpMax = &X[14:10];
    assign XFracZero = ~|XFrac;
    assign XNaN = XExpMax & ~XFracZero;
    assign XInf = XExpMax & XFracZero;
    assign XSNaN = XNaN & ~(X[9]);
    assign XZero = ~ExpNonZero & XFracZero;
    assign XSubnorm = ~ExpNonZero & ~XFracZero;

    //always_comb begin
    //    $display("Unpack: XNaN=%b", XNaN);
    //end

endmodule