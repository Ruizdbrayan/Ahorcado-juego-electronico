module siete_segmentos (

    input logic clk,
    input logic rst,

    input logic [3:0] unidades,
    input logic [3:0] decenas,
    input logic [3:0] centenas,

    input logic mostrar_guiones,

    output logic [6:0] segmentos,
    output logic [7:0] anodos

);

    logic [16:0] contador_multiplex;
    logic [1:0] digito_actual;

    // =========================================================
    // MULTIPLEXADO
    // =========================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            contador_multiplex <= 17'd0;
            digito_actual <= 2'd0;

        end else begin

            if (contador_multiplex == 17'd99_999) begin

                contador_multiplex <= 17'd0;

                if (digito_actual == 2'd2)
                    digito_actual <= 2'd0;
                else
                    digito_actual <= digito_actual + 1'b1;

            end else begin

                contador_multiplex <=
                    contador_multiplex + 1'b1;

            end

        end

    end

    // =========================================================
    // DECODIFICADOR
    // =========================================================

    always_comb begin

        // =====================================================
        // POR DEFECTO:
        // TODOS LOS 8 DIGITOS APAGADOS
        // =====================================================

        anodos = 8'b1111_1111;

        if (mostrar_guiones) begin

            case (digito_actual)

                // AN0
                2'd0:
                    anodos = 8'b1111_1110;

                // AN1
                2'd1:
                    anodos = 8'b1111_1101;

                // AN2
                2'd2:
                    anodos = 8'b1111_1011;

                default:
                    anodos = 8'b1111_1111;

            endcase

            // =================================================
            // "-"
            // =================================================

            segmentos = 7'b0111111;

        end else begin

            case (digito_actual)

                // =================================================
                // UNIDADES -> AN0
                // =================================================

                2'd0: begin

                    anodos = 8'b1111_1110;

                    case (unidades)

                        4'd0: segmentos = 7'b1000000;
                        4'd1: segmentos = 7'b1111001;
                        4'd2: segmentos = 7'b0100100;
                        4'd3: segmentos = 7'b0110000;
                        4'd4: segmentos = 7'b0011001;
                        4'd5: segmentos = 7'b0010010;
                        4'd6: segmentos = 7'b0000010;
                        4'd7: segmentos = 7'b1111000;
                        4'd8: segmentos = 7'b0000000;
                        4'd9: segmentos = 7'b0010000;

                        default:
                            segmentos = 7'b1111111;

                    endcase

                end

                // =================================================
                // DECENAS -> AN1
                // =================================================

                2'd1: begin

                    anodos = 8'b1111_1101;

                    case (decenas)

                        4'd0: segmentos = 7'b1000000;
                        4'd1: segmentos = 7'b1111001;
                        4'd2: segmentos = 7'b0100100;
                        4'd3: segmentos = 7'b0110000;
                        4'd4: segmentos = 7'b0011001;
                        4'd5: segmentos = 7'b0010010;
                        4'd6: segmentos = 7'b0000010;
                        4'd7: segmentos = 7'b1111000;
                        4'd8: segmentos = 7'b0000000;
                        4'd9: segmentos = 7'b0010000;

                        default:
                            segmentos = 7'b1111111;

                    endcase

                end

                // =================================================
                // CENTENAS -> AN2
                // =================================================

                2'd2: begin

                    anodos = 8'b1111_1011;

                    case (centenas)

                        4'd0: segmentos = 7'b1000000;
                        4'd1: segmentos = 7'b1111001;
                        4'd2: segmentos = 7'b0100100;
                        4'd3: segmentos = 7'b0110000;
                        4'd4: segmentos = 7'b0011001;
                        4'd5: segmentos = 7'b0010010;
                        4'd6: segmentos = 7'b0000010;
                        4'd7: segmentos = 7'b1111000;
                        4'd8: segmentos = 7'b0000000;
                        4'd9: segmentos = 7'b0010000;

                        default:
                            segmentos = 7'b1111111;

                    endcase

                end

                default: begin

                    anodos = 8'b1111_1111;
                    segmentos = 7'b1111111;

                end

            endcase

        end

    end

endmodule