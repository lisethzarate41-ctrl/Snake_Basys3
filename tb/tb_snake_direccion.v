`timescale 1ns/1ps
module tb_snake_direccion;
reg clk=0,rst=1,ps2_clk=1,ps2_data=1,move_tick=0,juego_activo=0;
wire [1:0] dir_actual;
wire tecla_flecha;
integer errores=0;
snake_direccion uut(.*);
always #5 clk=~clk;
// Envía inicio, 8 bits, paridad impar y parada.
task enviar(input [7:0] dato);
integer i; reg paridad;
begin
 paridad=~(^dato);
 for(i=0;i<11;i=i+1) begin
   case(i)
    0: ps2_data=0;
    9: ps2_data=paridad;
    10: ps2_data=1;
    default: ps2_data=dato[i-1];
   endcase
   #80; ps2_clk=0; #80; ps2_clk=1; #80;
 end
 ps2_data=1; #100;
end endtask
initial begin
 repeat(4) @(negedge clk); rst=0;
 enviar(8'he0); enviar(8'h75);
 if(dir_actual!==2'b00) begin $display("ERROR flecha arriba"); errores=errores+1; end
 enviar(8'he0); enviar(8'h74);
 if(dir_actual!==2'b01) begin $display("ERROR flecha derecha"); errores=errores+1; end
 // Una liberación no debe cambiar la dirección.
 enviar(8'he0); enviar(8'hf0); enviar(8'h6b);
 if(dir_actual!==2'b01) begin $display("ERROR liberacion"); errores=errores+1; end
 if(errores==0) $display("OK DIRECCION: flechas y liberacion");
 else $display("ERROR DIRECCION: %0d",errores);
 $finish;
end
endmodule
