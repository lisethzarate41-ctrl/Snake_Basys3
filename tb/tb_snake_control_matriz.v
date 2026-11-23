// Apoyo de IA (Claude): generacion del testbench y
// definicion de casos de prueba. Simulacion revisada en Vivado.
`timescale 1ns/1ps
// ============================================================
// tb_snake_control_matriz.v
// Prueba del controlador HUB75.
// Revisa 3 cosas en cada fila que se carga:
//   1. Llegan exactamente 32 pulsos de CLK antes del LAT.
//   2. El LAT ocurre cuando ya se envio la ultima columna (31).
//   3. Mientras LAT esta activo, el panel esta apagado (OE = 1).
// ============================================================
module tb_snake_control_matriz;

// ---------- Entradas (reg) y salidas (wire) ----------
reg clk = 0;
reg rst = 1;

wire [4:0] col;
wire [3:0] fila;
wire [1:0] fase_carga;
wire hub_clk;
wire hub_lat;
wire hub_oe;
wire A, B, C, D;

// ---------- Modulo a probar ----------
// LIMITE_MOSTRAR pequeno para que la simulacion sea rapida.
snake_control_matriz #(.LIMITE_MOSTRAR(7)) uut (
    .clk(clk),
    .rst(rst),
    .col(col),
    .fila(fila),
    .fase_carga(fase_carga),
    .hub_clk(hub_clk),
    .hub_lat(hub_lat),
    .hub_oe(hub_oe),
    .A(A),
    .B(B),
    .C(C),
    .D(D)
);

// ---------- Reloj de 100 MHz ----------
always #5 clk = ~clk;

// ---------- Contadores de la prueba ----------
integer pulsos_clk = 0;   // pulsos de CLK en la fila actual
integer filas      = 0;   // cuantos LAT han ocurrido
integer errores    = 0;

// Cuenta cada flanco de subida de hub_clk
always @(posedge hub_clk) begin
    pulsos_clk = pulsos_clk + 1;
end

// Cada vez que empieza un LAT, revisa la fila que se cargo
always @(posedge hub_lat) begin
    filas = filas + 1;

    if (pulsos_clk != 32) begin
        $display("ERROR fila %0d: llegaron %0d pulsos de CLK (deben ser 32)", filas, pulsos_clk);
        errores = errores + 1;
    end

    if (col != 31) begin
        $display("ERROR fila %0d: LAT en la columna %0d (debe ser 31)", filas, col);
        errores = errores + 1;
    end

    pulsos_clk = 0;   // empieza la cuenta de la siguiente fila
end

// Mientras LAT esta activo, OE debe estar en 1 (panel apagado)
always @(posedge clk) begin
    if (hub_lat == 1 && hub_oe == 0) begin
        $display("ERROR: OE activo durante LAT");
        errores = errores + 1;
    end
end

// ---------- Secuencia de la prueba ----------
initial begin
    // Reset durante 1 ciclo
    @(negedge clk);
    rst = 0;

    // Dejar correr el barrido (alcanza para mas de 16 filas)
    #200000;

    // Resultado
    if (filas < 16) begin
        $display("ERROR: solo se cargaron %0d filas", filas);
        errores = errores + 1;
    end

    if (errores == 0)
        $display("OK MATRIZ: %0d filas, 32 pulsos de CLK en cada una", filas);
    else
        $display("FALLO MATRIZ: %0d errores", errores);

    $finish;
end

endmodule
