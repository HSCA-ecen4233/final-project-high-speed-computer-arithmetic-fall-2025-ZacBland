
module fmaalign(
    input  logic [4:0] Ze,
    input  logic [10:0] Zm,      // unused for current alignment (kept for pipeline context)
    input  logic       XZero,
    input  logic       YZero,
    input  logic       ZZero,
    input  logic [5:0] Pe,      // Exponent Product
    output logic [47:0] Am,      // aligned mantissa output
    output logic       ASticky,
    output logic       KillProd
);
    
    logic Acnt;
    logic shift_left;

    // Subtract Bias (15) from Pe and then subtract Ze to get alignment count
    assign shift_left = (Pe < Ze); // Check if we need to shift left
    assign Acnt = shift_left ? (Ze - Pe) : (Pe - Ze);
    assign Am = shift_left ? (Zm << Acnt) : (Zm >> Acnt);
    
endmodule