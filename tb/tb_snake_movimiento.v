`timescale 1ns/1ps
// ============================================================
// tb_snake_movimiento.v
// Prueba el registro de la cabeza:
//   - arranca en (15,15),
//   - avanza a la derecha y hacia abajo,
//   - no avanza si hay colision o si no esta habilitado,
//   - el reset la devuelve a (15,15).
// ============================================================
module tb_snake_movimiento;

// ---------- Entradas (reg) y salidas (wire) ----------
reg clk       = 0;
reg rst       = 1;
reg move_tick = 0;
reg habilitar = 0;
reg colision  = 0;
reg [1:0] dir_actual = 2'b01;      // derecha

wire [4:0] x_actual;
wire [4:0] y_actual;
wire [4:0] x_siguiente;
wire [4:0] y_siguiente;
wire paso;

// ---------- Modulo a probar ----------
snake_movimiento uut (
    .clk(clk),
    .rst(rst),
    .move_tick(move_tick),
    .habilitar(habilitar),
    .dir_actual(dir_actual),
    .colision(colision),
    .x_actual(x_actual),
    .y_actual(y_actual),
    .x_siguiente(x_siguiente),
    .y_siguiente(y_siguiente),
    .paso(paso)
);

// ---------- Reloj de 100 MHz ----------
always #5 clk = ~clk;

integer errores = 0;

// ---------- Tarea: esperar un flanco y revisar la cabeza ----------
task revisar;
    input [4:0] x_esp;
    input [4:0] y_esp;
    begin
        @(posedge clk);
        #1;
        if (x_actual !== x_esp || y_actual !== y_esp) begin
            $display("ERROR: cabeza en (%0d,%0d), esperado (%0d,%0d)", x_actual, y_actual, x_esp, y_esp);
            errores = errores + 1;
        end
        else
            $display("OK: cabeza en (%0d,%0d)", x_actual, y_actual);
    end
endtask

// ---------- Secuencia de la prueba ----------
initial begin
    // 1. Con reset la cabeza esta en (15,15)
    revisar(15, 15);

    // 2. Sin reset, habilitado y con move_tick -> avanza a la derecha
    @(negedge clk);
    rst       = 0;
    habilitar = 1;
    move_tick = 1;
    revisar(16, 15);

    // 3. Cambia la direccion a abajo -> y aumenta
    @(negedge clk);
    dir_actual = 2'b10;
    revisar(16, 16);

    // 4. Con colision no avanza
    @(negedge clk);
    colision = 1;
    revisar(16, 16);

    // 5. Sin habilitar no avanza
    @(negedge clk);
    colision  = 0;
    habilitar = 0;
    revisar(16, 16);

    // 6. Reset -> vuelve a (15,15)
    @(negedge clk);
    rst = 1;
    revisar(15, 15);

    // Resultado
    if (errores == 0)
        $display("OK MOVIMIENTO: 6 verificaciones");
    else
        $display("FALLO MOVIMIENTO: %0d errores", errores);

    $finish;
end

endmodule
