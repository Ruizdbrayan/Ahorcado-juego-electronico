module TOP_AHORCADO (

    input logic        clk,
    input logic        rst,

    input logic [1:0]  botones,

    // ============================================================
    // UART FISICO
    // ============================================================

    input logic        RsRx,
    output logic       RsTx,

    // ============================================================
    // SALIDAS
    // ============================================================

    output logic [6:0] segmentos,
    output logic [7:0] anodos,

    output logic       buzzer,

    output logic [2:0] leds,

    // ============================================================
    // LCD FISICO
    // ============================================================

    output logic       lcd_rs,
    output logic       lcd_en,
    output logic [3:0] lcd_datos

);

    // ============================================================
    // DEBOUNCER
    // ============================================================

    logic [1:0] botones_estables;

    Debouncer debouncer_inst (
        .clk            (clk),
        .rst            (rst),
        .botones        (botones),
        .estado_botones (botones_estables)
    );


    // ============================================================
    // SELECTOR DE DIFICULTAD
    // ============================================================

    logic dificultad;
    logic partida_iniciada;

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

    logic [63:0] palabra_actual;
    logic [3:0]  cantidad_letras;

    Selector_palabra selector_palabra_inst (
        .clk             (clk),
        .rst             (rst),
        .partida_iniciada(partida_iniciada),
        .dificultad      (dificultad),
        .palabra_actual  (palabra_actual),
        .cantidad_letras (cantidad_letras)
    );


    // ============================================================
    // SEÑALES DEL JUEGO
    // ============================================================

    logic [1:0] estado_actual;

    logic partida_activa;

    logic victoria;
    logic derrota;

    logic letra_correcta;
    logic letra_incorrecta;

    logic mostrar_guiones;

    logic [63:0] palabra_estado;
    logic [63:0] palabra_lcd;

    logic [4:0] fallos;


    // ============================================================
    // TEMPORIZADOR
    // ============================================================

    logic [3:0] unidades;
    logic [3:0] decenas;
    logic [3:0] centenas;

    logic tiempo_agotado;

    Temporizador temporizador_inst (
        .clk            (clk),
        .rst            (rst),
        .partida_activa (partida_activa),
        .dificultad     (dificultad),
        .victoria       (victoria),
        .derrota        (derrota),
        .unidades       (unidades),
        .decenas        (decenas),
        .centenas       (centenas),
        .timeout        (tiempo_agotado)
    );


    // ============================================================
    // SIETE SEGMENTOS
    // ============================================================

    siete_segmentos siete_segmentos_inst (
        .clk            (clk),
        .rst            (rst),
        .unidades       (unidades),
        .decenas         (decenas),
        .centenas        (centenas),
        .mostrar_guiones(mostrar_guiones),
        .segmentos      (segmentos),
        .anodos         (anodos)
    );


    // ============================================================
    // FSM PRINCIPAL
    // ============================================================

    FSM fsm_inst (
        .clk              (clk),
        .rst              (rst),

        .partida_iniciada (partida_iniciada),

        .palabra_estado   (palabra_estado),
        .cantidad_letras  (cantidad_letras),

        .fallos           (fallos),

        .tiempo_agotado   (tiempo_agotado),

        .estado_actual    (estado_actual),

        .victoria         (victoria),
        .derrota          (derrota),

        .mostrar_guiones  (mostrar_guiones),

        .palabra_lcd      (palabra_lcd)
    );


    // ============================================================
    // PARTIDA ACTIVA
    // ============================================================

    assign partida_activa = (estado_actual == 2'b01);


    // ============================================================
    // BUS UART
    // ============================================================

    logic        uart_write_enable;
    logic [1:0]  uart_addr;
    logic [31:0] uart_wdata;
    logic [31:0] uart_rdata;


    // ============================================================
    // UART
    // ============================================================

    UART uart_inst (
        .clk          (clk),
        .rst          (rst),

        .write_enable (uart_write_enable),
        .addr         (uart_addr),
        .wdata        (uart_wdata),

        .rdata        (uart_rdata)
    );


    // ============================================================
    // VALIDADOR DE LETRA
    // ============================================================

    Validador_Letra validador_letra_inst (
        .clk              (clk),
        .rst              (rst),

        .partida_iniciada (partida_iniciada),
        .partida_activa   (partida_activa),

        .palabra_actual   (palabra_actual),
        .cantidad_letras  (cantidad_letras),

        .dificultad       (dificultad),

        .tiempo_agotado   (tiempo_agotado),

        .rdata            (uart_rdata),

        .rx_fisico        (RsRx),
        .tx_fisico        (RsTx),

        .write_enable     (uart_write_enable),
        .addr             (uart_addr),
        .wdata            (uart_wdata),

        .palabra_estado   (palabra_estado),

        .fallos           (fallos),

        .letra_correcta   (letra_correcta),
        .letra_incorrecta(letra_incorrecta)
    );


    // ============================================================
    // LED DE ESTADO
    // ============================================================

    LED_estado led_estado_inst (
        .clk          (clk),
        .rst          (rst),
        .estado_actual(estado_actual),
        .leds         (leds)
    );


    // ============================================================
    // BUZZER
    // ============================================================

    Buzzer buzzer_inst (
        .clk              (clk),
        .rst              (rst),
        .letra_correcta   (letra_correcta),
        .letra_incorrecta(letra_incorrecta),
        .victoria         (victoria),
        .derrota          (derrota),
        .buzzer           (buzzer)
    );


    // ============================================================
    // BUS DEL PERIFERICO LCD
    // ============================================================

    logic        lcd_write_enable;
    logic [1:0]  lcd_addr;
    logic [31:0] lcd_wdata;
    logic [31:0] lcd_rdata;


    // ============================================================
    // CONTROLADOR LCD
    // ============================================================

    Controlador_LCD controlador_lcd (
        .clk             (clk),
        .rst             (rst),

        .estado_actual   (estado_actual),
        .dificultad      (dificultad),

        .derrota         (derrota),
        .victoria        (victoria),
        .fallos          (fallos),

        .palabra_estado  (palabra_estado),
        .palabra_actual  (palabra_actual),
        .cantidad_letras (cantidad_letras),

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
        .addr       (lcd_addr),
        .wdata      (lcd_wdata),
        .rdata      (lcd_rdata),

        .lcd_rs    (lcd_rs),
        .lcd_en    (lcd_en),
        .lcd_datos (lcd_datos)
    );

endmodule