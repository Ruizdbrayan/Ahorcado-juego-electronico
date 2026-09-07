module Validador_Letra (

    input logic        clk,
    input logic        rst,

    input logic        partida_iniciada,
    input logic        partida_activa,

    input logic [63:0] palabra_actual,
    input logic [3:0]  cantidad_letras,

    input logic        dificultad,

    input logic        tiempo_agotado,

    input logic [31:0] rdata,

    input logic        rx_fisico,
    output logic       tx_fisico,

    output logic       write_enable,
    output logic [1:0] addr,
    output logic [31:0] wdata,

    output logic [63:0] palabra_estado,
    output logic [4:0]  fallos,

    output logic        letra_correcta,
    output logic        letra_incorrecta

);


// =========================================================
// PARAMETROS UART
// =========================================================

localparam integer FRECUENCIA_RELOJ = 100_000_000;
localparam integer BAUDRATE        = 115_200;

localparam integer CICLOS_BAUD =
    FRECUENCIA_RELOJ / BAUDRATE;

localparam integer MEDIO_BAUD =
    CICLOS_BAUD / 2;


// =========================================================
// ESTADOS
// =========================================================

localparam logic [4:0]

    ESPERA             = 5'd0,
    INICIALIZAR        = 5'd1,
    LEER_CONTROL       = 5'd2,
    LEER_DATO          = 5'd3,
    VALIDAR            = 5'd4,
    ACTUALIZAR         = 5'd5,
    LIMPIAR_RX         = 5'd6,
    PREPARAR_INICIO    = 5'd7,
    PREPARAR_RESULTADO = 5'd8,
    PREPARAR_FINAL     = 5'd9,
    ENVIAR_BYTE        = 5'd10,
    ESPERAR_TX         = 5'd11,
    RECEPCION_SERIAL   = 5'd12;


logic [4:0] estado_actual;


// =========================================================
// PALABRA
// =========================================================

logic [63:0] palabra_oculta;
logic [63:0] palabra_nueva;
logic [63:0] palabra_final;

logic [7:0] letra_recibida;

logic letra_valida;
logic letra_repetida;

logic letra_correcta_calculada;


// =========================================================
// LETRAS UTILIZADAS
// =========================================================

logic [25:0] letras_usadas;


// =========================================================
// UART
// =========================================================

logic [7:0] mensaje [0:255];

logic [7:0] indice_mensaje;
logic [8:0] longitud_mensaje;


// =========================================================
// RECEPCION SERIAL
// =========================================================

logic [15:0] contador_baud_rx;
logic [3:0]  bit_serial_rx;


// =========================================================
// FINAL
// =========================================================

logic partida_terminada;
logic resultado_final_victoria;
logic resultado_final_timeout;


// =========================================================
// VARIABLE PARA FOR
// =========================================================

integer i;


// =========================================================
// FUNCION ASCII NUMERO
// =========================================================

function automatic [7:0] ascii_numero(
    input logic [3:0] numero
);

    begin
        ascii_numero = "0" + numero;
    end

endfunction


// =========================================================
// INDICE DE LETRA
// A = 0
// B = 1
// ...
// Z = 25
// =========================================================

function automatic [4:0] indice_letra(
    input logic [7:0] letra
);

    begin
        indice_letra = letra - "A";
    end

endfunction


// =========================================================
// FUNCION PALABRA COMPLETA
// =========================================================

