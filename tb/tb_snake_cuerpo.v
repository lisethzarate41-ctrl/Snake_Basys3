`timescale 1ns/1ps
// Testbench de snake_cuerpo.
// Simula a snake_movimiento con una tarea "mover" que da un paso a una casilla.
module tb_snake_cuerpo;

reg        clk = 0;
reg        rst = 1;
reg        paso = 0;
reg  [4:0] x_sig = 0, y_sig = 0;
reg        come_comida = 0, come_veneno = 0;
reg  [4:0] x_pix = 0, y_pix = 0;
reg  [4:0] x_obj = 0, y_obj = 0;
wire obj_ocupada;

wire        casilla_ocupada, casilla_es_cola, cola_se_libera, pixel_serpiente;
wire [10:0] longitud;

snake_cuerpo uut (
    .clk(clk), .rst(rst), .paso(paso),
    .x_siguiente(x_sig), .y_siguiente(y_sig),
    .come_comida(come_comida), .come_veneno(come_veneno),
    .x_pixel(x_pix), .y_pixel(y_pix),
    .x_obj(x_obj), .y_obj(y_obj), .obj_ocupada(obj_ocupada),
    .casilla_ocupada(casilla_ocupada), .casilla_es_cola(casilla_es_cola),
    .cola_se_libera(cola_se_libera), .pixel_serpiente(pixel_serpiente),
    .longitud(longitud)
);

always #5 clk = ~clk;

integer errores = 0;
integer i;

// mueve la cabeza a (x,y); comida/veneno indican qué hay en esa casilla
task mover(input [4:0] x, input [4:0] y, input c, input v);
begin
    @(negedge clk);
    x_sig = x; y_sig = y; come_comida = c; come_veneno = v; paso = 1;
    @(negedge clk);
    paso = 0; come_comida = 0; come_veneno = 0;
    repeat (3) @(negedge clk);          // deja tiempo para retirar veneno
end
endtask

// pregunta por la casilla (x,y) usando el puerto de consulta de colisiones
task consultar(input [8*4-1:0] id, input [4:0] x, input [4:0] y,
               input e_ocup, input e_cola);
begin
    x_sig = x; y_sig = y; #1;
    if (casilla_ocupada !== e_ocup || casilla_es_cola !== e_cola) begin
        $display("ERROR %s: (%0d,%0d) ocupada=%b es_cola=%b | esperado %b %b",
                 id, x, y, casilla_ocupada, casilla_es_cola, e_ocup, e_cola);
        errores = errores + 1;
    end else
        $display("OK    %s: (%0d,%0d) ocupada=%b es_cola=%b se_libera=%b",
                 id, x, y, casilla_ocupada, casilla_es_cola, cola_se_libera);
end
endtask

task check_long(input [8*4-1:0] id, input [10:0] e);
begin
    #1;
    if (longitud !== e) begin
        $display("ERROR %s: longitud=%0d esperado=%0d", id, longitud, e);
        errores = errores + 1;
    end else $display("OK    %s: longitud=%0d", id, longitud);
end
endtask

// revisa un pixel por el puerto de dibujo
task check_pix(input [8*4-1:0] id, input [4:0] x, input [4:0] y, input e);
begin
    x_pix = x; y_pix = y; #1;
    if (pixel_serpiente !== e) begin
        $display("ERROR %s: pixel (%0d,%0d)=%b esperado %b", id, x, y, pixel_serpiente, e);
        errores = errores + 1;
    end else $display("OK    %s: pixel (%0d,%0d)=%b", id, x, y, pixel_serpiente);
end
endtask

initial begin
    $dumpfile("tb_snake_cuerpo.vcd");
    $dumpvars(0, tb_snake_cuerpo);

    // C1: reset -> solo (15,15)
    @(negedge clk); @(negedge clk); rst = 0;
    check_long("C1", 1);
    check_pix ("C1b", 15, 15, 1);
    check_pix ("C1c", 16, 15, 0);

    // Puerto independiente usado por snake_objetos
    x_obj=15; y_obj=15; #1;
    if(obj_ocupada!==1) begin $display("ERROR puerto objetos"); errores=errores+1; end

    // C11: comer con longitud 1 -> 2
    mover(16, 15, 1, 0); check_long("C11", 2);
    // crecer hasta 5: serpiente horizontal (15..19, 15), cola en (15,15)
    mover(17, 15, 1, 0); mover(18, 15, 1, 0); mover(19, 15, 1, 0);
    check_long("C8", 5);

    // C2: casilla libre
    consultar("C2", 20, 15, 0, 0);
    // C3: segmento del medio
    consultar("C3", 17, 15, 1, 0);
    // C4: la cola, sin comida -> se libera
    come_comida = 0;
    consultar("C4", 15, 15, 1, 1);
    if (cola_se_libera !== 1) begin $display("ERROR C4: se_libera"); errores = errores + 1; end
    // C5: la cola, con comida -> no se libera
    come_comida = 1; #1;
    if (cola_se_libera !== 0) begin $display("ERROR C5: se_libera"); errores = errores + 1; end
    else $display("OK    C5: con comida, cola_se_libera=0");
    come_comida = 0;

    // C7: paso normal: cabeza nueva (19,16), cola (15,15) se borra
    mover(19, 16, 0, 0);
    check_long("C7", 5);
    check_pix ("C7b", 19, 16, 1);
    check_pix ("C7c", 15, 15, 0);
    consultar("C7d", 16, 15, 1, 1);       // la cola ahora es (16,15)

    // C9: veneno con longitud 5 -> 4
    mover(19, 17, 0, 1);
    check_long("C9", 4);

    // C10: veneno hasta longitud 1 y uno más
    mover(19, 18, 0, 1); check_long("C10a", 3);
    mover(19, 19, 0, 1); check_long("C10b", 2);
    mover(19, 20, 0, 1); check_long("C10c", 1);
    mover(19, 21, 0, 1); check_long("C10d", 1);
    check_pix ("C10e", 19, 21, 1);
    check_pix ("C10f", 19, 20, 0);

    // C13: sin paso no cambia nada
    x_sig = 0; y_sig = 0; repeat (10) @(negedge clk);
    check_long("C13", 1);
    check_pix ("C13b", 0, 0, 0);

    // C12: más de 1024 pasos para que los punteros den la vuelta
    for (i = 0; i < 1100; i = i + 1)
        mover(i % 32, (i / 32) % 32, 0, 0);
    check_long("C12", 1);
    check_pix ("C12b", (1099 % 32), ((1099 / 32) % 32), 1);
    check_pix ("C12c", (1098 % 32), ((1098 / 32) % 32), 0);
    // crecer 3 después de la vuelta y revisar la cola
    mover(13, 2, 1, 0); mover(14, 2, 1, 0); mover(15, 2, 1, 0);
    check_long("C12d", 4);
    consultar("C12e", (1099 % 32), ((1099 / 32) % 32), 1, 1);

    // C6: la cabeza entra justo en la casilla que deja la cola
    // reset y crecer en un cuadrado 2x2: (15,15)(16,15)(16,16)(15,16)
    @(negedge clk) rst = 1; @(negedge clk) rst = 0;
    mover(16, 15, 1, 0); mover(16, 16, 1, 0); mover(15, 16, 1, 0);
    check_long("C6a", 4);
    consultar("C6b", 15, 15, 1, 1);       // arriba de la cabeza está la cola
    mover(15, 15, 0, 0);                  // la cabeza entra donde estaba la cola
    check_pix ("C6c", 15, 15, 1);         // la casilla debe seguir ocupada
    check_long("C6d", 4);
    consultar("C6e", 16, 15, 1, 1);       // la cola nueva es (16,15)

    // C14: reset en medio del juego
    @(negedge clk) rst = 1; @(negedge clk) rst = 0;
    check_long("C14", 1);
    check_pix ("C14b", 15, 15, 1);
    check_pix ("C14c", 14, 2, 0);

    if (errores == 0) $display("\n=== CUERPO: TODAS LAS PRUEBAS PASARON ===");
    else              $display("\n=== CUERPO: %0d ERRORES ===", errores);
    $finish;
end

endmodule
