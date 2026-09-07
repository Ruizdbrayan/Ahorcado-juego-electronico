module Controlador_LCD (

    input logic        clk,
    input logic        rst,

    // ============================================================
    // INFORMACION DEL JUEGO
    // ============================================================

    input logic [1:0]  estado_actual,
    input logic        dificultad,

    input logic        victoria,
    input logic        derrota,

    input logic [4:0]  fallos,

    input logic [63:0] palabra_estado,
    input logic [63:0] palabra_actual,

    input logic [3:0]  cantidad_letras,

    // ============================================================
    // BUS HACIA PERIFERICO LCD
    // ============================================================

    output logic        wenable,
    output logic [1:0]  addr,
    output logic [31:0] wdata,

    input logic [31:0]  rdata

);

    // ============================================================
    // ESTADOS DEL JUEGO
    // ============================================================

    localparam logic [1:0]
        SELECTOR   = 2'b00,
        JUGANDO    = 2'b01,
        FINALIZADO = 2'b10;

    // ============================================================
    // DIRECCIONES DEL PERIFERICO LCD
    // ============================================================

    localparam logic [1:0]
        LCD_DATOS   = 2'b00,
        LCD_COMANDO = 2'b01;

    // ============================================================
    // ESTADOS DEL CONTROLADOR LCD
    // ============================================================

    localparam logic [3:0]
        INICIO            = 4'd0,
        ESPERAR_LCD       = 4'd1,
        LIMPIAR_PANTALLA  = 4'd2,
        ESPERAR_LIMPIEZA  = 4'd3,
        ESCRIBIR_LINEA1   = 4'd4,
        ESPERAR_LINEA1    = 4'd5,
        POSICIONAR_LINEA2 = 4'd6,
        ESPERAR_LINEA2    = 4'd7,
        ESCRIBIR_LINEA2   = 4'd8,
        ESPERAR_FINAL     = 4'd9;

    logic [3:0] estado_control;

    // ============================================================
    // BUFFER DE PANTALLA
    // ============================================================

    logic [7:0] pantalla       [0:31];
    logic [7:0] pantalla_latch [0:31];

    logic [5:0] indice;
    logic       pantalla_valida;
    logic       cambio_pantalla;

    integer i;

    // ============================================================
    // CONSTRUIR PANTALLA (COMBINACIONAL)
    // ============================================================

    always_comb begin

        // --------------------------------------------------------
        // TODA LA PANTALLA EN ESPACIOS POR DEFECTO
        // --------------------------------------------------------

        for (i = 0; i < 32; i = i + 1)
            pantalla[i] = " ";

        // ========================================================
        // SELECTOR
        // ========================================================

        if (estado_actual == SELECTOR) begin

            // LINEA 1
            pantalla[0] = "M";
            pantalla[1] = "O";
            pantalla[2] = "D";
            pantalla[3] = "O";
            pantalla[4] = ":";

            if (dificultad == 1'b0) begin
                pantalla[5]  = ">";
                pantalla[6]  = "F";
                pantalla[7]  = "A";
                pantalla[8]  = "C";
                pantalla[9]  = "I";
                pantalla[10] = "L";
            end else begin
                pantalla[5]  = " ";
                pantalla[6]  = "F";
                pantalla[7]  = "A";
                pantalla[8]  = "C";
                pantalla[9]  = "I";
                pantalla[10] = "L";
            end

            // LINEA 2
            if (dificultad == 1'b0) begin
                pantalla[20] = "D";
                pantalla[21] = "I";
                pantalla[22] = "F";
                pantalla[23] = "I";
                pantalla[24] = "C";
                pantalla[25] = "I";
                pantalla[26] = "L";
            end else begin
                pantalla[19] = ">";
                pantalla[20] = "D";
                pantalla[21] = "I";
                pantalla[22] = "F";
                pantalla[23] = "I";
                pantalla[24] = "C";
                pantalla[25] = "I";
                pantalla[26] = "L";
            end

        end

        // ========================================================
        // JUGANDO
        // ========================================================

        else if (estado_actual == JUGANDO) begin

            pantalla[0] = "P";
            pantalla[1] = "A";
            pantalla[2] = "L";
            pantalla[3] = ":";

            pantalla[5]  = palabra_estado[63:56];
            pantalla[6]  = palabra_estado[55:48];
            pantalla[7]  = palabra_estado[47:40];
            pantalla[8]  = palabra_estado[39:32];
            pantalla[9]  = palabra_estado[31:24];
            pantalla[10] = palabra_estado[23:16];
            pantalla[11] = palabra_estado[15:8];
            pantalla[12] = palabra_estado[7:0];

            pantalla[16] = "F";
            pantalla[17] = "A";
            pantalla[18] = "L";
            pantalla[19] = "L";
            pantalla[20] = "O";
            pantalla[21] = "S";
            pantalla[22] = ":";

            pantalla[24] = 8'h30 + {3'b000, fallos[3:0]};

        end

        // ========================================================
        // FINALIZADO
        // ========================================================

        else if (estado_actual == FINALIZADO) begin

            // LINEA 1: RESULTADO
            if (victoria) begin
                pantalla[0] = "G";
                pantalla[1] = "A";
                pantalla[2] = "N";
                pantalla[3] = "A";
                pantalla[4] = "S";
                pantalla[5] = "T";
                pantalla[6] = "E";
                pantalla[7] = "!";
            end else begin
                // Ante cualquier caso no victorioso (derrota por fallos, timeout, etc.)
                pantalla[0] = "P";
                pantalla[1] = "E";
                pantalla[2] = "R";
                pantalla[3] = "D";
                pantalla[4] = "I";
                pantalla[5] = "S";
                pantalla[6] = "T";
                pantalla[7] = "E";
                pantalla[8] = "!";
            end

            // LINEA 2: PALABRA CORRECTA
            pantalla[16] = "P";
            pantalla[17] = "A";
            pantalla[18] = "L";
            pantalla[19] = ":";

            pantalla[21] = palabra_actual[63:56];
            pantalla[22] = palabra_actual[55:48];
            pantalla[23] = palabra_actual[47:40];
            pantalla[24] = palabra_actual[39:32];
            pantalla[25] = palabra_actual[31:24];
            pantalla[26] = palabra_actual[23:16];
            pantalla[27] = palabra_actual[15:8];
            pantalla[28] = palabra_actual[7:0];

        end

    end

    // ============================================================
    // DETECTAR CAMBIOS EN LA PANTALLA
    // ============================================================

    always_comb begin
        cambio_pantalla = 1'b0;

        if (!pantalla_valida) begin
            cambio_pantalla = 1'b1;
        end else begin
            for (int k = 0; k < 32; k++) begin
                if (pantalla[k] != pantalla_latch[k]) begin
                    cambio_pantalla = 1'b1;
                end
            end
        end
    end

    // ============================================================
    // FSM DEL CONTROLADOR LCD
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            estado_control  <= INICIO;
            indice          <= 6'd0;
            pantalla_valida <= 1'b0;

            for (i = 0; i < 32; i = i + 1)
                pantalla_latch[i] <= " ";

        end else begin

            case (estado_control)

                INICIO: begin
                    estado_control <= ESPERAR_LCD;
                end

                ESPERAR_LCD: begin
                    if (!rdata[0]) begin
                        if (cambio_pantalla) begin
                            // Capturar el nuevo buffer a mostrar
                            for (i = 0; i < 32; i = i + 1)
                                pantalla_latch[i] <= pantalla[i];

                            indice         <= 6'd0;
                            estado_control <= LIMPIAR_PANTALLA;
                        end
                    end
                end

                LIMPIAR_PANTALLA: begin
                    estado_control <= ESPERAR_LIMPIEZA;
                end

                ESPERAR_LIMPIEZA: begin
                    if (!rdata[0]) begin
                        indice         <= 6'd0;
                        estado_control <= ESCRIBIR_LINEA1;
                    end
                end

                ESCRIBIR_LINEA1: begin
                    estado_control <= ESPERAR_LINEA1;
                end

                ESPERAR_LINEA1: begin
                    if (!rdata[0]) begin
                        if (indice == 6'd15) begin
                            indice         <= 6'd16;
                            estado_control <= POSICIONAR_LINEA2;
                        end else begin
                            indice         <= indice + 1'b1;
                            estado_control <= ESCRIBIR_LINEA1;
                        end
                    end
                end

                POSICIONAR_LINEA2: begin
                    estado_control <= ESPERAR_LINEA2;
                end

                ESPERAR_LINEA2: begin
                    if (!rdata[0]) begin
                        indice         <= 6'd16;
                        estado_control <= ESCRIBIR_LINEA2;
                    end
                end

                ESCRIBIR_LINEA2: begin
                    estado_control <= ESPERAR_FINAL;
                end

                ESPERAR_FINAL: begin
                    if (!rdata[0]) begin
                        if (indice == 6'd31) begin
                            pantalla_valida <= 1'b1;
                            estado_control  <= ESPERAR_LCD;
                        end else begin
                            indice         <= indice + 1'b1;
                            estado_control <= ESCRIBIR_LINEA2;
                        end
                    end
                end

                default: begin
                    estado_control <= INICIO;
                end

            endcase

        end

    end

    // ============================================================
    // BUS HACIA EL PERIFERICO LCD
    // ============================================================

    always_comb begin

        wenable = 1'b0;
        addr    = LCD_DATOS;
        wdata   = 32'd0;

        case (estado_control)

            LIMPIAR_PANTALLA: begin
                wenable = 1'b1;
                addr    = LCD_COMANDO;
                wdata   = 32'h00000001;
            end

            ESCRIBIR_LINEA1: begin
                wenable = 1'b1;
                addr    = LCD_DATOS;
                wdata   = {24'd0, pantalla_latch[indice]};
            end

            POSICIONAR_LINEA2: begin
                wenable = 1'b1;
                addr    = LCD_COMANDO;
                wdata   = 32'h000000C0;
            end

            ESCRIBIR_LINEA2: begin
                wenable = 1'b1;
                addr    = LCD_DATOS;
                wdata   = {24'd0, pantalla_latch[indice]};
            end

            default: begin
                wenable = 1'b0;
                addr    = LCD_DATOS;
                wdata   = 32'd0;
            end

        endcase

    end

endmodule