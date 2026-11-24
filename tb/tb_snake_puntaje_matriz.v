// Apoyo de IA (Claude): generacion del testbench y
// definicion de casos de prueba.
`timescale 1ns/1ps
// ============================================================
// tb_snake_puntaje_matriz.v
// Prueba el modulo que dibuja el puntaje en la matriz:
//   - conversion binario a BCD (double dabble) para varios
//     puntajes, incluidos los limites 0 y 1023,
//   - deteccion de ceros a la izquierda (z3, z2, z1),
//   - colores: solo rojo (100) al perder, solo verde (010) al ganar,
//   - el numero enciende pixeles (no queda la pantalla negra),
//   - con rst = 1 las salidas quedan en negro.
// ============================================================
module tb_snake_puntaje_matriz;

// ---------- Entradas (reg) y salidas (wire) ----------
reg       clk = 0, rst = 1, victoria = 0;
reg [4:0] col = 0;
reg [3:0] fila = 0;
reg [9:0] puntaje = 0;
wire [2:0] rgb1, rgb2;

// ---------- Modulo a probar ----------
snake_puntaje_matriz uut (
    .clk(clk), .rst(rst), .col(col), .fila(fila),
    .puntaje(puntaje), .victoria(victoria),
    .rgb1(rgb1), .rgb2(rgb2));

// ---------- Reloj de 100 MHz ----------
always #5 clk = ~clk;

integer errores = 0;
integer c, f, encendidos, malos;
integer n;

// BCD esperado calculado con division (modelo de referencia)
function [15:0] bcd_ref;
    input [9:0] v;
    begin
        bcd_ref = {4'(v / 1000), 4'((v / 100) % 10), 4'((v / 10) % 10), 4'(v % 10)};
    end
endfunction

// ---------- Tarea: poner un puntaje y revisar los digitos ----------
task revisar_bcd;
    input [9:0] v;
    reg [15:0] esp;
    begin
        puntaje = v;
        repeat (30) @(posedge clk);   // 2 conversiones completas (12 ciclos c/u)
        #1;
        esp = bcd_ref(v);
        if (uut.digitos !== esp) begin
            $display("ERROR BCD: puntaje=%0d digitos=%h esperado=%h", v, uut.digitos, esp);
            errores = errores + 1;
        end
        // ceros a la izquierda: z3 = millar en 0, z2 = millar y centena en 0, ...
        if (uut.z3 !== (v < 1000) || uut.z2 !== (v < 100) || uut.z1 !== (v < 10)) begin
            $display("ERROR CEROS: puntaje=%0d z3z2z1=%b%b%b", v, uut.z3, uut.z2, uut.z1);
            errores = errores + 1;
        end
    end
endtask

// ---------- Tarea: barrer la pantalla y revisar colores ----------
task revisar_colores;
    input [2:0] color_esp;
    begin
        encendidos = 0;
        malos      = 0;
        for (f = 0; f < 16; f = f + 1)
            for (c = 0; c < 32; c = c + 1) begin
                col  = c;
                fila = f;
                @(posedge clk);       // el registro de salida carga
                @(posedge clk); #1;
                if (rgb1 != 3'b000) begin
                    encendidos = encendidos + 1;
                    if (rgb1 != color_esp) malos = malos + 1;
                end
                if (rgb2 != 3'b000) begin
                    encendidos = encendidos + 1;
                    if (rgb2 != color_esp) malos = malos + 1;
                end
            end
        if (encendidos == 0) begin
            $display("ERROR COLOR: no se encendio ningun pixel (puntaje=%0d)", puntaje);
            errores = errores + 1;
        end
        if (malos != 0) begin
            $display("ERROR COLOR: %0d pixeles con color distinto de %b", malos, color_esp);
            errores = errores + 1;
        end
    end
endtask

initial begin
    // reset
    repeat (3) @(posedge clk);
    rst = 0;

    // 1. Conversion BCD: valores normales y limites (0 y 1023)
    revisar_bcd(10'd0);
    revisar_bcd(10'd7);
    revisar_bcd(10'd42);
    revisar_bcd(10'd105);
    revisar_bcd(10'd999);
    revisar_bcd(10'd1000);
    revisar_bcd(10'd1023);
    // barrido completo: todos los puntajes de 0 a 1023
    for (n = 0; n < 1024; n = n + 1) revisar_bcd(n[9:0]);

    // 2. Colores: perder = rojo, ganar = verde
    revisar_bcd(10'd57);
    victoria = 0;
    revisar_colores(3'b100);
    victoria = 1;
    revisar_colores(3'b010);

    // 3. Reset durante la operacion: todo en negro
    rst = 1;
    col = 5'd10; fila = 4'd5;
    repeat (2) @(posedge clk); #1;
    if (rgb1 !== 3'b000 || rgb2 !== 3'b000) begin
        $display("ERROR RESET: rgb1=%b rgb2=%b", rgb1, rgb2);
        errores = errores + 1;
    end

    if (errores == 0)
        $display("OK NUMEROS: BCD de 0 a 1023, ceros a la izquierda, colores y reset");
    else
        $display("FALLA NUMEROS: %0d errores", errores);
    $finish;
end

endmodule
