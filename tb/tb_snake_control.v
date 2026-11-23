// Apoyo de IA (Claude): generacion del testbench y
// definicion de casos de prueba. Simulacion revisada en Vivado.
`timescale 1ns/1ps
// Testbench de snake_control.
// Parte 1: casos dirigidos (una historia de juego, paso a paso).
// Parte 2: 20000 ciclos con entradas al azar, comparando contra un
//          modelo escrito con if (solo en el testbench, fácil de leer).
module tb_snake_control;

reg clk = 0;
reg rst = 1;
reg tecla_flecha = 0, move_tick = 0, colision = 0, buscando = 0, tablero_lleno = 0;

wire juego_activo, fin_juego, victoria;
wire [1:0] estado;

snake_control uut (
    .clk(clk), .rst(rst), .tecla_flecha(tecla_flecha), .move_tick(move_tick),
    .colision(colision), .buscando(buscando), .tablero_lleno(tablero_lleno),
    .juego_activo(juego_activo), .fin_juego(fin_juego), .victoria(victoria),
    .estado(estado)
);

always #5 clk = ~clk;   // 100 MHz

localparam ESPERA = 2'b00, JUGANDO = 2'b01, PERDIO = 2'b10, GANO = 2'b11;

integer errores = 0;
integer i;

// pone las entradas, da UN flanco y revisa estado y salidas
task paso(input [8*4-1:0] id, input r, input t, input mt, input col, input b, input l,
          input [1:0] esp);
    reg ja, fj, vi;
begin
    @(negedge clk) begin
        rst = r; tecla_flecha = t; move_tick = mt; colision = col; buscando = b; tablero_lleno = l;
    end
    @(negedge clk);   // ya pasó el flanco de subida
    ja = (esp == JUGANDO); fj = esp[1]; vi = (esp == GANO);
    if (estado !== esp || juego_activo !== ja || fin_juego !== fj || victoria !== vi) begin
        $display("ERROR %s: estado=%b (esp %b) activo=%b fin=%b vic=%b",
                 id, estado, esp, juego_activo, fin_juego, victoria);
        errores = errores + 1;
    end else
        $display("OK    %s: estado=%b  activo=%b fin=%b vic=%b",
                 id, estado, juego_activo, fin_juego, victoria);
end
endtask

// ---------- modelo de referencia (con if, solo para comparar) ----------
reg [1:0] modelo;
function [1:0] siguiente(input [1:0] s, input r, input t, input mt, input col, input b, input l);
    reg choque;
begin
    choque = mt && col && !b;
    if (r)                          siguiente = ESPERA;
    else if (s == ESPERA)           siguiente = t ? JUGANDO : ESPERA;
    else if (s == JUGANDO) begin
        if (l)                      siguiente = GANO;
        else if (choque)            siguiente = PERDIO;
        else                        siguiente = JUGANDO;
    end
    else                            siguiente = s;   // PERDIO y GANO se quedan
end
endfunction

initial begin
    $dumpfile("tb_snake_control.vcd");
    $dumpvars(0, tb_snake_control);

    //    id      rst tec tick col bus llen  esperado
    paso("C1 ", 1,  0,  0,   0,  0,  0,   ESPERA);   // reinicio
    paso("C2 ", 0,  0,  0,   0,  0,  0,   ESPERA);   // sin tecla se queda quieta
    paso("C3 ", 0,  0,  1,   1,  0,  0,   ESPERA);   // tick y colision no importan en ESPERA
    paso("C4 ", 0,  1,  0,   0,  0,  0,   JUGANDO);  // flecha -> empieza
    paso("C5 ", 0,  0,  1,   0,  0,  0,   JUGANDO);  // tick sin choque: sigue
    paso("C6 ", 0,  0,  0,   1,  0,  0,   JUGANDO);  // colision SIN tick: aún puede girar
    paso("C7 ", 0,  0,  1,   1,  1,  0,   JUGANDO);  // tick+colision pero objetos buscando
    paso("C8 ", 0,  1,  0,   0,  0,  0,   JUGANDO);  // otra flecha: sigue jugando
    paso("C9 ", 0,  0,  1,   1,  0,  0,   PERDIO);   // choque real -> game over
    paso("C10", 0,  1,  0,   0,  0,  0,   PERDIO);   // flecha no revive
    paso("C11", 0,  0,  1,   0,  0,  1,   PERDIO);   // nada lo saca de PERDIO
    paso("C12", 1,  0,  0,   0,  0,  0,   ESPERA);   // botón de reinicio
    paso("C13", 0,  1,  0,   0,  0,  0,   JUGANDO);
    paso("C14", 0,  0,  0,   0,  0,  1,   GANO);     // tablero lleno -> victoria
    paso("C15", 0,  1,  1,   1,  0,  0,   GANO);     // se queda en GANO
    paso("C16", 1,  1,  0,   0,  0,  0,   ESPERA);   // rst gana sobre la flecha
    paso("C17", 0,  1,  0,   0,  0,  0,   JUGANDO);
    paso("C18", 0,  0,  1,   1,  0,  1,   GANO);     // lleno y choque juntos: gana
    paso("C19", 1,  0,  0,   0,  0,  0,   ESPERA);
    paso("C20", 0,  1,  0,   0,  0,  0,   JUGANDO);
    paso("C21", 1,  0,  1,   1,  0,  0,   ESPERA);   // rst en pleno juego

    // ---------- parte 2: al azar contra el modelo ----------
    modelo = estado;
    for (i = 0; i < 20000; i = i + 1) begin
        @(negedge clk) begin
            rst           = ($random % 50) == 0;   // reinicio poco frecuente
            tecla_flecha  = ($random % 8) == 0;
            move_tick     = $random;
            colision      = ($random % 6) == 0;
            buscando      = $random;
            tablero_lleno = ($random % 200) == 0;
            modelo = siguiente(modelo, rst, tecla_flecha, move_tick, colision, buscando, tablero_lleno);
        end
        @(posedge clk); #1;
        if (estado !== modelo) begin
            errores = errores + 1;
            if (errores < 10) $display("ERROR azar ciclo %0d: estado=%b modelo=%b", i, estado, modelo);
        end
    end
    $display("Azar: 20000 ciclos comparados contra el modelo");

    if (errores == 0) $display("=== TODO OK: 21/21 casos + 20000 ciclos al azar ===");
    else              $display("=== %0d ERRORES ===", errores);
    $finish;
end

endmodule
