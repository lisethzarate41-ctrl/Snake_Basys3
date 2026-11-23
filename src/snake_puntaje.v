
`timescale 1ns/1ps

// ============================================================
// snake_puntaje.v
// Suma un punto cada vez que la serpiente come.
// El puntaje maximo es 65535 (16 bits).
// Apoyo de IA (ChatGPT): revision de la logica de saturacion
// y elaboracion de pruebas de reinicio y conteo.
// ============================================================

module snake_puntaje(input wire clk, rst, comio_comida, output reg [15:0] puntaje);

// BLOQUE 1: REGISTRO DE 16 BITS
// Guarda el puntaje y lo actualiza en cada flanco de subida.
always @(posedge clk) begin

    // BLOQUE 2: MUX DE REINICIO
    // Si rst=1, el puntaje vuelve a cero.
    if (rst) puntaje <= 16'd0;

    // BLOQUES 3 Y 4: COMPARADOR, HABILITACION Y SUMADOR +1
    // Solo suma un punto cuando comio_comida=1 y no ha llegado
    // al maximo FFFF. Si no se cumple, conserva el valor anterior.
    else if (comio_comida && puntaje != 16'hffff) puntaje <= puntaje + 16'd1;
end

endmodule
