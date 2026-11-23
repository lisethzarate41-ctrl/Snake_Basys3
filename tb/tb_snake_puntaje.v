// Apoyo de IA (Claude): generacion del testbench y
// definicion de casos de prueba. Simulacion revisada en Vivado.
`timescale 1ns/1ps
// ============================================================
// tb_snake_puntaje.v
// Prueba el contador de puntaje:
//   - empieza en 0,
//   - sube 1 por cada ciclo con comio_comida = 1,
//   - no cambia si no come,
//   - el reset lo devuelve a 0.
// ============================================================
module tb_snake_puntaje;

// ---------- Entradas (reg) y salidas (wire) ----------
reg clk          = 0;
reg rst          = 1;
reg comio_comida = 0;

wire [15:0] puntaje;

// ---------- Modulo a probar ----------
snake_puntaje uut (
    .clk(clk),
    .rst(rst),
    .comio_comida(comio_comida),
    .puntaje(puntaje)
);

// ---------- Reloj de 100 MHz ----------
always #5 clk = ~clk;

integer errores = 0;

// ---------- Tarea: esperar un flanco y revisar el puntaje ----------
task revisar;
    input [15:0] esperado;
    begin
        @(posedge clk);
        #1;
        if (puntaje !== esperado) begin
            $display("ERROR: puntaje=%0d, esperado=%0d", puntaje, esperado);
            errores = errores + 1;
        end
        else
            $display("OK: puntaje=%0d", puntaje);
    end
endtask

// ---------- Secuencia de la prueba ----------
initial begin
    // 1. Con reset vale 0
    revisar(0);

    // 2. Come en dos ciclos seguidos -> 1, 2
    @(negedge clk);
    rst          = 0;
    comio_comida = 1;
    revisar(1);
    revisar(2);

    // 3. Deja de comer -> se queda en 2
    @(negedge clk);
    comio_comida = 0;
    revisar(2);

    // 4. Reset -> vuelve a 0
    @(negedge clk);
    rst = 1;
    revisar(0);

    // Resultado
    if (errores == 0)
        $display("OK PUNTAJE: 5 verificaciones");
    else
        $display("FALLO PUNTAJE: %0d errores", errores);

    $finish;
end

endmodule
