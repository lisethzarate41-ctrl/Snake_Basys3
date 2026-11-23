
`timescale 1ns/1ps
// ============================================================
// snake_puntaje_matriz.v
// Muestra el puntaje final en decimal sobre la matriz HUB75.
// Usa numeros de 3x5 ampliados a 6x10 pixeles.
// Rojo = derrota, verde = victoria.
//
// Apoyo de IA (ChatGPT): diseño del conversor binario a BCD,
// logica de visualizacion, fuente de numeros y revision del esquema.
// ============================================================
module snake_puntaje_matriz(
    input  wire       clk, rst,
    input  wire [4:0] col,
    input  wire [3:0] fila,
    input  wire [9:0] puntaje,
    input  wire       victoria,
    output wire [2:0] rgb1,
    output wire [2:0] rgb2
);

// BLOQUE 1: CONVERSOR BINARIO A BCD
// Convierte el puntaje binario en 4 digitos decimales.
// Utiliza el metodo double dabble: sumar 3 y desplazar.
reg [9:0]  bin     = 10'd0;
reg [15:0] bcd     = 16'd0;
reg [3:0]  paso    = 4'd0;
reg [15:0] digitos = 16'd0;

wire [15:0] bcd_ajustado;
add3 a0 (.a(bcd[3:0]),   .s(bcd_ajustado[3:0]));
add3 a1 (.a(bcd[7:4]),   .s(bcd_ajustado[7:4]));
add3 a2 (.a(bcd[11:8]),  .s(bcd_ajustado[11:8]));
add3 a3 (.a(bcd[15:12]), .s(bcd_ajustado[15:12]));

// BLOQUE 2: CONTADOR DE PASOS Y COMPARADORES
// Controla las 10 iteraciones de conversion y el momento
// en que se guardan los digitos decimales.
wire [3:0] c_paso    = {c_paso[2:0] & paso[2:0], 1'b1};
wire [3:0] paso_mas1 = paso ^ c_paso;
wire cargar = (paso == 4'd0);
wire listo  = (paso == 4'd11);

// BLOQUE 3: CORRIMIENTO Y REGISTROS
// Carga el puntaje, desplaza los bits y almacena el BCD final.
wire [9:0]  bin_D     = cargar ? puntaje : {bin[8:0], 1'b0};
wire [15:0] bcd_D     = cargar ? 16'd0   : {bcd_ajustado[14:0], bin[9]};
wire [3:0]  paso_D    = {4{~rst & ~listo}} & paso_mas1;
wire [15:0] digitos_D = listo ? bcd : digitos;

// BLOQUE 4: CEROS A LA IZQUIERDA
// Detecta los digitos que sobran y calcula k para centrar
// el numero en la pantalla.
wire z3 = ~|digitos[15:12];
wire z2 = z3 & ~|digitos[11:8];
wire z1 = z2 & ~|digitos[7:4];
wire [1:0] k = {z2, (z3 & ~z2) | z1};

// BLOQUE 5: PIXEL NUMERO
// Se utilizan dos copias del mismo circuito:
// una dibuja la mitad superior y otra la inferior.
wire pix_arriba, pix_abajo;

pixel_numero p_arriba (
    .x(col), .y({1'b0, fila}),
    .digitos(digitos), .k(k), .z3(z3), .z2(z2), .z1(z1),
    .pixel(pix_arriba));

pixel_numero p_abajo (
    .x(col), .y({1'b1, fila}),
    .digitos(digitos), .k(k), .z3(z3), .z2(z2), .z1(z1),
    .pixel(pix_abajo));

// BLOQUE 6: COLOR
// Selecciona rojo (100) si perdio o verde (010) si gano.
// Los pixeles apagados mantienen su salida en 000.
wire [2:0] color = {~victoria, victoria, 1'b0};
wire [2:0] rgb1_D = {3{~rst & pix_arriba}} & color;
wire [2:0] rgb2_D = {3{~rst & pix_abajo}}  & color;

// REGISTROS DE SALIDA RGB
// Guardan los colores que se enviaran a las dos mitades.
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
// MODULO: pixel_numero
// Determina si un pixel pertenece a alguno de los digitos.
// Apoyo de IA: logica de coordenadas y fuente de numeros 3x5.
// ============================================================
module pixel_numero(
    input  wire [4:0]  x, y,
    input  wire [15:0] digitos,
    input  wire [1:0]  k,
    input  wire        z3, z2, z1,
    output wire        pixel
);

// BLOQUE: PIXEL NUMERO - COLUMNAS
// Desplaza horizontalmente el numero para centrarlo.
// El sumador calcula la casilla y la columna del digito.
wire [4:0] alto;
sumador_restador_5b suma_x (
    .a({2'b00, x[4:2]}), .b({3'b000, k}), .sub(1'b0), .r(alto));

wire [1:0] casilla = alto[2:1];
wire [2:0] cc      = {alto[0], x[1:0]};
wire dentro_x      = ~alto[3] & ~alto[4]
                   & (|cc) & ~(&cc);

// Convierte las 6 columnas ampliadas en las 3 de la fuente.
wire fc1 = cc[2] & (cc[1] | cc[0]);
wire fc0 = (~cc[2] & cc[1] & cc[0]) | (cc[2] & ~cc[1] & ~cc[0]);

// BLOQUE: PIXEL NUMERO - FILAS
// Resta 11 para ubicar el numero verticalmente.
// Cada fila original se dibuja dos veces.
wire [4:0] y_rel;
sumador_restador_5b resta_y (
    .a(y), .b(5'd11), .sub(1'b1), .r(y_rel));

wire dentro_y = ~y_rel[4] & (~y_rel[3] | (~y_rel[2] & ~y_rel[1]));
wire [2:0] fr = y_rel[3:1];

// BLOQUE: MUX 4:1 Y CEROS A LA IZQUIERDA
// Selecciona el digito correspondiente a la casilla actual.
// Evita dibujar ceros innecesarios antes del puntaje.
wire c1 = casilla[1], c0 = casilla[0];
wire [3:0] dig = ({4{~c1 & ~c0}} & digitos[15:12]) |
                 ({4{~c1 &  c0}} & digitos[11:8])  |
                 ({4{ c1 & ~c0}} & digitos[7:4])   |
                 ({4{ c1 &  c0}} & digitos[3:0]);

wire vacio = (~c1 & ~c0 & z3) | (~c1 & c0 & z2) | (c1 & ~c0 & z1);

// BLOQUE: FUENTE DE NUMEROS 3x5
// Cada patron de 15 bits representa la forma de un numero
// mediante 5 filas y 3 columnas de pixeles.
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
                    15'b111_101_111_001_111;

// BLOQUE: MUX DE FILAS
// Selecciona los 3 bits de la fila que se desea dibujar.
wire [2:0] bits_fila =
    (fr == 3'd0) ? patron[14:12] :
    (fr == 3'd1) ? patron[11:9]  :
    (fr == 3'd2) ? patron[8:6]   :
    (fr == 3'd3) ? patron[5:3]   :
                   patron[2:0];

// BLOQUE: MUX DE COLUMNAS
// Selecciona el bit correspondiente al pixel solicitado.
wire bit_fuente = (~fc1 & ~fc0 & bits_fila[2]) |
                  (~fc1 &  fc0 & bits_fila[1]) |
                  ( fc1 & ~fc0 & bits_fila[0]);

// El pixel se enciende si esta dentro del numero,
// no es un cero oculto y su bit de la fuente vale 1.
assign pixel = dentro_x & dentro_y & ~vacio & bit_fuente;

endmodule


// ============================================================
// MODULO: add3
// Corrige cada digito BCD durante el metodo double dabble.
// Apoyo de IA: ecuaciones booleanas del ajuste BCD.
// ============================================================
module add3(
    input  wire [3:0] a,
    output wire [3:0] s
);

// BLOQUE AJUSTE BCD (FIGURA 21)
// Si el digito es 5 o mayor, suma 3 antes del corrimiento.
// Las expresiones implementan el ajuste mediante compuertas.
assign s[3] = a[3] | (a[2] & a[1]) | (a[2] & a[0]);
assign s[2] = (a[3] & a[0]) | (a[2] & ~a[1] & ~a[0]);
assign s[1] = (a[3] & ~a[0]) | (~a[2] & a[1]) | (a[1] & a[0]);
assign s[0] = (a[3] & ~a[0]) | (~a[3] & ~a[2] & a[0]) | (a[2] & a[1] & ~a[0]);
endmodule
