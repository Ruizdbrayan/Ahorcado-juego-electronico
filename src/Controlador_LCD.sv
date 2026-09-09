module Controlador_LCD (

    input  logic        clk,
    input  logic        rst,

    input  logic [1:0]  estado_actual,
    input  logic        dificultad,

    input  logic        victoria,
    input  logic        derrota,

    input  logic [4:0]  fallos,

    input  logic [63:0] palabra_estado,
    input  logic [63:0] palabra_actual,

    input  logic [3:0]  cantidad_letras,

    output logic [8:0]  direccion_memoria,
    input  logic [7:0]  dato_memoria,

    output logic        wenable,
    output logic [1:0]  addr,
    output logic [31:0] wdata,

    input  logic [31:0] rdata

);

    // =========================================================
    // ESTADOS DEL JUEGO
    // =========================================================

    localparam logic [1:0]
        SELECTOR   = 2'b00,
        JUGANDO    = 2'b01,
        FINALIZADO = 2'b10;


    // =========================================================
    // DIRECCIONES DEL LCD
    // =========================================================

    localparam logic [1:0]
        LCD_DATOS   = 2'b00,
        LCD_COMANDO = 2'b01;


    // =========================================================
    // ESTADOS DEL CONTROLADOR
    // =========================================================

    localparam logic [3:0]
        INICIO            = 4'd0,
        ESPERAR_LCD       = 4'd1,
        LIMPIAR           = 4'd2,
        ESPERAR_LIMPIAR   = 4'd3,
        ESCRIBIR_LINEA1   = 4'd4,
        ESPERAR_LINEA1    = 4'd5,
        POSICIONAR_LINEA2 = 4'd6,
        ESPERAR_LINEA2    = 4'd7,
        ESCRIBIR_LINEA2   = 4'd8,
        ESPERAR_FINAL     = 4'd9;

    logic [3:0] estado_control;

    logic [4:0] indice;


    // =========================================================
    // CONTROL DE PANTALLA
    // =========================================================

    logic pantalla_valida;
    logic cambio_pantalla;


    // =========================================================
    // VALORES ANTERIORES
    // =========================================================

    logic [1:0] estado_anterior;
    logic dificultad_anterior;

    logic victoria_anterior;
    logic derrota_anterior;

    logic [63:0] palabra_estado_anterior;
    logic [63:0] palabra_actual_anterior;

    logic [4:0] fallos_anterior;


    // =========================================================
    // CARACTER
    // =========================================================

    logic [7:0] caracter_actual;


    // =========================================================
    // DIRECCION DE MEMORIA
    // =========================================================

    always_comb begin

        case (estado_actual)

            SELECTOR:
                direccion_memoria = 9'd0;

            JUGANDO:
                direccion_memoria = 9'd64;

            FINALIZADO: begin

                if (victoria)
                    direccion_memoria = 9'd96;

                else
                    direccion_memoria = 9'd128;

            end

            default:
                direccion_memoria = 9'd0;

        endcase

        direccion_memoria =
            direccion_memoria + {4'd0, indice};

    end


    // =========================================================
    // CARACTER DEL LCD
    // =========================================================

    always_comb begin

        caracter_actual = dato_memoria;


        // -----------------------------------------------------
        // SELECTOR
        // -----------------------------------------------------

        if (estado_actual == SELECTOR) begin

            if (!dificultad && indice == 5'd6)

                caracter_actual = ">";

            else if (dificultad && indice == 5'd22)

                caracter_actual = ">";

        end


        // -----------------------------------------------------
        // PALABRA EN JUEGO
        // -----------------------------------------------------

        else if (estado_actual == JUGANDO) begin

            case (indice)

                5'd5:
                    caracter_actual = palabra_estado[63:56];

                5'd6:
                    caracter_actual = palabra_estado[55:48];

                5'd7:
                    caracter_actual = palabra_estado[47:40];

                5'd8:
                    caracter_actual = palabra_estado[39:32];

                5'd9:
                    caracter_actual = palabra_estado[31:24];

                5'd10:
                    caracter_actual = palabra_estado[23:16];

                5'd11:
                    caracter_actual = palabra_estado[15:8];

                5'd12:
                    caracter_actual = palabra_estado[7:0];

                5'd24:
                    caracter_actual =
                        8'h30 + {3'b000, fallos[3:0]};

                default:
                    caracter_actual = dato_memoria;

            endcase

        end


        // -----------------------------------------------------
        // PALABRA FINAL
        // -----------------------------------------------------

        else if (estado_actual == FINALIZADO) begin

            case (indice)

                5'd21:
                    caracter_actual = palabra_actual[63:56];

                5'd22:
                    caracter_actual = palabra_actual[55:48];

                5'd23:
                    caracter_actual = palabra_actual[47:40];

                5'd24:
                    caracter_actual = palabra_actual[39:32];

                5'd25:
                    caracter_actual = palabra_actual[31:24];

                5'd26:
                    caracter_actual = palabra_actual[23:16];

                5'd27:
                    caracter_actual = palabra_actual[15:8];

                5'd28:
                    caracter_actual = palabra_actual[7:0];

                default:
                    caracter_actual = dato_memoria;

            endcase

        end

    end


    // =========================================================
    // DETECTAR CAMBIOS
    // =========================================================

    always_comb begin

        cambio_pantalla = 1'b0;

        if (!pantalla_valida)

            cambio_pantalla = 1'b1;

        else if (estado_actual != estado_anterior)

            cambio_pantalla = 1'b1;

        else if (dificultad != dificultad_anterior)

            cambio_pantalla = 1'b1;

        else if (victoria != victoria_anterior)

            cambio_pantalla = 1'b1;

        else if (derrota != derrota_anterior)

            cambio_pantalla = 1'b1;

        else if (fallos != fallos_anterior)

            cambio_pantalla = 1'b1;

        else if (palabra_estado != palabra_estado_anterior)

            cambio_pantalla = 1'b1;

        else if (palabra_actual != palabra_actual_anterior)

            cambio_pantalla = 1'b1;

    end


    // =========================================================
    // FSM LCD
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            estado_control <= INICIO;
            indice <= 5'd0;

            pantalla_valida <= 1'b0;

            estado_anterior <= SELECTOR;
            dificultad_anterior <= 1'b0;

            victoria_anterior <= 1'b0;
            derrota_anterior <= 1'b0;

            palabra_estado_anterior <= 64'd0;
            palabra_actual_anterior <= 64'd0;

            fallos_anterior <= 5'd0;

        end

        else begin

            case (estado_control)

                // -------------------------------------------------
                // INICIO
                // -------------------------------------------------

                INICIO:
                    estado_control <= ESPERAR_LCD;


                // -------------------------------------------------
                // ESPERAR CAMBIO
                // -------------------------------------------------

                ESPERAR_LCD: begin

                    if (!rdata[0] && cambio_pantalla) begin

                        estado_anterior <= estado_actual;
                        dificultad_anterior <= dificultad;

                        victoria_anterior <= victoria;
                        derrota_anterior <= derrota;

                        palabra_estado_anterior <=
                            palabra_estado;

                        palabra_actual_anterior <=
                            palabra_actual;

                        fallos_anterior <= fallos;

                        pantalla_valida <= 1'b0;

                        indice <= 5'd0;

                        estado_control <= LIMPIAR;

                    end

                end


                // -------------------------------------------------
                // LIMPIAR
                // -------------------------------------------------

                LIMPIAR:
                    estado_control <= ESPERAR_LIMPIAR;


                // -------------------------------------------------
                // ESPERAR LIMPIEZA
                // -------------------------------------------------

                ESPERAR_LIMPIAR: begin

                    if (!rdata[0]) begin

                        indice <= 5'd0;

                        estado_control <=
                            ESCRIBIR_LINEA1;

                    end

                end


                // -------------------------------------------------
                // LINEA 1
                // -------------------------------------------------

                ESCRIBIR_LINEA1:
                    estado_control <= ESPERAR_LINEA1;


                ESPERAR_LINEA1: begin

                    if (!rdata[0]) begin

                        if (indice == 5'd15) begin

                            indice <= 5'd16;

                            estado_control <=
                                POSICIONAR_LINEA2;

                        end

                        else begin

                            indice <= indice + 1'b1;

                            estado_control <=
                                ESCRIBIR_LINEA1;

                        end

                    end

                end


                // -------------------------------------------------
                // POSICIONAR LINEA 2
                // -------------------------------------------------

                POSICIONAR_LINEA2:
                    estado_control <= ESPERAR_LINEA2;


                ESPERAR_LINEA2: begin

                    if (!rdata[0]) begin

                        indice <= 5'd16;

                        estado_control <=
                            ESCRIBIR_LINEA2;

                    end

                end


                // -------------------------------------------------
                // LINEA 2
                // -------------------------------------------------

                ESCRIBIR_LINEA2:
                    estado_control <= ESPERAR_FINAL;


                ESPERAR_FINAL: begin

                    if (!rdata[0]) begin

                        if (indice == 5'd31) begin

                            pantalla_valida <= 1'b1;

                            estado_control <=
                                ESPERAR_LCD;

                        end

                        else begin

                            indice <= indice + 1'b1;

                            estado_control <=
                                ESCRIBIR_LINEA2;

                        end

                    end

                end


                default:
                    estado_control <= INICIO;

            endcase

        end

    end


    // =========================================================
    // BUS LCD
    // =========================================================

    always_comb begin

        wenable = 1'b0;
        addr = LCD_DATOS;
        wdata = 32'd0;

        case (estado_control)

            // -------------------------------------------------
            // LIMPIAR LCD
            // -------------------------------------------------

            LIMPIAR: begin

                wenable = 1'b1;
                addr = LCD_COMANDO;
                wdata = 32'h00000001;

            end


            // -------------------------------------------------
            // ESCRIBIR DATOS
            // -------------------------------------------------

            ESCRIBIR_LINEA1,
            ESCRIBIR_LINEA2: begin

                wenable = 1'b1;
                addr = LCD_DATOS;
                wdata = {24'd0, caracter_actual};

            end


            // -------------------------------------------------
            // SEGUNDA LINEA
            // -------------------------------------------------

            POSICIONAR_LINEA2: begin

                wenable = 1'b1;
                addr = LCD_COMANDO;
                wdata = 32'h000000C0;

            end


            default: begin

                wenable = 1'b0;

            end

        endcase

    end

endmodule