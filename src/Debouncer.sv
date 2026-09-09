module Debouncer #(
    parameter integer FRECUENCIA_RELOJ = 100_000_000,
    parameter integer TIEMPO_REBOTE_MS = 20
)(
    input  logic       clk,
    input  logic       rst,
    input  logic [1:0] botones,

    output logic [1:0] estado_botones
);

    localparam integer CICLOS_REBOTE =
        (FRECUENCIA_RELOJ / 1000) * TIEMPO_REBOTE_MS;

    localparam integer ANCHO_CONTADOR =
        $clog2(CICLOS_REBOTE + 1);

    logic [1:0] botones_muestra;
    logic [1:0] botones_estables;

    logic [ANCHO_CONTADOR-1:0] contadores [1:0];

    integer i;

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            botones_muestra  <= 2'b00;
            botones_estables <= 2'b00;

            for (i = 0; i < 2; i = i + 1)
                contadores[i] <= '0;

        end else begin

            for (i = 0; i < 2; i = i + 1) begin

                if (botones[i] != botones_muestra[i]) begin

                    botones_muestra[i] <= botones[i];
                    contadores[i] <= '0;

                end else begin

                    if (contadores[i] < CICLOS_REBOTE - 1) begin

                        contadores[i] <= contadores[i] + 1'b1;

                    end else begin

                        botones_estables[i] <= botones_muestra[i];

                    end

                end

            end

        end

    end

    assign estado_botones = botones_estables;

endmodule