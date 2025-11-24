module fmashiftcalc(Se, Sm, SCnt, NormSumE, SZero, PreResultSubnorm, PreShiftAmt);

    input logic [5:0] Se;
    input logic [34:0] Sm;
    input logic [4:0] SCnt;

    output logic signed [5:0] NormSumE;
    output logic SZero;
    output logic PreResultSubnorm;
    output logic [5:0] PreShiftAmt;

    logic [4:0] int_SCnt;
    logic [5:0] int_Se;
    logic [34:0] int_Sm;

    logic [6:0] inv_SCnt;
    logic [7:0] ext_inv_SCnt;

    logic [8:0] PreNormSumExp;


    always_comb begin

        int_Se = Se & (1 << 7) - 1; // Mask to 7 bits
        int_Sm = Sm & ((1 << 36) - 1);
        int_SCnt = SCnt & ((1 << 6) - 1); // Mask to 6 bits
        SZero = (Sm == 0);
        
        inv_SCnt = ~SCnt & (1 << 6) - 1;
        ext_inv_SCnt = (1 << 6) | inv_SCnt; // Sign extend

        PreNormSumExp = (Se + ext_inv_SCnt + 14) & (1 << 7) - 1;
        NormSumE = PreNormSumExp[5:0];

        PreResultSubnorm = ($signed(PreNormSumExp) <= 0) & ($signed(PreNormSumExp) >= -10);

        if (PreResultSubnorm) begin
            PreShiftAmt = ((Se & (1 << 6) - 1) + 13) & (1 << 6) - 1;
        end else begin
            PreShiftAmt = int_SCnt & (1 << 6) - 1;
        end

        //$display("fmashiftcalc NormSumExp: %d SZero: %b PreResultSubnorm: %b PreShiftAmt: %d", NormSumE, SZero, PreResultSubnorm, PreShiftAmt);
    end


endmodule

module fmanorm(Se, Sm, Ss, result);

    input logic [5:0]  Se;
    input logic [34:0] Sm;
    input logic       Ss;
    output logic [15:0] result;

    logic [4:0] SCnt;
    logic [34:0] PreNormCnt;

    assign PreNormCnt = Sm & ((1 << 36) - 1);
    fmalzc lzc (
        .Sm(PreNormCnt),
        .NormCnt(SCnt)
    );

    logic [5:0] NormSumE;
    logic SZero;
    logic PreResultSubnorm;
    logic [5:0] PreShiftAmt;

    fmashiftcalc shiftcalc (
        .Se(Se),
        .Sm(Sm),
        .SCnt(SCnt),
        .NormSumE(NormSumE),
        .SZero(SZero),
        .PreResultSubnorm(PreResultSubnorm),
        .PreShiftAmt(PreShiftAmt)
    );

    logic [5:0] shift;
    logic [5:0] e;

    logic [35:0] shiftedSm;

    logic [10:0] frac;
    logic [9:0] mant;
    logic guard;
    logic roundb;
    logic sticky;

    logic tie;
    logic incr;

    logic [4:0] e5;
    logic [4:0] temp_e;

    assign shift = PreShiftAmt & 'h3F;

    logic [1:0] roundmode;
    assign roundmode = 2'b00;

    always_comb begin // Round to nearest even 
        if (roundmode == 2'b10) begin
            shiftedSm = (shift < 64) ? ((Sm << shift) & ((1 << 36) - 1)) : 35'd0;
            e = NormSumE & 'h7F;

            frac = (shiftedSm >> 25) & 'h7FF;
            mant = frac & 'h3FF;
            guard = (shiftedSm >> 24) & 1'b1;
            roundb = (shiftedSm >> 23) & 1'b1;
            sticky = |(shiftedSm & ((1 << 23) - 1));

            tie = guard & ~roundb & ~sticky;
            incr = (guard & (roundb | sticky)) | (tie & mant[0]);
            if (incr) begin
                mant = mant + 1;
                if (mant == (1 << 10)) begin
                    mant = 0;
                    e = (e+1) & 'h7F;
                end
            end

            if (PreResultSubnorm) begin
                e5 = 0;
            end else begin
                temp_e = e & 'h1F;
                e5 = (temp_e < 31) ? temp_e : 31;
                e5 = (e5 > 0) ? e5 : 0;
            end

            if (e5 == 'h1F & ~PreResultSubnorm) begin
                result = {Ss, ('h1F << 10)};
            end else begin
                result = {Ss, e5[4:0], mant[9:0]};
            end
        end else begin
            shiftedSm = (shift < 64) ? ((Sm << shift) & ((1 << 36) - 1)) : 35'd0;
            e = NormSumE & 'h7F;
            frac = (shiftedSm >> 25) & 'h3FF;
            mant = frac & 'h3FF;

            result = {Ss, e[4:0], mant[9:0]};
        end
    end

endmodule