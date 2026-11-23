`timescale 1ns/1ps
// ============================================================
// snake_direccion.v  (version con ecuaciones booleanas)
// Lee el teclado PS/2 de la Basys 3 (puerto USB HOST) y decide
// hacia donde va la serpiente.
//
// Codigos PS/2 (scan code set 2):
//   letras  (1 byte):       W 1D arriba, D 23 derecha, S 1B abajo, A 1C izquierda
//   flechas = E0 + codigo:  arriba 75, derecha 74, abajo 72, izquierda 6B
//   soltar una tecla = F0 + codigo (se ignora)
//   Enter = 5A  -> tecla_enter (reinicia el juego)
// Direccion: 00 arriba, 01 derecha, 10 abajo, 11 izquierda.
// Reglas: no se puede devolver (giro opuesto) y maximo 1 giro por paso.
// ============================================================
module snake_direccion(
    input  wire       clk, rst,
    input  wire       ps2_clk, ps2_data,
    input  wire       move_tick,      // pulso cada paso (borra giro_usado)
    input  wire       juego_activo,   // 1 = se esta jugando
    output wire [1:0] dir_actual,
    output wire       tecla_flecha,   // pulso: se oprimio una flecha
    output wire       tecla_enter     // pulso: se oprimio Enter
);

// ---------- REGISTROS ----------
reg [2:0] sc = 3'b111, sd = 3'b111;   // sincronizadores de ps2_clk y ps2_data
reg [9:0] r  = 10'd0;                 // registro de desplazamiento (trama)
reg [3:0] cuenta = 4'd0;              // bits recibidos 0..10
reg extendida = 0, liberacion = 0, giro_usado = 0;
reg [1:0] dir = 2'b01;                // arranca a la derecha
reg flecha_r = 0, enter_r = 0;

// ---------- BLOQUE 1: SINCRONIZADOR + DETECTOR DE FLANCO DE BAJADA ----------
// 3 flip-flops en serie por senal. Bajada = antes 1, ahora 0.
wire bajada = sc[2] & ~sc[1];
wire dato   = sd[2];

// ---------- BLOQUE 2: CONTADOR DE BITS (incrementador de 4 bits + comparador) ----------
wire [3:0] c_cnt = {c_cnt[2:0] & cuenta[2:0], 1'b1};   // half adders
wire [3:0] cuenta_mas1 = cuenta ^ c_cnt;
wire es_bit10  = cuenta[3] & ~cuenta[2] & cuenta[1] & ~cuenta[0];   // cuenta == 10 (1010)
wire fin_trama = bajada & es_bit10;    // llego el bit de parada

// ---------- BLOQUE 3: VERIFICAR TRAMA ----------
// r = {paridad, d7..d0, inicio}. inicio=0, parada=1, paridad impar.
wire [7:0] codigo = r[8:1];
wire paridad_ok = ^r[9:1];             // XOR de 9 bits = 1 si hay # impar de unos
wire trama_ok   = ~r[0] & dato & paridad_ok;
wire valida = fin_trama &  trama_ok;
wire error  = fin_trama & ~trama_ok;

// ---------- BLOQUE 4: COMPARADORES DE CODIGO (igualdad con constante) ----------
wire es_E0 = (codigo == 8'hE0);
wire es_F0 = (codigo == 8'hF0);
wire es_75 = (codigo == 8'h75);   // arriba
wire es_74 = (codigo == 8'h74);   // derecha
wire es_72 = (codigo == 8'h72);   // abajo
wire es_6B = (codigo == 8'h6B);   // izquierda
wire es_5A = (codigo == 8'h5A);   // Enter
wire es_1D = (codigo == 8'h1D);   // W arriba
wire es_23 = (codigo == 8'h23);   // D derecha
wire es_1B = (codigo == 8'h1B);   // S abajo
wire es_1C = (codigo == 8'h1C);   // A izquierda

// ---------- BLOQUE 5: QUE TECLA FUE ----------
wire byte_normal = valida & ~es_E0 & ~es_F0;      // ultimo byte de la secuencia
wire presion     = byte_normal & ~liberacion;     // se oprimio (no se solto)
wire es_flecha   = es_75 | es_74 | es_72 | es_6B;   // necesitan E0 antes
wire es_wasd     = es_1D | es_23 | es_1B | es_1C;   // no necesitan E0
wire flecha      = presion & ((extendida & es_flecha) | (~extendida & es_wasd));
wire enter       = presion & es_5A;

// ---------- BLOQUE 6: CODIFICADOR 8 a 2 (tecla -> direccion) ----------
wire arriba    = es_75 | es_1D;   // flecha arriba o W
wire derecha   = es_74 | es_23;   // flecha derecha o D
wire abajo     = es_72 | es_1B;   // flecha abajo o S
wire izquierda = es_6B | es_1C;   // flecha izquierda o A
wire n1 = abajo | izquierda;      // 10 o 11
wire n0 = derecha | izquierda;    // 01 o 11

// ---------- BLOQUE 7: REGLAS DE GIRO ----------
wire opuesta = (n1 ^ dir[1]) & ~(n0 ^ dir[0]);   // nueva = dir XOR 10
wire cambia  = (n1 ^ dir[1]) |  (n0 ^ dir[0]);   // nueva distinta de dir
wire aceptar = flecha & (~juego_activo | (~giro_usado & ~opuesta));

// ---------- BLOQUE 8: SIGUIENTE ESTADO (MUX 2:1 + reset) ----------
wire [9:0] r_D      = bajada ? {dato, r[9:1]} : r;          // desplaza a la derecha
wire [3:0] cuenta_D = {4{~rst & ~fin_trama}} &
                      (bajada ? cuenta_mas1 : cuenta);       // 0..10 y vuelve a 0
wire ext_D  = ~rst & ((valida & es_E0) | (extendida  & ~byte_normal & ~error));
wire lib_D  = ~rst & ((valida & es_F0) | (liberacion & ~byte_normal & ~error));
wire giro_D = ~rst & ((aceptar & juego_activo & cambia) | (giro_usado & ~move_tick));
wire dir1_D = ~rst & (aceptar ? n1 : dir[1]);
wire dir0_D =  rst | (aceptar ? n0 : dir[0]);                 // reset -> 01

always @(posedge clk) begin
    sc <= {sc[1:0], ps2_clk};
    sd <= {sd[1:0], ps2_data};
    r  <= r_D;
    cuenta     <= cuenta_D;
    extendida  <= ext_D;
    liberacion <= lib_D;
    giro_usado <= giro_D;
    dir        <= {dir1_D, dir0_D};
    flecha_r   <= ~rst & flecha;
    enter_r    <= ~rst & enter;
end

assign dir_actual   = dir;
assign tecla_flecha = flecha_r;
assign tecla_enter  = enter_r;

endmodule
