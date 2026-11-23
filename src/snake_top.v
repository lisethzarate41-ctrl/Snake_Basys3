`timescale 1ns/1ps
// ============================================================
// snake_top.v  (version con ecuaciones booleanas)
// Conecta todos los modulos del Snake. Aqui casi todo son cables;
// la unica logica propia son 5 registros (BLOQUE 1).
//
//   velocidad -> move_tick cada 0.2 s
//   direccion -> flechas y Enter del teclado
//   control   -> FSM ESPERA / JUGANDO / PERDIO / GANO
//   movimiento, cuerpo, colisiones, objetos (LFSR), puntaje
//   veneno con solo la cabeza -> pierde (BLOQUE 1b)
//   control_matriz + dibujo -> panel HUB75
//   puntaje_matriz -> al terminar, el puntaje en numeros en el panel
// ============================================================
module snake_top #(
    parameter integer LIMITE_MOV    = 19999999,   // 0.2 s a 100 MHz
    parameter integer LIMITE_MATRIZ = 31118
)(
    input  wire clk, rst, ps2_clk, ps2_data,
    output wire R1, G1, B1, R2, G2, B2, A, B, C, D, HUB_CLK, HUB_LAT, HUB_OE,
    output wire [1:0]  leds_estado,
    output wire [15:0] leds_puntaje
);

// ---------- CABLES ----------
wire move_tick_base, tecla_flecha, tecla_enter;
wire juego_activo, fin_juego, victoria;
wire [1:0] dir_actual;
wire [4:0] x_actual, y_actual, x_siguiente, y_siguiente;
wire [4:0] col, x_pixel, y_pixel, x_obj, y_obj;
wire [3:0] fila;
wire [1:0] fase_carga;
wire [4:0] x_comida, y_comida, x_veneno, y_veneno;
wire pixel_serpiente, casilla_ocupada, casilla_es_cola, cola_se_libera, obj_ocupada;
wire comida_activa, veneno_activo, come_comida, come_veneno, buscando, colision;
wire colision_pared, colision_cuerpo, paso;
wire [10:0] longitud;
wire [2:0] rgb1, rgb2;           // dibujo del juego
wire [2:0] rgb1_num, rgb2_num;   // numero del puntaje

// ---------- BLOQUE 1: REGISTROS DEL TOP ----------
// rst_juego: reinicia con el boton central O con Enter.
// Cada paso se hace en 3 ciclos (T = ciclo del move_tick):
//   T   : dir_g guarda la direccion (registro con enable = MUX 2:1 + FF D)
//   T+1 : tick_g = 1. Con dir_g YA guardada, colisiones revisa pared y
//         cuerpo en la casilla a la que de verdad se va; colision_g lo guarda.
//   T+2 : tick_g2 = 1. Control y movimiento deciden con colision_g.
// Asi la pared y el cuerpo se revisan con la MISMA direccion con la que
// la serpiente avanza, tambien cuando hay un giro.
reg rst_juego = 1'b1;
reg tick_g = 1'b0, tick_g2 = 1'b0, colision_g = 1'b0;
reg [1:0] dir_g = 2'b01;

wire tick_g_D     = ~rst_juego & move_tick_base;
wire tick_g2_D    = ~rst_juego & tick_g;
wire colision_g_D = ~rst_juego & (tick_g ? colision : colision_g);
wire [1:0] dir_g_D = rst_juego ? 2'b01 : (move_tick_base ? dir_actual : dir_g);

always @(posedge clk) begin
    rst_juego  <= rst | tecla_enter;
    tick_g     <= tick_g_D;
    tick_g2    <= tick_g2_D;
    colision_g <= colision_g_D;
    dir_g      <= dir_g_D;
end

wire tablero_lleno = longitud[10];          // longitud == 1024
wire habilitar     = juego_activo & ~buscando;

// ---------- BLOQUE 1b: MUERTE POR VENENO ----------
// Si solo queda la cabeza (longitud = 1) y la siguiente casilla es
// el veneno, cuenta como choque: la serpiente no avanza y el juego
// pasa a PERDIO (el puntaje que se muestra es el que lleve, ej. 0).
//   long_uno: comparador longitud == 1  ->  ~(L10+...+L1) · L0
//   choque  : OR entre el choque normal y la muerte por veneno
wire long_uno      = ~(|longitud[10:1]) & longitud[0];
wire muere_veneno  = come_veneno & long_uno;
wire choque        = colision_g | muere_veneno;

// ---------- BLOQUE 2: INSTANCIAS ----------
snake_velocidad #(.LIMITE(LIMITE_MOV)) u_velocidad(
    .clk(clk), .rst(rst_juego), .move_tick(move_tick_base));

// direccion usa solo el boton (no se reinicia a mitad de una tecla)
snake_direccion u_direccion(
    .clk(clk), .rst(rst), .ps2_clk(ps2_clk), .ps2_data(ps2_data),
    .move_tick(move_tick_base), .juego_activo(juego_activo),
    .dir_actual(dir_actual), .tecla_flecha(tecla_flecha), .tecla_enter(tecla_enter));

snake_control u_control(
    .clk(clk), .rst(rst_juego), .tecla_flecha(tecla_flecha),
    .move_tick(tick_g2), .colision(choque),
    .buscando(buscando), .tablero_lleno(tablero_lleno),
    .juego_activo(juego_activo), .fin_juego(fin_juego),
    .victoria(victoria), .estado(leds_estado));

snake_movimiento u_movimiento(
    .clk(clk), .rst(rst_juego), .move_tick(tick_g2),
    .habilitar(habilitar), .dir_actual(dir_g), .colision(choque),
    .x_actual(x_actual), .y_actual(y_actual),
    .x_siguiente(x_siguiente), .y_siguiente(y_siguiente), .paso(paso));

snake_cuerpo u_cuerpo(
    .clk(clk), .rst(rst_juego), .paso(paso),
    .x_siguiente(x_siguiente), .y_siguiente(y_siguiente),
    .come_comida(come_comida), .come_veneno(come_veneno),
    .x_pixel(x_pixel), .y_pixel(y_pixel), .x_obj(x_obj), .y_obj(y_obj),
    .obj_ocupada(obj_ocupada), .casilla_ocupada(casilla_ocupada),
    .casilla_es_cola(casilla_es_cola), .cola_se_libera(cola_se_libera),
    .pixel_serpiente(pixel_serpiente), .longitud(longitud));

snake_colisiones u_colisiones(
    .x_actual(x_actual), .y_actual(y_actual), .dir_actual(dir_g),
    .casilla_ocupada(casilla_ocupada), .casilla_es_cola(casilla_es_cola),
    .cola_se_libera(cola_se_libera), .colision(colision),
    .colision_pared(colision_pared), .colision_cuerpo(colision_cuerpo));

snake_objetos u_objetos(
    .clk(clk), .rst(rst_juego), .cuerpo_listo(1'b1), .consulta_ocupada(obj_ocupada),
    .x_siguiente(x_siguiente), .y_siguiente(y_siguiente), .paso(paso),
    .x_consulta(x_obj), .y_consulta(y_obj),
    .x_comida(x_comida), .y_comida(y_comida), .comida_activa(comida_activa),
    .x_veneno(x_veneno), .y_veneno(y_veneno), .veneno_activo(veneno_activo),
    .come_comida(come_comida), .come_veneno(come_veneno), .buscando(buscando));

snake_puntaje u_puntaje(
    .clk(clk), .rst(rst_juego), .comio_comida(paso & come_comida),
    .puntaje(leds_puntaje));

snake_control_matriz #(.LIMITE_MOSTRAR(LIMITE_MATRIZ)) u_matriz(
    .clk(clk), .rst(rst), .col(col), .fila(fila), .fase_carga(fase_carga),
    .hub_clk(HUB_CLK), .hub_lat(HUB_LAT), .hub_oe(HUB_OE),
    .A(A), .B(B), .C(C), .D(D));

snake_dibujo #(.MODO_FASE(1)) u_dibujo(
    .clk(clk), .rst(rst_juego), .fase(fase_carga), .col(col), .fila(fila),
    .x_cabeza(x_actual), .y_cabeza(y_actual), .pixel_serpiente(pixel_serpiente),
    .x_comida(x_comida), .y_comida(y_comida), .comida_activa(comida_activa),
    .x_veneno(x_veneno), .y_veneno(y_veneno), .veneno_activo(veneno_activo),
    .fin_juego(fin_juego), .x_pixel(x_pixel), .y_pixel(y_pixel),
    .rgb1(rgb1), .rgb2(rgb2));

snake_puntaje_matriz u_puntaje_matriz(
    .clk(clk), .rst(rst_juego), .col(col), .fila(fila),
    .puntaje(leds_puntaje[9:0]), .victoria(victoria),
    .rgb1(rgb1_num), .rgb2(rgb2_num));

// ---------- BLOQUE 3: SALIDAS AL PANEL (MUX 2:1 de 3 bits) ----------
// Jugando: dibujo del juego. Fin del juego: el puntaje.
assign {R1, G1, B1} = fin_juego ? rgb1_num : rgb1;   // mitad de arriba
assign {R2, G2, B2} = fin_juego ? rgb2_num : rgb2;   // mitad de abajo

endmodule
