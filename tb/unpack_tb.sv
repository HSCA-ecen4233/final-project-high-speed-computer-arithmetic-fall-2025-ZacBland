module test;
    string line;
    integer file;
    integer passed=0;
    integer total=0;

    logic [15:0] X;
    logic SgnX;
    logic [4:0] ExpX;
    logic [10:0] ManX;
    logic XNaN;
    logic XSNaN;
    logic XZero;
    logic XInf;
    logic XExpMax;
    logic XSubnorm;

    unpack dut (
        .X(X),
        .SgnX(SgnX),
        .ExpX(ExpX),
        .ManX(ManX),
        .XNaN(XNaN),
        .XSNaN(XSNaN),
        .XZero(XZero),
        .XInf(XInf),
        .XExpMax(XExpMax),
        .XSubnorm(XSubnorm)
    );

    logic expected_SgnX;
    logic [4:0] expected_ExpX;
    logic [10:0] expected_ManX;
    logic expected_XNaN;
    logic expected_XSNaN;
    logic expected_XZero;
    logic expected_XInf;
    logic expected_XExpMax;
    logic expected_XSubnorm;

    initial begin
        // open the CSV file
        file = $fopen("tb/vecs/unpack_vectors.csv", "r");
        if (file == 0) begin
            $fatal("Failed to open unpack_vectors.csv");
        end
        
        while(!$feof(file)) begin
            if ($fgets(line, file)) begin
                
                // Skip header line
                if (line == "X_hex,SgnX,ExpX,ManX,XNaN,XSNaN,XZero,XInf,XExpMax,XSubnorm\n") continue;
                if (line.len() == 0 || line.substr(0,0) == "#") continue; // skip empty lines or comments

                // Parse the CSV line
                $sscanf(line, "%h,%d,%d,%d,%b,%b,%b,%b,%b,%b", 
                        X, expected_SgnX, expected_ExpX, expected_ManX, expected_XNaN, expected_XSNaN, expected_XZero, expected_XInf, expected_XExpMax, expected_XSubnorm);

                #10; // wait for outputs to stabilize
                total++;

                // Compare outputs
                //$display("Testing X=%h", X);
                //$display("Expected SgnX=%b, got %b", expected_SgnX, SgnX);
                //$display("Expected ExpX=%d, got %d", expected_ExpX, ExpX);
                //$display("Expected ManX=%d, got %d", expected_ManX, ManX);
                //$display("Expected XNaN=%b, got %b", expected_XNaN, XNaN);
                //$display("Expected XSNaN=%b, got %b", expected_XSNaN, XSNaN);
                //$display("Expected XZero=%b, got %b", expected_XZero, XZero);
                //$display("Expected XInf=%b, got %b", expected_XInf, XInf);
                //$display("Expected XExpMax=%b, got %b", expected_XExpMax, XExpMax);
                //$display("Expected XSubnorm=%b, got %b", expected_XSubnorm, XSubnorm);

                if (SgnX !== expected_SgnX) begin
                    $display("Test failed for X=%h: SgnX expected %b, got %b", X, expected_SgnX, SgnX);
                    continue;
                end
                if (ExpX !== expected_ExpX) begin
                    $display("Test failed for X=%h: ExpX expected %d, got %d", X, expected_ExpX, ExpX);
                    continue;
                end
                if (ManX !== expected_ManX) begin
                    $display("Test failed for X=%h: ManX expected %d, got %d", X, expected_ManX, ManX);
                    continue;
                end
                if (XNaN !== expected_XNaN) begin
                    $display("Test failed for X=%h: XNaN expected %b, got %b", X, expected_XNaN, XNaN);
                    continue;
                end
                if (XSNaN !== expected_XSNaN) begin
                    $display("Test failed for X=%h: XSNaN expected %b, got %b", X, expected_XSNaN, XSNaN);
                    continue;
                end
                if (XZero !== expected_XZero) begin
                    $display("Test failed for X=%h: XZero expected %b, got %b", X, expected_XZero, XZero);
                    continue;
                end
                if (XInf !== expected_XInf) begin
                    $display("Test failed for X=%h: XInf expected %b, got %b", X, expected_XInf, XInf);
                    continue;
                end
                if (XExpMax !== expected_XExpMax) begin
                    $display("Test failed for X=%h: XExpMax expected %b, got %b", X, expected_XExpMax, XExpMax);
                    continue;
                end
                if (XSubnorm !== expected_XSubnorm) begin
                    $display("Test failed for X=%h: XSubnorm expected %b, got %b", X, expected_XSubnorm, XSubnorm);
                    continue;
                end
                passed++;
            end
        end

        if (passed == total)
            $display("\033[32mAll tests passed: %0d/%0d\033[0m", passed, total);
        else
            $display("\033[31mSome tests failed: %0d/%0d passed.\033[0m", passed, total);
        $finish;

    end

endmodule
