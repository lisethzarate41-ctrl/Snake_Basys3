`timescale 1ns/1ps
module tb_snake_velocidad;
reg clk=0, rst=1;
wire move_tick;
integer i, pulsos=0, errores=0;
snake_velocidad #(.LIMITE(4)) uut(.clk(clk), .rst(rst), .move_tick(move_tick));
always #5 clk=~clk;
initial begin
    @(negedge clk); rst=0;
    for (i=1;i<=20;i=i+1) begin
        @(posedge clk); #1;
        if (move_tick !== (i%5==0)) begin
            $display("ERROR ciclo %0d: tick=%b",i,move_tick); errores=errores+1;
        end
        if (move_tick) pulsos=pulsos+1;
    end
    if (pulsos!=4) errores=errores+1;
    if (errores==0) $display("OK VELOCIDAD: 4 pulsos en 20 ciclos");
    else $display("ERROR VELOCIDAD: %0d",errores);
    $finish;
end
endmodule
