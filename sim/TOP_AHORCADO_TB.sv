`timescale 1ns / 1ps

module TB_TOP_AHORCADO;

localparam integer FRECUENCIA_RELOJ = 100_000_000;

localparam time TIEMPO_PRESION    = 21ms;
localparam time TIEMPO_LIBERACION = 21ms;

localparam integer TIEMPO_PROCESAMIENTO = 100;
localparam integer TIMEOUT_ESTADO = 5_000_000;
localparam integer TIMEOUT_UART = 1_000_000;

// =========================================================
// ESTADOS FSM
// =========================================================

localparam logic [1:0] ESTADO_SELECTOR   = 2'b00;
localparam logic [1:0] ESTADO_JUGANDO    = 2'b01;
localparam logic [1:0] ESTADO_FINALIZADO = 2'b10;

// =========================================================
// ESTADOS CONTROLADOR UART
// =========================================================

localparam logic [3:0] UART_ESPERA = 4'd0;

// =========================================================
// ESTADO LCD
// =========================================================

localparam logic [3:0] LCD_LISTO = 4'd12;

// =========================================================
// SEÑALES DUT
// =========================================================

logic clk;
logic rst;
logic [1:0] botones;

logic RsRx;
logic RsTx;

logic [6:0] segmentos;
logic [7:0] anodos;
logic buzzer;
logic [2:0] leds;

logic lcd_rs;
logic lcd_en;
logic [3:0] lcd_datos;

// =========================================================
// INSTANCIA DUT
// =========================================================

TOP_AHORCADO dut (
    .clk       (clk),
    .rst       (rst),
    .botones   (botones),
    .RsRx      (RsRx),
    .RsTx      (RsTx),
    .segmentos (segmentos),
    .anodos     (anodos),
    .buzzer     (buzzer),
    .leds       (leds),
    .lcd_rs     (lcd_rs),
    .lcd_en     (lcd_en),
    .lcd_datos  (lcd_datos)
);

// =========================================================
// VARIABLES DEL TB
// =========================================================

integer errores;
integer pruebas;

logic [63:0] palabra_prueba;
integer cantidad_prueba;

integer fallos_antes;
integer fallos_despues;

logic [7:0] letras_incorrectas [0:5];
integer cantidad_incorrectas;

// =========================================================
// RELOJ
// =========================================================

initial begin

    clk = 1'b0;

    forever
        #5 clk = ~clk;

end

// =========================================================
// VERIFICAR
// =========================================================

task verificar;

    input logic condicion;
    input [255:0] mensaje;

    begin

        if (condicion) begin

            $display(
                "[OK] %s",
                mensaje
            );

        end

        else begin

            $display(
                "[ERROR] %s",
                mensaje
            );

            errores = errores + 1;

        end

    end

endtask

// =========================================================
// ESPERAR CICLOS
// =========================================================

task esperar_ciclos;

    input integer cantidad;

    integer i;

    begin

        for (
            i = 0;
            i < cantidad;
            i = i + 1
        ) begin

            @(posedge clk);

        end

    end

endtask

// =========================================================
// PRESIONAR BOTON
// =========================================================

task presionar_boton;

    input integer numero_boton;

    begin

        botones[numero_boton] = 1'b1;

        #(TIEMPO_PRESION);

        botones[numero_boton] = 1'b0;

        #(TIEMPO_LIBERACION);

        repeat (10)
            @(posedge clk);

    end

endtask

// =========================================================
// ESPERAR SELECTOR
// =========================================================

task esperar_selector;

    integer contador;

    begin

        contador = 0;

        while (
            dut.estado_actual != ESTADO_SELECTOR
        ) begin

            @(posedge clk);

            contador = contador + 1;

            if (contador >= TIMEOUT_ESTADO) begin

                $display(
                    "[ERROR] Timeout esperando estado SELECTOR"
                );

                errores = errores + 1;

                disable esperar_selector;

            end

        end

    end

endtask

// =========================================================
// ESPERAR JUGANDO
// =========================================================

task esperar_jugando;

    integer contador;

    begin

        contador = 0;

        while (
            dut.estado_actual != ESTADO_JUGANDO
        ) begin

            @(posedge clk);

            contador = contador + 1;

            if (contador >= TIMEOUT_ESTADO) begin

                $display(
                    "[ERROR] Timeout esperando estado JUGANDO"
                );

                errores = errores + 1;

                disable esperar_jugando;

            end

        end

    end

endtask

// =========================================================
// ESPERAR UART DISPONIBLE
// =========================================================

task esperar_uart_libre;

    integer contador;

    begin

        contador = 0;

        while (
            (dut.controlador_uart_inst.estado != UART_ESPERA) ||
            dut.letra_disponible
        ) begin

            @(posedge clk);

            contador = contador + 1;

            if (contador >= TIMEOUT_UART) begin

                $display(
                    "[ERROR] Timeout esperando UART libre"
                );

                errores = errores + 1;

                disable esperar_uart_libre;

            end

        end

    end

endtask

// =========================================================
// SIMULAR RECEPCION UART
// =========================================================

task enviar_uart;

    input [7:0] dato;

    integer contador;

    begin

        if (
            dut.estado_actual != ESTADO_JUGANDO
        ) begin

            $display(
                "[ERROR] Intento de enviar letra fuera de JUGANDO"
            );

            errores = errores + 1;

            disable enviar_uart;

        end

        // -------------------------------------------------
        // Esperar a que termine el mensaje anterior.
        // -------------------------------------------------

        esperar_uart_libre;

        // -------------------------------------------------
        // Simular byte recibido.
        // -------------------------------------------------

        $display(
            "[INFO] Enviando letra: %c",
            dato
        );

        force dut.uart_inst.registro_rx =
            {24'b0, dato};

        force dut.uart_inst.rx_recibido =
            1'b1;

        // -------------------------------------------------
        // Dar tiempo para que el controlador lo detecte.
        // -------------------------------------------------

        repeat (3)
            @(posedge clk);

        release dut.uart_inst.registro_rx;
        release dut.uart_inst.rx_recibido;

        // -------------------------------------------------
        // Esperar a que el RX sea limpiado.
        // -------------------------------------------------

        contador = 0;

        while (
            dut.uart_inst.rx_recibido !== 1'b0
        ) begin

            @(posedge clk);

            contador = contador + 1;

            if (contador >= TIMEOUT_UART) begin

                $display(
                    "[ERROR] Timeout esperando limpieza de RX"
                );

                errores = errores + 1;

                disable enviar_uart;

            end

        end

        $display(
            "[OK] RX limpiado correctamente"
        );

        // -------------------------------------------------
        // Esperar a que la letra sea consumida.
        // -------------------------------------------------

        contador = 0;

        while (
            dut.letra_disponible !== 1'b0
        ) begin

            @(posedge clk);

            contador = contador + 1;

            if (contador >= TIMEOUT_UART) begin

                $display(
                    "[ERROR] Timeout esperando consumo de letra"
                );

                errores = errores + 1;

                disable enviar_uart;

            end

        end

        // -------------------------------------------------
        // Esperar a que termine el resultado UART.
        // -------------------------------------------------

        contador = 0;

        while (
            dut.controlador_uart_inst.estado != UART_ESPERA
        ) begin

            @(posedge clk);

            contador = contador + 1;

            if (contador >= TIMEOUT_UART) begin

                $display(
                    "[ERROR] Timeout esperando final de mensaje UART"
                );

                errores = errores + 1;

                disable enviar_uart;

            end

        end

        // -------------------------------------------------
        // Dar un pequeño margen al resto del sistema.
        // -------------------------------------------------

        repeat (10)
            @(posedge clk);

    end

endtask

// =========================================================
// ESPERAR PROCESAMIENTO
// =========================================================

task esperar_procesamiento;

    begin

        repeat (TIEMPO_PROCESAMIENTO)
            @(posedge clk);

    end

endtask

// =========================================================
// ESPERAR LCD LISTO
// =========================================================

task esperar_lcd_listo;

    integer contador;

    begin

        contador = 0;

        while (
            dut.periferico_lcd.estado != LCD_LISTO
        ) begin

            @(posedge clk);

            contador = contador + 1;

            if (contador >= 5_000_000) begin

                $display(
                    "[ERROR] Timeout esperando LCD LISTO"
                );

                errores = errores + 1;

                disable esperar_lcd_listo;

            end

        end

    end

endtask

// =========================================================
// OBTENER LETRA
// =========================================================

function automatic [7:0] obtener_letra;

    input [63:0] palabra;
    input integer indice;

    begin

        case (indice)

            0:
                obtener_letra = palabra[63:56];

            1:
                obtener_letra = palabra[55:48];

            2:
                obtener_letra = palabra[47:40];

            3:
                obtener_letra = palabra[39:32];

            4:
                obtener_letra = palabra[31:24];

            5:
                obtener_letra = palabra[23:16];

            6:
                obtener_letra = palabra[15:8];

            7:
                obtener_letra = palabra[7:0];

            default:
                obtener_letra = 8'h20;

        endcase

    end

endfunction

// =========================================================
// LETRA EN PALABRA
// =========================================================

function automatic logic letra_en_palabra;

    input [63:0] palabra;
    input integer cantidad;
    input [7:0] letra;

    integer i;

    begin

        letra_en_palabra = 1'b0;

        for (
            i = 0;
            i < cantidad;
            i = i + 1
        ) begin

            if (
                obtener_letra(
                    palabra,
                    i
                ) == letra
            )
                letra_en_palabra = 1'b1;

        end

    end

endfunction

// =========================================================
// ENVIAR LETRAS CORRECTAS
// =========================================================

task enviar_letras_palabra;

    integer i;
    integer j;

    reg [7:0] letra_actual;
    reg repetida;

    begin

        for (
            i = 0;
            i < cantidad_prueba;
            i = i + 1
        ) begin

            letra_actual =
                obtener_letra(
                    palabra_prueba,
                    i
                );

            repetida = 1'b0;

            for (
                j = 0;
                j < i;
                j = j + 1
            ) begin

                if (
                    obtener_letra(
                        palabra_prueba,
                        j
                    ) == letra_actual
                )
                    repetida = 1'b1;

            end

            if (!repetida) begin

                $display(
                    "[INFO] Letra correcta: %c",
                    letra_actual
                );

                enviar_uart(
                    letra_actual
                );

                esperar_procesamiento;

            end

        end

    end

endtask

// =========================================================
// PREPARAR LETRAS INCORRECTAS
// =========================================================

task preparar_letras_incorrectas;

    integer candidato;
    integer i;

    reg [7:0] letra_candidata;
    reg presente;

    begin

        cantidad_incorrectas = 0;

        for (
            candidato = 0;
            candidato < 26;
            candidato = candidato + 1
        ) begin

            if (
                cantidad_incorrectas < 6
            ) begin

                letra_candidata =
                    8'h41 + candidato;

                presente = 1'b0;

                for (
                    i = 0;
                    i < cantidad_prueba;
                    i = i + 1
                ) begin

                    if (
                        obtener_letra(
                            palabra_prueba,
                            i
                        ) == letra_candidata
                    )
                        presente = 1'b1;

                end

                if (!presente) begin

                    letras_incorrectas[
                        cantidad_incorrectas
                    ] = letra_candidata;

                    $display(
                        "[INFO] Letra incorrecta %0d: %c",
                        cantidad_incorrectas + 1,
                        letra_candidata
                    );

                    cantidad_incorrectas =
                        cantidad_incorrectas + 1;

                end

            end

        end

    end

endtask

// =========================================================
// VERIFICAR PALABRA COMPLETA
// =========================================================

task verificar_palabra_completa;

    integer i;

    begin

        for (
            i = 0;
            i < cantidad_prueba;
            i = i + 1
        ) begin

            verificar(

                obtener_letra(
                    dut.palabra_estado,
                    i
                ) ==
                obtener_letra(
                    palabra_prueba,
                    i
                ),

                "Letra de palabra revelada correctamente"

            );

        end

    end

endtask

// =========================================================
// RESET
// =========================================================

task reset_dut;

    begin

        rst = 1'b1;

        botones = 2'b00;

        RsRx = 1'b1;

        #(100ns);

        rst = 1'b0;

        #(100ns);

    end

endtask

// =========================================================
// PROGRAMA PRINCIPAL
// =========================================================

initial begin

    errores = 0;
    pruebas = 0;

    rst = 1'b1;
    botones = 2'b00;
    RsRx = 1'b1;

    // =====================================================
    // RESET INICIAL
    // =====================================================

    #(100ns);

    rst = 1'b0;

    #(100ns);

    // =====================================================
    // PRUEBA 1
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 1: ESTADO INICIAL");
    $display("----------------------------------------------------");

    verificar(
        dut.estado_actual == ESTADO_SELECTOR,
        "FSM inicia en SELECTOR"
    );

    verificar(
        dut.dificultad == 1'b0,
        "Dificultad inicial = FACIL"
    );

    verificar(
        dut.victoria == 1'b0,
        "Victoria inicial = 0"
    );

    verificar(
        dut.derrota == 1'b0,
        "Derrota inicial = 0"
    );

    verificar(
        dut.fallos == 5'd0,
        "Fallos iniciales = 0"
    );

    // =====================================================
    // PRUEBA 2
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 2: CAMBIO DE DIFICULTAD");
    $display("----------------------------------------------------");

    presionar_boton(0);

    verificar(
        dut.dificultad == 1'b1,
        "Dificultad cambia a DIFICIL"
    );

    presionar_boton(0);

    verificar(
        dut.dificultad == 1'b0,
        "Dificultad vuelve a FACIL"
    );

    // =====================================================
    // PRUEBA 3
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 3: INICIAR PARTIDA");
    $display("----------------------------------------------------");

    presionar_boton(1);

    esperar_jugando;

    verificar(
        dut.estado_actual == ESTADO_JUGANDO,
        "Partida llega a JUGANDO"
    );

    verificar(
        dut.partida_iniciada == 1'b0,
        "partida_iniciada vuelve a 0"
    );

    esperar_procesamiento;

    verificar(
        dut.estado_actual == ESTADO_JUGANDO,
        "FSM permanece JUGANDO"
    );

    verificar(
        dut.victoria == 1'b0,
        "No existe victoria inmediata"
    );

    verificar(
        dut.derrota == 1'b0,
        "No existe derrota inmediata"
    );

    // =====================================================
    // PRUEBA 4
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 4: PALABRA SELECCIONADA");
    $display("----------------------------------------------------");

    palabra_prueba =
        dut.palabra_actual;

    cantidad_prueba =
        dut.cantidad_letras;

    $display(
        "[INFO] Palabra seleccionada = %s",
        palabra_prueba
    );

    $display(
        "[INFO] Cantidad de letras = %0d",
        cantidad_prueba
    );

    verificar(
        (cantidad_prueba >= 4) &&
        (cantidad_prueba <= 8),
        "Cantidad de letras valida"
    );

    verificar(
        dut.palabra_estado != 64'b0,
        "Palabra estado fue inicializada"
    );

    verificar(
        dut.palabra_estado[63:56] == 8'h5F,
        "Primera letra inicia como guion"
    );

    if (cantidad_prueba >= 2)
        verificar(
            dut.palabra_estado[55:48] == 8'h5F,
            "Segunda letra inicia como guion"
        );

    if (cantidad_prueba >= 3)
        verificar(
            dut.palabra_estado[47:40] == 8'h5F,
            "Tercera letra inicia como guion"
        );

    if (cantidad_prueba >= 4)
        verificar(
            dut.palabra_estado[39:32] == 8'h5F,
            "Cuarta letra inicia como guion"
        );

    // =====================================================
    // PRUEBA 5
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 5: LCD");
    $display("----------------------------------------------------");

    esperar_lcd_listo;

    verificar(
        dut.periferico_lcd.estado == LCD_LISTO,
        "LCD termino inicializacion"
    );

    // =====================================================
    // PRUEBA 6
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 6: LETRA INCORRECTA");
    $display("----------------------------------------------------");

    preparar_letras_incorrectas;

    verificar(
        cantidad_incorrectas >= 6,
        "Se encontraron seis letras incorrectas"
    );

    enviar_uart(
        letras_incorrectas[0]
    );

    esperar_procesamiento;

    fallos_antes =
        dut.fallos;

    verificar(
        fallos_antes == 1,
        "Letra incorrecta aumenta fallos a 1"
    );

    verificar(
        dut.estado_actual == ESTADO_JUGANDO,
        "FSM permanece JUGANDO"
    );

    verificar(
        dut.derrota == 1'b0,
        "Derrota permanece en 0"
    );

    // =====================================================
    // PRUEBA 7
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 7: LETRA REPETIDA");
    $display("----------------------------------------------------");

    enviar_uart(
        letras_incorrectas[0]
    );

    esperar_procesamiento;

    fallos_despues =
        dut.fallos;

    verificar(
        fallos_despues == fallos_antes,
        "Letra repetida no aumenta fallos"
    );

    // =====================================================
    // PRUEBA 8
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 8: LETRAS CORRECTAS");
    $display("----------------------------------------------------");

    enviar_letras_palabra;

    esperar_procesamiento;

    // =====================================================
    // PRUEBA 9
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 9: VICTORIA");
    $display("----------------------------------------------------");

    begin : esperar_victoria

        integer contador;

        contador = 0;

        while (
            dut.estado_actual != ESTADO_FINALIZADO
        ) begin

            @(posedge clk);

            contador = contador + 1;

            if (contador >= TIMEOUT_ESTADO) begin

                $display(
                    "[ERROR] Timeout esperando FINALIZADO"
                );

                errores = errores + 1;

                disable esperar_victoria;

            end

        end

    end

    verificar(
        dut.estado_actual == ESTADO_FINALIZADO,
        "FSM pasa a FINALIZADO"
    );

    verificar(
        dut.victoria == 1'b1,
        "Victoria = 1"
    );

    verificar(
        dut.derrota == 1'b0,
        "Derrota = 0"
    );

    verificar(
        dut.mostrar_guiones == 1'b1,
        "mostrar_guiones = 1"
    );

    verificar_palabra_completa;

    // =====================================================
    // PRUEBA 10
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 10: LCD DESPUES DE VICTORIA");
    $display("----------------------------------------------------");

    esperar_lcd_listo;

    verificar(
        dut.periferico_lcd.estado == LCD_LISTO,
        "LCD termino pantalla de victoria"
    );

    // =====================================================
    // PRUEBA 11
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 11: ESTADO FINAL");
    $display("----------------------------------------------------");

    esperar_procesamiento;

    verificar(
        dut.victoria == 1'b1,
        "Victoria permanece en 1"
    );

    verificar(
        dut.derrota == 1'b0,
        "Derrota permanece en 0"
    );

    verificar(
        dut.estado_actual == ESTADO_FINALIZADO,
        "FSM permanece en FINALIZADO"
    );

    // =====================================================
    // PRUEBA 12
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 12: SALIDAS");
    $display("----------------------------------------------------");

    verificar(
        segmentos !== 7'bx,
        "Segmentos tienen valor valido"
    );

    verificar(
        anodos !== 8'bx,
        "Anodos tienen valor valido"
    );

    verificar(
        leds !== 3'bx,
        "LEDs tienen valor valido"
    );

    verificar(
        buzzer !== 1'bx,
        "Buzzer tiene valor valido"
    );

    // =====================================================
    // SEGUNDA PARTIDA
    // =====================================================

    $display("");
    $display("====================================================");
    $display("INICIANDO SEGUNDA PARTIDA");
    $display("====================================================");

    reset_dut;

    esperar_ciclos(20);

    // =====================================================
    // PRUEBA 13
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 13: NUEVA PARTIDA");
    $display("----------------------------------------------------");

    verificar(
        dut.estado_actual == ESTADO_SELECTOR,
        "Reset devuelve FSM a SELECTOR"
    );

    verificar(
        dut.victoria == 1'b0,
        "Victoria vuelve a 0"
    );

    verificar(
        dut.derrota == 1'b0,
        "Derrota vuelve a 0"
    );

    verificar(
        dut.fallos == 5'd0,
        "Fallos se reinician a 0"
    );

    verificar(
        dut.dificultad == 1'b0,
        "Dificultad vuelve a FACIL"
    );

    presionar_boton(1);

    esperar_jugando;

    verificar(
        dut.estado_actual == ESTADO_JUGANDO,
        "Partida llega a JUGANDO"
    );

    verificar(
        dut.victoria == 1'b0,
        "Victoria vuelve a 0"
    );

    verificar(
        dut.derrota == 1'b0,
        "Derrota vuelve a 0"
    );

    verificar(
        dut.fallos == 5'd0,
        "Fallos se reinician a 0"
    );

    // =====================================================
    // PRUEBA 14
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 14: SEGUNDA PARTIDA");
    $display("----------------------------------------------------");

    palabra_prueba =
        dut.palabra_actual;

    cantidad_prueba =
        dut.cantidad_letras;

    $display(
        "[INFO] Segunda palabra = %s",
        palabra_prueba
    );

    $display(
        "[INFO] Cantidad de letras = %0d",
        cantidad_prueba
    );

    verificar(
        (cantidad_prueba >= 4) &&
        (cantidad_prueba <= 8),
        "Cantidad de letras valida"
    );

    verificar(
        dut.palabra_estado[63:56] == 8'h5F,
        "Primera letra inicia oculta"
    );

    verificar(
        dut.victoria == 1'b0,
        "Segunda partida no tiene victoria inmediata"
    );

    verificar(
        dut.derrota == 1'b0,
        "Segunda partida no tiene derrota inmediata"
    );

    // =====================================================
    // PRUEBA 15
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 15: SEIS LETRAS INCORRECTAS");
    $display("----------------------------------------------------");

    preparar_letras_incorrectas;

    verificar(
        cantidad_incorrectas == 6,
        "Se encontraron seis letras incorrectas"
    );

    enviar_uart(
        letras_incorrectas[0]
    );

    esperar_procesamiento;

    enviar_uart(
        letras_incorrectas[1]
    );

    esperar_procesamiento;

    enviar_uart(
        letras_incorrectas[2]
    );

    esperar_procesamiento;

    enviar_uart(
        letras_incorrectas[3]
    );

    esperar_procesamiento;

    enviar_uart(
        letras_incorrectas[4]
    );

    esperar_procesamiento;

    enviar_uart(
        letras_incorrectas[5]
    );

    esperar_procesamiento;

    verificar(
        dut.fallos == 5'd6,
        "Contador llega a 6"
    );

    verificar(
        dut.derrota == 1'b1,
        "Comparador detecta seis fallos"
    );

    verificar(
        dut.estado_actual == ESTADO_FINALIZADO,
        "FSM pasa a FINALIZADO"
    );

    // =====================================================
    // PRUEBA 16
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 16: DERROTA");
    $display("----------------------------------------------------");

    verificar(
        dut.estado_actual == ESTADO_FINALIZADO,
        "FSM permanece FINALIZADO"
    );

    verificar(
        dut.derrota == 1'b1,
        "Derrota = 1"
    );

    verificar(
        dut.victoria == 1'b0,
        "Victoria = 0"
    );

    // =====================================================
    // PRUEBA 17
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 17: UART DESPUES DE DERROTA");
    $display("----------------------------------------------------");

    fallos_antes =
        dut.fallos;

    force dut.uart_inst.registro_rx =
        {24'b0, "Z"};

    force dut.uart_inst.rx_recibido =
        1'b1;

    repeat (20)
        @(posedge clk);

    release dut.uart_inst.registro_rx;
    release dut.uart_inst.rx_recibido;

    esperar_procesamiento;

    verificar(
        dut.estado_actual == ESTADO_FINALIZADO,
        "FSM permanece FINALIZADO"
    );

    verificar(
        dut.derrota == 1'b1,
        "Derrota permanece en 1"
    );

    verificar(
        dut.victoria == 1'b0,
        "Victoria permanece en 0"
    );

    verificar(
        dut.fallos == fallos_antes,
        "Fallos no cambian despues de derrota"
    );

    // =====================================================
    // PRUEBA 18
    // =====================================================

    pruebas = pruebas + 1;

    $display("");
    $display("----------------------------------------------------");
    $display("PRUEBA 18: RESET FINAL");
    $display("----------------------------------------------------");

    rst = 1'b1;

    #(100ns);

    verificar(
        dut.estado_actual == ESTADO_SELECTOR,
        "Reset devuelve FSM a SELECTOR"
    );

    verificar(
        dut.victoria == 1'b0,
        "Reset limpia victoria"
    );

    verificar(
        dut.derrota == 1'b0,
        "Reset limpia derrota"
    );

    verificar(
        dut.fallos == 5'd0,
        "Reset limpia fallos"
    );

    verificar(
        dut.dificultad == 1'b0,
        "Reset devuelve dificultad a FACIL"
    );

    verificar(
        dut.uart_inst.registro_tx == 32'b0,
        "Reset limpia TX"
    );

    verificar(
        dut.uart_inst.registro_rx == 32'b0,
        "Reset limpia RX"
    );

    verificar(
        dut.uart_inst.tx_pendiente == 1'b0,
        "Reset limpia TX pendiente"
    );

    verificar(
        dut.uart_inst.rx_recibido == 1'b0,
        "Reset limpia RX recibido"
    );

    rst = 1'b0;

    #(100ns);

    // =====================================================
    // RESULTADO
    // =====================================================

    $display("");
    $display("");
    $display("====================================================");
    $display("             FIN DE PRUEBAS AHORCADO");
    $display("====================================================");

    $display("");
    $display(
        "Pruebas ejecutadas : %0d",
        pruebas
    );

    $display(
        "Errores encontrados: %0d",
        errores
    );

    if (errores == 0) begin

        $display("");
        $display("****************************************************");
        $display("*                                                  *");
        $display("*          TODAS LAS PRUEBAS PASARON              *");
        $display("*                                                  *");
        $display("*                  %0d / %0d                       *",
                 pruebas,
                 pruebas);
        $display("*                                                  *");
        $display("****************************************************");

    end

    else begin

        $display("");
        $display("****************************************************");
        $display("*                                                  *");
        $display("*          SE ENCONTRARON ERRORES                  *");
        $display("*                                                  *");
        $display("*          BLOQUES EJECUTADOS: %0d                 *",
                 pruebas);
        $display("*          ERRORES: %0d                            *",
                 errores);
        $display("*                                                  *");
        $display("****************************************************");

    end

    $finish;

end

endmodule