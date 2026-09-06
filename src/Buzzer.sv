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
        10_000_000;

    localparam integer DURACION_INCORRECTA =
        15_000_000;

    localparam integer DURACION_VICTORIA =
        25_000_000;

    localparam integer DURACION_DERROTA =
        35_000_000;

    // =========================================================
    // DIVISORES DE FRECUENCIA
    // =========================================================

    localparam integer DIV_1000 =
        FRECUENCIA_RELOJ / (2 * 1000);

    localparam integer DIV_1500 =
        FRECUENCIA_RELOJ / (2 * 1500);

    localparam integer DIV_400 =
        FRECUENCIA_RELOJ / (2 * 400);

    localparam integer DIV_300 =
        FRECUENCIA_RELOJ / (2 * 300);

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
    // MEMORIA DEL ESTADO ANTERIOR
    // =========================================================

    logic victoria_anterior;
    logic derrota_anterior;

    // =========================================================
    // DIVISOR
    // =========================================================

    always_comb begin

        case (estado_sonido)

            SONIDO_CORRECTO:
                divisor_frecuencia = DIV_1000;

            SONIDO_INCORRECTO:
                divisor_frecuencia = DIV_1500;

            SONIDO_VICTORIA1:
                divisor_frecuencia = DIV_400;

            SONIDO_VICTORIA2:
                divisor_frecuencia = DIV_300;

            SONIDO_DERROTA1:
                divisor_frecuencia = DIV_250;

            SONIDO_DERROTA2:
                divisor_frecuencia = DIV_300;

            default:
                divisor_frecuencia = 27'd0;

        endcase

    end

    // =========================================================
    // GENERACION DEL TONO
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            contador_frecuencia <= 27'd0;
            tono <= 1'b0;

        end else if (estado_sonido == IDLE) begin

            contador_frecuencia <= 27'd0;
            tono <= 1'b0;

        end else begin

            if (contador_frecuencia >=
                divisor_frecuencia - 1) begin

                contador_frecuencia <= 27'd0;

                tono <= ~tono;

            end else begin

                contador_frecuencia <=
                    contador_frecuencia + 1'b1;

            end

        end

    end

    // =========================================================
    // CONTROL DEL SONIDO
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            estado_sonido <= IDLE;

            contador_duracion <= 26'd0;

            victoria_anterior <= 1'b0;
            derrota_anterior <= 1'b0;

        end else begin

            // Guardar nivel anterior

            victoria_anterior <= victoria;
            derrota_anterior <= derrota;

            case (estado_sonido)

                // =================================================
                // IDLE
                // =================================================

                IDLE: begin

                    contador_duracion <= 26'd0;

                    // Detectar 0 -> 1

                    if (victoria &&
                        !victoria_anterior) begin

                        estado_sonido <=
                            SONIDO_VICTORIA1;

                    end else if (derrota &&
                               !derrota_anterior) begin

                        estado_sonido <=
                            SONIDO_DERROTA1;

                    end else if (letra_correcta) begin

                        estado_sonido <=
                            SONIDO_CORRECTO;

                    end else if (letra_incorrecta) begin

                        estado_sonido <=
                            SONIDO_INCORRECTO;

                    end

                end

                // =================================================
                // CORRECTA
                // =================================================

                SONIDO_CORRECTO: begin

                    if (contador_duracion >=
                        DURACION_CORRECTA - 1) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <= IDLE;

                    end else begin

                        contador_duracion <=
                            contador_duracion + 1'b1;

                    end

                end

                // =================================================
                // INCORRECTA
                // =================================================

                SONIDO_INCORRECTO: begin

                    if (contador_duracion >=
                        DURACION_INCORRECTA - 1) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <= IDLE;

                    end else begin

                        contador_duracion <=
                            contador_duracion + 1'b1;

                    end

                end

                // =================================================
                // VICTORIA 1
                // =================================================

                SONIDO_VICTORIA1: begin

                    if (contador_duracion >=
                        DURACION_VICTORIA - 1) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <=
                            SONIDO_VICTORIA2;

                    end else begin

                        contador_duracion <=
                            contador_duracion + 1'b1;

                    end

                end

                // =================================================
                // VICTORIA 2
                // =================================================

                SONIDO_VICTORIA2: begin

                    if (contador_duracion >=
                        DURACION_VICTORIA - 1) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <= IDLE;

                    end else begin

                        contador_duracion <=
                            contador_duracion + 1'b1;

                    end

                end

                // =================================================
                // DERROTA 1
                // =================================================

                SONIDO_DERROTA1: begin

                    if (contador_duracion >=
                        DURACION_DERROTA - 1) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <=
                            SONIDO_DERROTA2;

                    end else begin

                        contador_duracion <=
                            contador_duracion + 1'b1;

                    end

                end

                // =================================================
                // DERROTA 2
                // =================================================

                SONIDO_DERROTA2: begin

                    if (contador_duracion >=
                        DURACION_DERROTA - 1) begin

                        contador_duracion <= 26'd0;

                        estado_sonido <= IDLE;

                    end else begin

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