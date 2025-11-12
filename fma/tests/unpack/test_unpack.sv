module test_unpack;
    logic clk;

    always begin
	    clk = 1; #5; clk = 0; #5;
        $display("Test!");
    end

endmodule
