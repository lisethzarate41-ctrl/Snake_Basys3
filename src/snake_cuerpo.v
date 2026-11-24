// Apoyo de IA (Claude): implementacion del mapa de ocupacion,
// manejo de la lista circular y optimizacion de temporizacion.
`timescale 1ns/1ps
// Serpiente: mapa de 1024 casillas, lista circular y cola registrada.
// Optimizaciones que pasaron testbench: cola_actual, p_escritura.
// Apoyo de IA: optimizacion de temporizacion.
module snake_cuerpo(
 input wire clk,rst,paso,
 input wire [4:0] x_siguiente,y_siguiente,
 input wire come_comida,come_veneno,
 input wire [4:0] x_pixel,y_pixel,
 output wire casilla_ocupada,casilla_es_cola,cola_se_libera,pixel_serpiente,
 input wire [4:0] x_obj,y_obj,
 output wire obj_ocupada,
 output wire [10:0] longitud
);
localparam [9:0] INICIO={5'd15,5'd15};
reg [1023:0] mapa;
reg [9:0] lista [0:1023];
reg [9:0] p_cabeza,p_cola;
reg [9:0] cola_actual;
reg [9:0] p_escritura;
reg [10:0] long_reg,pendientes;
wire [9:0] idx_sig={y_siguiente,x_siguiente};
wire [9:0] pos_siguiente_cola=lista[p_cola+10'd1];
assign casilla_ocupada=mapa[idx_sig];
assign casilla_es_cola=(idx_sig==cola_actual);
assign cola_se_libera=~come_comida;
assign pixel_serpiente=mapa[{y_pixel,x_pixel}];
assign obj_ocupada=mapa[{y_obj,x_obj}];
assign longitud=long_reg;
wire retirar=~paso && (pendientes!=11'd0) && (long_reg>11'd1);
always @(posedge clk) begin
 if(rst) begin
  mapa<=1024'd0;
  mapa[INICIO]<=1'b1;
  lista[0]<=INICIO;
  p_cabeza<=10'd0;
  p_cola<=10'd0;
  p_escritura<=10'd1;
  cola_actual<=INICIO;
  long_reg<=11'd1;
  pendientes<=11'd0;
 end else if(paso) begin
  if(cola_se_libera) begin
   mapa[cola_actual]<=1'b0;
   p_cola<=p_cola+10'd1;
   if(long_reg==11'd1) cola_actual<=idx_sig;
   else cola_actual<=pos_siguiente_cola;
  end
  mapa[idx_sig]<=1'b1;
  lista[p_escritura]<=idx_sig;
  p_cabeza<=p_cabeza+10'd1;
  p_escritura<=p_escritura+10'd1;
  if(come_comida) long_reg<=long_reg+11'd1;
  if(come_veneno) pendientes<=pendientes+11'd1;
 end else if(retirar) begin
  mapa[cola_actual]<=1'b0;
  p_cola<=p_cola+10'd1;
  cola_actual<=pos_siguiente_cola;
  long_reg<=long_reg-11'd1;
  pendientes<=pendientes-11'd1;
 end else if(long_reg==11'd1) pendientes<=11'd0;
end
endmodule
