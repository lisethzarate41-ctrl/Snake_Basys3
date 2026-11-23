
`timescale 1ns/1ps
// ============================================================
// snake_direccion.v
// Recibe teclas PS/2 (flechas y WASD), reconoce Enter y controla
// la direccion de la serpiente.
//
// Direcciones: 00 arriba, 01 derecha, 10 abajo, 11 izquierda.
// Reglas: no permite giros opuestos ni varios giros por paso.
//
// Apoyo de IA (ChatGPT): diseño del receptor PS/2, ecuaciones
// booleanas, decodificacion de teclas y revision de reglas de giro.
// ============================================================
module snake_direccion(
    input  wire       clk, rst,
    input  wire       ps2_clk, ps2_data,
    input  wire       move_tick,
    input  wire       juego_activo,
    output wire [1:0] dir_actual,
    output wire       tecla_flecha,
    output wire       tecla_enter
);

// FIGURA 10: REGISTROS DEL RECEPTOR PS/2
// Guardan muestras, bits recibidos y numero de bits de la trama.
reg [2:0] sc = 3'b111, sd = 3'b111;
reg [9:0] r  = 10'd0;
reg [3:0] cuenta = 4'd0;

// FIGURA 11: REGISTROS DE CONTROL Y DIRECCION
// Recuerdan los prefijos, el giro y la direccion actual.
reg extendida = 0, liberacion = 0, giro_usado = 0;
reg [1:0] dir = 2'b01;
reg flecha_r = 0, enter_r = 0;

// BLOQUE 1: SINCRONIZADOR Y DETECTOR DE FLANCO (FIG. 10)
// Detecta la bajada de ps2_clk y obtiene el bit recibido.
wire bajada = sc[2] & ~sc[1];
wire dato   = sd[2];

// BLOQUE 2: CONTADOR DE BITS (FIG. 10)
// Incrementador de 4 bits construido con AND y XOR.
// Detecta el bit 10, que corresponde al final de la trama.
wire [3:0] c_cnt;
assign c_cnt[0] = 1'b1;
assign c_cnt[1] = cuenta[0];
assign c_cnt[2] = cuenta[1] & cuenta[0];
assign c_cnt[3] = cuenta[2] & cuenta[1] & cuenta[0];
wire [3:0] cuenta_mas1 = cuenta ^ c_cnt;

wire es_bit10  = cuenta[3] & ~cuenta[2] & cuenta[1] & ~cuenta[0];
wire fin_trama = bajada & es_bit10;

// BLOQUE 3: VERIFICACION DE TRAMA (FIG. 10)
// Extrae los 8 bits del codigo y verifica inicio, parada
// y paridad impar. Indica si la trama fue valida o incorrecta.
wire [7:0] codigo = r[8:1];
wire paridad_ok = ^r[9:1];
wire trama_ok   = ~r[0] & dato & paridad_ok;
wire valida = fin_trama &  trama_ok;
wire error  = fin_trama & ~trama_ok;

// BLOQUE 4: COMPARADORES DE CODIGO (FIG. 11)
// Identifican prefijos E0/F0, flechas, WASD y Enter.
wire es_E0 = (codigo == 8'hE0);
wire es_F0 = (codigo == 8'hF0);
wire es_75 = (codigo == 8'h75);
wire es_74 = (codigo == 8'h74);
wire es_72 = (codigo == 8'h72);
wire es_6B = (codigo == 8'h6B);
wire es_5A = (codigo == 8'h5A);
wire es_1D = (codigo == 8'h1D);
wire es_23 = (codigo == 8'h23);
wire es_1B = (codigo == 8'h1B);
wire es_1C = (codigo == 8'h1C);

// BLOQUE 5: DECODIFICACION DE TECLAS (FIG. 11)
// Distingue pulsacion de liberacion y reconoce direcciones
// mediante flechas extendidas o las teclas WASD.
wire byte_normal = valida & ~es_E0 & ~es_F0;
wire presion     = byte_normal & ~liberacion;
wire es_flecha   = es_75 | es_74 | es_72 | es_6B;
wire es_wasd     = es_1D | es_23 | es_1B | es_1C;
wire flecha      = presion & ((extendida & es_flecha) | (~extendida & es_wasd));
wire enter       = presion & es_5A;

// BLOQUE 6: CODIFICADOR DE DIRECCION (FIG. 11)
// Convierte la tecla reconocida en los bits n1 y n0.
wire arriba    = es_75 | es_1D;
wire derecha   = es_74 | es_23;
wire abajo     = es_72 | es_1B;
wire izquierda = es_6B | es_1C;
wire n1 = abajo | izquierda;
wire n0 = derecha | izquierda;

// BLOQUE 7: ACEPTACION DEL GIRO (FIG. 11)
// Detecta direcciones contrarias y cambios de direccion.
// Solo acepta giros permitidos cuando el juego esta activo.
wire opuesta = (n1 ^ dir[1]) & ~(n0 ^ dir[0]);
wire cambia  = (n1 ^ dir[1]) |  (n0 ^ dir[0]);
wire aceptar = flecha & (~juego_activo | (~giro_usado & ~opuesta));

// BLOQUE 8: LOGICA DE SIGUIENTE ESTADO (FIGS. 10 Y 11)
// Los MUX seleccionan entre conservar o actualizar registros.
// rst reinicia el contador y deja la direccion en 01.
wire [9:0] r_D      = bajada ? {dato, r[9:1]} : r;
wire [3:0] cuenta_D = {4{~rst & ~fin_trama}} &
                      (bajada ? cuenta_mas1 : cuenta);
wire ext_D  = ~rst & ((valida & es_E0) | (extendida  & ~byte_normal & ~error));
wire lib_D  = ~rst & ((valida & es_F0) | (liberacion & ~byte_normal & ~error));
wire giro_D = ~rst & ((aceptar & juego_activo & cambia) | (giro_usado & ~move_tick));
wire dir1_D = ~rst & (aceptar ? n1 : dir[1]);
wire dir0_D =  rst | (aceptar ? n0 : dir[0]);

// REGISTROS TIPO D (FIGS. 10 Y 11)
// Actualizan simultaneamente sus valores en cada flanco de clk.
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

// SALIDAS DEL MODULO
// Entregan la direccion almacenada y los pulsos de tecla.
assign dir_actual   = dir;
assign tecla_flecha = flecha_r;
assign tecla_enter  = enter_r;

endmodule
