// Apoyo de IA (Claude): generacion del testbench y
// definicion de casos de prueba. Simulacion revisada en Vivado.
`timescale 1ns/1ps
// Testbench de snake_dibujo.
// Hace de snake_cuerpo con un mapa pequeño (mapa_tb) y de controlador
// HUB75 poniendo col y fila. Compara rgb1/rgb2 con lo esperado.
module tb_snake_dibujo;

reg        clk = 0;
reg        rst = 1;
reg  [4:0] col = 0;
reg  [3:0] fila = 0;
reg  [4:0] x_cabeza = 5'd15, y_cabeza = 5'd15;
reg  [4:0] x_comida = 5'd3,  y_comida = 5'd20;
reg  [4:0] x_veneno = 5'd10, y_veneno = 5'd5;
reg        comida_activa = 1, veneno_activo = 1;
reg        fin_juego = 0;

wire [4:0] x_pixel, y_pixel;
wire [2:0] rgb1, rgb2;

// --- modelo de snake_cuerpo: mapa de 1024 bits, igual que el real ---
reg  [1023:0] mapa_tb;
wire pixel_serpiente = mapa_tb[{y_pixel, x_pixel}];

snake_dibujo uut (
    .clk(clk), .rst(rst), .fase(2'b00), .col(col), .fila(fila),
    .x_cabeza(x_cabeza), .y_cabeza(y_cabeza),
    .pixel_serpiente(pixel_serpiente),
    .x_comida(x_comida), .y_comida(y_comida), .comida_activa(comida_activa),
    .x_veneno(x_veneno), .y_veneno(y_veneno), .veneno_activo(veneno_activo),
    .fin_juego(fin_juego),
    .x_pixel(x_pixel), .y_pixel(y_pixel),
    .rgb1(rgb1), .rgb2(rgb2)
);

always #5 clk = ~clk;   // 100 MHz

integer errores = 0;
integer f, c;

// modelo de referencia: color de (x,y) escrito con if, fácil de leer
function [2:0] color_ref(input [4:0] x, input [4:0] y);
    reg es_cab, es_serp, es_com, es_ven;
begin
    es_cab  = (x == x_cabeza) && (y == y_cabeza);
    es_serp = es_cab || mapa_tb[{y, x}];
    es_com  = comida_activa && (x == x_comida) && (y == y_comida);
    es_ven  = veneno_activo && (x == x_veneno) && (y == y_veneno);
    if (es_serp && fin_juego) color_ref = 3'b111;   // blanco
    else if (es_cab)          color_ref = 3'b110;   // amarillo
    else if (es_serp)         color_ref = 3'b010;   // verde
    else if (es_com)          color_ref = 3'b100;   // rojo
    else if (es_ven)          color_ref = 3'b101;   // magenta
    else                      color_ref = 3'b000;   // negro
end
endfunction

// pone (col, fila), espera 2 ciclos (una vuelta de mitad) y revisa ambas mitades
task pixel(input [8*4-1:0] id, input [4:0] cx, input [3:0] fl,
           input [2:0] e1, input [2:0] e2);
begin
    @(negedge clk) begin col = cx; fila = fl; end
    @(negedge clk); @(negedge clk); @(negedge clk);
    if (rgb1 !== e1 || rgb2 !== e2) begin
        $display("ERROR %s: col=%0d fila=%0d rgb1=%b (esp %b) rgb2=%b (esp %b)",
                 id, cx, fl, rgb1, e1, rgb2, e2);
        errores = errores + 1;
    end else
        $display("OK    %s: (%0d,%0d)=%b  (%0d,%0d)=%b", id, cx, fl, rgb1, cx, fl+16, rgb2);
end
endtask

initial begin
    $dumpfile("tb_snake_dibujo.vcd");
    $dumpvars(0, tb_snake_dibujo);

    // serpiente: cabeza (15,15), cuerpo (14,15) (13,15) (13,16)
    mapa_tb = 0;
    mapa_tb[{5'd15, 5'd15}] = 1;
    mapa_tb[{5'd15, 5'd14}] = 1;
    mapa_tb[{5'd15, 5'd13}] = 1;
    mapa_tb[{5'd16, 5'd13}] = 1;

    // D1: reset -> negro
    @(negedge clk); @(negedge clk);
    if (rgb1 !== 3'b000 || rgb2 !== 3'b000 || uut.mitad !== 1'b0) begin
        $display("ERROR D1: reset no deja negro"); errores = errores + 1;
    end else $display("OK    D1: reset -> rgb1=rgb2=000, mitad=0");
    @(negedge clk) rst = 0;

    // D2: cabeza (15,15) arriba; abajo (15,31) fondo
    pixel("D2", 5'd15, 4'd15, 3'b110, 3'b000);
    // D3: cuerpo (14,15) arriba; (14,31) fondo
    pixel("D3", 5'd14, 4'd15, 3'b010, 3'b000);
    // D4: (13,0) fondo arriba; (13,16) cuerpo abajo
    pixel("D4", 5'd13, 4'd0, 3'b000, 3'b010);
    // D5: comida (3,20) -> fila 4, abajo
    pixel("D5", 5'd3, 4'd4, 3'b000, 3'b100);
    // D6: veneno (10,5) -> fila 5, arriba
    pixel("D6", 5'd10, 4'd5, 3'b101, 3'b000);
    // D7: comida inactiva -> no se pinta
    comida_activa = 0;
    pixel("D7", 5'd3, 4'd4, 3'b000, 3'b000);
    comida_activa = 1;

    // D8: x_pixel / y_pixel = (col, {mitad, fila})
    @(negedge clk) begin col = 5'd7; fila = 4'd9; end
    #1;
    if (x_pixel !== 5'd7 || y_pixel !== {uut.mitad, 4'd9}) begin
        $display("ERROR D8: x/y_pixel"); errores = errores + 1;
    end else $display("OK    D8: x_pixel=%0d y_pixel=%0d (mitad=%b)", x_pixel, y_pixel, uut.mitad);

    // D9: fin_juego -> serpiente blanca, comida sigue roja
    fin_juego = 1;
    pixel("D9a", 5'd15, 4'd15, 3'b111, 3'b000);
    pixel("D9b", 5'd13, 4'd0,  3'b000, 3'b111);
    pixel("D9c", 5'd3,  4'd4,  3'b000, 3'b100);
    fin_juego = 0;

    // D10: prioridad, comida debajo de la cabeza -> gana la cabeza
    x_comida = 5'd15; y_comida = 5'd15;
    pixel("D10", 5'd15, 4'd15, 3'b110, 3'b000);
    // D11: comida y veneno en la misma casilla -> gana la comida
    x_comida = 5'd10; y_comida = 5'd5;
    pixel("D11", 5'd10, 4'd5, 3'b100, 3'b000);
    x_comida = 5'd3; y_comida = 5'd20;

    // D12: barrido completo de las 16 líneas x 32 columnas (1024 píxeles)
    begin : barrido
        integer err0;
        err0 = errores;
        for (f = 0; f < 16; f = f + 1)
            for (c = 0; c < 32; c = c + 1) begin
                @(negedge clk) begin col = c; fila = f; end
                @(negedge clk); @(negedge clk); @(negedge clk);
                if (rgb1 !== color_ref(c, f) || rgb2 !== color_ref(c, f + 16)) begin
                    $display("ERROR D12: (%0d,%0d) rgb1=%b esp %b | (%0d,%0d) rgb2=%b esp %b",
                             c, f, rgb1, color_ref(c, f), c, f + 16, rgb2, color_ref(c, f + 16));
                    errores = errores + 1;
                end
            end
        if (errores == err0) $display("OK    D12: barrido completo, 1024 pixeles iguales al modelo");
    end

    // D13: rgb1 se queda quieto mientras mitad = 1
    @(negedge clk) begin col = 5'd15; fila = 4'd15; end
    @(negedge clk); @(negedge clk); @(negedge clk);
    repeat (6) begin
        @(negedge clk);
        if (rgb1 !== 3'b110) begin
            $display("ERROR D13: rgb1 cambió a %b", rgb1); errores = errores + 1;
        end
    end
    $display("OK    D13: rgb1 estable 6 ciclos seguidos");

    // D14: reset en medio -> negro
    @(negedge clk) rst = 1;
    @(negedge clk);
    if (rgb1 !== 3'b000 || rgb2 !== 3'b000) begin
        $display("ERROR D14: reset en medio"); errores = errores + 1;
    end else $display("OK    D14: reset en medio -> negro");
    rst = 0;

    if (errores == 0) $display("=== DIBUJO: TODAS LAS PRUEBAS PASARON ===");
    else              $display("=== DIBUJO: %0d ERRORES ===", errores);
    $finish;
end

endmodule
