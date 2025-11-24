module fmamult(Xm, Ym, Pm);

    input logic [10:0] Xm;
    input logic [10:0] Ym;
    output logic [22:0] Pm;

    logic [22:0] product;
    always_comb begin
        // Placeholder for multiplication logic
        product = Xm * Ym; // Simple multiplication for illustration
        Pm = product[21:0]; // Taking the upper bits as the product mantissa

        $display("Mult: Pm=%h", Pm);
    end

endmodule