module FSM (

    input logic clk,
    input logic rst,

    input logic partida_iniciada,
    input logic letra_disponible,
    input logic palabra_completa,
    input logic [4:0] fallos,
    input logic tiempo_agotado,

    output logic inicializar_partida,
    output logic procesar_letra,
    output logic consumir_letra,

    output logic enviar_inicio,
    output logic enviar_resultado,
    output logic enviar_final,

    output logic [1:0] estado_actual,

    output logic victoria,
    output logic derrota,

    output logic mostrar_guiones,

    output logic [63:0] palabra_lcd
);

    // =========================================================
    // ESTADOS
    // =========================================================

    typedef enum logic [2:0] {

        SELECTOR            = 3'd0,
        INICIALIZAR         = 3'd1,
        ESPERAR_LETRA       = 3'd2,
        PROCESAR_LETRA      = 3'd3,
        COMPROBAR_RESULTADO = 3'd4,
        FINALIZADO          = 3'd5

    } estado_t;

    estado_t estado;
    estado_t siguiente_estado;


    // =========================================================
    // RESULTADO FINAL
    // =========================================================

    logic resultado_victoria;


    // =========================================================
    // CONTADOR FINAL
    // =========================================================

    localparam integer DURACION_FINAL = 200_000_000;

    logic [31:0] contador_final;


    // =========================================================
    // REGISTROS
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            estado             <= SELECTOR;
            resultado_victoria <= 1'b0;
            contador_final     <= 32'd0;

        end

        else begin

            estado <= siguiente_estado;


            // -------------------------------------------------
            // RESULTADO DE LA PARTIDA
            // -------------------------------------------------

            if (estado == COMPROBAR_RESULTADO) begin

                if (palabra_completa) begin

                    resultado_victoria <= 1'b1;

                end

                else if (fallos >= 6) begin

                    resultado_victoria <= 1'b0;

                end

            end


            // -------------------------------------------------
            // TIMEOUT
            // -------------------------------------------------

            if ((estado == ESPERAR_LETRA) &&
                tiempo_agotado) begin

                resultado_victoria <= 1'b0;

            end


            // -------------------------------------------------
            // CONTADOR FINAL
            // -------------------------------------------------

            if (estado != FINALIZADO) begin

                contador_final <= 32'd0;

            end

            else if (contador_final < DURACION_FINAL) begin

                contador_final <= contador_final + 1'b1;

            end

        end

    end


    // =========================================================
    // SIGUIENTE ESTADO
    // =========================================================

    always_comb begin

        siguiente_estado = estado;

        case (estado)

            // =================================================
            // SELECTOR
            // =================================================

            SELECTOR: begin

                if (partida_iniciada)

                    siguiente_estado = INICIALIZAR;

            end


            // =================================================
            // INICIALIZAR
            // =================================================

            INICIALIZAR: begin

                siguiente_estado = ESPERAR_LETRA;

            end


            // =================================================
            // ESPERAR LETRA
            // =================================================

            ESPERAR_LETRA: begin

                if (tiempo_agotado) begin

                    siguiente_estado = FINALIZADO;

                end

                else if (letra_disponible) begin

                    siguiente_estado = PROCESAR_LETRA;

                end

            end


            // =================================================
            // PROCESAR LETRA
            // =================================================

            PROCESAR_LETRA: begin

                siguiente_estado = COMPROBAR_RESULTADO;

            end


            // =================================================
            // COMPROBAR RESULTADO
            // =================================================

            COMPROBAR_RESULTADO: begin

                if (palabra_completa) begin

                    siguiente_estado = FINALIZADO;

                end

                else if (fallos >= 6) begin

                    siguiente_estado = FINALIZADO;

                end

                else begin

                    siguiente_estado = ESPERAR_LETRA;

                end

            end


            // =================================================
            // FINALIZADO
            // =================================================

            FINALIZADO: begin

                if (contador_final >= DURACION_FINAL - 1)

                    siguiente_estado = SELECTOR;

            end


            default: begin

                siguiente_estado = SELECTOR;

            end

        endcase

    end


    // =========================================================
    // SALIDAS
    // =========================================================

    always_comb begin

        inicializar_partida = 1'b0;
        procesar_letra      = 1'b0;
        consumir_letra      = 1'b0;

        enviar_inicio       = 1'b0;
        enviar_resultado    = 1'b0;
        enviar_final        = 1'b0;

        victoria            = 1'b0;
        derrota             = 1'b0;

        mostrar_guiones     = 1'b0;

        palabra_lcd         = 64'd0;


        case (estado)

            // =================================================
            // INICIALIZAR
            // =================================================

            INICIALIZAR: begin

                inicializar_partida = 1'b1;

                enviar_inicio = 1'b1;

            end


            // =================================================
            // PROCESAR LETRA
            // =================================================

            PROCESAR_LETRA: begin

                procesar_letra = 1'b1;

                consumir_letra = 1'b1;

            end


            // =================================================
            // COMPROBAR RESULTADO
            // =================================================

            COMPROBAR_RESULTADO: begin

                if (!palabra_completa &&
                    fallos < 6 &&
                    !tiempo_agotado) begin

                    enviar_resultado = 1'b1;

                end

            end


            // =================================================
            // FINALIZADO
            // =================================================

            FINALIZADO: begin

                mostrar_guiones = 1'b1;

                if (resultado_victoria) begin

                    victoria = 1'b1;
                    derrota  = 1'b0;

                end

                else begin

                    victoria = 1'b0;
                    derrota  = 1'b1;

                end


                // ---------------------------------------------
                // SOLO UN PULSO
                // ---------------------------------------------

                if (contador_final == 0)

                    enviar_final = 1'b1;

            end

        endcase

    end


    // =========================================================
    // ESTADO PARA EL RESTO DEL SISTEMA
    // =========================================================

    always_comb begin

        case (estado)

            SELECTOR:

                estado_actual = 2'b00;


            INICIALIZAR,
            ESPERAR_LETRA,
            PROCESAR_LETRA,
            COMPROBAR_RESULTADO:

                estado_actual = 2'b01;


            FINALIZADO:

                estado_actual = 2'b10;


            default:

                estado_actual = 2'b00;

        endcase

    end

endmodule