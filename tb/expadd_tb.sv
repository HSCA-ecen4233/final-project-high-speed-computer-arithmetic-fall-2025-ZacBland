module test;
    string line;
    integer file;
    integer passed=0;
    integer total=0;

    logic [4:0] Xe;
    logic [4:0] Ye;
    logic       XZero;
    logic       YZero;
    logic [10:0] Pe;
    logic       PeOverflow;

    fmaexpadd dut (
        .Xe(Xe),
        .Ye(Ye),
        .XZero(XZero),
        .YZero(YZero),
        .Pe(Pe),
        .PeOverflow(PeOverflow)
    );

    logic [10:0] expected_Pe;
    logic expected_PeOverflow;

    integer line_num = 0;

    initial begin
        // open the CSV file
        file = $fopen("tb/vecs/expadd_vectors.csv", "r");
        if (file == 0) begin
            $fatal("Failed to open expadd_vectors.csv");
        end
        
        while(!$feof(file)) begin
            if ($fgets(line, file)) begin
                
                // Skip header line
                if (line == "Xe_hex,Ye_hex,XZero,YZero,Pe_hex,PeOverflow\n") continue;
                if (line.len() == 0 || line.substr(0,0) == "#") continue; // skip empty lines or comments

                // Parse the CSV line
                $sscanf(line, "%h,%h,%b,%b,%h,%b", 
                        Xe, Ye, XZero, YZero, expected_Pe, expected_PeOverflow);
                line_num++;
                #10; // wait for outputs to stabilize
                total++;
                if (Pe === expected_Pe && PeOverflow === expected_PeOverflow) begin
                    passed++;
                end
                else begin
                    $display("Test (#%0d) failed for Xe=%h, Ye=%h, XZero=%b, YZero=%b: Expected Pe=%h, PeOverflow=%b but got Pe=%h, PeOverflow=%b",
                             line_num, Xe, Ye, XZero, YZero, expected_Pe, expected_PeOverflow, Pe, PeOverflow);
                end
            end
        end

        $display("Test complete: %0d/%0d passed", passed, total);
        $fclose(file);
        $finish;
    end

endmodule