function automatic logic palabra_completa_func(
    input logic [63:0] palabra,
    input logic [3:0] cantidad
);

    begin

        palabra_completa_func = 1'b1;

        if (cantidad == 4'd0) begin

            palabra_completa_func = 1'b0;

        end

        else begin

            if (cantidad >= 4'd1)
                if (!(
                    palabra[63:56] >= "A" &&
                    palabra[63:56] <= "Z"
                ))
                    palabra_completa_func = 1'b0;


            if (cantidad >= 4'd2)
                if (!(
                    palabra[55:48] >= "A" &&
                    palabra[55:48] <= "Z"
                ))
                    palabra_completa_func = 1'b0;


            if (cantidad >= 4'd3)
                if (!(
                    palabra[47:40] >= "A" &&
                    palabra[47:40] <= "Z"
                ))
                    palabra_completa_func = 1'b0;


            if (cantidad >= 4'd4)
                if (!(
                    palabra[39:32] >= "A" &&
                    palabra[39:32] <= "Z"
                ))
                    palabra_completa_func = 1'b0;


            if (cantidad >= 4'd5)
                if (!(
                    palabra[31:24] >= "A" &&
                    palabra[31:24] <= "Z"
                ))
                    palabra_completa_func = 1'b0;


            if (cantidad >= 4'd6)
                if (!(
                    palabra[23:16] >= "A" &&
                    palabra[23:16] <= "Z"
                ))
                    palabra_completa_func = 1'b0;


            if (cantidad >= 4'd7)
                if (!(
                    palabra[15:8] >= "A" &&
                    palabra[15:8] <= "Z"
                ))
                    palabra_completa_func = 1'b0;


            if (cantidad >= 4'd8)
                if (!(
                    palabra[7:0] >= "A" &&
                    palabra[7:0] <= "Z"
                ))
                    palabra_completa_func = 1'b0;

        end

    end

endfunction


// =========================================================
// LETRA VALIDA
// =========================================================

always_comb begin

    letra_valida = 1'b0;

    if (
        letra_recibida >= "A" &&
        letra_recibida <= "Z"
    ) begin

        letra_valida = 1'b1;

    end

end


// =========================================================
// CALCULO DE PALABRA NUEVA
// =========================================================

always_comb begin

    // Por defecto conserva la palabra actual
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

end


// =========================================================
// RECEPTOR SERIAL
// =========================================================

always_ff @(posedge clk or posedge rst) begin

    if (rst) begin

        contador_baud_rx <= 16'd0;
        bit_serial_rx    <= 4'd0;

    end

    else begin

        if (estado_actual == RECEPCION_SERIAL) begin

            if (contador_baud_rx == CICLOS_BAUD - 1) begin

                contador_baud_rx <= 16'd0;

                if (bit_serial_rx == 4'd9)
                    bit_serial_rx <= 4'd0;

                else
                    bit_serial_rx <= bit_serial_rx + 1'b1;

            end

            else begin

                contador_baud_rx <= contador_baud_rx + 1'b1;

            end

        end

        else begin

            contador_baud_rx <= 16'd0;
            bit_serial_rx    <= 4'd0;

        end

    end

end


// =========================================================
// FSM PRINCIPAL
// =========================================================

always_ff @(posedge clk or posedge rst) begin

    if (rst) begin

        estado_actual <= ESPERA;

        palabra_oculta <= 64'b0;
        palabra_estado <= 64'h2020202020202020;
        palabra_final  <= 64'b0;

        letras_usadas <= 26'b0;

        fallos <= 5'd0;

        letra_recibida <= 8'h00;

        letra_repetida <= 1'b0;

        letra_correcta_calculada <= 1'b0;

        partida_terminada <= 1'b0;

        resultado_final_victoria <= 1'b0;

        resultado_final_timeout <= 1'b0;

        letra_correcta <= 1'b0;
        letra_incorrecta <= 1'b0;

        indice_mensaje <= 8'd0;
        longitud_mensaje <= 9'd0;

        for (i = 0; i < 256; i = i + 1)
            mensaje[i] <= 8'h00;

    end

    else begin

        // =====================================================
        // PULSOS DE RESULTADO
        // =====================================================

        letra_correcta   <= 1'b0;
        letra_incorrecta <= 1'b0;


        // =====================================================
        // TIMEOUT
        // =====================================================

        if (
            partida_activa &&
            tiempo_agotado &&
            !partida_terminada
        ) begin

            partida_terminada <= 1'b1;

            resultado_final_victoria <= 1'b0;

            resultado_final_timeout <= 1'b1;

            palabra_final <= palabra_oculta;

            estado_actual <= PREPARAR_FINAL;

        end

        else begin

            case (estado_actual)


                // =================================================
                // ESPERA
                // =================================================

                ESPERA: begin

                    if (partida_iniciada) begin

                        /*
                         * MUY IMPORTANTE:
                         *
                         * Aquí limpiamos todo lo perteneciente
                         * a la partida anterior.
                         */

                        palabra_oculta <= 64'b0;

                        palabra_estado <= 64'h2020202020202020;

                        palabra_final <= 64'b0;

                        letras_usadas <= 26'b0;

                        fallos <= 5'd0;

                        letra_recibida <= 8'h00;

                        letra_repetida <= 1'b0;

                        letra_correcta_calculada <= 1'b0;

                        partida_terminada <= 1'b0;

                        resultado_final_victoria <= 1'b0;

                        resultado_final_timeout <= 1'b0;

                        estado_actual <= INICIALIZAR;

                    end

                end


                // =================================================
                // INICIALIZAR
                // =================================================

                INICIALIZAR: begin

                    /*
                     * Capturamos la nueva palabra.
                     *
                     * Esto ocurre un ciclo después de
                     * partida_iniciada, por lo que el Selector_palabra
                     * ya tuvo tiempo de actualizar palabra_actual.
                     */

                    palabra_oculta <= palabra_actual;

                    letras_usadas <= 26'b0;

                    fallos <= 5'd0;

                    partida_terminada <= 1'b0;

                    resultado_final_victoria <= 1'b0;

                    resultado_final_timeout <= 1'b0;


                    // =============================================
                    // CREAR PALABRA OCULTA
                    // =============================================

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


                    estado_actual <= PREPARAR_INICIO;

                end


                // =================================================
                // PREPARAR MENSAJE START
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

                    mensaje[10] <= ascii_numero(cantidad_letras);

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
                // LEER CONTROL UART
                // =================================================

                LEER_CONTROL: begin

                    if (partida_terminada) begin

                        estado_actual <= PREPARAR_FINAL;

                    end

                    else if (rdata[1]) begin

                        estado_actual <= LEER_DATO;

                    end

                    else if (!partida_activa) begin

                        estado_actual <= ESPERA;

                    end

                    else if (!rx_fisico) begin

                        estado_actual <= RECEPCION_SERIAL;

                    end

                end


                // =================================================
                // LEER DATO UART
                // =================================================

                LEER_DATO: begin

                    letra_recibida <= rdata[7:0];

                    estado_actual <= VALIDAR;

                end


                // =================================================
                // RECEPCION SERIAL
                // =================================================

                RECEPCION_SERIAL: begin

                    if (
                        bit_serial_rx == 4'd9 &&
                        contador_baud_rx == CICLOS_BAUD - 1
                    ) begin

                        estado_actual <= LEER_CONTROL;

                    end

                end


                // =================================================
                // VALIDAR LETRA
                // =================================================

                VALIDAR: begin

                    if (!letra_valida) begin

                        letra_repetida <= 1'b0;

                        letra_correcta_calculada <= 1'b0;

                    end

                    else begin

                        // -----------------------------------------
                        // Verificar si ya fue utilizada
                        // -----------------------------------------

                        letra_repetida <=
                            letras_usadas[
                                indice_letra(letra_recibida)
                            ];


                        // -----------------------------------------
                        // Verificar si pertenece a la palabra
                        // -----------------------------------------

                        letra_correcta_calculada <=
                            (palabra_oculta[63:56] == letra_recibida) ||
                            (palabra_oculta[55:48] == letra_recibida) ||
                            (palabra_oculta[47:40] == letra_recibida) ||
                            (palabra_oculta[39:32] == letra_recibida) ||
                            (palabra_oculta[31:24] == letra_recibida) ||
                            (palabra_oculta[23:16] == letra_recibida) ||
                            (palabra_oculta[15:8]  == letra_recibida) ||
                            (palabra_oculta[7:0]   == letra_recibida);


                        // -----------------------------------------
                        // Registrar letra utilizada
                        // -----------------------------------------

                        if (
                            !letras_usadas[
                                indice_letra(letra_recibida)
                            ]
                        ) begin

                            letras_usadas[
                                indice_letra(letra_recibida)
                            ] <= 1'b1;

                        end

                    end


                    estado_actual <= ACTUALIZAR;

                end


                // =================================================
                // ACTUALIZAR
                // =================================================

                ACTUALIZAR: begin

                    /*
                     * Actualizamos la palabra mostrada.
                     */

                    palabra_estado <= palabra_nueva;


                    // =================================================
                    // LETRA INCORRECTA NUEVA
                    // =================================================

                    if (
                        !letra_repetida &&
                        !letra_correcta_calculada
                    ) begin

                        /*
                         * El límite es 6 fallos.
                         */

                        if (fallos < 5'd6)
                            fallos <= fallos + 1'b1;

                    end


                    // =================================================
                    // VICTORIA
                    // =================================================

                    if (
                        !letra_repetida &&
                        letra_correcta_calculada &&
                        palabra_completa_func(
                            palabra_nueva,
                            cantidad_letras
                        )
                    ) begin

                        /*
                         * Guardamos la palabra COMPLETA.
                         */

                        palabra_final <= palabra_nueva;

                        partida_terminada <= 1'b1;

                        resultado_final_victoria <= 1'b1;

                        resultado_final_timeout <= 1'b0;

                        letra_correcta <= 1'b0;
                        letra_incorrecta <= 1'b0;

                        estado_actual <= LIMPIAR_RX;

                    end


                    // =================================================
                    // DERROTA
                    // =================================================

                    else if (
                        !letra_repetida &&
                        !letra_correcta_calculada &&
                        (fallos >= 5'd5)
                    ) begin

                        /*
                         * Este es el SEXTO fallo:
                         *
                         * antes de esta instrucción fallos = 5
                         * después de ella fallos = 6
                         *
                         * Por eso usamos fallos >= 5 aquí.
                         */

                        palabra_final <= palabra_oculta;

                        partida_terminada <= 1'b1;

                        resultado_final_victoria <= 1'b0;

                        resultado_final_timeout <= 1'b0;

                        letra_correcta <= 1'b0;
                        letra_incorrecta <= 1'b0;

                        estado_actual <= LIMPIAR_RX;

                    end


                    // =================================================
                    // JUGADA NORMAL
                    // =================================================

                    else begin

                        if (
                            !letra_repetida &&
                            letra_correcta_calculada
                        ) begin

                            letra_correcta <= 1'b1;

                        end

                        else if (
                            !letra_repetida &&
                            !letra_correcta_calculada
                        ) begin

                            letra_incorrecta <= 1'b1;

                        end

                        estado_actual <= LIMPIAR_RX;

                    end

                end


                // =================================================
                // LIMPIAR RX
                // =================================================

                LIMPIAR_RX: begin

                    if (partida_terminada) begin

                        estado_actual <= PREPARAR_FINAL;

                    end

                    else if (partida_activa) begin

                        estado_actual <= PREPARAR_RESULTADO;

                    end

                    else begin

                        estado_actual <= ESPERA;

                    end

                end


                // =================================================
                // PREPARAR RESULTADO NORMAL
                // =================================================

                PREPARAR_RESULTADO: begin

                    mensaje[0] <= "R";
                    mensaje[1] <= "E";
                    mensaje[2] <= "S";
                    mensaje[3] <= "U";
                    mensaje[4] <= "L";
                    mensaje[5] <= "T";
                    mensaje[6] <= ",";


                    // =================================================
                    // REPETIDA
                    // =================================================

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
                            mensaje[30] <= ascii_numero(6 - fallos);

                        longitud_mensaje <= 9'd31;

                    end


                    // =================================================
                    // CORRECTA
                    // =================================================

                    else if (letra_correcta_calculada) begin

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
                            mensaje[31] <= ascii_numero(6 - fallos);

                        longitud_mensaje <= 9'd32;

                    end


                    // =================================================
                    // INCORRECTA
                    // =================================================

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
                            mensaje[32] <= ascii_numero(6 - fallos);

                        longitud_mensaje <= 9'd33;

                    end


                    indice_mensaje <= 8'd0;

                    estado_actual <= ENVIAR_BYTE;

                end


                // =================================================
                // PREPARAR FINAL
                // =================================================

                PREPARAR_FINAL: begin

                    // =================================================
                    // TIMEOUT
                    // =================================================

                    if (resultado_final_timeout) begin

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

                        mensaje[16] <= palabra_final[63:56];
                        mensaje[17] <= palabra_final[55:48];
                        mensaje[18] <= palabra_final[47:40];
                        mensaje[19] <= palabra_final[39:32];
                        mensaje[20] <= palabra_final[31:24];
                        mensaje[21] <= palabra_final[23:16];
                        mensaje[22] <= palabra_final[15:8];
                        mensaje[23] <= palabra_final[7:0];

                        longitud_mensaje <= 9'd24;

                    end


                    // =================================================
                    // VICTORIA
                    // =================================================

                    else if (
                        partida_terminada &&
                        resultado_final_victoria
                    ) begin

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

                        mensaje[10] <= palabra_final[63:56];
                        mensaje[11] <= palabra_final[55:48];
                        mensaje[12] <= palabra_final[47:40];
                        mensaje[13] <= palabra_final[39:32];
                        mensaje[14] <= palabra_final[31:24];
                        mensaje[15] <= palabra_final[23:16];
                        mensaje[16] <= palabra_final[15:8];
                        mensaje[17] <= palabra_final[7:0];

                        longitud_mensaje <= 9'd18;

                    end


                    // =================================================
                    // DERROTA
                    // =================================================

                    else if (
                        partida_terminada &&
                        !resultado_final_victoria
                    ) begin

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

                        mensaje[17] <= palabra_final[63:56];
                        mensaje[18] <= palabra_final[55:48];
                        mensaje[19] <= palabra_final[47:40];
                        mensaje[20] <= palabra_final[39:32];
                        mensaje[21] <= palabra_final[31:24];
                        mensaje[22] <= palabra_final[23:16];
                        mensaje[23] <= palabra_final[15:8];
                        mensaje[24] <= palabra_final[7:0];

                        longitud_mensaje <= 9'd25;

                    end


                    // =================================================
                    // RESPALDO
                    // =================================================

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

                    if (!rdata[0]) begin

                        if (
                            (indice_mensaje + 1'b1) <
                            longitud_mensaje
                        ) begin

                            indice_mensaje <=
                                indice_mensaje + 1'b1;

                            estado_actual <= ENVIAR_BYTE;

                        end

                        else begin

                            if (partida_terminada) begin

                                /*
                                 * El resultado final ya fue
                                 * transmitido. El FSM principal
                                 * se encarga de mantener FINALIZADO
                                 * durante los 2 segundos.
                                 */

                                estado_actual <= ESPERA;

                            end

                            else if (partida_activa) begin

                                estado_actual <= LEER_CONTROL;

                            end

                            else begin

                                estado_actual <= ESPERA;

                            end

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

end


// =========================================================
// BUS UART
// =========================================================

always_comb begin

    write_enable = 1'b0;

    addr = 2'b00;

    wdata = 32'b0;


    case (estado_actual)


        // =====================================================
        // LEER CONTROL
        // =====================================================

        LEER_CONTROL: begin

            write_enable = 1'b0;

            addr = 2'b10;

        end


        // =====================================================
        // LEER DATO
        // =====================================================

        LEER_DATO: begin

            write_enable = 1'b0;

            addr = 2'b01;

        end


        // =====================================================
        // RECEPCION SERIAL
        // =====================================================

        RECEPCION_SERIAL: begin

            addr = 2'b01;

            if (contador_baud_rx == MEDIO_BAUD) begin

                write_enable = 1'b1;

                wdata = 32'b0;

                wdata[0] = rx_fisico;

            end

        end


        // =====================================================
        // LIMPIAR RX
        // =====================================================

        LIMPIAR_RX: begin

            write_enable = 1'b1;

            addr = 2'b10;

            wdata = 32'h00000002;

        end


        // =====================================================
        // ENVIAR BYTE
        // =====================================================

        ENVIAR_BYTE: begin

            write_enable = 1'b1;

            addr = 2'b00;

            wdata = {
                24'b0,
                mensaje[indice_mensaje]
            };

        end


        // =====================================================
        // ESPERAR TX
        // =====================================================

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