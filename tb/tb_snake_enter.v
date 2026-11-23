// Apoyo de IA (Claude): generacion del testbench y
// definicion de casos de prueba. Simulacion revisada en Vivado.
`timescale 1ns/1ps
// ============================================================
// tb_snake_enter.v
// Prueba el reinicio con la tecla Enter:
//   1. Con la flecha derecha el juego arranca y se mueve.
//   2. Al oprimir Enter vuelve al inicio: (15,15), ESPERA, longitud 1.
//   3. Al soltar Enter NO se reinicia otra vez.
//   4. Sin tocar flechas, la serpiente se queda quieta.
//   5. Con la flecha abajo vuelve a arrancar.
// ============================================================
module tb_snake_enter;

// ---------- Entradas (reg) y salidas (wire) ----------
reg clk      = 0;
reg rst      = 1;
reg ps2_clk  = 1;
reg ps2_data = 1;

wire R1, G1, B1, R2, G2, B2;
wire A, B, C, D;
wire HUB_CLK, HUB_LAT, HUB_OE;
wire [1:0]  leds_estado;    // 00 ESPERA, 01 JUGANDO, 10 PERDIO, 11 GANO
wire [15:0] leds_puntaje;

// ---------- Modulo a probar ----------
// LIMITE_MOV pequeno: la serpiente avanza cada 2 us.
snake_top #(.LIMITE_MOV(200), .LIMITE_MATRIZ(7)) uut (
    .clk(clk), .rst(rst),
    .ps2_clk(ps2_clk), .ps2_data(ps2_data),
    .R1(R1), .G1(G1), .B1(B1), .R2(R2), .G2(G2), .B2(B2),
    .A(A), .B(B), .C(C), .D(D),
    .HUB_CLK(HUB_CLK), .HUB_LAT(HUB_LAT), .HUB_OE(HUB_OE),
    .leds_estado(leds_estado), .leds_puntaje(leds_puntaje)
);

// ---------- Reloj de 100 MHz ----------
always #5 clk = ~clk;

// ---------- Cuenta cuantas veces se activa tecla_enter ----------
integer reinicios = 0;
integer errores   = 0;

always @(posedge clk) begin
    if (uut.tecla_enter)
        reinicios = reinicios + 1;
end

// ---------- Tarea: enviar un byte por PS/2 ----------
// Trama: inicio (0), 8 bits de datos (LSB primero), paridad impar, parada (1)
task enviar_byte;
    input [7:0] dato;
    integer k;
    reg [10:0] trama;
    begin
        trama = {1'b1, ~^dato, dato, 1'b0};
        for (k = 0; k < 11; k = k + 1) begin
            ps2_data = trama[k];
            #200 ps2_clk = 0;    // el FPGA lee en el flanco de bajada
            #200 ps2_clk = 1;
        end
        #1000;
    end
endtask

// ---------- Secuencia de la prueba ----------
initial begin
    // Reset
    repeat (3) @(negedge clk);
    rst = 0;
    #20000;

    // 1. Flecha derecha: oprimir (E0 74) y soltar (E0 F0 74)
    enviar_byte(8'hE0);  enviar_byte(8'h74);
    enviar_byte(8'hE0);  enviar_byte(8'hF0);  enviar_byte(8'h74);
    #10000;
    if (leds_estado != 2'b01 || uut.x_actual <= 15) begin
        $display("ERROR 1: el juego no arranco");
        errores = errores + 1;
    end
    $display("Antes de Enter:   x=%0d y=%0d estado=%b", uut.x_actual, uut.y_actual, leds_estado);

    // 2. Oprimir Enter (5A)
    enviar_byte(8'h5A);
    #100;
    if (uut.x_actual != 15 || uut.y_actual != 15 || leds_estado != 2'b00 || uut.longitud != 1) begin
        $display("ERROR 2: Enter no reinicio el juego");
        errores = errores + 1;
    end

    // 3. Soltar Enter (F0 5A): no debe reiniciar otra vez
    enviar_byte(8'hF0);  enviar_byte(8'h5A);
    if (reinicios != 1) begin
        $display("ERROR 3: hubo %0d reinicios (debe ser 1)", reinicios);
        errores = errores + 1;
    end

    // 4. Sin flechas, la serpiente no se mueve
    #20000;
    if (uut.x_actual != 15 || leds_estado != 2'b00) begin
        $display("ERROR 4: se movio sin oprimir flecha");
        errores = errores + 1;
    end

    // 5. Flecha abajo (E0 72): vuelve a arrancar hacia abajo
    enviar_byte(8'hE0);  enviar_byte(8'h72);
    #10000;
    if (leds_estado != 2'b01 || uut.y_actual <= 15) begin
        $display("ERROR 5: no volvio a arrancar");
        errores = errores + 1;
    end
    $display("Despues de Enter: x=%0d y=%0d estado=%b", uut.x_actual, uut.y_actual, leds_estado);

    // Resultado
    if (errores == 0)
        $display("OK ENTER: reinicia con Enter, soltar no reinicia, flechas funcionan");
    else
        $display("FALLO ENTER: %0d errores", errores);

    $finish;
end

endmodule
