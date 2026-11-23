// Apoyo de IA (Claude): generacion del testbench y
// definicion de casos de prueba. Simulacion revisada en Vivado.
`timescale 1ns/1ps
// ============================================================
// tb_snake_giros.v
// Prueba que las 4 flechas cambian la direccion en pleno juego:
//   arriba -> izquierda -> abajo -> derecha
// Direccion: 00 arriba, 01 derecha, 10 abajo, 11 izquierda.
// ============================================================
module tb_snake_giros;

// ---------- Entradas (reg) y salidas (wire) ----------
reg clk      = 0;
reg rst      = 1;
reg ps2_clk  = 1;
reg ps2_data = 1;

wire R1, G1, B1, R2, G2, B2;
wire A, B, C, D;
wire HUB_CLK, HUB_LAT, HUB_OE;
wire [1:0]  leds_estado;
wire [15:0] leds_puntaje;

// ---------- Modulo a probar ----------
// LIMITE_MOV = 2000: la serpiente avanza cada 20 us.
snake_top #(.LIMITE_MOV(2000), .LIMITE_MATRIZ(7)) uut (
    .clk(clk), .rst(rst),
    .ps2_clk(ps2_clk), .ps2_data(ps2_data),
    .R1(R1), .G1(G1), .B1(B1), .R2(R2), .G2(G2), .B2(B2),
    .A(A), .B(B), .C(C), .D(D),
    .HUB_CLK(HUB_CLK), .HUB_LAT(HUB_LAT), .HUB_OE(HUB_OE),
    .leds_estado(leds_estado), .leds_puntaje(leds_puntaje)
);

// ---------- Reloj de 100 MHz ----------
always #5 clk = ~clk;

integer errores = 0;

// ---------- Tarea: enviar un byte por PS/2 ----------
task enviar_byte;
    input [7:0] dato;
    integer k;
    reg [10:0] trama;
    begin
        trama = {1'b1, ~^dato, dato, 1'b0};
        for (k = 0; k < 11; k = k + 1) begin
            ps2_data = trama[k];
            #200 ps2_clk = 0;
            #200 ps2_clk = 1;
        end
        #1000;
    end
endtask

// ---------- Tarea: oprimir y soltar una flecha ----------
task flecha;
    input [7:0] codigo;
    begin
        enviar_byte(8'hE0);  enviar_byte(codigo);                       // oprimir
        #3000;
        enviar_byte(8'hE0);  enviar_byte(8'hF0);  enviar_byte(codigo);  // soltar
    end
endtask

// ---------- Tarea: revisar la direccion ----------
task revisar;
    input [1:0] esperada;
    input [8*12:1] nombre;
    begin
        $display("%0s: dir=%b  cabeza=(%0d,%0d)  estado=%b",
                 nombre, uut.dir_actual, uut.x_actual, uut.y_actual, leds_estado);
        if (uut.dir_actual != esperada) begin
            $display("   ERROR: la direccion debia ser %b", esperada);
            errores = errores + 1;
        end
    end
endtask

// ---------- Secuencia de la prueba ----------
initial begin
    repeat (3) @(negedge clk);
    rst = 0;
    #5000;

    flecha(8'h75);  #60000;  revisar(2'b00, "ARRIBA");
    flecha(8'h6B);  #60000;  revisar(2'b11, "IZQUIERDA");
    flecha(8'h72);  #60000;  revisar(2'b10, "ABAJO");
    flecha(8'h74);  #60000;  revisar(2'b01, "DERECHA");

    if (errores == 0)
        $display("OK GIROS: las 4 flechas cambian la direccion");
    else
        $display("FALLO GIROS: %0d errores", errores);

    $finish;
end

endmodule
