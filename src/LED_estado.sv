module LED_estado (

    input logic clk,
    input logic rst,

    input logic [1:0] estado_actual,

    output logic [2:0] leds

);

    localparam logic [1:0]

        ESTADO_SELECTOR   = 2'b00,
        ESTADO_JUGANDO    = 2'b01,
        ESTADO_FINALIZADO = 2'b10;

    always_comb begin

        case (estado_actual)

            ESTADO_SELECTOR:
                leds = 3'b001;

            ESTADO_JUGANDO:
                leds = 3'b010;

            ESTADO_FINALIZADO:
                leds = 3'b100;

            default:
                leds = 3'b000;

        endcase

    end

endmodule