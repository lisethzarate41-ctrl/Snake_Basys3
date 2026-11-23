`timescale 1ns/1ps
// ============================================================
// snake_puntaje_matriz.v
// Al terminar el juego, la matriz muestra el PUNTAJE en decimal,
// centrado, con numeros de 3x5 pixeles ampliados al doble (6x10).
//
//   puntaje (binario) --[conversor binario->BCD]--> 4 digitos
//   (col, fila) --[pixel_numero x2]--> pixel de arriba y de abajo
//   pixel --[color]--> rgb1, rgb2
//
// Color: rojo si perdio, verde si gano.
// Cada digito ocupa una "casilla" de 8 columnas: 1 vacia + 6 del
// numero + 1 vacia. 4 casillas = 32 columnas. Filas 11 a 20.
// ============================================================
module snake_puntaje_matriz(
    input  wire       clk, rst,
    input  wire [4:0] col,          // columna que se esta enviando
    input  wire [3:0] fila,         // pareja de filas (0..15)
    input  wire [9:0] puntaje,      // 0..1023
    input  wire       victoria,     // 1 = gano, 0 = perdio
    output wire [2:0] rgb1,         // {R1,G1,B1} mitad de arriba
    output wire [2:0] rgb2          // {R2,G2,B2} mitad de abajo
);

// ============================================================
// BLOQUE 1: CONVERSOR BINARIO -> BCD (double dabble secuencial)
//   paso 0     : cargar puntaje
//   paso 1..10 : si un digito vale >= 5 se le suma 3 (add3)
//                y todo se desplaza 1 bit a la izquierda
//   paso 11    : guardar los 4 digitos
// ============================================================
reg [9:0]  bin     = 10'd0;
reg [15:0] bcd     = 16'd0;
reg [3:0]  paso    = 4'd0;
reg [15:0] digitos = 16'd0;    // {miles, centenas, decenas, unidades}

wire [15:0] bcd_ajustado;
add3 a0 (.a(bcd[3:0]),   .s(bcd_ajustado[3:0]));
add3 a1 (.a(bcd[7:4]),   .s(bcd_ajustado[7:4]));
add3 a2 (.a(bcd[11:8]),  .s(bcd_ajustado[11:8]));
add3 a3 (.a(bcd[15:12]), .s(bcd_ajustado[15:12]));

// contador de pasos: incrementador (half adders) + 2 comparadores
wire [3:0] c_paso    = {c_paso[2:0] & paso[2:0], 1'b1};
wire [3:0] paso_mas1 = paso ^ c_paso;
wire cargar = (paso == 4'd0);
wire listo  = (paso == 4'd11);

wire [9:0]  bin_D     = cargar ? puntaje : {bin[8:0], 1'b0};
wire [15:0] bcd_D     = cargar ? 16'd0   : {bcd_ajustado[14:0], bin[9]};
wire [3:0]  paso_D    = {4{~rst & ~listo}} & paso_mas1;
wire [15:0] digitos_D = listo ? bcd : digitos;          // registro con enable

// ============================================================
// BLOQUE 2: CUANTOS DIGITOS TIENE EL NUMERO (para centrarlo)
//   z3 = miles en 0, z2 = miles y centenas en 0, z1 = ... y decenas en 0
//   k = digitos vacios a la izquierda = 0, 1, 2 o 3
// ============================================================
wire z3 = ~|digitos[15:12];
wire z2 = z3 & ~|digitos[11:8];
wire z1 = z2 & ~|digitos[7:4];
wire [1:0] k = {z2, (z3 & ~z2) | z1};

// ============================================================
// BLOQUE 3: PIXEL DEL NUMERO (una copia por mitad del panel)
// ============================================================
wire pix_arriba, pix_abajo;

pixel_numero p_arriba (
    .x(col), .y({1'b0, fila}),
    .digitos(digitos), .k(k), .z3(z3), .z2(z2), .z1(z1),
    .pixel(pix_arriba));

pixel_numero p_abajo (
    .x(col), .y({1'b1, fila}),
    .digitos(digitos), .k(k), .z3(z3), .z2(z2), .z1(z1),
    .pixel(pix_abajo));

// ============================================================
// BLOQUE 4: COLOR  (perdio = rojo 100, gano = verde 010)
// ============================================================
wire [2:0] color = {~victoria, victoria, 1'b0};
wire [2:0] rgb1_D = {3{~rst & pix_arriba}} & color;
wire [2:0] rgb2_D = {3{~rst & pix_abajo}}  & color;

reg [2:0] q1 = 3'b000;
reg [2:0] q2 = 3'b000;

always @(posedge clk) begin
    bin     <= bin_D;
    bcd     <= bcd_D;
    paso    <= paso_D;
    digitos <= digitos_D;
    q1      <= rgb1_D;
    q2      <= rgb2_D;
end

assign rgb1 = q1;
assign rgb2 = q2;

endmodule


// ============================================================
// pixel_numero: dice si el pixel (x, y) pertenece al numero.
// Solo logica combinacional.
// ============================================================
module pixel_numero(
    input  wire [4:0]  x, y,
    input  wire [15:0] digitos,
    input  wire [1:0]  k,            // digitos vacios a la izquierda
    input  wire        z3, z2, z1,   // para apagar ceros a la izquierda
    output wire        pixel
);

// ---------- Columnas: centrar sumando 4k (sumador de 5 bits) ----------
// x_campo = x + 4k  -> como 4k solo cambia los bits [4:2], se suma
// k a x[4:2] con el sumador/restador de 5 bits de snake_movimiento.
wire [4:0] alto;
sumador_restador_5b suma_x (
    .a({2'b00, x[4:2]}), .b({3'b000, k}), .sub(1'b0), .r(alto));

wire [1:0] casilla = alto[2:1];            // cual de los 4 digitos (0 = miles)
wire [2:0] cc      = {alto[0], x[1:0]};    // columna dentro de la casilla 0..7
wire dentro_x      = ~alto[3] & ~alto[4]   // casilla 0..3
                   & (|cc) & ~(&cc);       // columna 1..6 (0 y 7 vacias)

// columna de la fuente 0..2 = (cc - 1) / 2   (tabla: 1,2->0  3,4->1  5,6->2)
wire fc1 = cc[2] & (cc[1] | cc[0]);
wire fc0 = (~cc[2] & cc[1] & cc[0]) | (cc[2] & ~cc[1] & ~cc[0]);

// ---------- Filas: y - 11 (restador de 5 bits) ----------
wire [4:0] y_rel;
sumador_restador_5b resta_y (
    .a(y), .b(5'd11), .sub(1'b1), .r(y_rel));

// dentro si 0 <= y_rel <= 9   (comparador)
wire dentro_y = ~y_rel[4] & (~y_rel[3] | (~y_rel[2] & ~y_rel[1]));
wire [2:0] fr = y_rel[3:1];               // fila de la fuente 0..4

// ---------- MUX 4:1: que digito va en esta casilla ----------
wire c1 = casilla[1], c0 = casilla[0];
wire [3:0] dig = ({4{~c1 & ~c0}} & digitos[15:12]) |
                 ({4{~c1 &  c0}} & digitos[11:8])  |
                 ({4{ c1 & ~c0}} & digitos[7:4])   |
                 ({4{ c1 &  c0}} & digitos[3:0]);

// ceros a la izquierda: miles si z3, centenas si z2, decenas si z1
wire vacio = (~c1 & ~c0 & z3) | (~c1 & c0 & z2) | (c1 & ~c0 & z1);

// ---------- ROM de la fuente 3x5 (MUX 10:1 de 15 bits) ----------
//   5 filas de 3 bits, de arriba hacia abajo; bit izquierdo primero
wire [14:0] patron =
    (dig == 4'd0) ? 15'b111_101_101_101_111 :
    (dig == 4'd1) ? 15'b010_110_010_010_111 :
    (dig == 4'd2) ? 15'b111_001_111_100_111 :
    (dig == 4'd3) ? 15'b111_001_111_001_111 :
    (dig == 4'd4) ? 15'b101_101_111_001_001 :
    (dig == 4'd5) ? 15'b111_100_111_001_111 :
    (dig == 4'd6) ? 15'b111_100_111_101_111 :
    (dig == 4'd7) ? 15'b111_001_001_001_001 :
    (dig == 4'd8) ? 15'b111_101_111_101_111 :
                    15'b111_101_111_001_111;    // 9

// ---------- MUX 5:1: la fila de la fuente ----------
wire [2:0] bits_fila =
    (fr == 3'd0) ? patron[14:12] :
    (fr == 3'd1) ? patron[11:9]  :
    (fr == 3'd2) ? patron[8:6]   :
    (fr == 3'd3) ? patron[5:3]   :
                   patron[2:0];

// ---------- MUX 3:1: la columna de la fuente ----------
wire bit_fuente = (~fc1 & ~fc0 & bits_fila[2]) |
                  (~fc1 &  fc0 & bits_fila[1]) |
                  ( fc1 & ~fc0 & bits_fila[0]);

assign pixel = dentro_x & dentro_y & ~vacio & bit_fuente;

endmodule


// ============================================================
// add3: si el digito BCD vale 5 o mas, le suma 3 (si no, igual)
//   0-4 -> igual   5->8  6->9  7->10  8->11  9->12  (10..15: don't care)
// ============================================================
module add3(
    input  wire [3:0] a,
    output wire [3:0] s
);
assign s[3] = a[3] | (a[2] & a[1]) | (a[2] & a[0]);
assign s[2] = (a[3] & a[0]) | (a[2] & ~a[1] & ~a[0]);
assign s[1] = (a[3] & ~a[0]) | (~a[2] & a[1]) | (a[1] & a[0]);
assign s[0] = (a[3] & ~a[0]) | (~a[3] & ~a[2] & a[0]) | (a[2] & a[1] & ~a[0]);
endmodule
