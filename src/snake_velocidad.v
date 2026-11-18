`timescale 1ns/1ps
// Pulso de movimiento a partir del reloj de 100 MHz.
// Apoyo de IA: revisión de ancho de contador y casos de prueba.
module snake_velocidad #(parameter integer LIMITE=19999999)(
    input wire clk, rst,
    output reg move_tick
);
reg [24:0] cuenta;
always @(posedge clk) begin
    if (rst) begin cuenta <= 0; move_tick <= 0; end
    else if (cuenta == LIMITE) begin cuenta <= 0; move_tick <= 1; end
    else begin cuenta <= cuenta + 1'b1; move_tick <= 0; end
end
endmodule
