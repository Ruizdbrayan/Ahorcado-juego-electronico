module UART #(
    parameter integer FRECUENCIA_RELOJ = 100_000_000,
    parameter integer BAUDRATE = 115_200
)(
    input  logic        clk,
    input  logic        rst,

    input  logic        write_enable,
    input  logic [1:0]  addr,
    input  logic [31:0] wdata,

    output logic [31:0] rdata
);

    localparam integer CICLOS_BAUD =
        FRECUENCIA_RELOJ / BAUDRATE;

    // =========================================================
    // REGISTROS DE DATOS
    // =========================================================

    logic [31:0] registro_tx;
    logic [31:0] registro_rx;

    logic tx_pendiente;
    logic rx_recibido;

    // =========================================================
    // TRANSMISOR UART
    // =========================================================

    logic [9:0] registro_desplazamiento_tx;
    logic [3:0] bit_tx;
    logic [15:0] contador_baud_tx;

    logic tx_activo;
    logic tx_bit;

    // =========================================================
    // RECEPTOR UART
    // =========================================================

    logic [7:0] registro_desplazamiento_rx;
    logic [3:0] bit_rx;
    logic rx_activo;

    // =========================================================
    // MAPA DE REGISTROS
    //
    // 00 -> TX DATA
    // 01 -> RX DATA
    // 10 -> STATUS
    //
    // STATUS:
    // bit 0 = TX pendiente
    // bit 1 = RX recibido
    // bit 2 = TX serial
    // =========================================================

    always_comb begin

        case (addr)

            2'b00: begin
                rdata = registro_tx;
            end

            2'b01: begin
                rdata = registro_rx;
            end

            2'b10: begin

                rdata = 32'b0;

                rdata[0] = tx_pendiente;
                rdata[1] = rx_recibido;
                rdata[2] = tx_bit;

            end

            default: begin
                rdata = 32'b0;
            end

        endcase

    end

    // =========================================================
    // LOGICA PRINCIPAL
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            registro_tx <= 32'b0;
            registro_rx <= 32'b0;

            tx_pendiente <= 1'b0;
            rx_recibido <= 1'b0;

            registro_desplazamiento_tx <= 10'b1111111111;
            bit_tx <= 4'd0;
            contador_baud_tx <= 16'd0;

            tx_activo <= 1'b0;
            tx_bit <= 1'b1;

            registro_desplazamiento_rx <= 8'b0;
            bit_rx <= 4'd0;
            rx_activo <= 1'b0;

        end

        else begin

            // =================================================
            // ACCESO AL BUS
            // =================================================

            if (write_enable) begin

                case (addr)

                    // =========================================
                    // TX DATA
                    // =========================================

                    2'b00: begin

                        registro_tx <= wdata;

                        // Solo aceptar un nuevo byte cuando
                        // el transmisor esté libre.
                        if (!tx_activo) begin

                            registro_desplazamiento_tx[0] <= 1'b0;

                            registro_desplazamiento_tx[1] <= wdata[0];
                            registro_desplazamiento_tx[2] <= wdata[1];
                            registro_desplazamiento_tx[3] <= wdata[2];
                            registro_desplazamiento_tx[4] <= wdata[3];
                            registro_desplazamiento_tx[5] <= wdata[4];
                            registro_desplazamiento_tx[6] <= wdata[5];
                            registro_desplazamiento_tx[7] <= wdata[6];
                            registro_desplazamiento_tx[8] <= wdata[7];

                            registro_desplazamiento_tx[9] <= 1'b1;

                            bit_tx <= 4'd0;
                            contador_baud_tx <= 16'd0;

                            tx_activo <= 1'b1;
                            tx_pendiente <= 1'b1;

                            tx_bit <= 1'b0;

                        end

                    end

                    // =========================================
                    // RX DATA
                    // =========================================

                    2'b01: begin

                        if (!rx_activo) begin

                            // Inicio de recepción
                            if (wdata[0] == 1'b0) begin

                                rx_activo <= 1'b1;
                                bit_rx <= 4'd0;
                                registro_desplazamiento_rx <= 8'b0;

                            end

                        end

                        else begin

                            // ---------------------------------
                            // BITS DE DATOS
                            // ---------------------------------

                            if (bit_rx < 8) begin

                                registro_desplazamiento_rx[bit_rx]
                                    <= wdata[0];

                                bit_rx <= bit_rx + 1'b1;

                            end

                            // ---------------------------------
                            // BIT DE STOP
                            // ---------------------------------

                            else begin

                                if (wdata[0] == 1'b1) begin

                                    registro_rx <= {
                                        24'b0,
                                        registro_desplazamiento_rx
                                    };

                                    rx_recibido <= 1'b1;

                                end

                                rx_activo <= 1'b0;
                                bit_rx <= 4'd0;

                            end

                        end

                    end

                    // =========================================
                    // CONTROL
                    // =========================================

                    2'b10: begin

                        // bit 0 -> limpiar TX
                        if (wdata[0])
                            tx_pendiente <= 1'b0;

                        // bit 1 -> limpiar RX
                        if (wdata[1])
                            rx_recibido <= 1'b0;

                    end

                    default: begin
                    end

                endcase

            end

            // =================================================
            // TRANSMISOR
            // =================================================

            if (tx_activo) begin

                if (contador_baud_tx == CICLOS_BAUD - 1) begin

                    contador_baud_tx <= 16'd0;

                    if (bit_tx == 4'd9) begin

                        // Último bit
                        tx_activo <= 1'b0;
                        tx_pendiente <= 1'b0;

                        tx_bit <= 1'b1;

                        bit_tx <= 4'd0;

                    end

                    else begin

                        bit_tx <= bit_tx + 1'b1;

                        tx_bit <=
                            registro_desplazamiento_tx[
                                bit_tx + 1'b1
                            ];

                    end

                end

                else begin

                    contador_baud_tx <=
                        contador_baud_tx + 1'b1;

                end

            end

        end

    end

endmodule