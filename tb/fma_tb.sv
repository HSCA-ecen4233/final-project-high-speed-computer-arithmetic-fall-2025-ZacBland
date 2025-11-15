module stimulus;

    logic clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [15:0] x, y, z;
    logic mult, add, negr, negz;
    logic [1:0] roundmode;

    logic [15:0] result;
    logic [3:0] flags;

    fma16 dut (
        .x(x),
        .y(y),
        .z(z),
        .mul(mult),
        .add(add),
        .negr(negr),
        .negz(negz),
        .roundmode(roundmode),
        .result(result),
        .flags(flags),
        .clk(clk)
    );

    initial begin
        // Example stimulus
        x = 16'b0100101110000000;
        y = 16'b0100000000000000;
        z = 16'b0100101110000000;
        mult = 1;
        add = 0;
        negr = 0;
        negz = 0;
        roundmode = 2'b00; // Round to nearest even
    end

    // Wait for a few clock cycles and then display the results
    always @(negedge clk) begin
        #10;
        $display("FMA16 Results:");
        $display("Result (bin): %b", result);
        $display("EXPECTED: %b", 16'b0100101110000000);
        $display("Sign: %b", result[15]);
        $display("Exponent: %b", result[14:10]);
        $display("Mantissa: %b", result[9:0]);
        $display("Flags: %b", flags);
        $finish;
    end

endmodule;