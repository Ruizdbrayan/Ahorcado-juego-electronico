module Selector_dificultad (

    input logic clk,
    input logic rst,

    input logic seleccionar,
    input logic aceptar,

    output logic dificultad,
    output logic partida_iniciada

);

    logic seleccionar_anterior;
    logic aceptar_anterior;


    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            dificultad <= 1'b0;

            seleccionar_anterior <= 1'b0;
            aceptar_anterior <= 1'b0;

            partida_iniciada <= 1'b0;

        end else begin

            // Por defecto no se inicia ninguna partida.
            partida_iniciada <= 1'b0;


            // =====================================================
            // CAMBIO DE DIFICULTAD
            // =====================================================
            //
            // Solo ocurre cuando detectar un flanco 0 -> 1.
            //

            if (seleccionar && !seleccionar_anterior)
                dificultad <= ~dificultad;


            // =====================================================
            // INICIO DE PARTIDA
            // =====================================================

            if (aceptar && !aceptar_anterior)
                partida_iniciada <= 1'b1;


            // Guardar estados anteriores
            seleccionar_anterior <= seleccionar;
            aceptar_anterior <= aceptar;

        end

    end

endmodule