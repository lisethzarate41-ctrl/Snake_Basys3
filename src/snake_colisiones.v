`timescale 1ns/1ps
// Detecta pared y cuerpo. Apoyo de IA: revisión de la excepción de la cola.
module snake_colisiones(
 input wire [4:0] x_actual, y_actual,
 input wire [1:0] dir_actual,
 input wire casilla_ocupada, casilla_es_cola, cola_se_libera,
 output wire colision, colision_pared, colision_cuerpo
);
assign colision_pared = ((dir_actual==2'b00) && (y_actual==0)) ||
                        ((dir_actual==2'b01) && (x_actual==31)) ||
                        ((dir_actual==2'b10) && (y_actual==31)) ||
                        ((dir_actual==2'b11) && (x_actual==0));
assign colision_cuerpo = casilla_ocupada & ~(casilla_es_cola & cola_se_libera);
assign colision = colision_pared | colision_cuerpo;
endmodule
