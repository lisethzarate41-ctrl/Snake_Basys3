`timescale 1ns/1ps
// ============================================================
// tb_snake_direccion.v
// Prueba la lectura del teclado PS/2 y las reglas de giro:
//   - las 4 flechas en espera (se aceptan todas),
//   - soltar una tecla (E0 F0 xx) no cambia nada,
//   - en juego: no se puede devolver y solo 1 giro por paso,
//   - Enter genera el pulso tecla_enter.
//   - Las letras W A S D tambien mueven (sin E0).
//   - Una trama con paridad mala o bit de parada en 0 se descarta.
// Direccion: 00 arriba, 01 derecha, 10 abajo, 11 izquierda.
// ============================================================
module tb_snake_direccion;

// ---------- Entradas (reg) y salidas (wire) ----------
reg clk          = 0;
reg rst          = 1;
reg ps2_clk      = 1;
reg ps2_data     = 1;
reg move_tick    = 0;
reg juego_activo = 0;

wire [1:0] dir_actual;
wire tecla_flecha;
wire tecla_enter;

// ---------- Modulo a probar ----------
snake_direccion uut (
    .clk(clk),
    .rst(rst),
    .ps2_clk(ps2_clk),
    .ps2_data(ps2_data),
    .move_tick(move_tick),
    .juego_activo(juego_activo),
    .dir_actual(dir_actual),
    .tecla_flecha(tecla_flecha),
    .tecla_enter(tecla_enter)
);

// ---------- Reloj de 100 MHz ----------
always #5 clk = ~clk;

integer errores = 0;
integer pruebas = 0;
integer enters  = 0;

// Cuenta los pulsos de tecla_enter
always @(posedge clk) begin
    if (tecla_enter)
        enters = enters + 1;
end

// ---------- Tarea: enviar un byte por PS/2 ----------
// Trama: inicio (0), 8 datos (LSB primero), paridad impar, parada (1)
task enviar;
    input [7:0] dato;
    integer k;
    reg [10:0] trama;
    begin
        trama = {1'b1, ~^dato, dato, 1'b0};
        for (k = 0; k < 11; k = k + 1) begin
            ps2_data = trama[k];
            #80 ps2_clk = 0;      // el FPGA lee en el flanco de bajada
            #80 ps2_clk = 1;
            #80;
        end
        ps2_data = 1;
        #100;
    end
endtask

// ---------- Tarea: enviar una trama con error (paridad o parada) ----------
// error = 0: paridad equivocada · error = 1: bit de parada en 0
task enviar_malo;
    input [7:0] dato;
    input       error;
    integer k;
    reg [10:0] trama;
    begin
        if (error == 0) trama = {1'b1,  ^dato, dato, 1'b0};
        else            trama = {1'b0, ~^dato, dato, 1'b0};
        for (k = 0; k < 11; k = k + 1) begin
            ps2_data = trama[k];
            #80 ps2_clk = 0;
            #80 ps2_clk = 1;
            #80;
        end
        ps2_data = 1;
        #100;
    end
endtask

// ---------- Tarea: oprimir una flecha (E0 + codigo) ----------
task flecha;
    input [7:0] codigo;
    begin
        enviar(8'hE0);
        enviar(codigo);
    end
endtask

// ---------- Tarea: simular un paso de la serpiente ----------
task pulso_movimiento;
    begin
        @(negedge clk) move_tick = 1;
        @(negedge clk) move_tick = 0;
        repeat (2) @(negedge clk);
    end
endtask

// ---------- Tarea: revisar la direccion ----------
task comprobar;
    input [1:0] esperada;
    begin
        pruebas = pruebas + 1;
        if (dir_actual !== esperada) begin
            $display("ERROR PRUEBA %0d: direccion=%b, esperado=%b", pruebas, dir_actual, esperada);
            errores = errores + 1;
        end
        else
            $display("OK PRUEBA %0d: direccion=%b", pruebas, dir_actual);
    end
endtask

// ---------- Secuencia de la prueba ----------
initial begin
    repeat (4) @(negedge clk);
    rst = 0;

    // --- En espera: se acepta cualquier flecha ---
    comprobar(2'b01);                       // 1. arranca a la derecha
    flecha(8'h75);  comprobar(2'b00);       // 2. arriba
    flecha(8'h74);  comprobar(2'b01);       // 3. derecha

    // 4. Soltar izquierda (E0 F0 6B) no cambia nada
    enviar(8'hE0);  enviar(8'hF0);  enviar(8'h6B);
    comprobar(2'b01);

    // --- En juego: reglas de giro ---
    @(negedge clk) juego_activo = 1;
    flecha(8'h6B);  comprobar(2'b01);       // 5. izquierda es opuesta -> ignora
    flecha(8'h75);  comprobar(2'b00);       // 6. arriba: giro valido
    flecha(8'h74);  comprobar(2'b00);       // 7. segundo giro sin paso -> ignora

    pulso_movimiento();
    flecha(8'h74);  comprobar(2'b01);       // 8. tras el paso: derecha
    pulso_movimiento();
    flecha(8'h72);  comprobar(2'b10);       // 9. abajo
    pulso_movimiento();
    flecha(8'h6B);  comprobar(2'b11);       // 10. izquierda
    pulso_movimiento();
    flecha(8'h74);  comprobar(2'b11);       // 11. derecha es opuesta -> ignora
    flecha(8'h75);  comprobar(2'b00);       // 12. arriba
    pulso_movimiento();
    flecha(8'h72);  comprobar(2'b00);       // 13. abajo es opuesta -> ignora

    // 14. Enter: oprimir (5A) da 1 pulso, soltar (F0 5A) no
    enviar(8'h5A);
    enviar(8'hF0);  enviar(8'h5A);
    pruebas = pruebas + 1;
    if (enters !== 1) begin
        $display("ERROR PRUEBA 14: %0d pulsos de Enter, esperado 1", enters);
        errores = errores + 1;
    end
    else
        $display("OK PRUEBA 14: Enter da 1 pulso");

    // --- 15 a 18: letras W A S D (sin E0) ---
    @(negedge clk) juego_activo = 0;
    enviar(8'h1D);  enviar(8'hF0);  enviar(8'h1D);
    comprobar(2'b00);   // 15. W -> arriba
    enviar(8'h23);  enviar(8'hF0);  enviar(8'h23);
    comprobar(2'b01);                            // 16. D -> derecha
    enviar(8'h1B);  enviar(8'hF0);  enviar(8'h1B);
    comprobar(2'b10);                            // 17. S -> abajo
    enviar(8'h1C);  enviar(8'hF0);  enviar(8'h1C);
    comprobar(2'b11);                            // 18. A -> izquierda

    // 19. En juego: A con direccion izquierda, luego D (opuesta) se ignora
    @(negedge clk) juego_activo = 1;
    pulso_movimiento();
    enviar(8'h23);  enviar(8'hF0);  enviar(8'h23);
    comprobar(2'b11);                            // 19. D opuesta -> ignora

    // --- 20 a 22: tramas con error se descartan ---
    @(negedge clk) juego_activo = 0;
    enviar_malo(8'h1D, 0);  comprobar(2'b11);    // 20. W con paridad mala -> ignora
    enviar_malo(8'h1D, 1);  comprobar(2'b11);    // 21. W con parada en 0 -> ignora
    enviar(8'h1D);  enviar(8'hF0);  enviar(8'h1D);
    comprobar(2'b00);                            // 22. W bien enviada -> arriba

    // Resultado
    $display("PRUEBAS EJECUTADAS: %0d", pruebas);
    if (errores == 0)
        $display("=== DIRECCION: TODAS LAS PRUEBAS PASARON ===");
    else
        $display("=== DIRECCION: %0d ERRORES ===", errores);

    $finish;
end

endmodule
