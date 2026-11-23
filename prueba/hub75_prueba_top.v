`timescale 1ns/1ps

// PRUEBA HUB75: CUATRO CUADRANTES
// Arriba izquierda: rojo
// Arriba derecha: verde
// Abajo izquierda: azul
// Abajo derecha: amarillo
// Apoyo de IA: diagnostico de la matriz.

module hub75_prueba_top(
    input wire clk,
    input wire rst,
    input wire ps2_clk,
    input wire ps2_data,

    output wire R1, G1, B1,
    output wire R2, G2, B2,

    output wire A, B, C, D,
    output wire HUB_CLK,
    output wire HUB_LAT,
    output wire HUB_OE,

    output wire [1:0] leds_estado,
    output wire [15:0] leds_puntaje
);

wire [4:0] col;
wire [3:0] fila;
wire [1:0] fase_carga;

snake_control_matriz #(
    .LIMITE_MOSTRAR(31118)
) u_matriz (
    .clk(clk),
    .rst(rst),
    .col(col),
    .fila(fila),
    .fase_carga(fase_carga),
    .hub_clk(HUB_CLK),
    .hub_lat(HUB_LAT),
    .hub_oe(HUB_OE),
    .A(A),
    .B(B),
    .C(C),
    .D(D)
);

// Columnas 0 a 15: izquierda.
// Columnas 16 a 31: derecha.
wire derecha = col[4];

// Mitad superior: izquierda rojo (100), derecha verde (010).
assign {R1,G1,B1} = derecha ? 3'b010 : 3'b100;

// Mitad inferior: izquierda azul (001), derecha amarillo (110).
assign {R2,G2,B2} = derecha ? 3'b110 : 3'b001;

// Indicadores apagados
assign leds_estado = 2'b00;
assign leds_puntaje = 16'b0;

endmodule
