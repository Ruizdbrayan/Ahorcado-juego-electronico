module Controlador_UART (

    input  logic        clk,
    input  logic        rst,

    input  logic        partida_activa,

    input  logic        enviar_inicio,
    input  logic        enviar_resultado,
    input  logic        enviar_final,

    input  logic        dificultad,
    input  logic [3:0]  cantidad_letras,
    input  logic [7:0]  letra_recibida,

    input  logic        letra_correcta,
    input  logic        letra_incorrecta,
    input  logic        letra_repetida,

    input  logic [63:0] palabra_estado,
    input  logic [63:0] palabra_actual,

    input  logic [4:0]  fallos,

    input  logic        victoria,
    input  logic        derrota,

    output logic        letra_disponible,
    output logic [7:0]  letra_uart,

    input  logic        consumir_letra,

    output logic [8:0]  direccion_memoria,
    input  logic [7:0]  dato_memoria,

    output logic        write_enable,
    output logic [1:0]  addr,
    output logic [31:0] wdata,

    input  logic [31:0] rdata

);


    // =========================================================
    // TIPOS DE MENSAJE
    // =========================================================

    localparam logic [3:0]
        TIPO_NINGUNO    = 4'd0,
        TIPO_START      = 4'd1,
        TIPO_RESULT_REP = 4'd2,
        TIPO_RESULT_OK  = 4'd3,
        TIPO_RESULT_ERR = 4'd4,
        TIPO_FINAL_WIN  = 4'd5,
        TIPO_FINAL_LOSE = 4'd6,
        TIPO_RESET      = 4'd7;


    // =========================================================
    // ESTADOS
    // =========================================================

    localparam logic [3:0]
        ESPERA             = 4'd0,
        LEER_RX            = 4'd1,
        CAPTURAR_RX        = 4'd2,
        LIMPIAR_RX         = 4'd3,
        PREPARAR_INICIO    = 4'd4,
        PREPARAR_RESULTADO = 4'd5,
        PREPARAR_FINAL     = 4'd6,
        ENVIAR_DATO        = 4'd7,
        INICIAR_TX         = 4'd8,
        ESPERAR_TX         = 4'd9,
        PREPARAR_RESET     = 4'd10;


    logic [3:0] estado;


    // =========================================================
    // RECEPCION UART
    // =========================================================

    logic [7:0] letra_guardada;

    assign letra_uart = letra_guardada;


    // =========================================================
    // EVENTOS PENDIENTES
    // =========================================================

    logic pendiente_inicio;
    logic pendiente_resultado;
    logic pendiente_final;
    logic pendiente_reset;


    // =========================================================
    // DATOS GUARDADOS
    // =========================================================

    logic        pendiente_dificultad;
    logic [3:0]  pendiente_cantidad;

    logic [7:0]  pendiente_letra;
    logic [63:0] pendiente_palabra;
    logic [4:0]  pendiente_fallos;

    logic pendiente_correcta;
    logic pendiente_incorrecta;
    logic pendiente_repetida;

    logic pendiente_victoria;


    // =========================================================
    // TRANSMISION
    // =========================================================

    logic [3:0] mensaje_actual;

    logic [8:0] longitud_mensaje;
    logic [8:0] indice_mensaje;
    logic [8:0] base_memoria;

    logic [8:0] direccion_calculada;

    logic [7:0] caracter_actual;


    // =========================================================
    // FUNCIONES
    // =========================================================

    function automatic [7:0] ascii_numero(
        input logic [3:0] numero
    );

        ascii_numero = 8'h30 + numero;

    endfunction


    function automatic [7:0] obtener_byte_palabra(
        input logic [63:0] palabra,
        input logic [2:0] posicion
    );

        obtener_byte_palabra =
            palabra[63 - posicion * 8 -: 8];

    endfunction


    function automatic [7:0] vidas_restantes(
        input logic [4:0] cantidad_fallos
    );

        if (cantidad_fallos >= 6)

            vidas_restantes = "0";

        else

            vidas_restantes =
                ascii_numero(6 - cantidad_fallos);

    endfunction


    // =========================================================
    // RECEPCION UART
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            letra_guardada <= 8'h00;
            letra_disponible <= 1'b0;

        end

        else begin

            if (estado == CAPTURAR_RX) begin

                letra_guardada <= rdata[7:0];
                letra_disponible <= 1'b1;

            end

            if (consumir_letra)

                letra_disponible <= 1'b0;

        end

    end


    // =========================================================
    // GUARDAR EVENTOS
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            pendiente_inicio <= 1'b0;
            pendiente_resultado <= 1'b0;
            pendiente_final <= 1'b0;

            // Se envia despues de liberar rst
            pendiente_reset <= 1'b1;

            pendiente_dificultad <= 1'b0;
            pendiente_cantidad <= 4'd0;

            pendiente_letra <= 8'h00;
            pendiente_palabra <= 64'd0;
            pendiente_fallos <= 5'd0;

            pendiente_correcta <= 1'b0;
            pendiente_incorrecta <= 1'b0;
            pendiente_repetida <= 1'b0;

            pendiente_victoria <= 1'b0;

        end

        else begin

            // -------------------------------------------------
            // NUEVA PARTIDA
            // -------------------------------------------------

            if (enviar_inicio) begin

                pendiente_inicio <= 1'b1;

                pendiente_dificultad <= dificultad;
                pendiente_cantidad <= cantidad_letras;

            end


            // -------------------------------------------------
            // RESULTADO DE LETRA
            // -------------------------------------------------

            if (enviar_resultado) begin

                pendiente_resultado <= 1'b1;

                pendiente_cantidad <= cantidad_letras;
                pendiente_letra <= letra_recibida;

                pendiente_palabra <= palabra_estado;
                pendiente_fallos <= fallos;

                pendiente_correcta <= letra_correcta;
                pendiente_incorrecta <= letra_incorrecta;
                pendiente_repetida <= letra_repetida;

            end


            // -------------------------------------------------
            // FINAL DE PARTIDA
            // -------------------------------------------------

            if (enviar_final) begin

                pendiente_final <= 1'b1;

                pendiente_cantidad <= cantidad_letras;
                pendiente_palabra <= palabra_actual;

                pendiente_victoria <= victoria;

                pendiente_inicio <= 1'b0;
                pendiente_resultado <= 1'b0;

            end


            // -------------------------------------------------
            // LIMPIAR EVENTOS ENVIADOS
            // -------------------------------------------------

            if ((estado == PREPARAR_INICIO) &&
                !enviar_inicio)

                pendiente_inicio <= 1'b0;


            if ((estado == PREPARAR_RESULTADO) &&
                !enviar_resultado)

                pendiente_resultado <= 1'b0;


            if ((estado == PREPARAR_FINAL) &&
                !enviar_final)

                pendiente_final <= 1'b0;


            if (estado == PREPARAR_RESET)

                pendiente_reset <= 1'b0;

        end

    end


    // =========================================================
    // FSM
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            estado <= ESPERA;

            mensaje_actual <= TIPO_NINGUNO;

            longitud_mensaje <= 9'd0;
            indice_mensaje <= 9'd0;
            base_memoria <= 9'd0;

        end

        else begin

            case (estado)

                // -------------------------------------------------
                // ESPERA
                // -------------------------------------------------

                ESPERA: begin

                    if (pendiente_reset)

                        estado <= PREPARAR_RESET;

                    else if (pendiente_final)

                        estado <= PREPARAR_FINAL;

                    else if (pendiente_resultado)

                        estado <= PREPARAR_RESULTADO;

                    else if (pendiente_inicio)

                        estado <= PREPARAR_INICIO;

                    else if (partida_activa &&
                             !letra_disponible)

                        estado <= LEER_RX;

                end


                // -------------------------------------------------
                // LEER RX
                // -------------------------------------------------

                LEER_RX: begin

                    if (rdata[1])

                        estado <= CAPTURAR_RX;

                    else

                        estado <= ESPERA;

                end


                // -------------------------------------------------
                // CAPTURAR RX
                // -------------------------------------------------

                CAPTURAR_RX:

                    estado <= LIMPIAR_RX;


                // -------------------------------------------------
                // LIMPIAR RX
                // -------------------------------------------------

                LIMPIAR_RX:

                    estado <= ESPERA;


                // -------------------------------------------------
                // PREPARAR RESET
                // -------------------------------------------------

                PREPARAR_RESET: begin

                    indice_mensaje <= 9'd0;

                    mensaje_actual <= TIPO_RESET;

                    base_memoria <= 9'd0;

                    // RESET\r\n
                    longitud_mensaje <= 9'd7;

                    estado <= ENVIAR_DATO;

                end


                // -------------------------------------------------
                // PREPARAR START
                // -------------------------------------------------

                PREPARAR_INICIO: begin

                    indice_mensaje <= 9'd0;

                    mensaje_actual <= TIPO_START;

                    if (pendiente_dificultad) begin

                        base_memoria <= 9'd40;

                        // START,LEN=8,MODE=DIFICIL\r\n
                        longitud_mensaje <= 9'd26;

                    end

                    else begin

                        base_memoria <= 9'd0;

                        // START,LEN=4,MODE=FACIL\r\n
                        longitud_mensaje <= 9'd24;

                    end

                    estado <= ENVIAR_DATO;

                end


                // -------------------------------------------------
                // PREPARAR RESULTADO
                // -------------------------------------------------

                PREPARAR_RESULTADO: begin

                    indice_mensaje <= 9'd0;

                    if (pendiente_repetida) begin

                        mensaje_actual <= TIPO_RESULT_REP;
                        base_memoria <= 9'd80;

                        // 30 + cantidad_letras
                        longitud_mensaje <=
                            9'd30 + pendiente_cantidad;

                    end

                    else if (pendiente_correcta) begin

                        mensaje_actual <= TIPO_RESULT_OK;
                        base_memoria <= 9'd120;

                        // 31 + cantidad_letras
                        longitud_mensaje <=
                            9'd31 + pendiente_cantidad;

                    end

                    else begin

                        mensaje_actual <= TIPO_RESULT_ERR;
                        base_memoria <= 9'd160;

                        // 32 + cantidad_letras
                        longitud_mensaje <=
                            9'd32 + pendiente_cantidad;

                    end

                    estado <= ENVIAR_DATO;

                end


                // -------------------------------------------------
                // PREPARAR FINAL
                // -------------------------------------------------

                PREPARAR_FINAL: begin

                    indice_mensaje <= 9'd0;

                    if (pendiente_victoria) begin

                        mensaje_actual <= TIPO_FINAL_WIN;
                        base_memoria <= 9'd200;

                        // FINAL,WIN,PAL: palabra\r\n
                        longitud_mensaje <=
                            9'd17 + pendiente_cantidad;

                    end

                    else begin

                        mensaje_actual <= TIPO_FINAL_LOSE;
                        base_memoria <= 9'd240;

                        // FINAL,LOSE,PAL: palabra\r\n
                        longitud_mensaje <=
                            9'd18 + pendiente_cantidad;

                    end

                    estado <= ENVIAR_DATO;

                end


                // -------------------------------------------------
                // ESCRIBIR DATO
                // -------------------------------------------------

                ENVIAR_DATO:

                    estado <= INICIAR_TX;


                // -------------------------------------------------
                // INICIAR TX
                // -------------------------------------------------

                INICIAR_TX:

                    estado <= ESPERAR_TX;


                // -------------------------------------------------
                // ESPERAR TX
                // -------------------------------------------------

                ESPERAR_TX: begin

                    if (!rdata[0]) begin

                        if ((indice_mensaje + 1'b1) <
                            longitud_mensaje) begin

                            indice_mensaje <=
                                indice_mensaje + 1'b1;

                            estado <= ENVIAR_DATO;

                        end

                        else begin

                            estado <= ESPERA;

                        end

                    end

                end


                default:

                    estado <= ESPERA;

            endcase

        end

    end


    // =========================================================
    // DIRECCION DE MEMORIA
    // =========================================================

    always_comb begin

        direccion_calculada =
            base_memoria + indice_mensaje;

        case (mensaje_actual)

            // -------------------------------------------------
            // RESET
            // -------------------------------------------------

            TIPO_RESET: begin

                direccion_calculada = 9'd0;

            end


            // -------------------------------------------------
            // RESULTADO REPETIDO
            // -------------------------------------------------

            TIPO_RESULT_REP: begin

                if (indice_mensaje >
                    (9'd15 + pendiente_cantidad)) begin

                    direccion_calculada =
                        base_memoria +
                        indice_mensaje +
                        (9'd8 - pendiente_cantidad);

                end

            end


            // -------------------------------------------------
            // RESULTADO CORRECTO
            // -------------------------------------------------

            TIPO_RESULT_OK: begin

                if (indice_mensaje >
                    (9'd16 + pendiente_cantidad)) begin

                    direccion_calculada =
                        base_memoria +
                        indice_mensaje +
                        (9'd8 - pendiente_cantidad);

                end

            end


            // -------------------------------------------------
            // RESULTADO INCORRECTO
            // -------------------------------------------------

            TIPO_RESULT_ERR: begin

                if (indice_mensaje >
                    (9'd17 + pendiente_cantidad)) begin

                    direccion_calculada =
                        base_memoria +
                        indice_mensaje +
                        (9'd8 - pendiente_cantidad);

                end

            end


            // -------------------------------------------------
            // FINAL VICTORIA
            // -------------------------------------------------

            TIPO_FINAL_WIN: begin

                if (indice_mensaje >
                    (9'd14 + pendiente_cantidad)) begin

                    direccion_calculada =
                        base_memoria +
                        indice_mensaje +
                        (9'd8 - pendiente_cantidad);

                end

            end


            // -------------------------------------------------
            // FINAL DERROTA
            // -------------------------------------------------

            TIPO_FINAL_LOSE: begin

                if (indice_mensaje >
                    (9'd15 + pendiente_cantidad)) begin

                    direccion_calculada =
                        base_memoria +
                        indice_mensaje +
                        (9'd8 - pendiente_cantidad);

                end

            end


            default: begin

                direccion_calculada =
                    base_memoria + indice_mensaje;

            end

        endcase

    end


    assign direccion_memoria = direccion_calculada;


    // =========================================================
    // CARACTER ACTUAL
    // =========================================================

    always_comb begin

        caracter_actual = dato_memoria;

        case (mensaje_actual)

            // -------------------------------------------------
            // RESET
            // -------------------------------------------------

            TIPO_RESET: begin

                case (indice_mensaje)

                    9'd0: caracter_actual = "R";
                    9'd1: caracter_actual = "E";
                    9'd2: caracter_actual = "S";
                    9'd3: caracter_actual = "E";
                    9'd4: caracter_actual = "T";
                    9'd5: caracter_actual = 8'h0D;
                    9'd6: caracter_actual = 8'h0A;

                    default:
                        caracter_actual = 8'h00;

                endcase

            end


            // -------------------------------------------------
            // START
            // -------------------------------------------------

            TIPO_START: begin

                if (indice_mensaje == 9'd10)

                    caracter_actual =
                        ascii_numero(pendiente_cantidad);

            end


            // -------------------------------------------------
            // RESULTADO REPETIDO
            // -------------------------------------------------

            TIPO_RESULT_REP: begin

                if ((indice_mensaje >= 9'd16) &&
                    (indice_mensaje <
                     (9'd16 + pendiente_cantidad))) begin

                    caracter_actual =
                        obtener_byte_palabra(
                            pendiente_palabra,
                            indice_mensaje - 9'd16
                        );

                end

                else if (indice_mensaje ==
                         (9'd27 + pendiente_cantidad)) begin

                    caracter_actual =
                        vidas_restantes(pendiente_fallos);

                end

            end


            // -------------------------------------------------
            // RESULTADO CORRECTO
            // -------------------------------------------------

            TIPO_RESULT_OK: begin

                if (indice_mensaje == 9'd10) begin

                    caracter_actual =
                        pendiente_letra;

                end

                else if ((indice_mensaje >= 9'd17) &&
                         (indice_mensaje <
                          (9'd17 + pendiente_cantidad))) begin

                    caracter_actual =
                        obtener_byte_palabra(
                            pendiente_palabra,
                            indice_mensaje - 9'd17
                        );

                end

                else if (indice_mensaje ==
                         (9'd28 + pendiente_cantidad)) begin

                    caracter_actual =
                        vidas_restantes(pendiente_fallos);

                end

            end


            // -------------------------------------------------
            // RESULTADO INCORRECTO
            // -------------------------------------------------

            TIPO_RESULT_ERR: begin

                if (indice_mensaje == 9'd11) begin

                    caracter_actual =
                        pendiente_letra;

                end

                else if ((indice_mensaje >= 9'd18) &&
                         (indice_mensaje <
                          (9'd18 + pendiente_cantidad))) begin

                    caracter_actual =
                        obtener_byte_palabra(
                            pendiente_palabra,
                            indice_mensaje - 9'd18
                        );

                end

                else if (indice_mensaje ==
                         (9'd29 + pendiente_cantidad)) begin

                    caracter_actual =
                        vidas_restantes(pendiente_fallos);

                end

            end


            // -------------------------------------------------
            // FINAL VICTORIA
            // -------------------------------------------------

            TIPO_FINAL_WIN: begin

                if ((indice_mensaje >= 9'd15) &&
                    (indice_mensaje <
                     (9'd15 + pendiente_cantidad))) begin

                    caracter_actual =
                        obtener_byte_palabra(
                            pendiente_palabra,
                            indice_mensaje - 9'd15
                        );

                end

            end


            // -------------------------------------------------
            // FINAL DERROTA
            // -------------------------------------------------

            TIPO_FINAL_LOSE: begin

                if ((indice_mensaje >= 9'd16) &&
                    (indice_mensaje <
                     (9'd16 + pendiente_cantidad))) begin

                    caracter_actual =
                        obtener_byte_palabra(
                            pendiente_palabra,
                            indice_mensaje - 9'd16
                        );

                end

            end


            default:

                caracter_actual = dato_memoria;

        endcase

    end


    // =========================================================
    // BUS UART
    // =========================================================

    always_comb begin

        write_enable = 1'b0;
        addr = 2'b00;
        wdata = 32'd0;

        case (estado)

            // -------------------------------------------------
            // LEER RX
            // -------------------------------------------------

            LEER_RX: begin

                addr = 2'b10;

            end


            // -------------------------------------------------
            // CAPTURAR RX
            // -------------------------------------------------

            CAPTURAR_RX: begin

                addr = 2'b01;

            end


            // -------------------------------------------------
            // LIMPIAR RX
            // -------------------------------------------------

            LIMPIAR_RX: begin

                write_enable = 1'b1;
                addr = 2'b10;
                wdata = 32'h00000002;

            end


            // -------------------------------------------------
            // ESCRIBIR CARACTER
            // -------------------------------------------------

            ENVIAR_DATO: begin

                write_enable = 1'b1;
                addr = 2'b00;
                wdata = {24'd0, caracter_actual};

            end


            // -------------------------------------------------
            // INICIAR TRANSMISION
            // -------------------------------------------------

            INICIAR_TX: begin

                write_enable = 1'b1;
                addr = 2'b10;
                wdata = 32'h00000001;

            end


            // -------------------------------------------------
            // ESPERAR TRANSMISION
            // -------------------------------------------------

            ESPERAR_TX: begin

                addr = 2'b10;

            end


            default: begin

                write_enable = 1'b0;

            end

        endcase

    end

endmodule