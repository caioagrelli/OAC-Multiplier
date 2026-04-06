// multiplier_control.sv  (versão refinada)
// FSM de controle do multiplicador refinado (Figura 3.11 - Patterson & Hennessy)
//
// Diferenças em relação à versão original:
//
//   ORIGINAL (Figura 3.4):
//     - ADD_OR_SKIP: testa multiplier_lsb (vindo de multiplier_reg[0])
//     - SHIFT: desloca multiplicand_reg à esquerda E multiplier_reg à direita
//
//   REFINADO (Figura 3.11):
//     - ADD_OR_SKIP: testa multiplier_lsb (vindo de product_reg[0] — mesma interface!)
//     - SHIFT: desloca apenas product_reg[64:0] à direita
//              o multiplicador "some" pelo shift; o carry integra ao acumulador
//
// A interface da FSM com o datapath É IDÊNTICA ao original:
//   multiplier_lsb → entrada  (agora vem de product_reg[0] no datapath)
//   load, product_wr, shift_en → saídas (mesmos sinais, nova semântica no datapath)
//
// Fluxo dos estados (mesmo do original):
//
//   IDLE        — aguarda 'start'
//   LOAD        — inicializa registradores (1 ciclo)
//   ADD_OR_SKIP — testa product_reg[0]; se 1: product_wr=1 (soma); se 0: product_wr=0 (pula)
//   SHIFT       — shift right em product_reg[64:0]; incrementa contador
//   DONE        — sinaliza conclusão; aguarda 'start' ser desativado

module multiplier_control (
    input  logic clk,
    input  logic rst_n,

    // Interface com o usuário
    input  logic start,
    output logic done,

    // Interface com o datapath (idêntica ao original)
    input  logic multiplier_lsb, // product_reg[0] na versão refinada

    output logic load,           // Carrega operandos iniciais
    output logic product_wr,     // Habilita escrita da ALU em product_reg[64:32]
    output logic shift_en        // Habilita shift right em product_reg[64:0]
);

    // -----------------------------------------------------------------------
    // Definição dos estados — one-hot encoding (idêntica ao original)
    // -----------------------------------------------------------------------
    typedef enum logic [4:0] {
        IDLE        = 5'b00001,
        LOAD        = 5'b00010,
        ADD_OR_SKIP = 5'b00100,
        SHIFT       = 5'b01000,
        DONE        = 5'b10000
    } state_t;

    state_t state, next_state;

    // -----------------------------------------------------------------------
    // Contador de iterações (0 a 31 → 32 iterações)
    // -----------------------------------------------------------------------
    logic [5:0] count;
    logic       count_en;
    logic       count_rst;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         count <= '0;
        else if (count_rst) count <= '0;
        else if (count_en)  count <= count + 6'd1;
    end

    // -----------------------------------------------------------------------
    // Registrador de estado
    // -----------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // -----------------------------------------------------------------------
    // Lógica de próximo estado (idêntica ao original)
    // -----------------------------------------------------------------------
    always_comb begin
        next_state = state;
        case (state)
            IDLE:        if (start)           next_state = LOAD;
            LOAD:                             next_state = ADD_OR_SKIP;
            ADD_OR_SKIP:                      next_state = SHIFT;
            SHIFT:       if (count == 6'd31)  next_state = DONE;
                         else                 next_state = ADD_OR_SKIP;
            DONE:        if (!start)          next_state = IDLE;
            default:                          next_state = IDLE;
        endcase
    end

    // -----------------------------------------------------------------------
    // Lógica de saída (idêntica ao original — a diferença está no datapath)
    // -----------------------------------------------------------------------
    always_comb begin
        load       = 1'b0;
        product_wr = 1'b0;
        shift_en   = 1'b0;
        done       = 1'b0;
        count_en   = 1'b0;
        count_rst  = 1'b0;

        case (state)
            IDLE: begin
                count_rst = 1'b1;
            end

            LOAD: begin
                load      = 1'b1;
                count_rst = 1'b1;
            end

            ADD_OR_SKIP: begin
                // product_reg[0] == 1 → soma multiplicand aos 32 bits altos
                // product_reg[0] == 0 → não escreve (pula a soma)
                product_wr = multiplier_lsb;
            end

            SHIFT: begin
                // Shift right em product_reg[64:0]
                // No original: shift left em multiplicand_reg + shift right em multiplier_reg
                // No refinado: apenas um shift right em product_reg — mais econômico
                shift_en = 1'b1;
                count_en = 1'b1;
            end

            DONE: begin
                done = 1'b1;
            end

            default: ;
        endcase
    end

endmodule
