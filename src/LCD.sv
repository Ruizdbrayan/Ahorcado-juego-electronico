module LCD #(
    parameter integer FRECUENCIA_RELOJ = 100_000_000
)(

    input logic        clk,
    input logic        rst,

    // ============================================================
    // BUS ESTANDAR
    // ============================================================

    input logic        wenable,
    input logic [1:0]  addr,
    input logic [31:0] wdata,

    output logic [31:0] rdata,

    // ============================================================
    // LCD FISICO
    // ============================================================

    output logic       lcd_rs,
    output logic       lcd_en,
    output logic [3:0] lcd_datos

);


    // ============================================================
    // DIRECCIONES
    // ============================================================

    localparam logic [1:0]
        LCD_DATOS   = 2'b00,
        LCD_COMANDO = 2'b01;


    // ============================================================
    // TIEMPOS
    // ============================================================

    localparam integer CICLOS_1US =
        FRECUENCIA_RELOJ / 1_000_000;

    localparam integer CICLOS_50US =
        FRECUENCIA_RELOJ / 20_000;

    localparam integer CICLOS_100US =
        FRECUENCIA_RELOJ / 10_000;

    localparam integer CICLOS_150US =
        (FRECUENCIA_RELOJ * 150) / 1_000_000;

    localparam integer CICLOS_2MS =
        FRECUENCIA_RELOJ / 500;

    localparam integer CICLOS_5MS =
        FRECUENCIA_RELOJ / 200;

    localparam integer CICLOS_20MS =
        FRECUENCIA_RELOJ / 50;


    // ============================================================
    // ESTADOS
    // ============================================================

    localparam logic [3:0]

        ESPERA_POWER   = 4'd0,

        INIT_SETUP     = 4'd1,
        INIT_EN_ALTO   = 4'd2,
        INIT_EN_BAJO   = 4'd3,
        INIT_ESPERA    = 4'd4,

        ESCRITURA_SETUP_ALTO = 4'd5,
        ESCRITURA_EN_ALTO   = 4'd6,
        ESCRITURA_EN_BAJO   = 4'd7,

        ESCRITURA_SETUP_BAJO = 4'd8,
        ESCRITURA_EN_ALTO2   = 4'd9,
        ESCRITURA_EN_BAJO2   = 4'd10,

        ESPERA_COMANDO = 4'd11,
        LISTO           = 4'd12;


    logic [3:0] estado;


    // ============================================================
    // CONTADORES
    // ============================================================

    logic [31:0] contador;


    // ============================================================
    // DATOS ACTUALES
    // ============================================================

    logic       rs_actual;

    logic [7:0] dato_actual;

    logic [3:0] nibble_init;

    logic [2:0] paso_init;


    // ============================================================
    // INDICE DE COMANDOS DE INICIALIZACION
    //
    // 0 -> 28
    // 1 -> 0C
    // 2 -> 06
    // 3 -> 01
    // ============================================================

    logic [1:0] indice_init_comando;


    // ============================================================
    // BUSY
    // ============================================================

    always_comb begin

        rdata = 32'd0;

        if (estado != LISTO)
            rdata[0] = 1'b1;

        else
            rdata[0] = 1'b0;

    end


    // ============================================================
    // FSM LCD
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            estado <= ESPERA_POWER;

            contador <= 32'd0;

            rs_actual <= 1'b0;

            dato_actual <= 8'h00;

            nibble_init <= 4'h0;

            paso_init <= 3'd0;

            indice_init_comando <= 2'd0;

        end

        else begin

            case (estado)


                // =================================================
                // ESPERA POWER-ON
                // =================================================

                ESPERA_POWER: begin

                    if (contador >= CICLOS_20MS - 1) begin

                        contador <= 32'd0;

                        paso_init <= 3'd0;

                        nibble_init <= 4'h3;

                        estado <= INIT_SETUP;

                    end

                    else begin

                        contador <= contador + 1'b1;

                    end

                end


                // =================================================
                // INIT SETUP
                // =================================================

                INIT_SETUP: begin

                    contador <= 32'd0;

                    estado <= INIT_EN_ALTO;

                end


                // =================================================
                // ENABLE ALTO
                // =================================================

                INIT_EN_ALTO: begin

                    if (contador >= CICLOS_1US - 1) begin

                        contador <= 32'd0;

                        estado <= INIT_EN_BAJO;

                    end

                    else begin

                        contador <= contador + 1'b1;

                    end

                end


                // =================================================
                // ENABLE BAJO
                // =================================================

                INIT_EN_BAJO: begin

                    contador <= 32'd0;

                    estado <= INIT_ESPERA;

                end


                // =================================================
                // ESPERA ENTRE NIBBLES DE INIT
                // =================================================

                INIT_ESPERA: begin

                    // Primer 0x3 necesita >4.1 ms
                    if (paso_init == 3'd0) begin

                        if (contador >= CICLOS_5MS - 1) begin

                            contador <= 32'd0;

                            paso_init <= 3'd1;

                            nibble_init <= 4'h3;

                            estado <= INIT_SETUP;

                        end

                        else begin

                            contador <= contador + 1'b1;

                        end

                    end

                    // Segundo 0x3
                    else if (paso_init == 3'd1) begin

                        if (contador >= CICLOS_150US - 1) begin

                            contador <= 32'd0;

                            paso_init <= 3'd2;

                            nibble_init <= 4'h3;

                            estado <= INIT_SETUP;

                        end

                        else begin

                            contador <= contador + 1'b1;

                        end

                    end

                    // Tercer 0x3
                    else if (paso_init == 3'd2) begin

                        if (contador >= CICLOS_150US - 1) begin

                            contador <= 32'd0;

                            paso_init <= 3'd3;

                            nibble_init <= 4'h2;

                            estado <= INIT_SETUP;

                        end

                        else begin

                            contador <= contador + 1'b1;

                        end

                    end

                    // 0x2 termina la entrada a 4 bits
                    else begin

                        if (contador >= CICLOS_150US - 1) begin

                            contador <= 32'd0;

                            dato_actual <= 8'h28;

                            rs_actual <= 1'b0;

                            indice_init_comando <= 2'd0;

                            estado <= ESCRITURA_SETUP_ALTO;

                        end

                        else begin

                            contador <= contador + 1'b1;

                        end

                    end

                end


                // =================================================
                // BYTE - HIGH NIBBLE SETUP
                // =================================================

                ESCRITURA_SETUP_ALTO: begin

                    contador <= 32'd0;

                    estado <= ESCRITURA_EN_ALTO;

                end


                // =================================================
                // BYTE - HIGH NIBBLE ENABLE
                // =================================================

                ESCRITURA_EN_ALTO: begin

                    if (contador >= CICLOS_1US - 1) begin

                        contador <= 32'd0;

                        estado <= ESCRITURA_EN_BAJO;

                    end

                    else begin

                        contador <= contador + 1'b1;

                    end

                end


                // =================================================
                // BYTE - HIGH NIBBLE ENABLE BAJO
                // =================================================

                ESCRITURA_EN_BAJO: begin

                    contador <= 32'd0;

                    estado <= ESCRITURA_SETUP_BAJO;

                end


                // =================================================
                // BYTE - LOW NIBBLE SETUP
                // =================================================

                ESCRITURA_SETUP_BAJO: begin

                    contador <= 32'd0;

                    estado <= ESCRITURA_EN_ALTO2;

                end


                // =================================================
                // BYTE - LOW NIBBLE ENABLE
                // =================================================

                ESCRITURA_EN_ALTO2: begin

                    if (contador >= CICLOS_1US - 1) begin

                        contador <= 32'd0;

                        estado <= ESCRITURA_EN_BAJO2;

                    end

                    else begin

                        contador <= contador + 1'b1;

                    end

                end


                // =================================================
                // BYTE - LOW NIBBLE ENABLE BAJO
                // =================================================

                ESCRITURA_EN_BAJO2: begin

                    contador <= 32'd0;

                    estado <= ESPERA_COMANDO;

                end


                // =================================================
                // ESPERA POST-COMANDO
                // =================================================

                ESPERA_COMANDO: begin

                    // Durante la inicialización usamos 2 ms
                    // para todos los comandos.
                    //
                    // Es seguro aunque algunos comandos
                    // necesiten mucho menos tiempo.

                    if (contador >= CICLOS_2MS - 1) begin

                        contador <= 32'd0;

                        if (indice_init_comando == 2'd0) begin

                            // 28 -> 0C

                            dato_actual <= 8'h0C;

                            indice_init_comando <= 2'd1;

                            estado <= ESCRITURA_SETUP_ALTO;

                        end

                        else if (indice_init_comando == 2'd1) begin

                            // 0C -> 06

                            dato_actual <= 8'h06;

                            indice_init_comando <= 2'd2;

                            estado <= ESCRITURA_SETUP_ALTO;

                        end

                        else if (indice_init_comando == 2'd2) begin

                            // 06 -> 01

                            dato_actual <= 8'h01;

                            indice_init_comando <= 2'd3;

                            estado <= ESCRITURA_SETUP_ALTO;

                        end

                        else begin

                            // LCD inicializado

                            estado <= LISTO;

                        end

                    end

                    else begin

                        contador <= contador + 1'b1;

                    end

                end


                // =================================================
                // LISTO
                // =================================================

                LISTO: begin

                    contador <= 32'd0;

                    if (wenable) begin

                        if (addr == LCD_DATOS) begin

                            rs_actual <= 1'b1;

                            dato_actual <= wdata[7:0];

                            estado <= ESCRITURA_SETUP_ALTO;

                        end

                        else if (addr == LCD_COMANDO) begin

                            rs_actual <= 1'b0;

                            dato_actual <= wdata[7:0];

                            estado <= ESCRITURA_SETUP_ALTO;

                        end

                    end

                end


                default: begin

                    estado <= ESPERA_POWER;

                    contador <= 32'd0;

                end

            endcase

        end

    end


    // ============================================================
    // SALIDAS FISICAS
    // ============================================================

    always_comb begin

        lcd_rs = rs_actual;

        lcd_en = 1'b0;

        lcd_datos = 4'h0;


        case (estado)


            // =====================================================
            // INIT
            // =====================================================

            INIT_SETUP,
            INIT_EN_ALTO,
            INIT_EN_BAJO: begin

                lcd_rs = 1'b0;

                lcd_datos = nibble_init;

            end


            // =====================================================
            // ENABLE DEL INIT
            // =====================================================

            INIT_EN_ALTO: begin

                lcd_rs = 1'b0;

                lcd_datos = nibble_init;

                lcd_en = 1'b1;

            end


            // =====================================================
            // BYTE - HIGH NIBBLE
            // =====================================================

            ESCRITURA_SETUP_ALTO: begin

                lcd_rs = rs_actual;

                lcd_datos = dato_actual[7:4];

                lcd_en = 1'b0;

            end


            ESCRITURA_EN_ALTO: begin

                lcd_rs = rs_actual;

                lcd_datos = dato_actual[7:4];

                lcd_en = 1'b1;

            end


            ESCRITURA_EN_BAJO: begin

                lcd_rs = rs_actual;

                lcd_datos = dato_actual[7:4];

                lcd_en = 1'b0;

            end


            // =====================================================
            // BYTE - LOW NIBBLE
            // =====================================================

            ESCRITURA_SETUP_BAJO: begin

                lcd_rs = rs_actual;

                lcd_datos = dato_actual[3:0];

                lcd_en = 1'b0;

            end


            ESCRITURA_EN_ALTO2: begin

                lcd_rs = rs_actual;

                lcd_datos = dato_actual[3:0];

                lcd_en = 1'b1;

            end


            ESCRITURA_EN_BAJO2: begin

                lcd_rs = rs_actual;

                lcd_datos = dato_actual[3:0];

                lcd_en = 1'b0;

            end


            default: begin

                lcd_rs = rs_actual;

                lcd_datos = 4'h0;

                lcd_en = 1'b0;

            end

        endcase

    end

endmodule