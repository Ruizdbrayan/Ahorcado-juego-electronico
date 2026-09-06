module Memoria (

    input  logic       dificultad,
    input  logic [4:0] indice_palabra,

    output logic [63:0] palabra_actual

);

    always_comb begin

        palabra_actual = "GATO    ";

        if (!dificultad) begin

            case (indice_palabra)

                5'd0:  palabra_actual = "GATO    ";
                5'd1:  palabra_actual = "CASA    ";
                5'd2:  palabra_actual = "LUNA    ";
                5'd3:  palabra_actual = "MESA    ";
                5'd4:  palabra_actual = "PERRO   ";
                5'd5:  palabra_actual = "PATO    ";
                5'd6:  palabra_actual = "GATO    ";
                5'd7:  palabra_actual = "RANA    ";
                5'd8:  palabra_actual = "FLOR    ";
                5'd9:  palabra_actual = "ROJO    ";
                5'd10: palabra_actual = "AZUL    ";
                5'd11: palabra_actual = "NUBE    ";
                5'd12: palabra_actual = "MESA    ";
                5'd13: palabra_actual = "SILLA   ";
                5'd14: palabra_actual = "CAMA    ";
                5'd15: palabra_actual = "VASO    ";
                5'd16: palabra_actual = "TREN    ";
                5'd17: palabra_actual = "AUTO    ";
                5'd18: palabra_actual = "AVION   ";
                5'd19: palabra_actual = "LAGO    ";
                5'd20: palabra_actual = "RISA    ";
                5'd21: palabra_actual = "BESO    ";
                5'd22: palabra_actual = "PINO    ";
                5'd23: palabra_actual = "CAFE    ";
                5'd24: palabra_actual = "PATO    ";

                default:
                    palabra_actual = "GATO    ";

            endcase

        end else begin

            case (indice_palabra)

                5'd0:  palabra_actual = "COMPUTO ";
                5'd1:  palabra_actual = "TECLADO ";
                5'd2:  palabra_actual = "CIRCUITO";
                5'd3:  palabra_actual = "HARDWARE";
                5'd4:  palabra_actual = "SOFTWARE";
                5'd5:  palabra_actual = "AMAPOLA ";
                5'd6:  palabra_actual = "ROBOTICA";
                5'd7:  palabra_actual = "MOTOR   ";
                5'd8:  palabra_actual = "SENSOR  ";
                5'd9:  palabra_actual = "ARDUINO ";
                5'd10: palabra_actual = "PROGRAMA";
                5'd11: palabra_actual = "DISPLAY ";
                5'd12: palabra_actual = "MEMORIA ";
                5'd13: palabra_actual = "VOLTAJE ";
                5'd14: palabra_actual = "ENERGIA ";
                5'd15: palabra_actual = "RESISTOR";
                5'd16: palabra_actual = "CAPACITO";
                5'd17: palabra_actual = "TRANSIST";
                5'd18: palabra_actual = "AMPLIFIC";
                5'd19: palabra_actual = "SENALES ";
                5'd20: palabra_actual = "ELECTRON";
                5'd21: palabra_actual = "SISTEMA ";
                5'd22: palabra_actual = "CONTROL ";
                5'd23: palabra_actual = "LOGICA  ";
                5'd24: palabra_actual = "DIGITAL ";

                default:
                    palabra_actual = "COMPUTO ";

            endcase

        end

    end

endmodule