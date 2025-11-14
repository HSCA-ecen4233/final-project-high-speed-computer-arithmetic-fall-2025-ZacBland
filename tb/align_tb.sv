
module test;
    string line;
    integer file;
    integer passed=0;
    integer total=0;

    logic [4:0]    Ze;
    logic [9:0]    Zm;
    logic          XZero, YZero, ZZero;
    logic [4:0]    Xe, Ye;
    logic [9:0]    Am;    // aligned mantissa output
    logic          ASticky, KillProd; // outputs

    align dut (
        .Ze(Ze),
        .Zm(Zm),
        .XZero(XZero),
        .YZero(YZero),
        .ZZero(ZZero),
        .Xe(Xe),
        .Ye(Ye),
        .Am(Am),
        .ASticky(ASticky),
        .KillProd(KillProd)
    );

    logic expected_ASticky;
    logic expected_KillProd;
    logic [9:0] expected_Am;

    integer line_num = 0;

    initial begin
        // open the CSV file
        file = $fopen("tb\\vecs\\align_vectors.csv", "r");
        if (file == 0) begin
            $fatal("Failed to open align_vectors.csv");
        end
        
        while(!$feof(file)) begin
            if ($fgets(line, file)) begin
                line_num++;
                // Skip header line
                if (line == "Ze_hex,Zm_hex,XZero,YZero,ZZero,Xe_hex,Ye_hex,Am_hex,ASticky,KillProd\n") continue;
                if (line.len() == 0 || line.substr(0,0) == "#") continue; // skip empty lines or comments

                // Parse the CSV line
                $sscanf(line, "%h,%h,%b,%b,%b,%h,%h,%h,%b,%b", 
                        Ze, Zm, XZero, YZero, ZZero, Xe, Ye, expected_Am, expected_ASticky, expected_KillProd);

                #10; // wait for outputs to stabilize
                total++;

                if (Am === expected_Am && ASticky === expected_ASticky && KillProd === expected_KillProd) begin
                    passed++;
                end
                else begin
                    $display("Test (#%0d) failed for Ze=%h, Zm=%h, XZero=%b, YZero=%b, ZZero=%b: Expected Am=%h, ASticky=%b, KillProd=%b but got Am=%h, ASticky=%b, KillProd=%b",
                             line_num, Ze, Zm, XZero, YZero, ZZero, expected_Am, expected_ASticky, expected_KillProd, Am, ASticky, KillProd);
                end
            end
        end

        $display("Test complete: %0d/%0d passed", passed, total);
        $fclose(file);
        $finish;
    end
endmodule