`timescale 1ns/1ps
// Teclado PS/2: flechas extendidas E0 75,74,72,6B.
// Se descartan liberaciones E0 F0 codigo y giros opuestos.
// Apoyo de IA: recepción serie PS/2 y pruebas de códigos.
module snake_direccion(
 input wire clk, rst, ps2_clk, ps2_data, move_tick, juego_activo,
 output reg [1:0] dir_actual,
 output reg tecla_flecha
);
reg [2:0] sync_clk, sync_data;
wire bajada = (sync_clk[2:1] == 2'b10);
reg [3:0] bit_num;
reg [10:0] trama;
reg extendida, liberacion, giro_usado;
reg [1:0] nueva_dir;
reg flecha_valida;
wire [7:0] codigo = trama[8:1];
always @* begin
    nueva_dir = dir_actual;
    flecha_valida = 1;
    case (codigo)
       8'h75: nueva_dir = 2'b00;
       8'h74: nueva_dir = 2'b01;
       8'h72: nueva_dir = 2'b10;
       8'h6b: nueva_dir = 2'b11;
       default: flecha_valida = 0;
    endcase
end
always @(posedge clk) begin
    sync_clk <= {sync_clk[1:0], ps2_clk};
    sync_data <= {sync_data[1:0], ps2_data};
    if (rst) begin
        bit_num <= 0; trama <= 0; extendida <= 0;
        liberacion <= 0; dir_actual <= 2'b01;
        tecla_flecha <= 0; giro_usado <= 0;
    end else begin
        tecla_flecha <= 0;
        if (move_tick) giro_usado <= 0;
        if (bajada) begin
            trama[bit_num] <= sync_data[2];
            if (bit_num == 10) begin
                bit_num <= 0;
                // Trama: inicio=0, datos=8, paridad impar, parada=1.
                if (trama[0]==0 && sync_data[2]==1 && (^{trama[9:1]})==1) begin
                    if (codigo == 8'he0) extendida <= 1;
                    else if (codigo == 8'hf0) liberacion <= 1;
                    else begin
                        if (extendida && !liberacion && flecha_valida) begin
                            tecla_flecha <= 1;
                            if (!juego_activo || (!giro_usado && nueva_dir != (dir_actual ^ 2'b10))) begin
                                dir_actual <= nueva_dir;
                                if (juego_activo && nueva_dir != dir_actual) giro_usado <= 1;
                            end
                        end
                        extendida <= 0;
                        liberacion <= 0;
                    end
                end else begin extendida <= 0; liberacion <= 0; end
            end else bit_num <= bit_num + 1'b1;
        end
    end
end
endmodule
