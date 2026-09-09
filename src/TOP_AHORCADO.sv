module TOP_AHORCADO (

    // ============================================================
    // RELOJ Y RESET
    // ============================================================

    input logic clk,
    input logic rst,

    // ============================================================
    // BOTONES
    // ============================================================

    input logic [1:0] botones,

    // ============================================================
    // UART FISICO
    // ============================================================

    input logic RsRx,
    output logic RsTx,

    // ============================================================
    // SALIDAS
    // ============================================================

    output logic [6:0] segmentos,
    output logic [7:0] anodos,

    output logic buzzer,

    output logic [2:0] leds,

    // ============================================================
    // LCD FISICO
    // ============================================================

    output logic lcd_rs,
    output logic lcd_en,
    output logic [3:0] lcd_datos

);

    // ============================================================
    // DEBOUNCER
    // ============================================================

    logic [1:0] botones_estables;

    // ============================================================
    // DIFICULTAD
    // ============================================================

    logic dificultad;
    logic partida_iniciada;

    // ============================================================
    // PALABRA
    // ============================================================

    logic [63:0] palabra_actual;
    logic [3:0] cantidad_letras;

    // ============================================================
    // ESTADO DEL JUEGO
    // ============================================================

    logic [1:0] estado_actual;

    logic partida_activa;

    logic victoria;
    logic derrota;

    logic letra_correcta;
    logic letra_incorrecta;
    logic letra_repetida;

    logic palabra_completa;

    logic mostrar_guiones;

    logic [63:0] palabra_estado;

    logic [4:0] fallos;

    // ============================================================
    // FSM
    // ============================================================

    logic inicializar_partida;
    logic procesar_letra;
    logic consumir_letra;

    // ============================================================
    // EVENTOS UART
    // ============================================================

    logic enviar_inicio;
    logic enviar_resultado;
    logic enviar_final;

    // ============================================================
    // RX UART
    // ============================================================

    logic letra_disponible;
    logic [7:0] letra_uart;

    // ============================================================
    // BUS UART
    // ============================================================

    logic uart_write_enable;
    logic [1:0] uart_addr;
    logic [31:0] uart_wdata;
    logic [31:0] uart_rdata;

    // ============================================================
    // BUS LCD
    // ============================================================

    logic lcd_write_enable;
    logic [1:0] lcd_addr;
    logic [31:0] lcd_wdata;
    logic [31:0] lcd_rdata;

    // ============================================================
    // MEMORIA
    // ============================================================

    logic [8:0] direccion_lcd_memoria;
    logic [7:0] dato_lcd_memoria;

    logic [8:0] direccion_uart_memoria;
    logic [7:0] dato_uart_memoria;

    // ============================================================
    // TEMPORIZADOR
    // ============================================================

    logic [3:0] unidades;
    logic [3:0] decenas;
    logic [3:0] centenas;

    logic tiempo_agotado;

    // ============================================================
    // DEBOUNCER
    // ============================================================

    Debouncer debouncer_inst (

        .clk            (clk),
        .rst            (rst),

        .botones        (botones),
        .estado_botones (botones_estables)

    );

    // ============================================================
    // SELECTOR DE DIFICULTAD
    // ============================================================

    Selector_dificultad selector_dificultad_inst (

        .clk              (clk),
        .rst              (rst),

        .seleccionar      (botones_estables[0]),
        .aceptar          (botones_estables[1]),

        .dificultad       (dificultad),
        .partida_iniciada (partida_iniciada)

    );

    // ============================================================
    // SELECTOR DE PALABRA
    // ============================================================

    Selector_palabra selector_palabra_inst (

        .clk             (clk),
        .rst             (rst),

        .partida_iniciada(partida_iniciada),
        .dificultad      (dificultad),

        .palabra_actual  (palabra_actual),
        .cantidad_letras (cantidad_letras)

    );

    // ============================================================
    // PARTIDA ACTIVA
    // ============================================================

    assign partida_activa =
        (estado_actual == 2'b01);

    // ============================================================
    // TEMPORIZADOR
    // ============================================================

    Temporizador temporizador_inst (

        .clk            (clk),
        .rst            (rst),

        .partida_activa (partida_activa),
        .dificultad     (dificultad),

        .victoria       (victoria),
        .derrota        (derrota),

        .unidades       (unidades),
        .decenas        (decenas),
        .centenas        (centenas),

        .timeout        (tiempo_agotado)

    );

    // ============================================================
    // SIETE SEGMENTOS
    // ============================================================

    siete_segmentos siete_segmentos_inst (

        .clk            (clk),
        .rst            (rst),

        .unidades       (unidades),
        .decenas        (decenas),
        .centenas       (centenas),

        .mostrar_guiones(mostrar_guiones),

        .segmentos      (segmentos),
        .anodos         (anodos)

    );

    // ============================================================
    // FSM PRINCIPAL
    // ============================================================

    FSM fsm_inst (

        .clk                 (clk),
        .rst                 (rst),

        .partida_iniciada    (partida_iniciada),

        .letra_disponible    (letra_disponible),

        .palabra_completa    (palabra_completa),

        .fallos              (fallos),

        .tiempo_agotado      (tiempo_agotado),

        .inicializar_partida (inicializar_partida),
        .procesar_letra      (procesar_letra),

        .consumir_letra      (consumir_letra),

        .enviar_inicio       (enviar_inicio),
        .enviar_resultado    (enviar_resultado),
        .enviar_final        (enviar_final),

        .estado_actual       (estado_actual),

        .victoria            (victoria),
        .derrota             (derrota),

        .mostrar_guiones     (mostrar_guiones),

        .palabra_lcd         ()

    );

    // ============================================================
    // CONTROLADOR UART
    // ============================================================

    Controlador_UART controlador_uart_inst (

        .clk               (clk),
        .rst               (rst),

        .partida_activa    (partida_activa),

        .enviar_inicio     (enviar_inicio),
        .enviar_resultado  (enviar_resultado),
        .enviar_final      (enviar_final),

        .dificultad        (dificultad),

        .cantidad_letras   (cantidad_letras),

        .letra_recibida    (letra_uart),

        .letra_correcta    (letra_correcta),
        .letra_incorrecta  (letra_incorrecta),
        .letra_repetida    (letra_repetida),

        .palabra_estado    (palabra_estado),
        .palabra_actual    (palabra_actual),

        .fallos            (fallos),

        .victoria          (victoria),
        .derrota           (derrota),

        .letra_disponible  (letra_disponible),
        .letra_uart        (letra_uart),

        .consumir_letra    (consumir_letra),

        .direccion_memoria (direccion_uart_memoria),
        .dato_memoria      (dato_uart_memoria),

        .write_enable      (uart_write_enable),
        .addr              (uart_addr),
        .wdata             (uart_wdata),

        .rdata             (uart_rdata)

    );

    // ============================================================
    // UART
    // ============================================================

    UART #(

        .FRECUENCIA_RELOJ(100_000_000),
        .BAUDRATE        (115_200)

    ) uart_inst (

        .clk          (clk),
        .rst          (rst),

        .write_enable (uart_write_enable),
        .addr         (uart_addr),
        .wdata        (uart_wdata),
        .rdata        (uart_rdata),

        .rx_fisico    (RsRx),
        .tx_fisico    (RsTx)

    );

    // ============================================================
    // VALIDADOR DE LETRA
    // ============================================================

    Validador_Letra validador_letra_inst (

        .clk                 (clk),
        .rst                 (rst),

        .inicializar_partida (inicializar_partida),
        .procesar_letra      (procesar_letra),

        .palabra_actual      (palabra_actual),
        .cantidad_letras     (cantidad_letras),

        .letra_recibida      (letra_uart),

        .palabra_estado      (palabra_estado),

        .fallos              (fallos),

        .letra_correcta      (letra_correcta),
        .letra_incorrecta    (letra_incorrecta),
        .letra_repetida      (letra_repetida),

        .palabra_completa    (palabra_completa)

    );

    // ============================================================
    // LED
    // ============================================================

    LED_estado led_estado_inst (

        .clk           (clk),
        .rst           (rst),

        .estado_actual (estado_actual),

        .leds          (leds)

    );

    // ============================================================
    // BUZZER
    // ============================================================

    Buzzer buzzer_inst (

        .clk              (clk),
        .rst              (rst),

        .letra_correcta   (letra_correcta),
        .letra_incorrecta (letra_incorrecta),

        .victoria         (victoria),
        .derrota          (derrota),

        .buzzer           (buzzer)

    );

    // ============================================================
    // CONTROLADOR LCD
    // ============================================================

    Controlador_LCD controlador_lcd (

        .clk             (clk),
        .rst             (rst),

        .estado_actual   (estado_actual),
        .dificultad      (dificultad),

        .victoria        (victoria),
        .derrota         (derrota),

        .fallos          (fallos),

        .palabra_estado  (palabra_estado),
        .palabra_actual  (palabra_actual),

        .cantidad_letras (cantidad_letras),

        .direccion_memoria(direccion_lcd_memoria),
        .dato_memoria    (dato_lcd_memoria),

        .wenable         (lcd_write_enable),
        .addr            (lcd_addr),
        .wdata           (lcd_wdata),

        .rdata           (lcd_rdata)

    );

    // ============================================================
    // PERIFERICO LCD
    // ============================================================

    LCD #(

        .FRECUENCIA_RELOJ(100_000_000)

    ) periferico_lcd (

        .clk       (clk),
        .rst       (rst),

        .wenable   (lcd_write_enable),
        .addr      (lcd_addr),
        .wdata     (lcd_wdata),
        .rdata     (lcd_rdata),

        .lcd_rs    (lcd_rs),
        .lcd_en    (lcd_en),
        .lcd_datos (lcd_datos)

    );

    // ============================================================
    // MEMORIA COMPARTIDA
    // ============================================================

    Memoria memoria_inst (

        .dificultad       (dificultad),
        .indice_palabra   (5'd0),

        .palabra_actual   (),

        .direccion_lcd    (direccion_lcd_memoria),
        .dato_lcd         (dato_lcd_memoria),

        .direccion_uart   (direccion_uart_memoria),
        .dato_uart        (dato_uart_memoria)

    );

endmodule