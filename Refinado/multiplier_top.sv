// multiplier_top.sv
// Módulo top-level — conecta controle e datapath
// Interface idêntica para ambas as versões (simples e refinada)

module multiplier_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [31:0] multiplicand_in,
    input  logic [31:0] multiplier_in,
    output logic [63:0] product,
    output logic        done
);

    logic multiplier_lsb;
    logic load, product_wr, shift_en;

    multiplier_control ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .done           (done),
        .multiplier_lsb (multiplier_lsb),
        .load           (load),
        .product_wr     (product_wr),
        .shift_en       (shift_en)
    );

    multiplier_datapath dp (
        .clk             (clk),
        .rst_n           (rst_n),
        .multiplicand_in (multiplicand_in),
        .multiplier_in   (multiplier_in),
        .load            (load),
        .product_wr      (product_wr),
        .shift_en        (shift_en),
        .multiplier_lsb  (multiplier_lsb),
        .product         (product)
    );

endmodule
