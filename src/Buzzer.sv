module Buzzer #(
    parameter integer FRECUENCIA_RELOJ = 100_000_000
)(
    input logic clk,
    input logic rst,

    input logic letra_correcta,
    input logic letra_incorrecta,

    input logic victoria,
    input logic derrota,

    output logic buzzer

);


// =========================================================
// DURACIONES
// =========================================================

localparam integer DURACION_CORRECTA =
    10_000_000;       // 100 ms

localparam integer DURACION_INCORRECTA =
    15_000_000;       // 150 ms

localparam integer DURACION_VICTORIA =
    25_000_000;       // 250 ms

localparam integer DURACION_DERROTA =
    30_000_000;       // 300 ms


// =========================================================
// DIVISORES
// =========================================================

localparam integer DIV_2048 =
    FRECUENCIA_RELOJ / (2 * 2048);

localparam integer DIV_1500 =
    FRECUENCIA_RELOJ / (2 * 1500);

localparam integer DIV_800 =
    FRECUENCIA_RELOJ / (2 * 800);

localparam integer DIV_1200 =
    FRECUENCIA_RELOJ / (2 * 1200);

localparam integer DIV_500 =
    FRECUENCIA_RELOJ / (2 * 500);

localparam integer DIV_250 =
    FRECUENCIA_RELOJ / (2 * 250);


// =========================================================
// ESTADOS
// =========================================================

localparam logic [2:0]

    IDLE              = 3'd0,
    SONIDO_CORRECTO   = 3'd1,
    SONIDO_INCORRECTO = 3'd2,
    SONIDO_VICTORIA1  = 3'd3,
    SONIDO_VICTORIA2  = 3'd4,
    SONIDO_DERROTA1   = 3'd5,
    SONIDO_DERROTA2   = 3'd6;


logic [2:0] estado_sonido;


// =========================================================
// CONTADORES
// =========================================================

logic [25:0] contador_duracion;

logic [26:0] contador_frecuencia;

logic [26:0] divisor_frecuencia;

logic tono;


// =========================================================
// ESTADOS ANTERIORES
// =========================================================

logic victoria_anterior;
logic derrota_anterior;


// =========================================================
// DIVISOR DE FRECUENCIA
// =========================================================

always_comb begin

    case (estado_sonido)

        SONIDO_CORRECTO:
            divisor_frecuencia = DIV_2048;

        SONIDO_INCORRECTO:
            divisor_frecuencia = DIV_1500;

        SONIDO_VICTORIA1:
            divisor_frecuencia = DIV_800;

        SONIDO_VICTORIA2:
            divisor_frecuencia = DIV_1200;

        SONIDO_DERROTA1:
            divisor_frecuencia = DIV_500;

        SONIDO_DERROTA2:
            divisor_frecuencia = DIV_250;

        default:
            divisor_frecuencia = 27'd0;

    endcase

end


// =========================================================
// GENERADOR DE TONO
// =========================================================

always_ff @(posedge clk or posedge rst) begin

    if (rst) begin

        contador_frecuencia <= 27'd0;
        tono <= 1'b0;

    end

    else if (estado_sonido == IDLE) begin

        contador_frecuencia <= 27'd0;
        tono <= 1'b0;

    end

    else begin

        if (
            contador_frecuencia >=
            divisor_frecuencia - 1
        ) begin

            contador_frecuencia <= 27'd0;

            tono <= ~tono;

        end

        else begin

            contador_frecuencia <=
                contador_frecuencia + 1'b1;

        end

    end

end


// =========================================================
// CONTROL DEL BUZZER
// =========================================================

always_ff @(posedge clk or posedge rst) begin

    if (rst) begin

        estado_sonido <= IDLE;

        contador_duracion <= 26'd0;

        victoria_anterior <= 1'b0;
        derrota_anterior <= 1'b0;

    end

    else begin

        // =====================================================
        // PRIORIDAD ABSOLUTA:
        // EVENTOS FINALES
        // =====================================================
        //
        // Se comprueban ANTES del case.
        //
        // Así victoria/derrota no se pierden aunque el buzzer
        // esté reproduciendo un sonido normal.
        // =====================================================

        if (
            victoria &&
            !victoria_anterior
        ) begin

            estado_sonido <= SONIDO_VICTORIA1;

            contador_duracion <= 26'd0;

        end

        else if (
            derrota &&
            !derrota_anterior
        ) begin

            estado_sonido <= SONIDO_DERROTA1;

            contador_duracion <= 26'd0;

        end

        else begin

            case (estado_sonido)


                // =================================================
                // IDLE
                // =================================================

                IDLE: begin

                    contador_duracion <= 26'd0;


                    if (letra_correcta) begin

                        estado_sonido <=
                            SONIDO_CORRECTO;

                    end

                    else if (letra_incorrecta) begin

                        estado_sonido <=
                            SONIDO_INCORRECTO;

                    end

                end


                // =================================================
                // CORRECTO
                // =================================================

                SONIDO_CORRECTO: begin

                    if (
                        contador_duracion >=
                        DURACION_CORRECTA - 1
                    ) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <= IDLE;

                    end

                    else begin

                        contador_duracion <=
                            contador_duracion + 1'b1;

                    end

                end


                // =================================================
                // INCORRECTO
                // =================================================

                SONIDO_INCORRECTO: begin

                    if (
                        contador_duracion >=
                        DURACION_INCORRECTA - 1
                    ) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <= IDLE;

                    end

                    else begin

                        contador_duracion <=
                            contador_duracion + 1'b1;

                    end

                end


                // =================================================
                // VICTORIA 1
                // =================================================

                SONIDO_VICTORIA1: begin

                    if (
                        contador_duracion >=
                        DURACION_VICTORIA - 1
                    ) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <=
                            SONIDO_VICTORIA2;

                    end

                    else begin

                        contador_duracion <=
                            contador_duracion + 1'b1;

                    end

                end


                // =================================================
                // VICTORIA 2
                // =================================================

                SONIDO_VICTORIA2: begin

                    if (
                        contador_duracion >=
                        DURACION_VICTORIA - 1
                    ) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <= IDLE;

                    end

                    else begin

                        contador_duracion <=
                            contador_duracion + 1'b1;

                    end

                end


                // =================================================
                // DERROTA 1
                // =================================================

                SONIDO_DERROTA1: begin

                    if (
                        contador_duracion >=
                        DURACION_DERROTA - 1
                    ) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <=
                            SONIDO_DERROTA2;

                    end

                    else begin

                        contador_duracion <=
                            contador_duracion + 1'b1;

                    end

                end


                // =================================================
                // DERROTA 2
                // =================================================

                SONIDO_DERROTA2: begin

                    if (
                        contador_duracion >=
                        DURACION_DERROTA - 1
                    ) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <= IDLE;

                    end

                    else begin

                        contador_duracion <=
                            contador_duracion + 1'b1;

                    end

                end


                default: begin

                    estado_sonido <= IDLE;

                    contador_duracion <= 26'd0;

                end

            endcase

        end


        // =====================================================
        // ACTUALIZAR FLANCOS
        // =====================================================

        victoria_anterior <= victoria;
        derrota_anterior <= derrota;

    end

end


// =========================================================
// SALIDA
// =========================================================

always_comb begin

    if (estado_sonido == IDLE)
        buzzer = 1'b0;

    else
        buzzer = tono;

end

endmodule