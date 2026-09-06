module LFSR (

    input  logic       clk,
    input  logic       rst,

    output logic [4:0] numero_aleatorio

);

    logic retroalimentacion;

    assign retroalimentacion =
        numero_aleatorio[4] ^ numero_aleatorio[2];

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            numero_aleatorio <= 5'b00001;

        end else begin

            numero_aleatorio <= {
                numero_aleatorio[3:0],retroalimentacion
            };

        end

    end

endmodule