// multiplier_datapath.sv  (versão refinada)
// Datapath do multiplicador refinado (Figura 3.11 - Patterson & Hennessy)
//
// Diferenças em relação à versão original:
//
//   ORIGINAL:
//     - multiplicand_reg [63:0]  — shift left a cada iteração
//     - multiplier_reg   [31:0]  — shift right a cada iteração
//     - product_reg      [63:0]  — acumula o resultado
//     - ALU de 64 bits
//
//   REFINADO:
//     - multiplicand_reg [31:0]  — FIXO durante toda a operação (sem shifts)
//     - product_reg      [64:0]  — 65 bits: [64]=carry, [63:32]=acumulador, [31:0]=multiplicador
//                                  o multiplicador é carregado em product_reg[31:0] no início
//                                  e vai sendo consumido pelo shift right a cada iteração
//     - ALU de 32 bits           — opera apenas sobre product_reg[63:32]
//
// Inicialização (sinal load):
//   product_reg      <= {33'b0, multiplier_in}   carry=0, acumulador=0, multiplier=valor
//   multiplicand_reg <= multiplicand_in
//
// A cada iteração:
//   1. Se product_reg[0] == 1 → product_reg[64:32] = product_reg[63:32] + multiplicand_reg
//   2. product_reg[64:0] >>= 1  (shift right lógico, 0 entra no MSB)
//
// Após 32 iterações: product_reg[63:0] contém o resultado completo

module multiplier_datapath (
    input  logic        clk,
    input  logic        rst_n,

    // Entradas de dados
    input  logic [31:0] multiplicand_in,
    input  logic [31:0] multiplier_in,

    // Sinais de controle vindos da FSM (mesma interface do original)
    input  logic        load,        // Carrega operandos iniciais
    input  logic        product_wr,  // Escreve resultado da ALU em product_reg[64:32]
    input  logic        shift_en,    // Shift right em product_reg[64:0]

    // Saída de status para a FSM
    output logic        multiplier_lsb, // product_reg[0] — bit atual do multiplicador

    // Saída do resultado
    output logic [63:0] product
);

    // -----------------------------------------------------------------------
    // Registradores internos (Figura 3.11)
    // -----------------------------------------------------------------------
    logic [31:0] multiplicand_reg;  // fixo — sem shift
    logic [64:0] product_reg;       // 65 bits: carry | acumulador | multiplicador

    // -----------------------------------------------------------------------
    // ALU de 32 bits — opera sobre a metade alta do product_reg
    // -----------------------------------------------------------------------
    logic [32:0] alu_sum;           // 33 bits: carry-out + 32 bits de resultado

    alu_32 alu (
        .a   (product_reg[63:32]),  // metade alta (acumulador)
        .b   (multiplicand_reg),    // multiplicando fixo
        .sum (alu_sum)              // resultado com carry
    );

    // -----------------------------------------------------------------------
    // Saídas combinacionais
    // -----------------------------------------------------------------------
    assign multiplier_lsb = product_reg[0];   // bit atual do multiplicador (LSB do product)
    assign product        = product_reg[63:0]; // resultado final após 32 iterações

    // -----------------------------------------------------------------------
    // Atualização dos registradores
    // -----------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand_reg <= '0;
            product_reg      <= '0;

        end else if (load) begin
            // Inicialização refinada:
            //   - multiplicand fica fixo em multiplicand_reg
            //   - multiplier vai para a metade baixa do product_reg
            //   - metade alta e carry iniciam em zero
            multiplicand_reg <= multiplicand_in;
            product_reg      <= {33'b0, multiplier_in}; // [64]=0, [63:32]=0, [31:0]=multiplier

        end else begin
            // Passo 1: se product_reg[0]==1, soma multiplicand aos 32 bits altos
            // product_wr é ativado pela FSM somente quando multiplier_lsb==1
            if (product_wr)
                product_reg[64:32] <= alu_sum; // carry capturado no bit 64

            // Passo 2: shift right lógico de todo o registrador (65 bits)
            // O carry do bit 64 desce para o bit 63 naturalmente
            if (shift_en)
                product_reg <= {1'b0, product_reg[64:1]};
        end
    end

endmodule
