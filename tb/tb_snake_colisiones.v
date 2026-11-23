// Apoyo de IA (Claude): generacion del testbench y
// definicion de casos de prueba. Simulacion revisada en Vivado.
`timescale 1ns/1ps
// ============================================================
// tb_snake_colisiones.v
// Prueba la deteccion de choques (modulo combinacional):
//   - las 4 paredes,
//   - chocar con el cuerpo,
//   - la excepcion de la cola (si la cola se mueve, no es choque).
// ============================================================
module tb_snake_colisiones;

// ---------- Entradas (reg) y salidas (wire) ----------
reg [4:0] x_actual = 15;
reg [4:0] y_actual = 15;
reg [1:0] dir_actual = 2'b00;      // 00 arriba, 01 der, 10 abajo, 11 izq
reg casilla_ocupada = 0;
reg casilla_es_cola = 0;
reg cola_se_libera  = 0;

wire colision;
wire colision_pared;
wire colision_cuerpo;

// ---------- Modulo a probar ----------
snake_colisiones uut (
    .x_actual(x_actual),
    .y_actual(y_actual),
    .dir_actual(dir_actual),
    .casilla_ocupada(casilla_ocupada),
    .casilla_es_cola(casilla_es_cola),
    .cola_se_libera(cola_se_libera),
    .colision(colision),
    .colision_pared(colision_pared),
    .colision_cuerpo(colision_cuerpo)
);

integer errores = 0;

// ---------- Tarea: comparar colision con lo esperado ----------
task verificar;
    input [8*20:1] nombre;
    input esperado;
    begin
        #1;
        if (colision !== esperado) begin
            $display("ERROR %0s: colision=%b, esperado=%b", nombre, colision, esperado);
            errores = errores + 1;
        end
        else
            $display("OK %0s", nombre);
    end
endtask

// ---------- Secuencia de la prueba ----------
initial begin
    // Centro del tablero, nada ocupado
    verificar("centro libre", 0);

    // Paredes: en el borde y mirando hacia afuera
    x_actual = 15;  y_actual = 0;   dir_actual = 2'b00;
    verificar("pared arriba", 1);

    x_actual = 31;  y_actual = 15;  dir_actual = 2'b01;
    verificar("pared derecha", 1);

    x_actual = 15;  y_actual = 31;  dir_actual = 2'b10;
    verificar("pared abajo", 1);

    x_actual = 0;   y_actual = 15;  dir_actual = 2'b11;
    verificar("pared izquierda", 1);

    // Cuerpo: la casilla siguiente esta ocupada
    x_actual = 15;
    casilla_ocupada = 1;
    verificar("cuerpo ocupado", 1);

    // Cola: esta ocupada, pero se libera en este paso -> no es choque
    casilla_es_cola = 1;
    cola_se_libera  = 1;
    verificar("cola liberada", 0);

    // Cola que NO se libera (acaba de comer) -> si es choque
    cola_se_libera = 0;
    verificar("cola no liberada", 1);

    // Resultado
    if (errores == 0)
        $display("OK COLISIONES: 8 verificaciones");
    else
        $display("FALLO COLISIONES: %0d errores", errores);

    $finish;
end

endmodule
