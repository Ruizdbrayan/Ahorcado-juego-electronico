`timescale 1ns / 1ps

module TB_TOP_AHORCADO;

    // =========================================================
    // PARAMETROS
    // =========================================================

    localparam integer FRECUENCIA_RELOJ = 100_000_000;

    // Simulacion de pulsacion humana.
    localparam time TIEMPO_PRESION    = 21ms;
    localparam time TIEMPO_LIBERACION = 21ms;

    localparam integer TIEMPO_PROCESAMIENTO = 100;


    // =========================================================
    // SEÑALES DUT
    // =========================================================

    logic clk;
    logic rst;

    logic [1:0] botones;

    logic [6:0] segmentos;
    logic [2:0] anodos;

    logic buzzer;

    logic [2:0] leds;

    logic lcd_rs;
    logic lcd_en;
    logic [3:0] lcd_datos;


    // =========================================================
    // INSTANCIA DUT
    // =========================================================

    TOP_AHORCADO dut (

        .clk(clk),
        .rst(rst),

        .botones(botones),

        .segmentos(segmentos),
        .anodos(anodos),

        .buzzer(buzzer),

        .leds(leds),

        .lcd_rs(lcd_rs),
        .lcd_en(lcd_en),
        .lcd_datos(lcd_datos)

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
    // VARIABLES UART TX
    // =========================================================

    integer cantidad_bytes_tx;

    logic [7:0] ultimo_byte_tx;


    // =========================================================
    // RELOJ 100 MHz
    // =========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // =========================================================
    // MONITOR DE ESCRITURA AL UART
    //
    // Esto comprueba que Validador_Letra esta utilizando
    // correctamente el periferico UART mediante:
    //
    // write_enable
    // addr = 00
    // wdata
    //
    // Todavia no representa el pin fisico RsTx.
    // =========================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (
                dut.uart_write_enable &&
                dut.uart_addr == 2'b00
            ) begin

                ultimo_byte_tx =
                    dut.uart_wdata[7:0];

                cantidad_bytes_tx =
                    cantidad_bytes_tx + 1;

                $display(
                    "[UART BUS TX] Byte = '%c' (0x%h)",
                    dut.uart_wdata[7:0],
                    dut.uart_wdata[7:0]
                );

            end

        end

    end


    // =========================================================
    // TAREA VERIFICAR
    // =========================================================

    task verificar;

        input logic condicion;
        input [255:0] mensaje;

        begin

            if (condicion) begin

                $display(
                    "[OK]       %s",
                    mensaje
                );

            end

            else begin

                $display(
                    "[ERROR]    %s",
                    mensaje
                );

                errores = errores + 1;

            end

        end

    endtask


    // =========================================================
    // PRESIONAR BOTON
    //
    // Se mantiene la simulacion de una pulsacion humana.
    // El debouncer debe detectar el boton aunque permanezca
    // presionado mas tiempo.
    // =========================================================

    task presionar_boton;

        input integer numero_boton;

        begin

            $display("");
            $display(
                "[BOTON] Presionando boton %0d",
                numero_boton
            );

            botones[numero_boton] = 1'b1;

            #(TIEMPO_PRESION);

            $display(
                "[BOTON] Liberando boton %0d",
                numero_boton
            );

            botones[numero_boton] = 1'b0;

            #(TIEMPO_LIBERACION);

        end

    endtask


    // =========================================================
    // ESPERAR VALIDADOR EN LEER_CONTROL
    // =========================================================

    task esperar_uart_lista;

        integer contador;

        begin

            contador = 0;

            while (
                dut.validador_letra_inst.estado_actual != 4'd2
            ) begin

                @(posedge clk);

                contador = contador + 1;

                if (contador > 1000000) begin

                    $display(
                        "[ERROR] Timeout esperando LEER_CONTROL"
                    );

                    errores = errores + 1;

                    disable esperar_uart_lista;

                end

            end

        end

    endtask


    // =========================================================
    // SIMULAR RECEPCION DE BYTE
    //
    // IMPORTANTE:
    //
    // El UART actual todavia no tiene entrada serial fisica.
    // Por eso esta tarea representa el resultado final de una
    // recepcion UART:
    //
    //   serial -> UART -> registro_rx
    //                     rx_recibido = 1
    //
    // Cuando implementemos el receptor de 115200 baudios
    // esta parte sera reemplazada por la estimulacion de
    // RsRx.
    // =========================================================

    task enviar_uart;

        input [7:0] dato;

        begin

            $display("");
            $display(
                "[UART RX] Simulando byte recibido '%c' (0x%h)",
                dato,
                dato
            );


            // -------------------------------------------------
            // Esperar a que Validador_Letra este consultando
            // el registro de control del UART.
            // -------------------------------------------------

            esperar_uart_lista;


            // -------------------------------------------------
            // Simular byte recibido por el UART.
            //
            // El dato se coloca en registro_rx y se activa
            // rx_recibido.
            // -------------------------------------------------

            force dut.uart_inst.registro_rx =
                {24'b0, dato};

            force dut.uart_inst.rx_recibido =
                1'b1;


            // Mantener la condicion de RX durante un ciclo.
            @(posedge clk);


            // Liberar las fuerzas.
            release dut.uart_inst.registro_rx;
            release dut.uart_inst.rx_recibido;


            // -------------------------------------------------
            // Dar tiempo al Validador_Letra para:
            //
            // LEER_DATO
            // VALIDAR
            // ACTUALIZAR
            // LIMPIAR_RX
            //
            // -------------------------------------------------

            repeat (500)
                @(posedge clk);


            // -------------------------------------------------
            // Verificar que Validador_Letra limpio RX.
            // -------------------------------------------------

            if (dut.uart_inst.rx_recibido !== 1'b0) begin

                $display(
                    "[ERROR] RX no fue limpiado despues de '%c'",
                    dato
                );

                errores = errores + 1;

            end

            else begin

                $display(
                    "[OK] RX limpiado despues de '%c'",
                    dato
                );

            end

        end

    endtask


    // =========================================================
    // ESPERAR PROCESAMIENTO
    // =========================================================

    task esperar_procesamiento;

        integer i;

        begin

            for (
                i = 0;
                i < TIEMPO_PROCESAMIENTO;
                i = i + 1
            ) begin

                @(posedge clk);

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

                0: obtener_letra = palabra[63:56];
                1: obtener_letra = palabra[55:48];
                2: obtener_letra = palabra[47:40];
                3: obtener_letra = palabra[39:32];
                4: obtener_letra = palabra[31:24];
                5: obtener_letra = palabra[23:16];
                6: obtener_letra = palabra[15:8];
                7: obtener_letra = palabra[7:0];

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
    // ENVIAR TODAS LAS LETRAS CORRECTAS
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
                        "[INFO] Enviando letra correcta: %c",
                        letra_actual
                    );

                    enviar_uart(letra_actual);

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

                if (cantidad_incorrectas < 6) begin

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
                            "[INFO] Letra incorrecta %0d = %c",
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
    // MOSTRAR ESTADO UART
    // =========================================================

    task mostrar_estado_uart;

        begin

            $display("");
            $display(
                "*************** ESTADO UART ***************"
            );

            $display(
                "[UART] registro_tx = %h",
                dut.uart_inst.registro_tx
            );

            $display(
                "[UART] registro_rx = %h",
                dut.uart_inst.registro_rx
            );

            $display(
                "[UART] tx_pendiente = %b",
                dut.uart_inst.tx_pendiente
            );

            $display(
                "[UART] rx_recibido = %b",
                dut.uart_inst.rx_recibido
            );

            $display(
                "[UART] Bytes TX por bus = %0d",
                cantidad_bytes_tx
            );

            $display(
                "********************************************"
            );

        end

    endtask


    // =========================================================
    // PROGRAMA PRINCIPAL
    // =========================================================

    initial begin

        errores = 0;
        pruebas = 0;

        cantidad_bytes_tx = 0;
        ultimo_byte_tx = 8'h00;

        rst = 1'b1;
        botones = 2'b00;


        // =====================================================
        // RESET
        // =====================================================

        #100ns;

        rst = 1'b0;

        #100ns;


        // =====================================================
        // PRUEBA 1
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 1: ESTADO INICIAL"
        );
        $display(
            "----------------------------------------------------"
        );

        verificar(
            dut.estado_actual == 2'b00,
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


        // =====================================================
        // PRUEBA 2
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 2: CAMBIO DE DIFICULTAD"
        );
        $display(
            "----------------------------------------------------"
        );

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
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 3: INICIAR PARTIDA"
        );
        $display(
            "----------------------------------------------------"
        );

        presionar_boton(1);

        verificar(
            dut.estado_actual == 2'b01,
            "Partida llega a JUGANDO"
        );

        verificar(
            dut.partida_iniciada == 1'b0,
            "partida_iniciada vuelve a 0"
        );

        esperar_procesamiento;

        verificar(
            dut.estado_actual == 2'b01,
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
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 4: PALABRA SELECCIONADA Y ESTADO INICIAL"
        );
        $display(
            "----------------------------------------------------"
        );

        palabra_prueba =
            dut.palabra_actual;

        cantidad_prueba =
            dut.cantidad_letras;

        $display(
            "[INFO] Palabra seleccionada = %s",
            palabra_prueba
        );

        $display(
            "[INFO] Palabra HEX = %h",
            palabra_prueba
        );

        $display(
            "[INFO] Estado HEX = %h",
            dut.palabra_estado
        );

        $display(
            "[INFO] Cantidad letras = %0d",
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
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 5: LCD"
        );
        $display(
            "----------------------------------------------------"
        );

        #100ms;

        verificar(
            dut.controlador_lcd_inst
               .lcd_periferico
               .inicializado == 1'b1,
            "LCD termino inicializacion"
        );


        // =====================================================
        // PRUEBA 6
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 6: LETRA INCORRECTA"
        );
        $display(
            "----------------------------------------------------"
        );

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

        $display(
            "[DEBUG] Fallos = %0d",
            fallos_antes
        );

        verificar(
            fallos_antes == 1,
            "Letra incorrecta aumenta fallos a 1"
        );

        verificar(
            dut.estado_actual == 2'b01,
            "FSM permanece JUGANDO"
        );


        // =====================================================
        // PRUEBA 7
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 7: LETRA REPETIDA"
        );
        $display(
            "----------------------------------------------------"
        );

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
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 8: LETRAS CORRECTAS"
        );
        $display(
            "----------------------------------------------------"
        );

        enviar_letras_palabra;

        esperar_procesamiento;

        $display(
            "[DEBUG] palabra_estado = %h",
            dut.palabra_estado
        );


        // =====================================================
        // PRUEBA 9
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 9: VICTORIA"
        );
        $display(
            "----------------------------------------------------"
        );

        esperar_procesamiento;

        verificar(
            dut.estado_actual == 2'b10,
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

        verificar(
            dut.palabra_lcd ==
            dut.palabra_estado,
            "palabra_lcd coincide con palabra_estado"
        );


        // =====================================================
        // PRUEBA 10
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 10: LCD DESPUES DE VICTORIA"
        );
        $display(
            "----------------------------------------------------"
        );

        verificar(
            dut.controlador_lcd_inst
               .lcd_periferico
               .inicializado == 1'b1,
            "LCD permanece inicializado"
        );


        // =====================================================
        // PRUEBA 11
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 11: ESTADO FINAL"
        );
        $display(
            "----------------------------------------------------"
        );

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
            dut.estado_actual == 2'b10,
            "FSM permanece en FINALIZADO"
        );


        // =====================================================
        // PRUEBA 12
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 12: SALIDAS"
        );
        $display(
            "----------------------------------------------------"
        );

        verificar(
            segmentos !== 7'bx,
            "Segmentos tienen valor valido"
        );

        verificar(
            anodos !== 3'bx,
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
        // PRUEBA 13
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 13: NUEVA PARTIDA"
        );
        $display(
            "----------------------------------------------------"
        );

        presionar_boton(1);

        verificar(
            dut.estado_actual == 2'b01,
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

        esperar_procesamiento;


        // =====================================================
        // PRUEBA 14
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 14: SEGUNDA PARTIDA"
        );
        $display(
            "----------------------------------------------------"
        );

        palabra_prueba =
            dut.palabra_actual;

        cantidad_prueba =
            dut.cantidad_letras;

        $display(
            "[INFO] Segunda palabra = %s",
            palabra_prueba
        );

        $display(
            "[INFO] Segunda palabra HEX = %h",
            palabra_prueba
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


        // =====================================================
        // PRUEBA 15
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 15: SEIS LETRAS INCORRECTAS"
        );
        $display(
            "----------------------------------------------------"
        );

        preparar_letras_incorrectas;

        verificar(
            cantidad_incorrectas == 6,
            "Se encontraron seis letras incorrectas"
        );

        enviar_uart(letras_incorrectas[0]);
        esperar_procesamiento;

        enviar_uart(letras_incorrectas[1]);
        esperar_procesamiento;

        enviar_uart(letras_incorrectas[2]);
        esperar_procesamiento;

        enviar_uart(letras_incorrectas[3]);
        esperar_procesamiento;

        enviar_uart(letras_incorrectas[4]);
        esperar_procesamiento;

        enviar_uart(letras_incorrectas[5]);
        esperar_procesamiento;


        $display(
            "[DEBUG] fallos = %0d",
            dut.fallos
        );

        $display(
            "[DEBUG] estado = %b",
            dut.estado_actual
        );

        verificar(
            dut.fallos == 5'd6,
            "Contador llega a 6"
        );

        verificar(
            dut.estado_actual == 2'b10,
            "FSM pasa a FINALIZADO"
        );


        // =====================================================
        // PRUEBA 16
        // =====================================================

        pruebas = pruebas + 1;

        $display("");
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 16: DERROTA"
        );
        $display(
            "----------------------------------------------------"
        );

        verificar(
            dut.estado_actual == 2'b10,
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
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 17: UART DESPUES DE DERROTA"
        );
        $display(
            "----------------------------------------------------"
        );

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
            dut.estado_actual == 2'b10,
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
        $display(
            "----------------------------------------------------"
        );
        $display(
            "PRUEBA 18: RESET FINAL"
        );
        $display(
            "----------------------------------------------------"
        );

        rst = 1'b1;

        #(100ns);

        verificar(
            dut.estado_actual == 2'b00,
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
        // ESTADO UART
        // =====================================================

        mostrar_estado_uart;


        // =====================================================
        // RESULTADO FINAL
        // =====================================================

        $display("");
        $display(
            "===================================================="
        );

        $display(
            "             FIN DE PRUEBAS AHORCADO"
        );

        $display(
            "===================================================="
        );

        $display("");

        $display(
            "Pruebas ejecutadas : %0d",
            pruebas
        );

        $display(
            "Errores encontrados: %0d",
            errores
        );

        $display(
            "Bytes escritos al TX por bus: %0d",
            cantidad_bytes_tx
        );


        if (errores == 0) begin

            $display("");
            $display(
                "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            );
            $display(
                "!                                                  !"
            );
            $display(
                "!       TODAS LAS PRUEBAS PASARON                 !"
            );
            $display(
                "!                                                  !"
            );
            $display(
                "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            );

        end

        else begin

            $display("");
            $display(
                "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            );
            $display(
                "!                                                  !"
            );
            $display(
                "!       SE ENCONTRARON %0d ERRORES                 !",
                errores
            );
            $display(
                "!                                                  !"
            );
            $display(
                "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            );

        end


        // =====================================================
        // ESTADO INTERNO
        // =====================================================

        $display("");

        $display(
            "**************** ESTADO INTERNO ****************"
        );

        $display(
            "[DEBUG] FSM estado_actual = %b",
            dut.estado_actual
        );

        $display(
            "[DEBUG] dificultad = %b",
            dut.dificultad
        );

        $display(
            "[DEBUG] partida_iniciada = %b",
            dut.partida_iniciada
        );

        $display(
            "[DEBUG] palabra_actual = %h",
            dut.palabra_actual
        );

        $display(
            "[DEBUG] palabra_estado = %h",
            dut.palabra_estado
        );

        $display(
            "[DEBUG] cantidad_letras = %0d",
            dut.cantidad_letras
        );

        $display(
            "[DEBUG] fallos = %0d",
            dut.fallos
        );

        $display(
            "[DEBUG] victoria = %b",
            dut.victoria
        );

        $display(
            "[DEBUG] derrota = %b",
            dut.derrota
        );

        $display(
            "[DEBUG] tiempo_agotado = %b",
            dut.tiempo_agotado
        );

        $display(
            "[DEBUG] mostrar_guiones = %b",
            dut.mostrar_guiones
        );

        $display(
            "[DEBUG] UART TX = %h",
            dut.uart_inst.registro_tx
        );

        $display(
            "[DEBUG] UART RX = %h",
            dut.uart_inst.registro_rx
        );

        $display(
            "************************************************"
        );


        $finish;

    end

endmodule