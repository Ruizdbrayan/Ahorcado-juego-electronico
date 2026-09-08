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

logic [4:0] indice;
logic       pantalla_valida;
logic       cambio_pantalla;

// ============================================================
// CONSTRUIR PANTALLA (COMBINACIONAL)
// ============================================================

always_comb begin

    // --------------------------------------------------------
    // TODA LA PANTALLA EN ESPACIOS POR DEFECTO
    // --------------------------------------------------------

    pantalla[0]  = " ";
    pantalla[1]  = " ";
    pantalla[2]  = " ";
    pantalla[3]  = " ";
    pantalla[4]  = " ";
    pantalla[5]  = " ";
    pantalla[6]  = " ";
    pantalla[7]  = " ";
    pantalla[8]  = " ";
    pantalla[9]  = " ";
    pantalla[10] = " ";
    pantalla[11] = " ";
    pantalla[12] = " ";
    pantalla[13] = " ";
    pantalla[14] = " ";
    pantalla[15] = " ";
    pantalla[16] = " ";
    pantalla[17] = " ";
    pantalla[18] = " ";
    pantalla[19] = " ";
    pantalla[20] = " ";
    pantalla[21] = " ";
    pantalla[22] = " ";
    pantalla[23] = " ";
    pantalla[24] = " ";
    pantalla[25] = " ";
    pantalla[26] = " ";
    pantalla[27] = " ";
    pantalla[28] = " ";
    pantalla[29] = " ";
    pantalla[30] = " ";
    pantalla[31] = " ";

    // ========================================================
    // SELECTOR
    // ========================================================

    if (estado_actual == SELECTOR) begin

        // ----------------------------------------------------
        // LINEA 1
        // ----------------------------------------------------

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

        // ----------------------------------------------------
        // LINEA 2
        // ----------------------------------------------------

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

        // ----------------------------------------------------
        // LINEA 1: RESULTADO
        // ----------------------------------------------------

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

        // ----------------------------------------------------
        // LINEA 2: PALABRA CORRECTA
        // ----------------------------------------------------

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

        if (pantalla[0]  != pantalla_latch[0]  ||
            pantalla[1]  != pantalla_latch[1]  ||
            pantalla[2]  != pantalla_latch[2]  ||
            pantalla[3]  != pantalla_latch[3]  ||
            pantalla[4]  != pantalla_latch[4]  ||
            pantalla[5]  != pantalla_latch[5]  ||
            pantalla[6]  != pantalla_latch[6]  ||
            pantalla[7]  != pantalla_latch[7]  ||
            pantalla[8]  != pantalla_latch[8]  ||
            pantalla[9]  != pantalla_latch[9]  ||
            pantalla[10] != pantalla_latch[10] ||
            pantalla[11] != pantalla_latch[11] ||
            pantalla[12] != pantalla_latch[12] ||
            pantalla[13] != pantalla_latch[13] ||
            pantalla[14] != pantalla_latch[14] ||
            pantalla[15] != pantalla_latch[15] ||
            pantalla[16] != pantalla_latch[16] ||
            pantalla[17] != pantalla_latch[17] ||
            pantalla[18] != pantalla_latch[18] ||
            pantalla[19] != pantalla_latch[19] ||
            pantalla[20] != pantalla_latch[20] ||
            pantalla[21] != pantalla_latch[21] ||
            pantalla[22] != pantalla_latch[22] ||
            pantalla[23] != pantalla_latch[23] ||
            pantalla[24] != pantalla_latch[24] ||
            pantalla[25] != pantalla_latch[25] ||
            pantalla[26] != pantalla_latch[26] ||
            pantalla[27] != pantalla_latch[27] ||
            pantalla[28] != pantalla_latch[28] ||
            pantalla[29] != pantalla_latch[29] ||
            pantalla[30] != pantalla_latch[30] ||
            pantalla[31] != pantalla_latch[31]) begin

            cambio_pantalla = 1'b1;

        end

    end

