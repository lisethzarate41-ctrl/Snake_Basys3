
`timescale 1ns/1ps
// ============================================================
// snake_objetos.v
// Busca casillas libres para la comida y el veneno (tablero 32x32).
// Estados: S0 INICIO, S1 BUSCA_COMIDA, S2 BUSCA_VENENO, S3 JUEGO.
//
// Posiciones ALEATORIAS con un LFSR de 11 bits (lfsr_11b, abajo):
//   - avanza en CADA ciclo de reloj (100 MHz) y nunca se reinicia,
//     asi que el valor depende del instante exacto en que la
//     serpiente come o se oprime Enter -> casilla distinta cada vez.
//   - candidato = 10 bits bajos del LFSR = {y[4:0], x[4:0]}.
//   - si la casilla esta ocupada, se prueba el valor del siguiente
//     ciclo (el LFSR ya cambio solo).
//
// Apoyo de IA (ChatGPT): diseño de la FSM para colocar comida
// y veneno, generación de posiciones mediante LFSR y revisión
// de las condiciones para evitar casillas ocupadas.
// ============================================================
module snake_objetos(
 input wire clk, rst, cuerpo_listo, consulta_ocupada,
 input wire [4:0] x_siguiente, y_siguiente,
 input wire paso,
 output wire [4:0] x_consulta, y_consulta,
 output reg [4:0] x_comida, y_comida, x_veneno, y_veneno,
 output reg comida_activa, veneno_activo,
 output wire come_comida, come_veneno, buscando
);

// BLOQUE FSM: registro de 3 bits que guarda el estado actual.
localparam S0=3'd0, S1=3'd1, S2=3'd2, S3=3'd3, S4=3'd4;
reg [2:0] estado;

// BLOQUE 1: LFSR
// Genera valores pseudoaleatorios que cambian con cada ciclo.
wire [10:0] aleatorio;
lfsr_11b u_lfsr(.clk(clk), .q(aleatorio));

// BLOQUE 2: CANDIDATO
// Se toman 10 bits: 5 para X y 5 para Y.
// Estas coordenadas se consultan en la memoria del cuerpo.
wire [9:0] candidato = aleatorio[9:0];
wire [9:0] ubicacion = {candidato[9:5],candidato[4:0]};
assign x_consulta = ubicacion[4:0];
assign y_consulta = ubicacion[9:5];

// BLOQUE "¿SE LOS COME?"
// Compara la siguiente posicion de la cabeza con los objetos.
// Solo detecta consumo cuando la FSM esta en S3 (LISTO).
assign buscando = (estado != S3);
assign come_comida = (estado==S3) && comida_activa &&
                      (x_siguiente==x_comida) && (y_siguiente==y_comida);
assign come_veneno = (estado==S3) && veneno_activo &&
                      (x_siguiente==x_veneno) && (y_siguiente==y_veneno);

// BLOQUE "¿CANDIDATO OCUPADO?"
// Comprueba si el candidato coincide con comida o veneno.
// consulta_ocupada indica si tambien esta ocupado por el cuerpo.
wire es_comida = comida_activa && ({y_comida,x_comida} == candidato);
wire es_veneno = veneno_activo && ({y_veneno,x_veneno} == candidato);

// BLOQUE 3: FSM DE OBJETOS
// Controla la busqueda y guarda las coordenadas en los registros
// verdes de comida y veneno cuando encuentra una casilla libre.
always @(posedge clk) begin
    if (rst) begin
        estado <= S0;
        x_comida <= 0; y_comida <= 0;
        x_veneno <= 0; y_veneno <= 0;
        comida_activa <= 0; veneno_activo <= 0;
    end else begin
        case (estado)
            // S0: espera a que el cuerpo este listo.
            S0: if (cuerpo_listo) estado <= S1;

            // S1: busca una casilla libre para colocar comida.
            S1: begin
                if (!consulta_ocupada && !es_veneno) begin
                    x_comida <= candidato[4:0]; y_comida <= candidato[9:5];
                    comida_activa <= 1;
                    estado <= S2;
                end
            end

            // S2: busca una casilla libre para colocar veneno.
            S2: begin
                if (!consulta_ocupada && !es_comida) begin
                    x_veneno <= candidato[4:0]; y_veneno <= candidato[9:5];
                    veneno_activo <= 1;
                    estado <= S3;
                end
            end

            // S3: espera a que la serpiente consuma un objeto.
            // Si come, vuelve al estado que busca ese objeto.
            S3: begin
                if (paso && come_comida) begin
                    comida_activa <= 0; estado <= S1;
                end else if (paso && come_veneno) begin
                    veneno_activo <= 0; estado <= S2;
                end
            end

            // Estado adicional y recuperacion de estados no definidos.
            S4: estado <= S3;
            default: estado <= S0;
        endcase
    end
end
endmodule

// ============================================================
// lfsr_11b: registro de desplazamiento con realimentacion lineal.
//   Polinomio x^11 + x^9 + 1  (maxima longitud: 2047 estados).
//   Realimentacion = q[10] XOR q[8]  (una sola compuerta XOR).
//   Cada ciclo: se corre a la izquierda y entra la realimentacion.
//   Arranca en 1 (nunca en 0, porque con 0 se quedaria pegado).
//
// Apoyo de IA (ChatGPT): diseño del generador pseudoaleatorio
// de 11 bits y revisión de la lógica de realimentación XOR.
// ============================================================
module lfsr_11b(
    input  wire        clk,
    output wire [10:0] q
);

// CIRCUITO LFSR DE LA FIGURA 16
// Registro de 11 bits con realimentacion mediante una XOR.
// Su valor cambia en cada flanco positivo del reloj.
reg  [10:0] r = 11'd1;
wire realim = r[10] ^ r[8];          // compuerta XOR
wire [10:0] r_D = {r[9:0], realim};  // corrimiento a la izquierda
always @(posedge clk) r <= r_D;
assign q = r;
endmodule
