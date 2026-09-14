module UART #(
    parameter integer FRECUENCIA_RELOJ = 100_000_000,
    parameter integer BAUDRATE        = 115_200
)(
    input  logic        clk,
    input  logic        rst,

    // =========================================================
    // INTERFAZ ESTANDAR DEL PERIFERICO
    // =========================================================

    input  logic        write_enable,
    input  logic [1:0]  addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,

    // =========================================================
    // INTERFAZ FISICA UART
    // =========================================================

    input  logic        rx_fisico,
    output logic        tx_fisico
);

    // =========================================================
    // PARAMETROS
    // =========================================================

    localparam integer CICLOS_BAUD =
        FRECUENCIA_RELOJ / BAUDRATE;

    localparam integer MEDIO_BAUD =
        CICLOS_BAUD / 2;


    // =========================================================
    // REGISTROS
    // =========================================================

    logic [7:0] registro_tx;
    logic [7:0] registro_rx;

    logic tx_pendiente;
    logic rx_recibido;


    // =========================================================
    // TRANSMISOR
    // =========================================================

    logic [9:0] registro_tx_serial;
    logic [3:0] bit_tx;
    logic [31:0] contador_tx;
    logic tx_activo;


    // =========================================================
    // RECEPTOR
    // =========================================================

    logic [7:0] registro_rx_serial;
    logic [3:0] bit_rx;
    logic [31:0] contador_rx;
    logic rx_activo;

    logic rx_sync1;
    logic rx_sync2;


    // =========================================================
    // SINCRONIZADOR RX
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;

        end

        else begin

            rx_sync1 <= rx_fisico;
            rx_sync2 <= rx_sync1;

        end

    end


    // =========================================================
    // LOGICA PRINCIPAL
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            // -------------------------------------------------
            // REGISTROS
            // -------------------------------------------------

            registro_tx <= 8'h00;
            registro_rx <= 8'h00;

            tx_pendiente <= 1'b0;
            rx_recibido  <= 1'b0;


            // -------------------------------------------------
            // TX
            // -------------------------------------------------

            registro_tx_serial <= 10'b1111111111;

            bit_tx      <= 4'd0;
            contador_tx <= 32'd0;
            tx_activo   <= 1'b0;


            // -------------------------------------------------
            // RX
            // -------------------------------------------------

            registro_rx_serial <= 8'h00;

            bit_rx      <= 4'd0;
            contador_rx <= 32'd0;
            rx_activo   <= 1'b0;

        end

        else begin

            // =================================================
            // ESCRITURAS DEL BUS
            // =================================================

            if (write_enable) begin

                case (addr)

                    // -------------------------------------------------
                    // TX DATA
                    // -------------------------------------------------

                    2'b00: begin

                        registro_tx <= wdata[7:0];

                    end


                    // -------------------------------------------------
                    // RX DATA
                    // -------------------------------------------------

                    2'b01: begin

                    end


                    // -------------------------------------------------
                    // CONTROL
                    // -------------------------------------------------

                    2'b10: begin

                        // ---------------------------------------------
                        // SEND
                        // ---------------------------------------------

                        if (wdata[0] &&
                            !tx_activo &&
                            !tx_pendiente) begin

                            tx_pendiente <= 1'b1;

                        end


                        // ---------------------------------------------
                        // CLEAR RX
                        // ---------------------------------------------

                        if (wdata[1]) begin

                            rx_recibido <= 1'b0;

                        end

                    end

                    default: begin

                    end

                endcase

            end


            // =================================================
            // INICIAR TX
            // =================================================

            if (tx_pendiente && !tx_activo) begin

                registro_tx_serial <= {
                    1'b1,
                    registro_tx,
                    1'b0
                };

                bit_tx      <= 4'd0;
                contador_tx <= 32'd0;

                tx_activo <= 1'b1;
                tx_pendiente <= 1'b0;

            end


            // =================================================
            // TRANSMISION
            // =================================================

            if (tx_activo) begin

                if (contador_tx == CICLOS_BAUD - 1) begin

                    contador_tx <= 32'd0;

                    if (bit_tx == 4'd9) begin

                        tx_activo <= 1'b0;
                        bit_tx    <= 4'd0;

                    end

                    else begin

                        bit_tx <= bit_tx + 1'b1;

                    end

                end

                else begin

                    contador_tx <= contador_tx + 1'b1;

                end

            end


            // =================================================
            // DETECCION DEL START BIT
            // =================================================
            //
            // UART en reposo = 1
            // START            = 0
            //
            // Al detectar 0:
            //
            // esperamos medio periodo.
            //
            // =================================================

            if (!rx_activo &&
                (rx_sync2 == 1'b0)) begin

                rx_activo   <= 1'b1;
                bit_rx      <= 4'd0;

                contador_rx <= 32'd0;

            end


            // =================================================
            // RECEPCION
            // =================================================

            if (rx_activo) begin

                // -------------------------------------------------
                // Primer medio bit:
                // validar START
                // -------------------------------------------------

                if (bit_rx == 4'd0) begin

                    if (contador_rx == MEDIO_BAUD - 1) begin

                        contador_rx <= 32'd0;

                        if (rx_sync2 == 1'b0) begin

                            bit_rx <= 4'd1;

                        end

                        else begin

                            // START falso

                            rx_activo <= 1'b0;
                            bit_rx    <= 4'd0;

                        end

                    end

                    else begin

                        contador_rx <= contador_rx + 1'b1;

                    end

                end

                // -------------------------------------------------
                // BITS DE DATOS
                // -------------------------------------------------

                else if (bit_rx <= 4'd8) begin

                    if (contador_rx == CICLOS_BAUD - 1) begin

                        contador_rx <= 32'd0;

                        registro_rx_serial[bit_rx - 1'b1]
                            <= rx_sync2;

                        bit_rx <= bit_rx + 1'b1;

                    end

                    else begin

                        contador_rx <= contador_rx + 1'b1;

                    end

                end

                // -------------------------------------------------
                // STOP BIT
                // -------------------------------------------------

                else begin

                    if (contador_rx == CICLOS_BAUD - 1) begin

                        contador_rx <= 32'd0;

                        rx_activo <= 1'b0;
                        bit_rx    <= 4'd0;

                        if (rx_sync2) begin

                            registro_rx <= registro_rx_serial;
                            rx_recibido <= 1'b1;

                        end

                    end

                    else begin

                        contador_rx <= contador_rx + 1'b1;

                    end

                end

            end

        end

    end


    // =========================================================
    // SALIDAS DEL BUS
    // =========================================================

    always_comb begin

        rdata = 32'd0;

        case (addr)

            // =================================================
            // TX DATA
            // =================================================

            2'b00: begin

                rdata[7:0] = registro_tx;

            end


            // =================================================
            // RX DATA
            // =================================================

            2'b01: begin

                rdata[7:0] = registro_rx;

            end


            // =================================================
            // ESTADO
            // =================================================

            2'b10: begin

                rdata[0] = tx_activo || tx_pendiente;
                rdata[1] = rx_recibido;
                rdata[2] = tx_fisico;

            end


            default: begin

                rdata = 32'd0;

            end

        endcase

    end


    // =========================================================
    // TX FISICO
    // =========================================================

    always_comb begin

        if (tx_activo)

            tx_fisico = registro_tx_serial[bit_tx];

        else

            tx_fisico = 1'b1;

    end

endmodule