end

// ============================================================
// FSM DEL CONTROLADOR LCD
// ============================================================

always_ff @(posedge clk or posedge rst) begin

    if (rst) begin

        estado_control  <= INICIO;
        indice          <= 5'd0;
        pantalla_valida <= 1'b0;

        // ----------------------------------------------------
        // Inicializar latch en espacios
        // ----------------------------------------------------

        pantalla_latch[0]  <= " ";
        pantalla_latch[1]  <= " ";
        pantalla_latch[2]  <= " ";
        pantalla_latch[3]  <= " ";
        pantalla_latch[4]  <= " ";
        pantalla_latch[5]  <= " ";
        pantalla_latch[6]  <= " ";
        pantalla_latch[7]  <= " ";
        pantalla_latch[8]  <= " ";
        pantalla_latch[9]  <= " ";
        pantalla_latch[10] <= " ";
        pantalla_latch[11] <= " ";
        pantalla_latch[12] <= " ";
        pantalla_latch[13] <= " ";
        pantalla_latch[14] <= " ";
        pantalla_latch[15] <= " ";
        pantalla_latch[16] <= " ";
        pantalla_latch[17] <= " ";
        pantalla_latch[18] <= " ";
        pantalla_latch[19] <= " ";
        pantalla_latch[20] <= " ";
        pantalla_latch[21] <= " ";
        pantalla_latch[22] <= " ";
        pantalla_latch[23] <= " ";
        pantalla_latch[24] <= " ";
        pantalla_latch[25] <= " ";
        pantalla_latch[26] <= " ";
        pantalla_latch[27] <= " ";
        pantalla_latch[28] <= " ";
        pantalla_latch[29] <= " ";
        pantalla_latch[30] <= " ";
        pantalla_latch[31] <= " ";

    end else begin

        case (estado_control)

            // =================================================
            // INICIO
            // =================================================

            INICIO: begin

                estado_control <= ESPERAR_LCD;

            end

            // =================================================
            // ESPERAR LCD
            // =================================================

            ESPERAR_LCD: begin

                if (!rdata[0]) begin

                    if (cambio_pantalla) begin

                        // ------------------------------------------------
                        // Capturar manualmente los 32 caracteres
                        // ------------------------------------------------

                        pantalla_latch[0]  <= pantalla[0];
                        pantalla_latch[1]  <= pantalla[1];
                        pantalla_latch[2]  <= pantalla[2];
                        pantalla_latch[3]  <= pantalla[3];
                        pantalla_latch[4]  <= pantalla[4];
                        pantalla_latch[5]  <= pantalla[5];
                        pantalla_latch[6]  <= pantalla[6];
                        pantalla_latch[7]  <= pantalla[7];
                        pantalla_latch[8]  <= pantalla[8];
                        pantalla_latch[9]  <= pantalla[9];
                        pantalla_latch[10] <= pantalla[10];
                        pantalla_latch[11] <= pantalla[11];
                        pantalla_latch[12] <= pantalla[12];
                        pantalla_latch[13] <= pantalla[13];
                        pantalla_latch[14] <= pantalla[14];
                        pantalla_latch[15] <= pantalla[15];
                        pantalla_latch[16] <= pantalla[16];
                        pantalla_latch[17] <= pantalla[17];
                        pantalla_latch[18] <= pantalla[18];
                        pantalla_latch[19] <= pantalla[19];
                        pantalla_latch[20] <= pantalla[20];
                        pantalla_latch[21] <= pantalla[21];
                        pantalla_latch[22] <= pantalla[22];
                        pantalla_latch[23] <= pantalla[23];
                        pantalla_latch[24] <= pantalla[24];
                        pantalla_latch[25] <= pantalla[25];
                        pantalla_latch[26] <= pantalla[26];
                        pantalla_latch[27] <= pantalla[27];
                        pantalla_latch[28] <= pantalla[28];
                        pantalla_latch[29] <= pantalla[29];
                        pantalla_latch[30] <= pantalla[30];
                        pantalla_latch[31] <= pantalla[31];

                        indice         <= 5'd0;
                        estado_control <= LIMPIAR_PANTALLA;

                    end

                end

            end

            // =================================================
            // LIMPIAR PANTALLA
            // =================================================

            LIMPIAR_PANTALLA: begin

                estado_control <= ESPERAR_LIMPIEZA;

            end

            // =================================================
            // ESPERAR LIMPIEZA
            // =================================================

            ESPERAR_LIMPIEZA: begin

                if (!rdata[0]) begin

                    indice         <= 5'd0;
                    estado_control <= ESCRIBIR_LINEA1;

                end

            end

            // =================================================
            // ESCRIBIR LINEA 1
            // =================================================

            ESCRIBIR_LINEA1: begin

                estado_control <= ESPERAR_LINEA1;

            end

            // =================================================
            // ESPERAR LINEA 1
            // =================================================

            ESPERAR_LINEA1: begin

                if (!rdata[0]) begin

                    if (indice == 5'd15) begin

                        indice         <= 5'd16;
                        estado_control <= POSICIONAR_LINEA2;

                    end else begin

                        indice         <= indice + 1'b1;
                        estado_control <= ESCRIBIR_LINEA1;

                    end

                end

            end

            // =================================================
            // POSICIONAR LINEA 2
            // =================================================

            POSICIONAR_LINEA2: begin

                estado_control <= ESPERAR_LINEA2;

            end

            // =================================================
            // ESPERAR LINEA 2
            // =================================================

            ESPERAR_LINEA2: begin

                if (!rdata[0]) begin

                    indice         <= 5'd16;
                    estado_control <= ESCRIBIR_LINEA2;

                end

            end

            // =================================================
            // ESCRIBIR LINEA 2
            // =================================================

            ESCRIBIR_LINEA2: begin

                estado_control <= ESPERAR_FINAL;

            end

            // =================================================
            // ESPERAR FINAL
            // =================================================

            ESPERAR_FINAL: begin

                if (!rdata[0]) begin

                    if (indice == 5'd31) begin

                        pantalla_valida <= 1'b1;
                        estado_control  <= ESPERAR_LCD;

                    end else begin

                        indice         <= indice + 1'b1;
                        estado_control <= ESCRIBIR_LINEA2;

                    end

                end

            end

            // =================================================
            // DEFAULT
            // =================================================

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

        // ----------------------------------------------------
        // LIMPIAR PANTALLA
        // ----------------------------------------------------

        LIMPIAR_PANTALLA: begin

            wenable = 1'b1;
            addr    = LCD_COMANDO;
            wdata   = 32'h00000001;

        end

        // ----------------------------------------------------
        // ESCRIBIR LINEA 1
        // ----------------------------------------------------

        ESCRIBIR_LINEA1: begin

            wenable = 1'b1;
            addr    = LCD_DATOS;
            wdata   = {24'd0, pantalla_latch[indice]};

        end

        // ----------------------------------------------------
        // POSICIONAR LINEA 2
        // ----------------------------------------------------

        POSICIONAR_LINEA2: begin

            wenable = 1'b1;
            addr    = LCD_COMANDO;
            wdata   = 32'h000000C0;

        end

        // ----------------------------------------------------
        // ESCRIBIR LINEA 2
        // ----------------------------------------------------

        ESCRIBIR_LINEA2: begin

            wenable = 1'b1;
            addr    = LCD_DATOS;
            wdata   = {24'd0, pantalla_latch[indice]};

        end

        // ----------------------------------------------------
        // DEFAULT
        // ----------------------------------------------------

        default: begin

            wenable = 1'b0;
            addr    = LCD_DATOS;
            wdata   = 32'd0;

        end

    endcase

end

endmodule
