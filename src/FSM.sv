module FSM (

    input logic        clk,
    input logic        rst,

    input logic        partida_iniciada,

    input logic [63:0] palabra_estado,
    input logic [3:0]  cantidad_letras,

    input logic [4:0]  fallos,

    input logic        tiempo_agotado,

    output logic [1:0] estado_actual,

    output logic       victoria,
    output logic       derrota,
    output logic       mostrar_guiones,

    output logic [63:0] palabra_lcd

);

    // ============================================================
    // ESTADOS
    // ============================================================

    localparam logic [1:0]
        SELECTOR   = 2'b00,
        JUGANDO    = 2'b01,
        FINALIZADO = 2'b10;

    // ============================================================
    // DURACION DE PANTALLA FINAL
    // 2 segundos a 100 MHz
    // ============================================================

    localparam integer DURACION_FINAL = 200_000_000;

    logic [27:0] contador_final;

    // ============================================================
    // PALABRA
    // ============================================================

    logic palabra_completa;
    logic palabra_inicializada;

    // ============================================================
    // RESULTADO FINAL MEMORIZADO
    //
    // 1 = victoria
    // 0 = derrota
    // ============================================================

    logic resultado_final_victoria;

    // ============================================================
    // DETERMINAR SI LA PALABRA ESTA COMPLETA
    // ============================================================

    always_comb begin
        palabra_completa = 1'b1;

        if (cantidad_letras == 4'd0) begin
            palabra_completa = 1'b0;
        end else begin
            for (int i = 0; i < 8; i++) begin
                if (i < cantidad_letras) begin
                    // Evaluar los bytes de 8 en 8 desde MSB
                    if (!(palabra_estado[(7-i)*8 +: 8] >= "A" && palabra_estado[(7-i)*8 +: 8] <= "Z")) begin
                        palabra_completa = 1'b0;
                    end
                end
            end
        end
    end

    // ============================================================
    // PALABRA INICIALIZADA
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            palabra_inicializada <= 1'b0;
        end else begin
            if (partida_iniciada) begin
                palabra_inicializada <= 1'b0;
            end else if (estado_actual == JUGANDO) begin
                if (cantidad_letras != 4'd0)
                    palabra_inicializada <= 1'b1;
            end else if (estado_actual == SELECTOR) begin
                palabra_inicializada <= 1'b0;
            end
        end

    end

    // ============================================================
    // MAQUINA DE ESTADOS
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            estado_actual            <= SELECTOR;
            contador_final           <= 28'd0;
            resultado_final_victoria <= 1'b0;

        end else begin

            case (estado_actual)

                // =================================================
                // SELECTOR
                // =================================================

                SELECTOR: begin

                    contador_final <= 28'd0;

                    if (partida_iniciada) begin
                        estado_actual            <= JUGANDO;
                        resultado_final_victoria <= 1'b0;
                    end

                end

                // =================================================
                // JUGANDO
                // =================================================

                JUGANDO: begin

                    contador_final <= 28'd0;

                    // TIMEOUT
                    if (tiempo_agotado) begin
                        estado_actual            <= FINALIZADO;
                        resultado_final_victoria <= 1'b0;
                    end

                    // 6 FALLOS O MÁS
                    else if (fallos >= 5'd6) begin
                        estado_actual            <= FINALIZADO;
                        resultado_final_victoria <= 1'b0;
                    end

                    // PALABRA COMPLETA
                    else if (palabra_inicializada && palabra_completa) begin
                        estado_actual            <= FINALIZADO;
                        resultado_final_victoria <= 1'b1;
                    end

                end

                // =================================================
                // FINALIZADO
                // =================================================

                FINALIZADO: begin

                    if (contador_final >= DURACION_FINAL - 1) begin
                        contador_final           <= 28'd0;
                        estado_actual            <= SELECTOR;
                        resultado_final_victoria <= 1'b0;
                    end else begin
                        contador_final <= contador_final + 1'b1;
                    end

                end

                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    estado_actual            <= SELECTOR;
                    contador_final           <= 28'd0;
                    resultado_final_victoria <= 1'b0;

                end

            endcase

        end

    end

    // ============================================================
    // SALIDAS
    // ============================================================

    always_comb begin

        victoria        = 1'b0;
        derrota         = 1'b0;
        palabra_lcd     = palabra_estado;
        mostrar_guiones = 1'b0;

        if (estado_actual == FINALIZADO) begin
            mostrar_guiones = 1'b1;
            victoria        = resultado_final_victoria;
            derrota         = !resultado_final_victoria;
        end

    end

endmodule