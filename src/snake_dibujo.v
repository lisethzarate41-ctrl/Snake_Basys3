`timescale 1ns/1ps
// ============================================================
// snake_dibujo.v
// Decide de qué color va cada píxel que el controlador HUB75
// está enviando al panel 32x32 (scan 1/16).
//
// El controlador manda DOS píxeles a la vez:
//   R1 G1 B1 -> píxel (col, fila)        mitad de arriba  (y = 0..15)
//   R2 G2 B2 -> píxel (col, fila + 16)   mitad de abajo   (y = 16..31)
// snake_cuerpo solo tiene UN puerto de lectura (x_pixel, y_pixel),
// así que este módulo consulta las dos mitades por turnos:
//   mitad = 0 -> pregunta por la de arriba y guarda en rgb1
//   mitad = 1 -> pregunta por la de abajo  y guarda en rgb2
// mitad cambia en cada ciclo de 100 MHz; el panel recibe 1 bit
// cada 20 ciclos, así que siempre hay tiempo de sobra.
//
// Colores {R,G,B}:
//   cabeza   110 amarillo      comida  100 rojo
//   cuerpo   010 verde         veneno  101 magenta
//   fin_juego: toda la serpiente 111 blanco      fondo 000 negro
// Prioridad: serpiente > comida > veneno > fondo.
// ============================================================
module snake_dibujo #(parameter MODO_FASE=0)(
    input  wire       clk,             // reloj 100 MHz
    input  wire       rst,             // reinicio síncrono
    input  wire [1:0] fase,            // se usa solo con MODO_FASE=1 (HUB75)
    // del controlador HUB75
    input  wire [4:0] col,             // columna que se está enviando (0..31)
    input  wire [3:0] fila,            // línea que se está cargando (0..15)
    // de snake_movimiento
    input  wire [4:0] x_cabeza,        // x_actual
    input  wire [4:0] y_cabeza,        // y_actual
    // de snake_cuerpo
    input  wire       pixel_serpiente, // 1 = hay serpiente en (x_pixel, y_pixel)
    // de snake_objetos
    input  wire [4:0] x_comida,
    input  wire [4:0] y_comida,
    input  wire       comida_activa,
    input  wire [4:0] x_veneno,
    input  wire [4:0] y_veneno,
    input  wire       veneno_activo,
    // de snake_control
    input  wire       fin_juego,       // 1 = game over (serpiente en blanco)
    // a snake_cuerpo
    output wire [4:0] x_pixel,
    output wire [4:0] y_pixel,
    // al panel (pasando por los pines del .xdc)
    output wire [2:0] rgb1,            // {R1,G1,B1} mitad de arriba
    output wire [2:0] rgb2             // {R2,G2,B2} mitad de abajo
);

// Sincronización con HUB75 (apoyo IA): fase opcional para fijar RGB antes de CLK.
// ---------- 1. Flip-flop de mitad (flip-flop T) ----------
reg  mitad = 1'b0;
wire D_mitad = ~rst & ~mitad;          // reset -> 0; si no, se invierte

// ---------- 2. Coordenadas del píxel (solo cables) ----------
//   y = 16*mitad + fila  ->  poner mitad como bit 4 (no hace falta sumador)
assign x_pixel = col;
// En modo HUB75 sincronizado se consulta arriba en P0 y abajo en P1.
// En modo original (testbench entregado) se alterna mitad cada ciclo.
wire mitad_consulta = MODO_FASE ? (fase==2'd1) : mitad;
assign y_pixel = {mitad_consulta, fila};

// ---------- 3. Comparadores de igualdad de 10 bits ----------
//   iguales = AND de 10 XNOR
wire H  = &(~({x_pixel, y_pixel} ^ {x_cabeza, y_cabeza}));                  // es cabeza
wire Cm = comida_activa & (&(~({x_pixel, y_pixel} ^ {x_comida, y_comida}))); // es comida
wire V  = veneno_activo & (&(~({x_pixel, y_pixel} ^ {x_veneno, y_veneno}))); // es veneno

// ---------- 4. OR: ¿hay serpiente? ¿hay objeto? ----------
wire S = H | pixel_serpiente;          // cabeza o cuerpo
wire O = Cm | V;                       // comida o veneno
wire F = fin_juego;

// ---------- 5. Lógica de color (ecuaciones simplificadas) ----------
wire R = H | (S & F) | (~S & O);
wire G = S;
wire B = (S & F) | (~S & ~Cm & V);
wire [2:0] color = {R, G, B};

// ---------- 6. Registros de color con enable (MUX 2:1 + flip-flops D) ----------
reg  [2:0] q1 = 3'b000;
reg  [2:0] q2 = 3'b000;
//   carga rgb1 cuando mitad = 0, rgb2 cuando mitad = 1; si no, se mantiene
wire en_sup = MODO_FASE ? (fase==2'd0) : ~mitad;
wire en_inf = MODO_FASE ? (fase==2'd1) : mitad;
wire [2:0] mux1 = ({3{en_sup}} & color) | ({3{~en_sup}} & q1);
wire [2:0] mux2 = ({3{en_inf}} & color) | ({3{~en_inf}} & q2);
wire [2:0] D1   = {3{~rst}} & mux1;    // reset -> negro
wire [2:0] D2   = {3{~rst}} & mux2;

always @(posedge clk) begin
    mitad <= D_mitad;
    q1    <= D1;
    q2    <= D2;
end

assign rgb1 = q1;
assign rgb2 = q2;

endmodule
