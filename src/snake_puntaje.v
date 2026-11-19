`timescale 1ns/1ps
// Suma un punto por cada comida; satura en 65535.
// Apoyo de IA: pruebas del reinicio y saturación.
module snake_puntaje(input wire clk, rst, comio_comida, output reg [15:0] puntaje);
always @(posedge clk) begin
    if (rst) puntaje <= 16'd0;
    else if (comio_comida && puntaje != 16'hffff) puntaje <= puntaje + 16'd1;
end
endmodule
