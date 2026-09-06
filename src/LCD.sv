module LCD #(
    parameter integer FRECUENCIA_RELOJ = 100_000_000
)(
    input  logic        clk,
    input  logic        rst,

    input  logic        write_enable,
    input  logic [1:0]  addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,

    output logic        rs,
    output logic        en,
    output logic        rw,
    output logic [3:0]  datos
);

    // ============================================================
    // DIRECCIONES
    // ============================================================

    localparam logic [1:0] ADDR_DATA     = 2'b00;
    localparam logic [1:0] ADDR_CONTROL  = 2'b01;
    localparam logic [1:0] ADDR_POSICION = 2'b10;
    localparam logic [1:0] ADDR_STATUS   = 2'b11;


    // ============================================================
    // COMANDOS LCD
    // ============================================================

    localparam logic [7:0] CMD_CLEAR      = 8'h01;
    localparam logic [7:0] CMD_DISPLAY_ON = 8'h0C;
    localparam logic [7:0] CMD_FUNCTION   = 8'h28;
    localparam logic [7:0] CMD_ENTRY_MODE = 8'h06;


    // ============================================================
    // TIEMPOS
    // ============================================================

    localparam integer CICLOS_40MS =
        FRECUENCIA_RELOJ / 25;

    localparam integer CICLOS_5MS =
        FRECUENCIA_RELOJ / 200;

    localparam integer CICLOS_2MS =
        FRECUENCIA_RELOJ / 500;

    localparam integer CICLOS_50US =
        FRECUENCIA_RELOJ / 20_000;

    localparam integer CICLOS_1US =
        FRECUENCIA_RELOJ / 1_000_000;


    // ============================================================
    // ESTADOS
    // ============================================================

    typedef enum logic [4:0] {

        INICIO,
        ESPERA_INICIAL,

        INIT_1,
        INIT_2,
        INIT_3,
        INIT_4BIT,

        INIT_FUNCION,
        INIT_DISPLAY,
        INIT_CLEAR,
        INIT_ENTRY,

        ESPERA,

        NIBBLE_ALTO,
        NIBBLE_BAJO,

        ESPERA_COMANDO

    } estado_t;

    estado_t estado;


    // ============================================================
    // REGISTROS
    // ============================================================

    logic [31:0] contador;

    logic [7:0] dato_registro;

    logic [6:0] posicion_registro;

    logic ocupado;
    logic inicializado;


    // ============================================================
    // RDATA
    // ============================================================

    always_comb begin

        rdata = 32'b0;

        case (addr)

            ADDR_STATUS: begin

                rdata[0] = ocupado;
                rdata[1] = inicializado;

            end

            default: begin

                rdata = 32'b0;

            end

        endcase

    end


    // ============================================================
    // MAQUINA DE ESTADOS
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            estado            <= INICIO;
            contador          <= 32'd0;

            dato_registro     <= 8'd0;
            posicion_registro <= 7'd0;

            ocupado           <= 1'b1;
            inicializado      <= 1'b0;

            rs                <= 1'b0;
            rw                <= 1'b0;
            en                <= 1'b0;
            datos             <= 4'b0000;

        end

        else begin

            // EN solamente se activa durante los pulsos
            en <= 1'b0;

            case (estado)

                // =================================================
                // INICIO
                // =================================================

                INICIO: begin

                    ocupado  <= 1'b1;
                    contador <= 0;

                    rs    <= 1'b0;
                    rw    <= 1'b0;
                    datos <= 4'b0000;

                    estado <= ESPERA_INICIAL;

                end


                // =================================================
                // ESPERA DESPUES DEL ENCENDIDO
                // =================================================

                ESPERA_INICIAL: begin

                    if (contador < CICLOS_40MS - 1) begin

                        contador <= contador + 1;

                    end

                    else begin

                        contador <= 0;
                        estado   <= INIT_1;

                    end

                end


                // =================================================
                // SECUENCIA DE INICIALIZACION
                // =================================================

                INIT_1: begin

                    rs    <= 1'b0;
                    rw    <= 1'b0;
                    datos <= 4'b0011;
                    en    <= 1'b1;

                    contador <= 0;
                    estado   <= INIT_2;

                end


                INIT_2: begin

                    if (contador < CICLOS_5MS - 1) begin

                        contador <= contador + 1;

                    end

                    else begin

                        contador <= 0;

                        datos <= 4'b0011;
                        en    <= 1'b1;

                        estado <= INIT_3;

                    end

                end


                INIT_3: begin

                    if (contador < CICLOS_1US - 1) begin

                        contador <= contador + 1;

                    end

                    else begin

                        contador <= 0;

                        datos <= 4'b0011;
                        en    <= 1'b1;

                        estado <= INIT_4BIT;

                    end

                end


                INIT_4BIT: begin

                    if (contador < CICLOS_1US - 1) begin

                        contador <= contador + 1;

                    end

                    else begin

                        contador <= 0;

                        datos <= 4'b0010;
                        en    <= 1'b1;

                        estado <= INIT_FUNCION;

                    end

                end


                // =================================================
                // FUNCTION SET
                // =================================================

                INIT_FUNCION: begin

                    if (contador < CICLOS_1US - 1) begin

                        contador <= contador + 1;

                    end

                    else begin

                        contador <= 0;

                        dato_registro <= CMD_FUNCTION;
                        rs <= 1'b0;

                        estado <= NIBBLE_ALTO;

                    end

                end


                // =================================================
                // DISPLAY ON
                // =================================================

                INIT_DISPLAY: begin

                    if (contador < CICLOS_50US - 1) begin

                        contador <= contador + 1;

                    end

                    else begin

                        contador <= 0;

                        dato_registro <= CMD_DISPLAY_ON;
                        rs <= 1'b0;

                        estado <= NIBBLE_ALTO;

                    end

                end


                // =================================================
                // CLEAR
                // =================================================

                INIT_CLEAR: begin

                    if (contador < CICLOS_50US - 1) begin

                        contador <= contador + 1;

                    end

                    else begin

                        contador <= 0;

                        dato_registro <= CMD_CLEAR;
                        rs <= 1'b0;

                        estado <= NIBBLE_ALTO;

                    end

                end


                // =================================================
                // ENTRY MODE
                // =================================================

                INIT_ENTRY: begin

                    if (contador < CICLOS_2MS - 1) begin

                        contador <= contador + 1;

                    end

                    else begin

                        contador <= 0;

                        dato_registro <= CMD_ENTRY_MODE;
                        rs <= 1'b0;

                        estado <= NIBBLE_ALTO;

                    end

                end


                // =================================================
                // ESPERA NORMAL
                // =================================================

                ESPERA: begin

                    ocupado <= 1'b0;

                    if (write_enable) begin

                        ocupado <= 1'b1;

                        case (addr)

                            // -------------------------------------
                            // ESCRIBIR CARACTER
                            // -------------------------------------

                            ADDR_DATA: begin

                                dato_registro <= wdata[7:0];

                                rs <= 1'b1;

                                estado <= NIBBLE_ALTO;

                            end


                            // -------------------------------------
                            // COMANDO
                            // -------------------------------------

                            ADDR_CONTROL: begin

                                dato_registro <= wdata[7:0];

                                rs <= 1'b0;

                                estado <= NIBBLE_ALTO;

                            end


                            // -------------------------------------
                            // POSICION
                            // -------------------------------------

                            ADDR_POSICION: begin

                                posicion_registro <= wdata[6:0];

                                dato_registro <=
                                    8'h80 | wdata[6:0];

                                rs <= 1'b0;

                                estado <= NIBBLE_ALTO;

                            end


                            default: begin

                                estado <= ESPERA;

                            end

                        endcase

                    end

                end


                // =================================================
                // NIBBLE ALTO
                // =================================================

                NIBBLE_ALTO: begin

                    datos <= dato_registro[7:4];

                    en <= 1'b1;

                    contador <= 0;

                    estado <= NIBBLE_BAJO;

                end


                // =================================================
                // NIBBLE BAJO
                // =================================================

                NIBBLE_BAJO: begin

                    if (contador < CICLOS_1US - 1) begin

                        contador <= contador + 1;

                    end

                    else begin

                        contador <= 0;

                        datos <= dato_registro[3:0];

                        en <= 1'b1;

                        estado <= ESPERA_COMANDO;

                    end

                end


                // =================================================
                // ESPERA DESPUES DE COMANDO
                // =================================================

                ESPERA_COMANDO: begin

                    // CLEAR necesita aproximadamente 1.5 ms.
                    // Usamos 2 ms para tener margen.

                    if (dato_registro == CMD_CLEAR) begin

                        if (contador < CICLOS_2MS - 1) begin

                            contador <= contador + 1;

                        end

                        else begin

                            contador <= 0;

                            ocupado <= 1'b0;

                            if (!inicializado)
                                estado <= INIT_ENTRY;
                            else
                                estado <= ESPERA;

                        end

                    end

                    else begin

                        if (contador < CICLOS_50US - 1) begin

                            contador <= contador + 1;

                        end

                        else begin

                            contador <= 0;

                            ocupado <= 1'b0;

                            if (!inicializado) begin

                                case (dato_registro)

                                    CMD_FUNCTION:
                                        estado <= INIT_DISPLAY;

                                    CMD_DISPLAY_ON:
                                        estado <= INIT_CLEAR;

                                    CMD_ENTRY_MODE: begin

                                        inicializado <= 1'b1;
                                        estado <= ESPERA;

                                    end

                                    default:
                                        estado <= ESPERA;

                                endcase

                            end

                            else begin

                                estado <= ESPERA;

                            end

                        end

                    end

                end


                default: begin

                    estado <= INICIO;

                end

            endcase

        end

    end

endmodule