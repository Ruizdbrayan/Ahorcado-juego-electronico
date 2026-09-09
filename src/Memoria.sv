module Memoria (

    input  logic        dificultad,
    input  logic [4:0]  indice_palabra,

    output logic [63:0] palabra_actual,

    input  logic [8:0]  direccion_lcd,
    output logic [7:0]  dato_lcd,

    input  logic [8:0]  direccion_uart,
    output logic [7:0]  dato_uart

);

    // =========================================================
    // MEMORIA DE PALABRAS
    // =========================================================

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

        end

        else begin

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


    // =========================================================
    // MEMORIA LCD
    //
    // 0-31    SELECTOR
    // 64-95   JUGANDO
    // 96-127  VICTORIA
    // 128-159 DERROTA
    // =========================================================

    always_comb begin

        dato_lcd = " ";

        case (direccion_lcd)

            // -------------------------------------------------
            // SELECTOR
            // -------------------------------------------------

            9'd0:  dato_lcd = "M";
            9'd1:  dato_lcd = "O";
            9'd2:  dato_lcd = "D";
            9'd3:  dato_lcd = "O";
            9'd4:  dato_lcd = ":";
            9'd5:  dato_lcd = " ";

            9'd6:  dato_lcd = " ";
            9'd7:  dato_lcd = "F";
            9'd8:  dato_lcd = "A";
            9'd9:  dato_lcd = "C";
            9'd10: dato_lcd = "I";
            9'd11: dato_lcd = "L";

            9'd16: dato_lcd = " ";
            9'd17: dato_lcd = " ";
            9'd18: dato_lcd = " ";
            9'd19: dato_lcd = " ";
            9'd20: dato_lcd = " ";
            9'd21: dato_lcd = " ";

            9'd22: dato_lcd = " ";
            9'd23: dato_lcd = "D";
            9'd24: dato_lcd = "I";
            9'd25: dato_lcd = "F";
            9'd26: dato_lcd = "I";
            9'd27: dato_lcd = "C";
            9'd28: dato_lcd = "I";
            9'd29: dato_lcd = "L";


            // -------------------------------------------------
            // JUGANDO
            // -------------------------------------------------

            9'd64: dato_lcd = "P";
            9'd65: dato_lcd = "A";
            9'd66: dato_lcd = "L";
            9'd67: dato_lcd = ":";

            9'd80: dato_lcd = "F";
            9'd81: dato_lcd = "A";
            9'd82: dato_lcd = "L";
            9'd83: dato_lcd = "L";
            9'd84: dato_lcd = "O";
            9'd85: dato_lcd = "S";
            9'd86: dato_lcd = ":";


            // -------------------------------------------------
            // VICTORIA
            // -------------------------------------------------

            9'd96:  dato_lcd = "G";
            9'd97:  dato_lcd = "A";
            9'd98:  dato_lcd = "N";
            9'd99:  dato_lcd = "A";
            9'd100: dato_lcd = "S";
            9'd101: dato_lcd = "T";
            9'd102: dato_lcd = "E";
            9'd103: dato_lcd = "!";

            9'd112: dato_lcd = "P";
            9'd113: dato_lcd = "A";
            9'd114: dato_lcd = "L";
            9'd115: dato_lcd = ":";


            // -------------------------------------------------
            // DERROTA
            // -------------------------------------------------

            9'd128: dato_lcd = "P";
            9'd129: dato_lcd = "E";
            9'd130: dato_lcd = "R";
            9'd131: dato_lcd = "D";
            9'd132: dato_lcd = "I";
            9'd133: dato_lcd = "S";
            9'd134: dato_lcd = "T";
            9'd135: dato_lcd = "E";
            9'd136: dato_lcd = "!";

            9'd144: dato_lcd = "P";
            9'd145: dato_lcd = "A";
            9'd146: dato_lcd = "L";
            9'd147: dato_lcd = ":";


            default:
                dato_lcd = " ";

        endcase

    end


    // =========================================================
    // MEMORIA UART
    //
    // Cada mensaje ocupa un bloque de 40 posiciones.
    //
    // Las palabras tienen 8 posiciones reservadas.
    // Controlador_UART elimina las posiciones sobrantes.
    // =========================================================

    always_comb begin

        dato_uart = " ";

        case (direccion_uart)

            // =================================================
            // START FACIL
            //
            // START,LEN= ,MODE=FACIL\r\n
            // =================================================

            9'd0:  dato_uart = "S";
            9'd1:  dato_uart = "T";
            9'd2:  dato_uart = "A";
            9'd3:  dato_uart = "R";
            9'd4:  dato_uart = "T";
            9'd5:  dato_uart = ",";
            9'd6:  dato_uart = "L";
            9'd7:  dato_uart = "E";
            9'd8:  dato_uart = "N";
            9'd9:  dato_uart = "=";
            9'd10: dato_uart = " ";
            9'd11: dato_uart = ",";
            9'd12: dato_uart = "M";
            9'd13: dato_uart = "O";
            9'd14: dato_uart = "D";
            9'd15: dato_uart = "E";
            9'd16: dato_uart = "=";
            9'd17: dato_uart = "F";
            9'd18: dato_uart = "A";
            9'd19: dato_uart = "C";
            9'd20: dato_uart = "I";
            9'd21: dato_uart = "L";
            9'd22: dato_uart = 8'h0D;
            9'd23: dato_uart = 8'h0A;


            // =================================================
            // START DIFICIL
            //
            // START,LEN= ,MODE=DIFICIL\r\n
            // =================================================

            9'd40: dato_uart = "S";
            9'd41: dato_uart = "T";
            9'd42: dato_uart = "A";
            9'd43: dato_uart = "R";
            9'd44: dato_uart = "T";
            9'd45: dato_uart = ",";
            9'd46: dato_uart = "L";
            9'd47: dato_uart = "E";
            9'd48: dato_uart = "N";
            9'd49: dato_uart = "=";
            9'd50: dato_uart = " ";
            9'd51: dato_uart = ",";
            9'd52: dato_uart = "M";
            9'd53: dato_uart = "O";
            9'd54: dato_uart = "D";
            9'd55: dato_uart = "E";
            9'd56: dato_uart = "=";
            9'd57: dato_uart = "D";
            9'd58: dato_uart = "I";
            9'd59: dato_uart = "F";
            9'd60: dato_uart = "I";
            9'd61: dato_uart = "C";
            9'd62: dato_uart = "I";
            9'd63: dato_uart = "L";
            9'd64: dato_uart = 8'h0D;
            9'd65: dato_uart = 8'h0A;


            // =================================================
            // RESULTADO REPETIDO
            //
            // RESULT,REP,PAL: ________,INTENTOS: _
            // =================================================

            9'd80:  dato_uart = "R";
            9'd81:  dato_uart = "E";
            9'd82:  dato_uart = "S";
            9'd83:  dato_uart = "U";
            9'd84:  dato_uart = "L";
            9'd85:  dato_uart = "T";
            9'd86:  dato_uart = ",";
            9'd87:  dato_uart = "R";
            9'd88:  dato_uart = "E";
            9'd89:  dato_uart = "P";
            9'd90:  dato_uart = ",";
            9'd91:  dato_uart = "P";
            9'd92:  dato_uart = "A";
            9'd93:  dato_uart = "L";
            9'd94:  dato_uart = ":";
            9'd95:  dato_uart = " ";

            9'd104: dato_uart = ",";
            9'd105: dato_uart = "I";
            9'd106: dato_uart = "N";
            9'd107: dato_uart = "T";
            9'd108: dato_uart = "E";
            9'd109: dato_uart = "N";
            9'd110: dato_uart = "T";
            9'd111: dato_uart = "O";
            9'd112: dato_uart = "S";
            9'd113: dato_uart = ":";
            9'd114: dato_uart = " ";
            9'd116: dato_uart = 8'h0D;
            9'd117: dato_uart = 8'h0A;


            // =================================================
            // RESULTADO CORRECTO
            //
            // RESULT,OK,A,PAL: ________,INTENTOS: _
            // =================================================

            9'd120: dato_uart = "R";
            9'd121: dato_uart = "E";
            9'd122: dato_uart = "S";
            9'd123: dato_uart = "U";
            9'd124: dato_uart = "L";
            9'd125: dato_uart = "T";
            9'd126: dato_uart = ",";
            9'd127: dato_uart = "O";
            9'd128: dato_uart = "K";
            9'd129: dato_uart = ",";
            9'd130: dato_uart = " ";
            9'd131: dato_uart = ",";
            9'd132: dato_uart = "P";
            9'd133: dato_uart = "A";
            9'd134: dato_uart = "L";
            9'd135: dato_uart = ":";
            9'd136: dato_uart = " ";

            9'd145: dato_uart = ",";
            9'd146: dato_uart = "I";
            9'd147: dato_uart = "N";
            9'd148: dato_uart = "T";
            9'd149: dato_uart = "E";
            9'd150: dato_uart = "N";
            9'd151: dato_uart = "T";
            9'd152: dato_uart = "O";
            9'd153: dato_uart = "S";
            9'd154: dato_uart = ":";
            9'd155: dato_uart = " ";
            9'd157: dato_uart = 8'h0D;
            9'd158: dato_uart = 8'h0A;


            // =================================================
            // RESULTADO INCORRECTO
            //
            // RESULT,ERR,A,PAL: ________,INTENTOS: _
            // =================================================

            9'd160: dato_uart = "R";
            9'd161: dato_uart = "E";
            9'd162: dato_uart = "S";
            9'd163: dato_uart = "U";
            9'd164: dato_uart = "L";
            9'd165: dato_uart = "T";
            9'd166: dato_uart = ",";
            9'd167: dato_uart = "E";
            9'd168: dato_uart = "R";
            9'd169: dato_uart = "R";
            9'd170: dato_uart = ",";
            9'd171: dato_uart = " ";
            9'd172: dato_uart = ",";
            9'd173: dato_uart = "P";
            9'd174: dato_uart = "A";
            9'd175: dato_uart = "L";
            9'd176: dato_uart = ":";
            9'd177: dato_uart = " ";

            9'd186: dato_uart = ",";
            9'd187: dato_uart = "I";
            9'd188: dato_uart = "N";
            9'd189: dato_uart = "T";
            9'd190: dato_uart = "E";
            9'd191: dato_uart = "N";
            9'd192: dato_uart = "T";
            9'd193: dato_uart = "O";
            9'd194: dato_uart = "S";
            9'd195: dato_uart = ":";
            9'd196: dato_uart = " ";
            9'd198: dato_uart = 8'h0D;
            9'd199: dato_uart = 8'h0A;


            // =================================================
            // FINAL VICTORIA
            //
            // FINAL,WIN,PAL: ________
            // =================================================

            9'd200: dato_uart = "F";
            9'd201: dato_uart = "I";
            9'd202: dato_uart = "N";
            9'd203: dato_uart = "A";
            9'd204: dato_uart = "L";
            9'd205: dato_uart = ",";
            9'd206: dato_uart = "W";
            9'd207: dato_uart = "I";
            9'd208: dato_uart = "N";
            9'd209: dato_uart = ",";
            9'd210: dato_uart = "P";
            9'd211: dato_uart = "A";
            9'd212: dato_uart = "L";
            9'd213: dato_uart = ":";
            9'd214: dato_uart = " ";

            9'd223: dato_uart = 8'h0D;
            9'd224: dato_uart = 8'h0A;


            // =================================================
            // FINAL DERROTA
            //
            // FINAL,LOSE,PAL: ________
            // =================================================

            9'd240: dato_uart = "F";
            9'd241: dato_uart = "I";
            9'd242: dato_uart = "N";
            9'd243: dato_uart = "A";
            9'd244: dato_uart = "L";
            9'd245: dato_uart = ",";
            9'd246: dato_uart = "L";
            9'd247: dato_uart = "O";
            9'd248: dato_uart = "S";
            9'd249: dato_uart = "E";
            9'd250: dato_uart = ",";
            9'd251: dato_uart = "P";
            9'd252: dato_uart = "A";
            9'd253: dato_uart = "L";
            9'd254: dato_uart = ":";
            9'd255: dato_uart = " ";

            9'd264: dato_uart = 8'h0D;
            9'd265: dato_uart = 8'h0A;


            default:
                dato_uart = " ";

        endcase

    end

endmodule