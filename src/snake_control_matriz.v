// Apoyo de IA (Claude): implementacion de la FSM one-hot
// y temporizacion de las señales CLK, LAT y OE del panel HUB75.
`timescale 1ns/1ps
// ============================================================
// snake_control_matriz.v  (version con ecuaciones booleanas)
// Barre el panel HUB75 32x32 (scan 1/16): carga 32 columnas,
// hace LATCH, muestra la pareja de filas y pasa a la siguiente.
//
// FSM one-hot (un flip-flop por estado):
//   S0 inicio  -> S1 cargar 32 columnas -> S2 latch
//   -> S3 mostrar -> S4 siguiente fila -> S0
//
// Cada columna dura 32 ciclos (contador fase de 5 bits):
//   fase 0..15  -> CLK del panel en 0 (los datos se acomodan)
//   fase 16..31 -> CLK del panel en 1 (el panel lee el bit)
//   => CLK del panel = 100 MHz / 32 = 3.1 MHz, pulso de 160 ns.
//   (Con jumpers, un CLK mas rapido llega deformado.)
// ============================================================
module snake_control_matriz #(
    parameter integer LIMITE_MOSTRAR = 31118   // ciclos mostrando cada fila
)(
    input  wire       clk, rst,
    output wire [4:0] col,          // columna que se esta enviando
    output wire [3:0] fila,         // pareja de filas (0..15)
    output wire [1:0] fase_carga,   // para snake_dibujo
    output wire       hub_clk, hub_lat, hub_oe,
    output wire       A, B, C, D
);

// ---------- REGISTROS (flip-flops D) ----------
reg S0 = 1'b1, S1 = 1'b0, S2 = 1'b0, S3 = 1'b0, S4 = 1'b0;  // estados
reg [4:0]  fase    = 5'd0;    // ciclo dentro de la columna
reg [4:0]  columna = 5'd0;
reg [3:0]  fila_r  = 4'd0;
reg [14:0] tiempo  = 15'd0;   // ciclos mostrando la fila

// ---------- BLOQUE 1: INCREMENTADORES (+1) ----------
// Cadena de half adders: s_i = a_i XOR c_i ,  c_(i+1) = a_i AND c_i ,  c_0 = 1
wire [4:0]  c_fase, c_col;  wire [3:0] c_fila;  wire [14:0] c_t;
assign c_fase = {c_fase[3:0] & fase[3:0],      1'b1};
assign c_col  = {c_col[3:0]  & columna[3:0],   1'b1};
assign c_fila = {c_fila[2:0] & fila_r[2:0],    1'b1};
assign c_t    = {c_t[13:0]   & tiempo[13:0],   1'b1};
wire [4:0]  fase_mas1    = fase    ^ c_fase;
wire [4:0]  columna_mas1 = columna ^ c_col;
wire [3:0]  fila_mas1    = fila_r  ^ c_fila;
wire [14:0] tiempo_mas1  = tiempo  ^ c_t;

// ---------- BLOQUE 2: COMPARADORES ----------
wire fin_fase       = &fase;      // fase == 31     (AND de 5 bits)
wire ultima_columna = &columna;   // columna == 31  (AND de 5 bits)
wire [14:0] K = LIMITE_MOSTRAR;
wire fin_mostrar = &(~(tiempo ^ K));   // tiempo == LIMITE (15 XNOR + AND)

// ---------- BLOQUE 3: SENALES DE CONTROL ----------
wire fin_carga  = S1 & fin_fase &  ultima_columna;  // ya se cargaron las 32
wire inc_col    = S1 & fin_fase & ~ultima_columna;  // pasar a la sig. columna
wire fin_latch  = S2 & fin_fase;                    // LAT duro 32 ciclos

// ---------- BLOQUE 4: LOGICA DE SIGUIENTE ESTADO (one-hot) ----------
wire S0_D = rst | S4;
wire S1_D = ~rst & (S0 | (S1 & ~fin_carga));
wire S2_D = ~rst & ((S1 & fin_carga) | (S2 & ~fin_latch));
wire S3_D = ~rst & (fin_latch | (S3 & ~fin_mostrar));
wire S4_D = ~rst & S3 & fin_mostrar;

// ---------- BLOQUE 5: SIGUIENTE VALOR DE LOS CONTADORES (MUX 2:1) ----------
// fase: cuenta en S1 y S2, si no vale 0
wire [4:0]  fase_D    = {5{~rst & (S1 | S2)}} & fase_mas1;
// columna: 0 en S0; +1 con inc_col; si no, se queda
wire [4:0]  columna_D = {5{~rst & ~S0}} &
                        (({5{inc_col}} & columna_mas1) | ({5{~inc_col}} & columna));
// fila: +1 en S4; si no, se queda
wire [3:0]  fila_D    = {4{~rst}} &
                        (({4{S4}} & fila_mas1) | ({4{~S4}} & fila_r));
// tiempo: cuenta en S3 hasta el limite, si no vale 0
wire [14:0] tiempo_D  = {15{~rst & S3 & ~fin_mostrar}} & tiempo_mas1;

always @(posedge clk) begin
    S0 <= S0_D;  S1 <= S1_D;  S2 <= S2_D;  S3 <= S3_D;  S4 <= S4_D;
    fase    <= fase_D;
    columna <= columna_D;
    fila_r  <= fila_D;
    tiempo  <= tiempo_D;
end

// ---------- BLOQUE 6: SALIDAS (solo cables y compuertas) ----------
assign col        = columna;
assign fila       = fila_r;
assign {D,C,B,A}  = fila_r;        // direccion de la fila al panel
assign fase_carga = fase[1:0];     // dibujo carga rgb1 en 0 y rgb2 en 1
assign hub_clk    = S1 & fase[4];  // alto en fase 16..31
assign hub_lat    = S2;            // LAT activo en alto
assign hub_oe     = ~S3;           // OE activo en bajo: panel prende solo en S3

endmodule
