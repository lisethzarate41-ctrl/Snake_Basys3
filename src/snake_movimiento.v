// Apoyo de IA (Claude): generacion del codigo del decodificador
`timescale 1ns/1ps
// ============================================================
// snake_movimiento.v
// Guarda la posición de la cabeza y calcula la casilla siguiente.
//
// dir_actual (de snake_direccion):
//   00 arriba    -> y - 1
//   01 derecha   -> x + 1
//   10 abajo     -> y + 1
//   11 izquierda -> x - 1
// (0,0) = esquina superior izquierda. y crece hacia abajo.
//
// La cabeza solo avanza cuando:
//   paso = move_tick · habilitar · NOT colision
// colision la calcula snake_colisiones (paredes + cuerpo).
// ============================================================
module snake_movimiento(
    input  wire       clk,          // reloj 100 MHz
    input  wire       rst,          // reinicio síncrono
    input  wire       move_tick,    // pulso de 1 ciclo cada 0.2 s (snake_velocidad)
    input  wire       habilitar,    // 1 = juego corriendo (snake_control)
    input  wire [1:0] dir_actual,   // dirección (snake_direccion)
    input  wire       colision,     // 1 = el paso no es válido (snake_colisiones)
    output wire [4:0] x_actual,     // columna actual de la cabeza
    output wire [4:0] y_actual,     // fila actual de la cabeza
    output wire [4:0] x_siguiente,  // columna a la que intenta avanzar
    output wire [4:0] y_siguiente,  // fila a la que intenta avanzar
    output wire       paso          // 1 = en este flanco la cabeza avanza
);

// ---------- 1. Decodificador de dirección ----------
wire Q1 = dir_actual[1];
wire Q0 = dir_actual[0];

wire Mx = Q0;            // se mueve en x
wire My = ~Q0;           // se mueve en y
wire Rx = Q1 & Q0;       // restar en x (izquierda)
wire Ry = ~Q1 & ~Q0;     // restar en y (arriba)

// ---------- 2. Sumadores/restadores de 5 bits ----------
sumador_restador_5b sr_x (.a(x_actual), .b({4'b0000, Mx}), .sub(Rx), .r(x_siguiente));
sumador_restador_5b sr_y (.a(y_actual), .b({4'b0000, My}), .sub(Ry), .r(y_siguiente));

// ---------- 3. Señal de avance ----------
assign paso = move_tick & habilitar & ~colision & ~rst;

// ---------- 4. Mux 2:1 + reset (siguiente estado) ----------
//   D = rst ? 15 : (paso ? siguiente : actual)      15 = 01111
wire [4:0] mux_x = ({5{paso}} & x_siguiente) | ({5{~paso}} & x_actual);
wire [4:0] mux_y = ({5{paso}} & y_siguiente) | ({5{~paso}} & y_actual);

wire [4:0] Dx = ({5{rst}} & 5'b01111) | ({5{~rst}} & mux_x);
wire [4:0] Dy = ({5{rst}} & 5'b01111) | ({5{~rst}} & mux_y);

// ---------- 5. Registro de posición (10 flip-flops D) ----------
reg [4:0] reg_x = 5'b01111;
reg [4:0] reg_y = 5'b01111;

always @(posedge clk) begin
    reg_x <= Dx;
    reg_y <= Dy;
end

assign x_actual = reg_x;
assign y_actual = reg_y;

endmodule


// ============================================================
// Sumador/restador de 5 bits (complemento a dos, ripple carry)
//   sub = 0 -> r = a + b
//   sub = 1 -> r = a - b = a + ~b + 1
// ============================================================
module sumador_restador_5b(
    input  wire [4:0] a,
    input  wire [4:0] b,
    input  wire       sub,
    output wire [4:0] r
);

wire [4:0] b_mod = b ^ {5{sub}};   // B' = B xor sub
wire [5:0] c;                      // carries C0..C5
assign c[0] = sub;                 // el "+1" del complemento a dos

full_adder fa0 (.a(a[0]), .b(b_mod[0]), .cin(c[0]), .s(r[0]), .cout(c[1]));
full_adder fa1 (.a(a[1]), .b(b_mod[1]), .cin(c[1]), .s(r[1]), .cout(c[2]));
full_adder fa2 (.a(a[2]), .b(b_mod[2]), .cin(c[2]), .s(r[2]), .cout(c[3]));
full_adder fa3 (.a(a[3]), .b(b_mod[3]), .cin(c[3]), .s(r[3]), .cout(c[4]));
full_adder fa4 (.a(a[4]), .b(b_mod[4]), .cin(c[4]), .s(r[4]), .cout(c[5]));

endmodule


// ============================================================
// Sumador completo de 1 bit
// ============================================================
module full_adder(
    input  wire a, b, cin,
    output wire s, cout
);

assign s    = a ^ b ^ cin;
assign cout = (a & b) | (cin & (a ^ b));

endmodule
