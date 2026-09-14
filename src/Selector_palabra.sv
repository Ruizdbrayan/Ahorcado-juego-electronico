module Selector_palabra (

    input logic       clk,
    input logic       rst,

    input logic       partida_iniciada,
    input logic       dificultad,

    output logic [63:0] palabra_actual,

    // IMPORTANTE:
    // 4 bits para poder representar hasta 8.
    output logic [3:0] cantidad_letras

);

    logic [4:0] numero_aleatorio;
    logic [4:0] indice_palabra;

    logic [63:0] palabra_memoria;

    logic [3:0] cantidad_letras_nueva;


    // ============================================================
    // LFSR
    // ============================================================

    LFSR lfsr_inst (

        .clk(clk),
        .rst(rst),

        .numero_aleatorio(numero_aleatorio)

    );


    // ============================================================
    // INDICE DE PALABRA
    // ============================================================

    assign indice_palabra = numero_aleatorio;


    // ============================================================
    // MEMORIA
    // ============================================================

    Memoria memoria_inst (

        .dificultad(dificultad),
        .indice_palabra(indice_palabra),

        .palabra_actual(palabra_memoria)

    );


    // ============================================================
    // DETERMINAR CANTIDAD DE LETRAS
    // ============================================================

    always_comb begin

        cantidad_letras_nueva = 4'd0;


        if (palabra_memoria[63:56] != 8'h20)
            cantidad_letras_nueva = 4'd1;

        if (palabra_memoria[55:48] != 8'h20)
            cantidad_letras_nueva = 4'd2;

        if (palabra_memoria[47:40] != 8'h20)
            cantidad_letras_nueva = 4'd3;

        if (palabra_memoria[39:32] != 8'h20)
            cantidad_letras_nueva = 4'd4;

        if (palabra_memoria[31:24] != 8'h20)
            cantidad_letras_nueva = 4'd5;

        if (palabra_memoria[23:16] != 8'h20)
            cantidad_letras_nueva = 4'd6;

        if (palabra_memoria[15:8] != 8'h20)
            cantidad_letras_nueva = 4'd7;

        if (palabra_memoria[7:0] != 8'h20)
            cantidad_letras_nueva = 4'd8;

    end


    // ============================================================
    // REGISTRO DE PALABRA
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            palabra_actual <= 64'b0;

            cantidad_letras <= 4'd0;

        end else if (partida_iniciada) begin

            palabra_actual <= palabra_memoria;

            cantidad_letras <= cantidad_letras_nueva;

        end

    end

endmodule