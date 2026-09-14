module Temporizador #(
    parameter integer FRECUENCIA_RELOJ = 100_000_000
)(
    input logic clk,
    input logic rst,

    input logic partida_activa,
    input logic dificultad,

    input logic victoria,
    input logic derrota,

    output logic [3:0] unidades,
    output logic [3:0] decenas,
    output logic [3:0] centenas,

    output logic timeout
);


// =========================================================
// PARAMETROS
// =========================================================

localparam integer CICLOS_SEGUNDO =
    FRECUENCIA_RELOJ;


// =========================================================
// REGISTROS
// =========================================================

logic [26:0] contador_segundo;

logic [7:0] tiempo_restante;


// =========================================================
// TEMPORIZADOR
// =========================================================

always_ff @(posedge clk or posedge rst) begin

    if (rst) begin

        contador_segundo <= 27'd0;

        tiempo_restante <= 8'd0;

        timeout <= 1'b0;

    end

    else begin

        // =====================================================
        // FUERA DE PARTIDA
        // =====================================================

        if (!partida_activa) begin

            contador_segundo <= 27'd0;

            timeout <= 1'b0;


            if (dificultad)
                tiempo_restante <= 8'd90;

            else
                tiempo_restante <= 8'd120;

        end


        // =====================================================
        // PARTIDA FINALIZADA
        // =====================================================

        else if (victoria || derrota) begin

            contador_segundo <= contador_segundo;

            tiempo_restante <= tiempo_restante;

            timeout <= 1'b0;

        end


        // =====================================================
        // PARTIDA ACTIVA
        // =====================================================

        else begin

            // -----------------------------------------------
            // Segundo transcurrido
            // -----------------------------------------------

            if (
                contador_segundo ==
                CICLOS_SEGUNDO - 1
            ) begin

                contador_segundo <= 27'd0;


                // -------------------------------------------
                // Todavía queda tiempo
                // -------------------------------------------

                if (tiempo_restante > 1) begin

                    tiempo_restante <=
                        tiempo_restante - 1'b1;

                    timeout <= 1'b0;

                end


                // -------------------------------------------
                // Llegó a cero
                // -------------------------------------------

                else begin

                    tiempo_restante <= 8'd0;

                    timeout <= 1'b1;

                end

            end

            else begin

                contador_segundo <=
                    contador_segundo + 1'b1;

                timeout <= 1'b0;

            end

        end

    end

end


// =========================================================
// DISPLAY BCD
// =========================================================

always_comb begin

    centenas =
        tiempo_restante / 100;

    decenas =
        (tiempo_restante % 100) / 10;

    unidades =
        tiempo_restante % 10;

end

endmodule