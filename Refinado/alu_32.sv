// alu_32.sv
// ALU de 32 bits para o multiplicador refinado
// Baseado na Figura 3.11 - Patterson & Hennessy
//
// Diferença do original (alu_64):
//   - Opera apenas sobre os 32 bits altos do registrador product
//   - Produz 33 bits de saída para capturar o carry-out da soma
//   - Isso elimina a necessidade de uma ALU de 64 bits

module alu_32 (
    input  logic [31:0] a,    // product_reg[63:32] — parte alta do acumulador
    input  logic [31:0] b,    // multiplicand_reg   — fixo durante toda a operação
    output logic [32:0] sum   // 33 bits: [32]=carry-out, [31:0]=resultado
);
    assign sum = {1'b0, a} + {1'b0, b};

endmodule
