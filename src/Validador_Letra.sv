module Validador_Letra (

    input logic        clk,
    input logic        rst,

    input logic        partida_iniciada,
    input logic        partida_activa,

    input logic [63:0] palabra_actual,
    input logic [3:0]  cantidad_letras,

    input logic        dificultad,

    input logic        victoria,
    input logic        derrota,
    input logic        tiempo_agotado,

    input logic [31:0] rdata,

    input logic        rx_fisico,
    output logic       tx_fisico,

    output logic       write_enable,
    output logic [1:0] addr,
    output logic [31:0] wdata,

    output logic [63:0] palabra_estado,
    output logic [4:0]  fallos
);

    // =========================================================
    // PARAMETROS UART
    // =========================================================

    localparam integer FRECUENCIA_RELOJ = 100_000_000;
    localparam integer BAUDRATE = 115_200;

    localparam integer CICLOS_BAUD =
        FRECUENCIA_RELOJ / BAUDRATE;

    localparam integer MEDIO_BAUD =
        CICLOS_BAUD / 2;


    // =========================================================
    // ESTADOS
    // =========================================================

    localparam logic [4:0] ESPERA             = 5'd0;
    localparam logic [4:0] INICIALIZAR        = 5'd1;
    localparam logic [4:0] LEER_CONTROL       = 5'd2;
    localparam logic [4:0] LEER_DATO          = 5'd3;
    localparam logic [4:0] VALIDAR            = 5'd4;
    localparam logic [4:0] ACTUALIZAR         = 5'd5;
    localparam logic [4:0] LIMPIAR_RX         = 5'd6;
    localparam logic [4:0] PREPARAR_INICIO    = 5'd7;
    localparam logic [4:0] PREPARAR_RESULTADO  = 5'd8;
    localparam logic [4:0] PREPARAR_FINAL     = 5'd9;
    localparam logic [4:0] ENVIAR_BYTE        = 5'd10;
    localparam logic [4:0] ESPERAR_TX         = 5'd11;
    localparam logic [4:0] RECEPCION_SERIAL   = 5'd12;


    logic [4:0] estado_actual;


    // =========================================================
    // PALABRA
    // =========================================================

    logic [63:0] palabra_oculta;
    logic [63:0] palabra_nueva;

    logic [7:0] letra_recibida;

    logic letra_valida;
    logic letra_repetida;
    logic letra_correcta;

    logic [25:0] letras_usadas;


    // =========================================================
    // MENSAJE UART
    // =========================================================

    logic [7:0] mensaje [0:255];

    logic [7:0] indice_mensaje;
    logic [8:0] longitud_mensaje;


    // =========================================================
    // RECEPCION FISICA
    // =========================================================

    logic [15:0] contador_baud_rx;
    logic [3:0]  bit_serial_rx;


    integer i;


    // =========================================================
    // FUNCIONES
    // =========================================================

    function automatic [7:0] ascii_numero(
        input logic [3:0] numero
    );

        begin
            ascii_numero = "0" + numero;
        end

    endfunction


    function automatic [4:0] indice_letra(
        input logic [7:0] letra
    );

        begin
            indice_letra = letra - "A";
        end

    endfunction


    // =========================================================
    // LETRA VALIDA
    // =========================================================

    always_comb begin

        letra_valida = 1'b0;

        if ((letra_recibida >= "A") &&
            (letra_recibida <= "Z"))

            letra_valida = 1'b1;

    end


    // =========================================================
    // CONTADOR DE RECEPCION SERIAL
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            contador_baud_rx <= 16'd0;
            bit_serial_rx <= 4'd0;

        end

        else begin

            if (estado_actual == RECEPCION_SERIAL) begin

                if (contador_baud_rx == CICLOS_BAUD - 1) begin

                    contador_baud_rx <= 16'd0;

                    if (bit_serial_rx == 4'd9)
                        bit_serial_rx <= 4'd0;

                    else
                        bit_serial_rx <=
                            bit_serial_rx + 1'b1;

                end

                else begin

                    contador_baud_rx <=
                        contador_baud_rx + 1'b1;

                end

            end

            else begin

                contador_baud_rx <= 16'd0;
                bit_serial_rx <= 4'd0;

            end

        end

    end


    // =========================================================
    // FSM PRINCIPAL DEL VALIDADOR
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            estado_actual <= ESPERA;

            palabra_oculta <= 64'b0;
            palabra_nueva <= 64'b0;
            palabra_estado <= 64'b0;

            letras_usadas <= 26'b0;

            fallos <= 5'd0;

            letra_recibida <= 8'h00;

            letra_repetida <= 1'b0;
            letra_correcta <= 1'b0;

            indice_mensaje <= 8'd0;
            longitud_mensaje <= 9'd0;

            for (i = 0; i < 256; i = i + 1)
                mensaje[i] <= 8'h00;

        end

        else begin

            case (estado_actual)

                // =================================================
                // ESPERA
                // =================================================

                ESPERA: begin

                    if (partida_iniciada) begin

                        estado_actual <= INICIALIZAR;

                    end

                end


                // =================================================
                // INICIALIZAR
                // =================================================

                INICIALIZAR: begin

                    palabra_oculta <= palabra_actual;

                    letras_usadas <= 26'b0;
                    fallos <= 5'd0;

                    palabra_nueva = 64'h2020202020202020;

                    if (cantidad_letras >= 4'd1)
                        palabra_nueva[63:56] = 8'h5F;

                    if (cantidad_letras >= 4'd2)
                        palabra_nueva[55:48] = 8'h5F;

                    if (cantidad_letras >= 4'd3)
                        palabra_nueva[47:40] = 8'h5F;

                    if (cantidad_letras >= 4'd4)
                        palabra_nueva[39:32] = 8'h5F;

                    if (cantidad_letras >= 4'd5)
                        palabra_nueva[31:24] = 8'h5F;

                    if (cantidad_letras >= 4'd6)
                        palabra_nueva[23:16] = 8'h5F;

                    if (cantidad_letras >= 4'd7)
                        palabra_nueva[15:8] = 8'h5F;

                    if (cantidad_letras >= 4'd8)
                        palabra_nueva[7:0] = 8'h5F;

                    palabra_estado <= palabra_nueva;

                    estado_actual <= PREPARAR_INICIO;

                end


                // =================================================
                // PREPARAR MENSAJE DE INICIO
                // =================================================

                PREPARAR_INICIO: begin

                    mensaje[0]  <= "S";
                    mensaje[1]  <= "T";
                    mensaje[2]  <= "A";
                    mensaje[3]  <= "R";
                    mensaje[4]  <= "T";
                    mensaje[5]  <= ",";

                    mensaje[6]  <= "L";
                    mensaje[7]  <= "E";
                    mensaje[8]  <= "N";
                    mensaje[9]  <= "=";

                    mensaje[10] <=
                        ascii_numero(cantidad_letras);

                    mensaje[11] <= ",";

                    mensaje[12] <= "M";
                    mensaje[13] <= "O";
                    mensaje[14] <= "D";
                    mensaje[15] <= "E";
                    mensaje[16] <= "=";


                    if (dificultad == 1'b0) begin

                        mensaje[17] <= "F";
                        mensaje[18] <= "A";
                        mensaje[19] <= "C";
                        mensaje[20] <= "I";
                        mensaje[21] <= "L";

                        longitud_mensaje <= 9'd22;

                    end

                    else begin

                        mensaje[17] <= "D";
                        mensaje[18] <= "I";
                        mensaje[19] <= "F";
                        mensaje[20] <= "I";
                        mensaje[21] <= "C";
                        mensaje[22] <= "I";
                        mensaje[23] <= "L";

                        longitud_mensaje <= 9'd24;

                    end

                    indice_mensaje <= 8'd0;

                    estado_actual <= ENVIAR_BYTE;

                end


                // =================================================
                // LEER CONTROL
                // =================================================

                LEER_CONTROL: begin

                    // RX listo
                    if (rdata[1]) begin

                        estado_actual <= LEER_DATO;

                    end

                    // Fin de partida
                    else if (!partida_activa) begin

                        estado_actual <= PREPARAR_FINAL;

                    end

                    // Nueva recepción física
                    else if (!rx_fisico) begin
                        estado_actual <= RECEPCION_SERIAL;
                    end

                end


                // =================================================
                // LEER DATO
                // =================================================

                LEER_DATO: begin

                    letra_recibida <= rdata[7:0];

                    estado_actual <= VALIDAR;

                end


                // =================================================
                // RECEPCION SERIAL
                // =================================================

                RECEPCION_SERIAL: begin

                    if ((bit_serial_rx == 4'd9) &&
                        (contador_baud_rx == CICLOS_BAUD - 1)) begin

                        estado_actual <= LEER_CONTROL;

                    end

                end


                // =================================================
                // VALIDAR
                // =================================================

                VALIDAR: begin

                    if (!letra_valida) begin

                        letra_repetida <= 1'b0;
                        letra_correcta <= 1'b0;

                        estado_actual <= LIMPIAR_RX;

                    end

                    else begin

                        letra_repetida <=
                            letras_usadas[
                                indice_letra(letra_recibida)
                            ];

                        letras_usadas[
                            indice_letra(letra_recibida)
                        ] <= 1'b1;

                        letra_correcta <=
                            (palabra_oculta[63:56] == letra_recibida) ||
                            (palabra_oculta[55:48] == letra_recibida) ||
                            (palabra_oculta[47:40] == letra_recibida) ||
                            (palabra_oculta[39:32] == letra_recibida) ||
                            (palabra_oculta[31:24] == letra_recibida) ||
                            (palabra_oculta[23:16] == letra_recibida) ||
                            (palabra_oculta[15:8]  == letra_recibida) ||
                            (palabra_oculta[7:0]   == letra_recibida);

                        estado_actual <= ACTUALIZAR;

                    end

                end


                // =================================================
                // ACTUALIZAR PALABRA
                // =================================================

                ACTUALIZAR: begin

                    palabra_nueva = palabra_estado;

                    if (palabra_oculta[63:56] == letra_recibida)
                        palabra_nueva[63:56] = letra_recibida;

                    if (palabra_oculta[55:48] == letra_recibida)
                        palabra_nueva[55:48] = letra_recibida;

                    if (palabra_oculta[47:40] == letra_recibida)
                        palabra_nueva[47:40] = letra_recibida;

                    if (palabra_oculta[39:32] == letra_recibida)
                        palabra_nueva[39:32] = letra_recibida;

                    if (palabra_oculta[31:24] == letra_recibida)
                        palabra_nueva[31:24] = letra_recibida;

                    if (palabra_oculta[23:16] == letra_recibida)
                        palabra_nueva[23:16] = letra_recibida;

                    if (palabra_oculta[15:8] == letra_recibida)
                        palabra_nueva[15:8] = letra_recibida;

                    if (palabra_oculta[7:0] == letra_recibida)
                        palabra_nueva[7:0] = letra_recibida;

                    palabra_estado <= palabra_nueva;

                    // -----------------------------------------
                    // CONTADOR DE FALLOS
                    // -----------------------------------------

                    if (!letra_repetida &&
                        !letra_correcta)
                    begin
                        if (fallos < 5'd31)
                            fallos <= fallos + 1'b1;
                    end

                    estado_actual <= LIMPIAR_RX;

                    end


                // =================================================
                // LIMPIAR RX
                // =================================================

                LIMPIAR_RX: begin

                    if (partida_activa)
                        estado_actual <= PREPARAR_RESULTADO;

                    else
                        estado_actual <= PREPARAR_FINAL;

                end


                // =================================================
                // PREPARAR RESULTADO
                // =================================================

                PREPARAR_RESULTADO: begin

                    mensaje[0] <= "R";
                    mensaje[1] <= "E";
                    mensaje[2] <= "S";
                    mensaje[3] <= "U";
                    mensaje[4] <= "L";
                    mensaje[5] <= "T";
                    mensaje[6] <= ",";


                    if (letra_repetida) begin

                        mensaje[7]  <= "R";
                        mensaje[8]  <= "E";
                        mensaje[9]  <= "P";
                        mensaje[10] <= ",";

                        mensaje[11] <= "W";
                        mensaje[12] <= "O";
                        mensaje[13] <= "R";
                        mensaje[14] <= "D";
                        mensaje[15] <= "=";

                        mensaje[16] <= palabra_estado[63:56];
                        mensaje[17] <= palabra_estado[55:48];
                        mensaje[18] <= palabra_estado[47:40];
                        mensaje[19] <= palabra_estado[39:32];
                        mensaje[20] <= palabra_estado[31:24];
                        mensaje[21] <= palabra_estado[23:16];
                        mensaje[22] <= palabra_estado[15:8];
                        mensaje[23] <= palabra_estado[7:0];

                        mensaje[24] <= ",";
                        mensaje[25] <= "L";
                        mensaje[26] <= "E";
                        mensaje[27] <= "F";
                        mensaje[28] <= "T";
                        mensaje[29] <= "=";

                        if (fallos >= 6)
                            mensaje[30] <= "0";
                        else
                            mensaje[30] <=
                                ascii_numero(6 - fallos);

                        longitud_mensaje <= 9'd31;

                    end


                    else if (letra_correcta) begin

                        mensaje[7]  <= "O";
                        mensaje[8]  <= "K";
                        mensaje[9]  <= ",";
                        mensaje[10] <= letra_recibida;
                        mensaje[11] <= ",";

                        mensaje[12] <= "W";
                        mensaje[13] <= "O";
                        mensaje[14] <= "R";
                        mensaje[15] <= "D";
                        mensaje[16] <= "=";

                        mensaje[17] <= palabra_estado[63:56];
                        mensaje[18] <= palabra_estado[55:48];
                        mensaje[19] <= palabra_estado[47:40];
                        mensaje[20] <= palabra_estado[39:32];
                        mensaje[21] <= palabra_estado[31:24];
                        mensaje[22] <= palabra_estado[23:16];
                        mensaje[23] <= palabra_estado[15:8];
                        mensaje[24] <= palabra_estado[7:0];

                        mensaje[25] <= ",";
                        mensaje[26] <= "L";
                        mensaje[27] <= "E";
                        mensaje[28] <= "F";
                        mensaje[29] <= "T";
                        mensaje[30] <= "=";

                        if (fallos >= 6)
                            mensaje[31] <= "0";
                        else
                            mensaje[31] <=
                                ascii_numero(6 - fallos);

                        longitud_mensaje <= 9'd32;

                    end


                    else begin

                        mensaje[7]  <= "E";
                        mensaje[8]  <= "R";
                        mensaje[9]  <= "R";
                        mensaje[10] <= ",";
                        mensaje[11] <= letra_recibida;
                        mensaje[12] <= ",";

                        mensaje[13] <= "W";
                        mensaje[14] <= "O";
                        mensaje[15] <= "R";
                        mensaje[16] <= "D";
                        mensaje[17] <= "=";

                        mensaje[18] <= palabra_estado[63:56];
                        mensaje[19] <= palabra_estado[55:48];
                        mensaje[20] <= palabra_estado[47:40];
                        mensaje[21] <= palabra_estado[39:32];
                        mensaje[22] <= palabra_estado[31:24];
                        mensaje[23] <= palabra_estado[23:16];
                        mensaje[24] <= palabra_estado[15:8];
                        mensaje[25] <= palabra_estado[7:0];

                        mensaje[26] <= ",";
                        mensaje[27] <= "L";
                        mensaje[28] <= "E";
                        mensaje[29] <= "F";
                        mensaje[30] <= "T";
                        mensaje[31] <= "=";

                        if (fallos >= 6)
                            mensaje[32] <= "0";
                        else
                            mensaje[32] <=
                                ascii_numero(6 - fallos);

                        longitud_mensaje <= 9'd33;

                    end


                    indice_mensaje <= 8'd0;

                    estado_actual <= ENVIAR_BYTE;

                end


                // =================================================
                // PREPARAR FINAL
                // =================================================

                PREPARAR_FINAL: begin

                    if (victoria) begin

                        mensaje[0] <= "F";
                        mensaje[1] <= "I";
                        mensaje[2] <= "N";
                        mensaje[3] <= "A";
                        mensaje[4] <= "L";
                        mensaje[5] <= ",";
                        mensaje[6] <= "W";
                        mensaje[7] <= "I";
                        mensaje[8] <= "N";
                        mensaje[9] <= ",";

                        mensaje[10] <= palabra_actual[63:56];
                        mensaje[11] <= palabra_actual[55:48];
                        mensaje[12] <= palabra_actual[47:40];
                        mensaje[13] <= palabra_actual[39:32];
                        mensaje[14] <= palabra_actual[31:24];
                        mensaje[15] <= palabra_actual[23:16];
                        mensaje[16] <= palabra_actual[15:8];
                        mensaje[17] <= palabra_actual[7:0];

                        longitud_mensaje <= 9'd18;

                    end


                    else if (tiempo_agotado) begin

                        mensaje[0] <= "F";
                        mensaje[1] <= "I";
                        mensaje[2] <= "N";
                        mensaje[3] <= "A";
                        mensaje[4] <= "L";
                        mensaje[5] <= ",";
                        mensaje[6] <= "L";
                        mensaje[7] <= "O";
                        mensaje[8] <= "S";
                        mensaje[9] <= "E";
                        mensaje[10] <= ",";
                        mensaje[11] <= "T";
                        mensaje[12] <= "I";
                        mensaje[13] <= "M";
                        mensaje[14] <= "E";
                        mensaje[15] <= ",";

                        mensaje[16] <= palabra_actual[63:56];
                        mensaje[17] <= palabra_actual[55:48];
                        mensaje[18] <= palabra_actual[47:40];
                        mensaje[19] <= palabra_actual[39:32];
                        mensaje[20] <= palabra_actual[31:24];
                        mensaje[21] <= palabra_actual[23:16];
                        mensaje[22] <= palabra_actual[15:8];
                        mensaje[23] <= palabra_actual[7:0];

                        longitud_mensaje <= 9'd24;

                    end


                    else begin

                        mensaje[0] <= "F";
                        mensaje[1] <= "I";
                        mensaje[2] <= "N";
                        mensaje[3] <= "A";
                        mensaje[4] <= "L";
                        mensaje[5] <= ",";
                        mensaje[6] <= "L";
                        mensaje[7] <= "O";
                        mensaje[8] <= "S";
                        mensaje[9] <= "E";
                        mensaje[10] <= ",";
                        mensaje[11] <= "F";
                        mensaje[12] <= "A";
                        mensaje[13] <= "I";
                        mensaje[14] <= "L";
                        mensaje[15] <= "S";
                        mensaje[16] <= ",";

                        mensaje[17] <= palabra_actual[63:56];
                        mensaje[18] <= palabra_actual[55:48];
                        mensaje[19] <= palabra_actual[47:40];
                        mensaje[20] <= palabra_actual[39:32];
                        mensaje[21] <= palabra_actual[31:24];
                        mensaje[22] <= palabra_actual[23:16];
                        mensaje[23] <= palabra_actual[15:8];
                        mensaje[24] <= palabra_actual[7:0];

                        longitud_mensaje <= 9'd25;

                    end

                    indice_mensaje <= 8'd0;

                    estado_actual <= ENVIAR_BYTE;

                end


                // =================================================
                // ENVIAR BYTE
                // =================================================

                ENVIAR_BYTE: begin

                    estado_actual <= ESPERAR_TX;

                end


                // =================================================
                // ESPERAR TX
                // =================================================

                ESPERAR_TX: begin

                    // UART terminó el byte actual
                    if (!rdata[0]) begin

                        if ((indice_mensaje + 1'b1) <
                            longitud_mensaje) begin

                            indice_mensaje <=
                                indice_mensaje + 1'b1;

                            estado_actual <= ENVIAR_BYTE;

                        end

                        else begin

                            if (partida_activa)
                                estado_actual <= LEER_CONTROL;

                            else
                                estado_actual <= ESPERA;

                        end

                    end

                end


                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    estado_actual <= ESPERA;

                end

            endcase

        end

    end


    // =========================================================
    // BUS HACIA UART
    // =========================================================

    always_comb begin

        write_enable = 1'b0;
        addr = 2'b00;
        wdata = 32'b0;


        case (estado_actual)

            // -----------------------------------------------
            // LEER STATUS
            // -----------------------------------------------

            LEER_CONTROL: begin

                write_enable = 1'b0;
                addr = 2'b10;

            end


            // -----------------------------------------------
            // LEER RX
            // -----------------------------------------------

            LEER_DATO: begin

                write_enable = 1'b0;
                addr = 2'b01;

            end


            // -----------------------------------------------
            // RECEPCION FISICA
            // -----------------------------------------------

            RECEPCION_SERIAL: begin

                addr = 2'b01;

                // Muestrear en el centro del bit
                if (contador_baud_rx == MEDIO_BAUD) begin

                    write_enable = 1'b1;

                    wdata = 32'b0;

                    wdata[0] = rx_fisico;

                end

            end


            // -----------------------------------------------
            // LIMPIAR RX
            // -----------------------------------------------

            LIMPIAR_RX: begin

                write_enable = 1'b1;

                addr = 2'b10;

                wdata = 32'h00000002;

            end


            // -----------------------------------------------
            // ENVIAR BYTE
            // -----------------------------------------------

            ENVIAR_BYTE: begin

                write_enable = 1'b1;

                addr = 2'b00;

                wdata = {
                    24'b0,
                    mensaje[indice_mensaje]
                };

            end


            // -----------------------------------------------
            // ESPERAR TX
            // -----------------------------------------------

            ESPERAR_TX: begin

                write_enable = 1'b0;

                addr = 2'b10;

            end


            default: begin

                write_enable = 1'b0;

                addr = 2'b00;

                wdata = 32'b0;

            end

        endcase

    end


    // =========================================================
    // TX FISICO
    // =========================================================

    always_comb begin

        if (estado_actual == ESPERAR_TX)

            tx_fisico = rdata[2];

        else

            tx_fisico = 1'b1;

    end

endmodule