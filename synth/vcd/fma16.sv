// Example synthesis
module fma16 (x, y, z, result);
   
   input logic [15:0]  x, y, z;   
   
   output logic [15:0] result;

   // Example (not fma)
   assign result = x[7:0]*y[7:0] + z;   
 
endmodule

