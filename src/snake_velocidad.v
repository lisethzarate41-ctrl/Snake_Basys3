
`timescale 1ns/1ps
// Pulso de movimiento a partir del reloj de 100 MHz.
// Apoyo de IA (ChatGPT): revision del ancho del contador,
// funcionamiento del pulso y casos de prueba.

module snake_velocidad #(parameter integer LIMITE=19999999)(
    input wire clk, rst,
    output reg move_tick
);

// BLOQUE 1: REGISTRO DE 25 BITS (cuenta)
// Almacena los ciclos del reloj. Con 25 bits podemos contar
// hasta 19.999.999 para generar 5 pulsos por segundo.
reg [24:0] cuenta;

// BLOQUES 2, 3 Y 4: SUMADOR +1, COMPARADOR Y MUX (FIGURA 9)
// En cada flanco positivo se incrementa el contador.
// Si llega al LIMITE, se reinicia y genera un pulso move_tick.
// El reset tiene prioridad y pone ambas señales en cero.
always @(posedge clk) begin
    if (rst) begin cuenta <= 0; move_tick <= 0; end
    else if (cuenta == LIMITE) begin cuenta <= 0; move_tick <= 1; end
    else begin cuenta <= cuenta + 1'b1; move_tick <= 0; end
end

endmodule
