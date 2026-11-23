`timescale 1ns/1ps
// ============================================================
// tb_snake_top.v
// Prueba de integracion del juego completo:
//   1. Reset: objetos listos, cabeza en (15,15), estado ESPERA,
//      y el panel HUB75 recibe pulsos de CLK y LAT.
//   2. La serpiente avanza a la derecha hasta x = 31.
//   3. En la pared derecha no se sale del tablero.
//   4. Desde la pared puede girar hacia abajo.
//   5. Al comer: longitud 1 -> 2 y puntaje 0 -> 1.
//   6. Con solo la cabeza, comer veneno = PERDIO con puntaje 0.
//   7. Girar hacia una casilla con cuerpo = PERDIO (la colision se
//      revisa con la direccion NUEVA, no con la del paso anterior).
// Se usan "force" para fijar senales internas (direccion,
// estado del juego, posicion de la comida) y probar cada caso.
// ============================================================
module tb_snake_top;

// ---------- Entradas (reg) y salidas (wire) ----------
reg clk      = 0;
reg rst      = 1;
reg ps2_clk  = 1;
reg ps2_data = 1;

wire R1, G1, B1, R2, G2, B2;
wire A, B, C, D;
wire HUB_CLK, HUB_LAT, HUB_OE;
wire [1:0]  leds_estado;      // 00 ESPERA, 01 JUGANDO, 10 PERDIO, 11 GANO
wire [15:0] leds_puntaje;

// ---------- Modulo a probar ----------
// Limites pequenos: la serpiente avanza cada 5 ciclos y el panel
// muestra cada fila poco tiempo, para que la simulacion sea corta.
snake_top #(.LIMITE_MOV(4), .LIMITE_MATRIZ(7)) uut (
    .clk(clk),
    .rst(rst),
    .ps2_clk(ps2_clk),
    .ps2_data(ps2_data),
    .R1(R1), .G1(G1), .B1(B1),
    .R2(R2), .G2(G2), .B2(B2),
    .A(A), .B(B), .C(C), .D(D),
    .HUB_CLK(HUB_CLK),
    .HUB_LAT(HUB_LAT),
    .HUB_OE(HUB_OE),
    .leds_estado(leds_estado),
    .leds_puntaje(leds_puntaje)
);

// ---------- Reloj de 100 MHz ----------
always #5 clk = ~clk;

integer errores   = 0;
integer i;
reg [4:0] x0, y0;   // posicion de la cabeza en la prueba 7
integer lat       = 0;    // ciclos con LAT activo
integer clk_panel = 0;    // ciclos con CLK del panel activo

// Por si algo se queda trabado: termina a los 100 us
initial begin
    #200000;
    $display("ERROR: tiempo maximo excedido");
    $finish;
end

// ---------- Tarea: revisar la posicion de la cabeza ----------
task verificar_posicion;
    input [4:0] x_esperada;
    input [4:0] y_esperada;
    begin
        if (uut.x_actual !== x_esperada || uut.y_actual !== y_esperada) begin
            $display("ERROR POSICION: esperado (%0d,%0d), recibido (%0d,%0d)",
                     x_esperada, y_esperada, uut.x_actual, uut.y_actual);
            errores = errores + 1;
        end
        // la cabeza tambien debe estar marcada en el mapa del cuerpo
        if (uut.u_cuerpo.mapa[{uut.y_actual, uut.x_actual}] !== 1'b1) begin
            $display("ERROR CUERPO: la cabeza no esta en el mapa");
            errores = errores + 1;
        end
    end
endtask

// ---------- Tarea: esperar a que la serpiente avance ----------
task esperar_avance;
    begin
        @(posedge uut.paso);
        @(posedge clk);
        #1;
    end
endtask

// ---------- Tarea: esperar un intento de movimiento (move_tick) ----------
task esperar_intento;
    begin
        @(posedge uut.move_tick_base);
        repeat (3) @(posedge clk);   // T: guarda dir, T+1: colision, T+2: avanza
        #1;
    end
endtask

// ---------- Secuencia de la prueba ----------
initial begin
    // ====== PRUEBA 1: reset y panel ======
    repeat (3) @(negedge clk);
    rst = 0;

    for (i = 0; i < 1200; i = i + 1) begin
        @(posedge clk);
        #1;
        if (HUB_LAT) lat = lat + 1;
        if (HUB_CLK) clk_panel = clk_panel + 1;
    end

    if (uut.buscando !== 1'b0) begin
        $display("ERROR: objetos no disponibles");
        errores = errores + 1;
    end
    verificar_posicion(5'd15, 5'd15);
    if (leds_estado !== 2'b00) begin
        $display("ERROR: estado inicial (debe ser ESPERA)");
        errores = errores + 1;
    end
    if (lat < 4 || clk_panel < 128) begin
        $display("ERROR HUB75: LAT=%0d CLK=%0d", lat, clk_panel);
        errores = errores + 1;
    end
    $display("PRUEBA 1: inicializacion y HUB75 terminadas");

    // ====== PRUEBA 2: avanzar a la derecha hasta x = 31 ======
    force uut.juego_activo = 1'b1;
    force uut.buscando     = 1'b0;
    force uut.dir_actual   = 2'b01;       // derecha
    for (i = 16; i <= 31; i = i + 1) begin
        esperar_avance();
        verificar_posicion(i, 5'd15);
    end
    $display("PRUEBA 2: movimiento horizontal terminado");

    // ====== PRUEBA 3: en la pared no se sale ======
    esperar_intento();
    verificar_posicion(5'd31, 5'd15);
    $display("PRUEBA 3: pared derecha comprobada");

    // ====== PRUEBA 4: girar hacia abajo desde la pared ======
    force uut.dir_actual = 2'b10;         // abajo
    esperar_intento();
    if (uut.x_actual !== 5'd31 || uut.y_actual !== 5'd16) begin
        $display("ERROR GIRO: (%0d,%0d)", uut.x_actual, uut.y_actual);
        errores = errores + 1;
    end
    else begin
        verificar_posicion(5'd31, 5'd16);
        $display("PRUEBA 4: giro desde pared correcto");
    end

    // ====== PRUEBA 5: comer y crecer ======
    release uut.dir_actual;
    release uut.buscando;
    release uut.juego_activo;

    // reiniciar el juego
    @(negedge clk);
    rst = 1'b1;
    force uut.juego_activo = 1'b0;
    repeat (3) @(negedge clk);
    rst = 1'b0;
    repeat (10) @(negedge clk);
    if (uut.u_objetos.estado !== 3'd3) begin
        $display("ERROR: objetos no estan en JUEGO");
        errores = errores + 1;
    end

    // poner la comida justo a la derecha de la cabeza (16,15)
    force uut.dir_actual             = 2'b01;
    force uut.u_objetos.x_comida      = 5'd16;
    force uut.u_objetos.y_comida      = 5'd15;
    force uut.u_objetos.comida_activa = 1'b1;
    if (uut.longitud !== 11'd1 || leds_puntaje !== 16'd0) begin
        $display("ERROR: estado inicial de comida");
        errores = errores + 1;
    end

    @(negedge clk);
    force uut.juego_activo = 1'b1;
    esperar_avance();
    verificar_posicion(5'd16, 5'd15);

    if (uut.longitud !== 11'd2) begin
        $display("ERROR COMIDA: longitud=%0d", uut.longitud);
        errores = errores + 1;
    end
    else
        $display("OK: longitud aumento a 2");

    if (leds_puntaje !== 16'd1) begin
        $display("ERROR PUNTAJE: %0d", leds_puntaje);
        errores = errores + 1;
    end
    else
        $display("OK: puntaje aumento a 1");

    if (uut.u_cuerpo.mapa[{5'd15, 5'd15}] !== 1'b1 ||
        uut.u_cuerpo.mapa[{5'd15, 5'd16}] !== 1'b1) begin
        $display("ERROR COMIDA: cabeza y cola");
        errores = errores + 1;
    end
    else
        $display("OK: cabeza y cola conservadas");
    $display("PRUEBA 5: comida y crecimiento terminados");

    release uut.u_objetos.x_comida;
    release uut.u_objetos.y_comida;
    release uut.u_objetos.comida_activa;
    release uut.dir_actual;
    release uut.juego_activo;

    // ====== PRUEBA 6: veneno con solo la cabeza -> pierde ======
    // reiniciar el juego
    @(negedge clk);
    rst = 1'b1;
    repeat (3) @(negedge clk);
    rst = 1'b0;
    repeat (10) @(negedge clk);

    // veneno justo a la derecha de la cabeza (16,15), comida lejos
    force uut.dir_actual              = 2'b01;
    force uut.u_objetos.x_veneno      = 5'd16;
    force uut.u_objetos.y_veneno      = 5'd15;
    force uut.u_objetos.veneno_activo = 1'b1;
    force uut.u_objetos.x_comida      = 5'd2;
    force uut.u_objetos.y_comida      = 5'd2;

    // simular que se oprimio una tecla: ESPERA -> JUGANDO
    @(negedge clk);
    force uut.tecla_flecha = 1'b1;
    @(negedge clk);
    release uut.tecla_flecha;
    if (leds_estado !== 2'b01) begin
        $display("ERROR: no paso a JUGANDO");
        errores = errores + 1;
    end

    // esperar el siguiente intento de movimiento
    esperar_intento();
    @(negedge clk);
    if (leds_estado !== 2'b10) begin
        $display("ERROR VENENO: estado=%b (debe ser 10 PERDIO)", leds_estado);
        errores = errores + 1;
    end
    else
        $display("OK: con longitud 1 el veneno mata (PERDIO)");

    if (leds_puntaje !== 16'd0 || uut.longitud !== 11'd1) begin
        $display("ERROR VENENO: puntaje=%0d longitud=%0d", leds_puntaje, uut.longitud);
        errores = errores + 1;
    end
    else
        $display("OK: puntaje 0 y longitud 1");

    if (uut.x_actual !== 5'd15 || uut.y_actual !== 5'd15) begin
        $display("ERROR VENENO: la cabeza se movio a (%0d,%0d)", uut.x_actual, uut.y_actual);
        errores = errores + 1;
    end
    $display("PRUEBA 6: muerte por veneno terminada");

    release uut.u_objetos.x_veneno;
    release uut.u_objetos.y_veneno;
    release uut.u_objetos.veneno_activo;
    release uut.u_objetos.x_comida;
    release uut.u_objetos.y_comida;
    release uut.dir_actual;

    // ====== PRUEBA 7: girar hacia el cuerpo -> pierde ======
    // Caso que fallaba antes: al girar, la casilla del cuerpo se revisaba
    // con la direccion vieja (dir_g del paso anterior). Ahora colisiones
    // revisa un ciclo despues (tick_g), con dir_g ya actualizada.
    @(negedge clk);
    rst = 1'b1;
    repeat (3) @(negedge clk);
    rst = 1'b0;
    repeat (10) @(negedge clk);

    // comida y veneno lejos para que no estorben
    force uut.dir_actual              = 2'b01;   // derecha
    force uut.u_objetos.x_comida      = 5'd2;
    force uut.u_objetos.y_comida      = 5'd2;
    force uut.u_objetos.x_veneno      = 5'd3;
    force uut.u_objetos.y_veneno      = 5'd3;

    // arrancar el juego con una "tecla"
    @(negedge clk);
    force uut.tecla_flecha = 1'b1;
    @(negedge clk);
    release uut.tecla_flecha;

    // esperar un paso a la derecha y anotar donde quedo la cabeza
    esperar_avance();
    x0 = uut.x_actual;
    y0 = uut.y_actual;

    // la casilla de ARRIBA (x0, y0-1) se marca como cuerpo; la de la
    // derecha queda libre. Luego se gira hacia arriba.
    uut.u_cuerpo.mapa[{y0 - 5'd1, x0}] = 1'b1;
    force uut.dir_actual = 2'b00;                // arriba
    esperar_intento();
    @(negedge clk);
    if (leds_estado !== 2'b10) begin
        $display("ERROR GIRO-CUERPO: estado=%b (debe ser 10 PERDIO)", leds_estado);
        errores = errores + 1;
    end
    else
        $display("OK: girar hacia el cuerpo da PERDIO");
    if (uut.x_actual !== x0 || uut.y_actual !== y0) begin
        $display("ERROR GIRO-CUERPO: la cabeza se movio de (%0d,%0d) a (%0d,%0d)",
                 x0, y0, uut.x_actual, uut.y_actual);
        errores = errores + 1;
    end
    else
        $display("OK: la cabeza no entra al cuerpo, queda en (%0d,%0d)", x0, y0);
    $display("PRUEBA 7: giro hacia el cuerpo terminado");

    release uut.u_objetos.x_comida;
    release uut.u_objetos.y_comida;
    release uut.u_objetos.x_veneno;
    release uut.u_objetos.y_veneno;
    release uut.dir_actual;

    // ====== Resultado ======
    if (errores == 0)
        $display("TODAS LAS PRUEBAS DE INTEGRACION PASARON");
    else
        $display("FALLARON %0d COMPROBACIONES", errores);
    $display("LAT=%0d CLK=%0d", lat, clk_panel);
    $finish;
end

endmodule
