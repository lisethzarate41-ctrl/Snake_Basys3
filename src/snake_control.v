// Apoyo de IA (Claude): generacion del codigo de la FSM (ecuaciones de estado y salida) a partir del diagrama de estados del grupo.
`timescale 1ns/1ps
// ============================================================
// snake_control.v
// Máquina de estados (FSM tipo Moore) que decide en qué parte
// del juego estamos. Hecha con el procedimiento del profe
// (diapositivas 93-102, ejemplo del semáforo):
//   1. entradas y salidas  2. diagrama  3. tabla de transición
//   4. codificación        5. tabla codificada
//   6. ecuaciones          7. esquemático
//
// Estados (codificación binaria, 2 flip-flops S1 S0):
//   ESPERA  = 00  serpiente quieta en (15,15), espera una flecha
//   JUGANDO = 01  la serpiente se mueve
//   PERDIO  = 10  chocó: game over (serpiente en blanco)
//   GANO    = 11  llenó el tablero (longitud 1024)
// De PERDIO y GANO solo se sale con el botón de reinicio (rst).
//
// Entradas de la FSM (después del bloque de condiciones):
//   T = tecla_flecha                      se presionó una flecha
//   C = move_tick · colision · ~buscando  la cabeza intentó avanzar y chocó
//   L = tablero_lleno                     longitud[10] de snake_cuerpo
//
// Ecuaciones de siguiente estado:
//   S1' = S1 + S0·(C + L)
//   S0' = ~S1·~S0·T + S0·(S1 + L + ~C)
// con reinicio síncrono:  D = ~rst · S'
//
// Ecuaciones de salida (Moore: solo dependen del estado):
//   juego_activo = ~S1·S0
//   fin_juego    = S1
//   victoria     = S1·S0
// ============================================================
module snake_control(
    input  wire       clk,           // reloj 100 MHz
    input  wire       rst,           // botón de reinicio (síncrono)
    input  wire       tecla_flecha,  // 1 = se presionó alguna flecha (teclado)
    input  wire       move_tick,     // pulso cada 0.2 s (snake_velocidad)
    input  wire       colision,      // 1 = la casilla siguiente no es válida (snake_colisiones)
    input  wire       buscando,      // 1 = objetos buscando casilla libre (snake_objetos)
    input  wire       tablero_lleno, // longitud[10] de snake_cuerpo
    output wire       juego_activo,  // 1 solo en JUGANDO (va a habilitar)
    output wire       fin_juego,     // 1 en PERDIO o GANO (a snake_dibujo)
    output wire       victoria,      // 1 solo en GANO
    output wire [1:0] estado         // {S1,S0}, para ver en LEDs o simulación
);

// ---------- 1. Bloque de condiciones (entradas de la FSM) ----------
wire T = tecla_flecha;
wire C = move_tick & colision & ~buscando;   // choque real
wire L = tablero_lleno;

// ---------- 2. Registro de estado (2 flip-flops D) ----------
reg  [1:0] S = 2'b00;            // arranca en ESPERA
wire S1 = S[1];
wire S0 = S[0];

// ---------- 3. Lógica de siguiente estado ----------
wire S1_sig = S1 | (S0 & (C | L));
wire S0_sig = (~S1 & ~S0 & T) | (S0 & (S1 | L | ~C));

// reinicio síncrono: si rst = 1, D = 00 (ESPERA)
wire D1 = ~rst & S1_sig;
wire D0 = ~rst & S0_sig;

always @(posedge clk) begin
    S <= {D1, D0};
end

// ---------- 4. Lógica de salida (Moore) ----------
assign juego_activo = ~S1 & S0;
assign fin_juego    = S1;
assign victoria     = S1 & S0;
assign estado       = S;

endmodule
