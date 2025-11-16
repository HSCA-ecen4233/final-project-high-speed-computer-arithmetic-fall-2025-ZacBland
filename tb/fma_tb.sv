
module stimulus;

    logic clk;
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    logic [15:0] x, y, z;
    logic mult, add, negr, negz;
    logic [1:0] roundmode; // 00: rz, 01: rne, 10: rp, 11: rn

    logic [15:0] result, expected_result;
    logic [3:0] flags, expected_flags; // Invalid, Overflow, Underflow, Inexact
    logic [7:0] ctrl;

    string line;
    integer file;
    integer passed=0;
    integer total=0;

    logic [75:0] testvectors[10000:0];
    logic [31:0] vectornum, errors;

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

    string testvector_file = "tb/tests/fma_1.tv";
    initial begin
        vectornum = 0; errors = 0;
        $readmemh(testvector_file, testvectors);
    end

    logic [75:0] value;

    logic skip;

    always @(posedge clk) begin
        skip = 0;
        #1; {x,y,z,ctrl, expected_result, expected_flags} = testvectors[vectornum];
        {roundmode, mult, add, negr, negz} = ctrl;
    end
    
    always @(negedge clk) begin
        if (~skip) begin
            if (result !== expected_result) begin
                $display("%c[1;31m", 27);
                $display("Error: inputs %h * %h + %h", x, y, z);
                $display("Operation: mult=%b add=%b negr=%b negz=%b roundmode=%b", mult, add, negr, negz, roundmode);
                $display("result   = %b_%b_%b", result[15], result[14:10], result[9:0]);
                $display("expected = %b_%b_%b", expected_result[15], expected_result[14:10], expected_result[9:0]);
                $display("flags    = %b", flags);
                $display("expected = %b", expected_flags);
                errors = errors + 1;
            end else begin
                passed = passed + 1;
            end
            total = total + 1;
        end
        vectornum = vectornum + 1;
        if (testvectors[vectornum] === 76'bx) begin
            $display("%c[1;32m", 27);
            $display("Test complete: %0d/%0d passed, %0d errors", passed, total, errors);
            $display("%c[0m", 27);
            $finish;
        end
    end


endmodule