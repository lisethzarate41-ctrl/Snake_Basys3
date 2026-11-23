
`timescale 1ns/1ps
// Detecta pared y cuerpo. Apoyo de IA: revisión de la excepción de la cola.
module snake_colisiones(
 input wire [4:0] x_actual, y_actual,
 input wire [1:0] dir_actual,
 input wire casilla_ocupada, casilla_es_cola, cola_se_libera,
 output wire colision, colision_pared, colision_cuerpo
);

// BLOQUE 1: CHOQUE CON PARED
// Compara la posicion de la cabeza y su direccion.
// Si esta en el borde y quiere avanzar hacia afuera, hay choque.
assign colision_pared = ((dir_actual==2'b00) && (y_actual==0)) ||
                        ((dir_actual==2'b01) && (x_actual==31)) ||
                        ((dir_actual==2'b10) && (y_actual==31)) ||
                        ((dir_actual==2'b11) && (x_actual==0));

// BLOQUE 2: CHOQUE CON CUERPO
// Detecta si la siguiente casilla esta ocupada.
// No hay choque si es la cola y esta se libera al avanzar.
assign colision_cuerpo = casilla_ocupada & ~(casilla_es_cola & cola_se_libera);

// BLOQUE 3: COMPUERTA OR
// Une ambos resultados: basta un choque para activar colision.
assign colision = colision_pared | colision_cuerpo;

endmodule
