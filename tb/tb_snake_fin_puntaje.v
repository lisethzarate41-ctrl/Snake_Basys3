`timescale 1ns/1ps
// ============================================================
// tb_snake_fin_puntaje.v
// Juega hasta chocar con la pared derecha y revisa que el panel
// muestre el puntaje (0) en rojo, centrado. Imprime el panel:
//   . = apagado   R = rojo   G = verde   # = otro color
// ============================================================
module tb_snake_fin_puntaje;

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
snake_top #(.LIMITE_MOV(200), .LIMITE_MATRIZ(20)) uut (
    .clk(clk), .rst(rst),
    .ps2_clk(ps2_clk), .ps2_data(ps2_data),
    .R1(R1), .G1(G1), .B1(B1), .R2(R2), .G2(G2), .B2(B2),
    .A(A), .B(B), .C(C), .D(D),
    .HUB_CLK(HUB_CLK), .HUB_LAT(HUB_LAT), .HUB_OE(HUB_OE),
    .leds_estado(leds_estado), .leds_puntaje(leds_puntaje)
);

// ---------- Reloj de 100 MHz ----------
always #5 clk = ~clk;

// ---------- Panel virtual: registro de 32 columnas por mitad ----------
reg [2:0] sh1 [0:31];
reg [2:0] sh2 [0:31];
reg [2:0] img [0:1023];          // imagen 32x32, indice = y*32 + x
integer i, x, y, lats = 0, rojos = 0, otros = 0, errores = 0;

always @(posedge HUB_CLK) begin
    for (i = 31; i > 0; i = i - 1) begin
        sh1[i] = sh1[i-1];
        sh2[i] = sh2[i-1];
    end
    sh1[0] = {R1, G1, B1};
    sh2[0] = {R2, G2, B2};
end

always @(posedge HUB_LAT) begin
    for (i = 0; i < 32; i = i + 1) begin
        img[{D, C, B, A} * 32 + (31 - i)]      = sh1[i];
        img[({D, C, B, A} + 16) * 32 + (31 - i)] = sh2[i];
    end
    lats = lats + 1;
end

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

// ---------- Secuencia de la prueba ----------
initial begin
    repeat (3) @(negedge clk);
    rst = 0;
    #5000;

    // D (derecha) y esperar a chocar con la pared
    enviar_byte(8'h23);
    wait (leds_estado == 2'b10);           // PERDIO
    $display("Choco: cabeza en (%0d,%0d), puntaje=%0d", uut.x_actual, uut.y_actual, leds_puntaje);

    // esperar 2 barridos completos del panel
    lats = 0;
    wait (lats == 40);

    // imprimir y contar
    for (y = 0; y < 32; y = y + 1) begin
        for (x = 0; x < 32; x = x + 1) begin
            if (img[y*32 + x] == 3'b000)
                $write(".");
            else if (img[y*32 + x] == 3'b100) begin
                $write("R");
                rojos = rojos + 1;
            end
            else if (img[y*32 + x] == 3'b010)
                $write("G");
            else begin
                $write("#");
                otros = otros + 1;
            end
        end
        $write("\n");
    end

    // el "0" grande tiene 6x10 - 2x6 = 48 pixeles rojos
    if (rojos != 48 || otros != 0) begin
        $display("ERROR: %0d pixeles rojos (esperado 48), %0d de otro color", rojos, otros);
        errores = errores + 1;
    end

    if (errores == 0)
        $display("OK FIN: al perder se ve el puntaje 0 en rojo");
    else
        $display("FALLO FIN: %0d errores", errores);
    $finish;
end

endmodule
