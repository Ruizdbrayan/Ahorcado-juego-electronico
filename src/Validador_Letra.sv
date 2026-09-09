module Validador_Letra (

    input logic        clk,
    input logic        rst,

    // =========================================================
    // CONTROL DESDE FSM
    // =========================================================

    input logic        inicializar_partida,
    input logic        procesar_letra,

    // =========================================================
    // DATOS DEL JUEGO
    // =========================================================

    input logic [63:0] palabra_actual,
    input logic [3:0]  cantidad_letras,

    input logic [7:0]  letra_recibida,

    // =========================================================
    // ESTADO DE LA PALABRA
    // =========================================================

    output logic [63:0] palabra_estado,

    // =========================================================
    // CONTADOR DE FALLOS
    // =========================================================

    output logic [4:0] fallos,

    // =========================================================
    // RESULTADO DE LA JUGADA
    // =========================================================

    output logic letra_correcta,
    output logic letra_incorrecta,
    output logic letra_repetida,

    // =========================================================
    // PALABRA COMPLETA
    // =========================================================

    output logic palabra_completa

);


    // =========================================================
    // REGISTROS INTERNOS
    // =========================================================

    logic [63:0] palabra_secreta;

    logic [25:0] letras_usadas;

    logic [63:0] palabra_nueva;

    logic letra_valida;
    logic letra_correcta_calculada;
    logic letra_repetida_calculada;

    integer i;


    // =========================================================
    // FUNCION INDICE DE LETRA
    //
    // A = 0
    // B = 1
    // ...
    // Z = 25
    // =========================================================

    function automatic [4:0] indice_letra(
        input logic [7:0] letra
    );

        indice_letra = letra - "A";

    endfunction


    // =========================================================
    // LETRA VALIDA
    // =========================================================

    always_comb begin

        letra_valida = 1'b0;

        if ((letra_recibida >= "A") &&
            (letra_recibida <= "Z")) begin

            letra_valida = 1'b1;

        end

    end


    // =========================================================
    // LETRA REPETIDA
    // =========================================================

    always_comb begin

        letra_repetida_calculada = 1'b0;

        if (letra_valida) begin

            letra_repetida_calculada =
                letras_usadas[
                    indice_letra(letra_recibida)
                ];

        end

    end


    // =========================================================
    // LETRA CORRECTA
    // =========================================================

    always_comb begin

        letra_correcta_calculada = 1'b0;

        if (letra_valida) begin

            if ((palabra_secreta[63:56] == letra_recibida) ||
                (palabra_secreta[55:48] == letra_recibida) ||
                (palabra_secreta[47:40] == letra_recibida) ||
                (palabra_secreta[39:32] == letra_recibida) ||
                (palabra_secreta[31:24] == letra_recibida) ||
                (palabra_secreta[23:16] == letra_recibida) ||
                (palabra_secreta[15:8]  == letra_recibida) ||
                (palabra_secreta[7:0]   == letra_recibida)) begin

                letra_correcta_calculada = 1'b1;

            end

        end

    end


    // =========================================================
    // ACTUALIZAR PALABRA
    // =========================================================

    always_comb begin

        palabra_nueva = palabra_estado;

        if (letra_correcta_calculada &&
            !letra_repetida_calculada) begin

            if (palabra_secreta[63:56] == letra_recibida)
                palabra_nueva[63:56] = letra_recibida;

            if (palabra_secreta[55:48] == letra_recibida)
                palabra_nueva[55:48] = letra_recibida;

            if (palabra_secreta[47:40] == letra_recibida)
                palabra_nueva[47:40] = letra_recibida;

            if (palabra_secreta[39:32] == letra_recibida)
                palabra_nueva[39:32] = letra_recibida;

            if (palabra_secreta[31:24] == letra_recibida)
                palabra_nueva[31:24] = letra_recibida;

            if (palabra_secreta[23:16] == letra_recibida)
                palabra_nueva[23:16] = letra_recibida;

            if (palabra_secreta[15:8] == letra_recibida)
                palabra_nueva[15:8] = letra_recibida;

            if (palabra_secreta[7:0] == letra_recibida)
                palabra_nueva[7:0] = letra_recibida;

        end

    end


    // =========================================================
    // DETERMINAR SI LA PALABRA ESTA COMPLETA
    // =========================================================

    always_comb begin

        palabra_completa = 1'b1;

        if (cantidad_letras == 0) begin

            palabra_completa = 1'b0;

        end

        else begin

            if (cantidad_letras >= 1)
                if (!((palabra_estado[63:56] >= "A") &&
                      (palabra_estado[63:56] <= "Z")))
                    palabra_completa = 1'b0;

            if (cantidad_letras >= 2)
                if (!((palabra_estado[55:48] >= "A") &&
                      (palabra_estado[55:48] <= "Z")))
                    palabra_completa = 1'b0;

            if (cantidad_letras >= 3)
                if (!((palabra_estado[47:40] >= "A") &&
                      (palabra_estado[47:40] <= "Z")))
                    palabra_completa = 1'b0;

            if (cantidad_letras >= 4)
                if (!((palabra_estado[39:32] >= "A") &&
                      (palabra_estado[39:32] <= "Z")))
                    palabra_completa = 1'b0;

            if (cantidad_letras >= 5)
                if (!((palabra_estado[31:24] >= "A") &&
                      (palabra_estado[31:24] <= "Z")))
                    palabra_completa = 1'b0;

            if (cantidad_letras >= 6)
                if (!((palabra_estado[23:16] >= "A") &&
                      (palabra_estado[23:16] <= "Z")))
                    palabra_completa = 1'b0;

            if (cantidad_letras >= 7)
                if (!((palabra_estado[15:8] >= "A") &&
                      (palabra_estado[15:8] <= "Z")))
                    palabra_completa = 1'b0;

            if (cantidad_letras >= 8)
                if (!((palabra_estado[7:0] >= "A") &&
                      (palabra_estado[7:0] <= "Z")))
                    palabra_completa = 1'b0;

        end

    end


    // =========================================================
    // REGISTROS
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            palabra_secreta <= 64'b0;

            palabra_estado <= 64'h2020202020202020;

            letras_usadas <= 26'b0;

            fallos <= 5'd0;

            letra_correcta <= 1'b0;
            letra_incorrecta <= 1'b0;
            letra_repetida <= 1'b0;

        end

        else begin

            // ---------------------------------------------
            // PULSOS
            // ---------------------------------------------

            letra_correcta <= 1'b0;
            letra_incorrecta <= 1'b0;
            letra_repetida <= 1'b0;


            // =================================================
            // INICIALIZAR PARTIDA
            // =================================================

            if (inicializar_partida) begin

                palabra_secreta <= palabra_actual;

                letras_usadas <= 26'b0;

                fallos <= 5'd0;


                case (cantidad_letras)

                    4'd1:
                        palabra_estado <=
                            64'h5F20202020202020;

                    4'd2:
                        palabra_estado <=
                            64'h5F5F202020202020;

                    4'd3:
                        palabra_estado <=
                            64'h5F5F5F2020202020;

                    4'd4:
                        palabra_estado <=
                            64'h5F5F5F5F20202020;

                    4'd5:
                        palabra_estado <=
                            64'h5F5F5F5F5F202020;

                    4'd6:
                        palabra_estado <=
                            64'h5F5F5F5F5F5F2020;

                    4'd7:
                        palabra_estado <=
                            64'h5F5F5F5F5F5F5F20;

                    4'd8:
                        palabra_estado <=
                            64'h5F5F5F5F5F5F5F5F;

                    default:
                        palabra_estado <=
                            64'h2020202020202020;

                endcase

            end


            // =================================================
            // PROCESAR LETRA
            // =================================================

            else if (procesar_letra) begin

                if (letra_valida) begin

                    // -----------------------------------------
                    // LETRA REPETIDA
                    // -----------------------------------------

                    if (letra_repetida_calculada) begin

                        letra_repetida <= 1'b1;

                    end


                    // -----------------------------------------
                    // LETRA NUEVA
                    // -----------------------------------------

                    else begin

                        // Marcar letra utilizada
                        letras_usadas[
                            indice_letra(letra_recibida)
                        ] <= 1'b1;


                        // -------------------------------------
                        // CORRECTA
                        // -------------------------------------

                        if (letra_correcta_calculada) begin

                            palabra_estado <= palabra_nueva;

                            letra_correcta <= 1'b1;

                        end


                        // -------------------------------------
                        // INCORRECTA
                        // -------------------------------------

                        else begin

                            if (fallos < 5'd6)
                                fallos <= fallos + 1'b1;

                            letra_incorrecta <= 1'b1;

                        end

                    end

                end

            end

        end

    end

endmodule