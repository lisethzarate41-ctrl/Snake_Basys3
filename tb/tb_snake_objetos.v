// Apoyo de IA (Claude): generacion del testbench y
// definicion de casos de prueba. Simulacion revisada en Vivado.
`timescale 1ns/1ps
// ============================================================
// tb_snake_objetos.v
// Prueba la generacion de comida y veneno:
//   1. No pone un objeto en una casilla ocupada.
//   2. Genera comida y veneno.
//   3. Detecta cuando la cabeza llega a la comida.
//   4. Genera comida nueva despues de comerla.
//   5. Detecta el veneno.
//   6. Genera veneno nuevo despues de comerlo.
//   7. Sin paso, no consume nada.
//   8. LFSR: reiniciando en instantes distintos, la comida sale
//      en casillas distintas (posiciones aleatorias).
// Siempre revisa que comida y veneno no queden en la misma casilla.
// ============================================================
module tb_snake_objetos;

// ---------- Entradas (reg) y salidas (wire) ----------
reg clk              = 0;
reg rst              = 1;
reg cuerpo_listo     = 1;
reg consulta_ocupada = 0;
reg paso             = 0;
reg [4:0] x_siguiente = 0;
reg [4:0] y_siguiente = 0;

wire [4:0] x_consulta, y_consulta;
wire [4:0] x_comida,   y_comida;
wire [4:0] x_veneno,   y_veneno;
wire comida_activa;
wire veneno_activo;
wire come_comida;
wire come_veneno;
wire buscando;

// ---------- Modulo a probar ----------
snake_objetos uut (
    .clk(clk),
    .rst(rst),
    .cuerpo_listo(cuerpo_listo),
    .consulta_ocupada(consulta_ocupada),
    .x_siguiente(x_siguiente),
    .y_siguiente(y_siguiente),
    .paso(paso),
    .x_consulta(x_consulta),
    .y_consulta(y_consulta),
    .x_comida(x_comida),
    .y_comida(y_comida),
    .x_veneno(x_veneno),
    .y_veneno(y_veneno),
    .comida_activa(comida_activa),
    .veneno_activo(veneno_activo),
    .come_comida(come_comida),
    .come_veneno(come_veneno),
    .buscando(buscando)
);

// ---------- Reloj de 100 MHz ----------
always #5 clk = ~clk;

integer errores = 0;
reg [9:0] candidato_rechazado;
reg [9:0] casilla [0:4];
integer k, m, iguales;

// ---------- Tarea: comida y veneno en casillas distintas ----------
task verificar_separacion;
    begin
        if ({y_comida, x_comida} === {y_veneno, x_veneno}) begin
            $display("ERROR: comida y veneno en la misma casilla");
            errores = errores + 1;
        end
        else
            $display("OK: comida y veneno separados");
    end
endtask

// ---------- Tarea: esperar a que termine de buscar (max 20 ciclos) ----------
task esperar_juego;
    integer intentos;
    begin
        intentos = 0;
        while (buscando !== 1'b0 && intentos < 20) begin
            @(negedge clk);
            intentos = intentos + 1;
        end
        if (buscando !== 1'b0) begin
            $display("ERROR: no termino la busqueda");
            errores = errores + 1;
        end
    end
endtask

// ---------- Tarea: la cabeza avanza a (x,y) ----------
task consumir;
    input [4:0] x;
    input [4:0] y;
    begin
        @(negedge clk);
        x_siguiente = x;
        y_siguiente = y;
        paso = 1;
        @(negedge clk);
        paso = 0;
    end
endtask

// ---------- Secuencia de la prueba ----------
initial begin
    // --- PRUEBA 1: casilla ocupada -> la rechaza ---
    consulta_ocupada = 1;
    repeat (2) @(negedge clk);
    rst = 0;
    repeat (4) @(negedge clk);

    if (comida_activa !== 1'b0) begin
        $display("ERROR: puso comida sobre una casilla ocupada");
        errores = errores + 1;
    end
    if (buscando !== 1'b1) begin
        $display("ERROR: dejo de buscar");
        errores = errores + 1;
    end

    candidato_rechazado = uut.candidato;
    consulta_ocupada = 0;
    esperar_juego();
    if ({y_comida, x_comida} !== candidato_rechazado) begin
        $display("ERROR: la comida no quedo en la primera casilla libre");
        errores = errores + 1;
    end
    $display("PRUEBA 1: rechazo de casilla ocupada");

    // --- PRUEBA 2: objetos generados ---
    if (buscando !== 0 || comida_activa !== 1 || veneno_activo !== 1) begin
        $display("ERROR: objetos no generados");
        errores = errores + 1;
    end
    else
        $display("PRUEBA 2: objetos generados");
    verificar_separacion();

    // --- PRUEBA 3: la cabeza llega a la comida ---
    @(negedge clk);
    x_siguiente = x_comida;
    y_siguiente = y_comida;
    #1;
    if (come_comida !== 1) begin
        $display("ERROR: no detecta la comida");
        errores = errores + 1;
    end
    else
        $display("PRUEBA 3: comida detectada");

    // --- PRUEBA 4: comida nueva ---
    consumir(x_comida, y_comida);
    if (buscando !== 1 || comida_activa !== 0) begin
        $display("ERROR: no busca comida nueva");
        errores = errores + 1;
    end
    esperar_juego();
    if (comida_activa !== 1 || veneno_activo !== 1) begin
        $display("ERROR: comida no regenerada");
        errores = errores + 1;
    end
    else
        $display("PRUEBA 4: comida regenerada");
    verificar_separacion();

    // --- PRUEBA 5: la cabeza llega al veneno ---
    @(negedge clk);
    x_siguiente = x_veneno;
    y_siguiente = y_veneno;
    #1;
    if (come_veneno !== 1) begin
        $display("ERROR: no detecta el veneno");
        errores = errores + 1;
    end
    else
        $display("PRUEBA 5: veneno detectado");

    // --- PRUEBA 6: veneno nuevo ---
    consumir(x_veneno, y_veneno);
    if (buscando !== 1 || veneno_activo !== 0) begin
        $display("ERROR: no busca veneno nuevo");
        errores = errores + 1;
    end
    esperar_juego();
    if (comida_activa !== 1 || veneno_activo !== 1) begin
        $display("ERROR: veneno no regenerado");
        errores = errores + 1;
    end
    else
        $display("PRUEBA 6: veneno regenerado");
    verificar_separacion();

    // --- PRUEBA 7: sin paso no consume ---
    @(negedge clk);
    paso = 0;
    x_siguiente = x_comida;
    y_siguiente = y_comida;
    repeat (3) @(negedge clk);
    if (comida_activa !== 1 || buscando !== 0) begin
        $display("ERROR: consumio comida sin paso");
        errores = errores + 1;
    end
    else
        $display("PRUEBA 7: sin paso no consume comida");

    // --- PRUEBA 8: posiciones aleatorias (LFSR) ---
    // 5 reinicios separados por tiempos distintos (como Enter
    // oprimido en momentos distintos). Las 5 comidas deben quedar
    // en casillas diferentes.
    for (k = 0; k < 5; k = k + 1) begin
        repeat (7 + 29*k) @(negedge clk);
        rst = 1;
        @(negedge clk);
        rst = 0;
        esperar_juego();
        casilla[k] = {y_comida, x_comida};
        $display("  reinicio %0d: comida en (%0d,%0d)", k, x_comida, y_comida);
    end
    iguales = 0;
    for (k = 0; k < 5; k = k + 1)
        for (m = k + 1; m < 5; m = m + 1)
            if (casilla[k] == casilla[m]) iguales = iguales + 1;
    if (iguales != 0) begin
        $display("ERROR: la comida se repite (%0d pares iguales)", iguales);
        errores = errores + 1;
    end
    else
        $display("PRUEBA 8: comida en posiciones distintas");

    // Resultado
    if (errores == 0)
        $display("=== OBJETOS: TODAS LAS PRUEBAS PASARON ===");
    else
        $display("=== OBJETOS: %0d ERRORES ===", errores);

    $finish;
end

endmodule
