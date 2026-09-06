module FSM (

    input logic clk,
    input logic rst,

    input logic partida_iniciada,

    input logic [63:0] palabra_estado,
    input logic [3:0] cantidad_letras,

    input logic [4:0] fallos,

    input logic tiempo_agotado,

    output logic [1:0] estado_actual,

    output logic victoria,
    output logic derrota,
    output logic mostrar_guiones,

    output logic [63:0] palabra_lcd

);


    // ============================================================
    // ESTADOS
    // ============================================================

    localparam logic [1:0] SELECTOR    = 2'b00;
    localparam logic [1:0] JUGANDO    = 2'b01;
    localparam logic [1:0] FINALIZADO = 2'b10;


    logic palabra_completa;

    // Indica que ya existe una palabra inicializada.
    logic palabra_inicializada;


    // ============================================================
    // DETERMINAR SI LA PALABRA ESTA COMPLETA
    // ============================================================

    always_comb begin

        palabra_completa = 1'b1;

        // --------------------------------------------------------
        // Si todavía no hay palabra, NO puede estar completa.
        // --------------------------------------------------------

        if (cantidad_letras == 4'd0) begin

            palabra_completa = 1'b0;

        end

        else begin

            // ----------------------------------------------------
            // LETRA 1
            // ----------------------------------------------------

            if (cantidad_letras >= 4'd1) begin

                if (!(
                    palabra_estado[63:56] >= "A" &&
                    palabra_estado[63:56] <= "Z"
                ))
                    palabra_completa = 1'b0;

            end


            // ----------------------------------------------------
            // LETRA 2
            // ----------------------------------------------------

            if (cantidad_letras >= 4'd2) begin

                if (!(
                    palabra_estado[55:48] >= "A" &&
                    palabra_estado[55:48] <= "Z"
                ))
                    palabra_completa = 1'b0;

            end


            // ----------------------------------------------------
            // LETRA 3
            // ----------------------------------------------------

            if (cantidad_letras >= 4'd3) begin

                if (!(
                    palabra_estado[47:40] >= "A" &&
                    palabra_estado[47:40] <= "Z"
                ))
                    palabra_completa = 1'b0;

            end


            // ----------------------------------------------------
            // LETRA 4
            // ----------------------------------------------------

            if (cantidad_letras >= 4'd4) begin

                if (!(
                    palabra_estado[39:32] >= "A" &&
                    palabra_estado[39:32] <= "Z"
                ))
                    palabra_completa = 1'b0;

            end


            // ----------------------------------------------------
            // LETRA 5
            // ----------------------------------------------------

            if (cantidad_letras >= 4'd5) begin

                if (!(
                    palabra_estado[31:24] >= "A" &&
                    palabra_estado[31:24] <= "Z"
                ))
                    palabra_completa = 1'b0;

            end


            // ----------------------------------------------------
            // LETRA 6
            // ----------------------------------------------------

            if (cantidad_letras >= 4'd6) begin

                if (!(
                    palabra_estado[23:16] >= "A" &&
                    palabra_estado[23:16] <= "Z"
                ))
                    palabra_completa = 1'b0;

            end


            // ----------------------------------------------------
            // LETRA 7
            // ----------------------------------------------------

            if (cantidad_letras >= 4'd7) begin

                if (!(
                    palabra_estado[15:8] >= "A" &&
                    palabra_estado[15:8] <= "Z"
                ))
                    palabra_completa = 1'b0;

            end


            // ----------------------------------------------------
            // LETRA 8
            // ----------------------------------------------------

            if (cantidad_letras >= 4'd8) begin

                if (!(
                    palabra_estado[7:0] >= "A" &&
                    palabra_estado[7:0] <= "Z"
                ))
                    palabra_completa = 1'b0;

            end

        end

    end


    // ============================================================
    // CONTROL DE PALABRA INICIALIZADA
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            palabra_inicializada <= 1'b0;

        end

        else begin

            // Nueva partida: todavía no consideramos
            // válida la palabra anterior.
            if (partida_iniciada) begin

                palabra_inicializada <= 1'b0;

            end

            // Cuando Validador_Letra ya produjo los guiones,
            // podemos considerar inicializada la palabra.
            else if (estado_actual == JUGANDO) begin

                if (cantidad_letras != 4'd0)
                    palabra_inicializada <= 1'b1;

            end

        end

    end


    // ============================================================
    // MAQUINA DE ESTADOS
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            estado_actual <= SELECTOR;

        end

        else begin

            case (estado_actual)


                // =================================================
                // SELECTOR
                // =================================================

                SELECTOR: begin

                    if (partida_iniciada)
                        estado_actual <= JUGANDO;

                end


                // =================================================
                // JUGANDO
                // =================================================

                JUGANDO: begin

                    // ------------------------------------------------
                    // Primero verificar timeout
                    // ------------------------------------------------

                    if (tiempo_agotado) begin

                        estado_actual <= FINALIZADO;

                    end

                    // ------------------------------------------------
                    // Luego verificar seis fallos
                    // ------------------------------------------------

                    else if (fallos >= 5'd6) begin

                        estado_actual <= FINALIZADO;

                    end

                    // ------------------------------------------------
                    // Finalmente verificar palabra completa
                    //
                    // SOLO después de que exista una palabra
                    // inicializada.
                    // ------------------------------------------------

                    else if (palabra_inicializada &&
                             palabra_completa) begin

                        estado_actual <= FINALIZADO;

                    end

                end


                // =================================================
                // FINALIZADO
                // =================================================

                FINALIZADO: begin

                    if (partida_iniciada)
                        estado_actual <= JUGANDO;

                end


                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    estado_actual <= SELECTOR;

                end

            endcase

        end

    end


    // ============================================================
    // SALIDAS
    // ============================================================

    always_comb begin

        victoria = 1'b0;
        derrota = 1'b0;

        palabra_lcd = palabra_estado;

        mostrar_guiones = 1'b0;


        if (estado_actual == FINALIZADO) begin

            mostrar_guiones = 1'b1;


            // ====================================================
            // VICTORIA
            // ====================================================

            if (palabra_completa &&
                fallos < 5'd6) begin

                victoria = 1'b1;

            end


            // ====================================================
            // DERROTA
            // ====================================================

            else begin

                derrota = 1'b1;

            end

        end

    end

endmodule