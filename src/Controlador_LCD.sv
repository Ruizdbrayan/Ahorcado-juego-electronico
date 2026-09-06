module Controlador_LCD (

    input logic clk,
    input logic rst,

    input logic [63:0] palabra_lcd,

    output logic lcd_rs,
    output logic lcd_en,
    output logic [3:0] lcd_datos

);

    // ============================================================
    // BUS LCD
    // ============================================================

    logic        write_enable;
    logic [1:0]  addr;
    logic [31:0] wdata;
    logic [31:0] rdata;


    // ============================================================
    // DIRECCIONES
    // ============================================================

    localparam logic [1:0] ADDR_DATA     = 2'b00;
    localparam logic [1:0] ADDR_CONTROL  = 2'b01;
    localparam logic [1:0] ADDR_POSICION = 2'b10;
    localparam logic [1:0] ADDR_STATUS   = 2'b11;


    // ============================================================
    // ESTADOS
    // ============================================================

    typedef enum logic [3:0] {

        ESPERA_LCD,

        PREPARAR_POSICION,
        ESCRIBIR_POSICION,
        ESPERAR_POSICION,

        PREPARAR_DATO,
        ESCRIBIR_DATO,
        ESPERAR_DATO,

        TERMINADO

    } estado_t;

    estado_t estado;


    // ============================================================
    // REGISTROS
    // ============================================================

    logic [63:0] palabra_registro;

    logic [3:0] indice;


    // ============================================================
    // PERIFERICO LCD
    // ============================================================

    LCD lcd_periferico (

        .clk(clk),
        .rst(rst),

        .write_enable(write_enable),
        .addr(addr),
        .wdata(wdata),

        .rdata(rdata),

        .rs(lcd_rs),
        .en(lcd_en),
        .rw(),
        .datos(lcd_datos)

    );


    // ============================================================
    // MAQUINA DE CONTROL
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            estado <= ESPERA_LCD;

            palabra_registro <= 64'b0;

            indice <= 4'd0;

            write_enable <= 1'b0;
            addr <= ADDR_DATA;
            wdata <= 32'b0;

        end

        else begin

            // Por defecto no escribimos
            write_enable <= 1'b0;

            case (estado)

                // =================================================
                // ESPERAR INICIALIZACION
                // =================================================

                ESPERA_LCD: begin

                    if (rdata[1]) begin

                        if (palabra_lcd != palabra_registro) begin

                            palabra_registro <= palabra_lcd;

                            indice <= 0;

                            estado <= PREPARAR_POSICION;

                        end

                    end

                end


                // =================================================
                // PREPARAR POSICION
                // =================================================

                PREPARAR_POSICION: begin

                    addr <= ADDR_POSICION;

                    wdata <= 32'd0;

                    estado <= ESCRIBIR_POSICION;

                end


                // =================================================
                // ENVIAR POSICION
                // =================================================

                ESCRIBIR_POSICION: begin

                    write_enable <= 1'b1;

                    estado <= ESPERAR_POSICION;

                end


                // =================================================
                // ESPERAR POSICION
                // =================================================

                ESPERAR_POSICION: begin

                    if (!rdata[0]) begin

                        indice <= 0;

                        estado <= PREPARAR_DATO;

                    end

                end


                // =================================================
                // PREPARAR DATO
                // =================================================

                PREPARAR_DATO: begin

                    addr <= ADDR_DATA;

                    case (indice)

                        4'd0:
                            wdata <= {24'b0, palabra_registro[63:56]};

                        4'd1:
                            wdata <= {24'b0, palabra_registro[55:48]};

                        4'd2:
                            wdata <= {24'b0, palabra_registro[47:40]};

                        4'd3:
                            wdata <= {24'b0, palabra_registro[39:32]};

                        4'd4:
                            wdata <= {24'b0, palabra_registro[31:24]};

                        4'd5:
                            wdata <= {24'b0, palabra_registro[23:16]};

                        4'd6:
                            wdata <= {24'b0, palabra_registro[15:8]};

                        4'd7:
                            wdata <= {24'b0, palabra_registro[7:0]};

                        default:
                            wdata <= {24'b0, 8'h20};

                    endcase

                    estado <= ESCRIBIR_DATO;

                end


                // =================================================
                // ESCRIBIR DATO
                // =================================================

                ESCRIBIR_DATO: begin

                    write_enable <= 1'b1;

                    estado <= ESPERAR_DATO;

                end


                // =================================================
                // ESPERAR DATO
                // =================================================

                ESPERAR_DATO: begin

                    if (!rdata[0]) begin

                        if (indice == 7) begin

                            estado <= TERMINADO;

                        end

                        else begin

                            indice <= indice + 1;

                            estado <= PREPARAR_DATO;

                        end

                    end

                end


                // =================================================
                // TERMINADO
                // =================================================

                TERMINADO: begin

                    // Si la palabra cambia, se actualiza nuevamente.
                    if (palabra_lcd != palabra_registro) begin

                        palabra_registro <= palabra_lcd;

                        indice <= 0;

                        estado <= PREPARAR_POSICION;

                    end

                    else begin

                        estado <= TERMINADO;

                    end

                end


                default: begin

                    estado <= ESPERA_LCD;

                end

            endcase

        end

    end

endmodule