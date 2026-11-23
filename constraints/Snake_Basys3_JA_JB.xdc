# Snake Basys3 - HUB75 32x32 mediante JA/JB
# Mapeo basado en Basys-3-Master.xdc oficial de Digilent.
# Asistencia IA: correspondencia entre cableado indicado y pines FPGA.
# Top: snake_top

# Reloj de 100 MHz de Basys 3
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

# Reset: boton central de Basys 3 (activo alto)
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports rst]

# Teclado mediante interfaz USB HID PS/2 de Basys 3 (NO JA/JB)
set_property -dict { PACKAGE_PIN C17 IOSTANDARD LVCMOS33 PULLUP true } [get_ports ps2_clk]
set_property -dict { PACKAGE_PIN B17 IOSTANDARD LVCMOS33 PULLUP true } [get_ports ps2_data]

# HUB75 - colores superiores, panel pines 1, 2, 3
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports R1]    ;# JA1 -> HUB75 pin 1
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports G1]    ;# JA2 -> HUB75 pin 2
set_property -dict { PACKAGE_PIN J2 IOSTANDARD LVCMOS33 } [get_ports B1]    ;# JA3 -> HUB75 pin 3

# HUB75 - colores inferiores, panel pines 5, 6, 7
set_property -dict { PACKAGE_PIN G2 IOSTANDARD LVCMOS33 } [get_ports R2]    ;# JA4 -> HUB75 pin 5
set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 } [get_ports G2]    ;# JA7 -> HUB75 pin 6
set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 } [get_ports B2]    ;# JA8 -> HUB75 pin 7

# HUB75 - seleccion de pareja de filas, panel pines 9-12
set_property -dict { PACKAGE_PIN H2 IOSTANDARD LVCMOS33 } [get_ports A]     ;# JA9  -> HUB75 pin 9
set_property -dict { PACKAGE_PIN G3 IOSTANDARD LVCMOS33 } [get_ports B]     ;# JA10 -> HUB75 pin 10
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports C]    ;# JB1  -> HUB75 pin 11
set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 } [get_ports D]    ;# JB2  -> HUB75 pin 12

# HUB75 - temporizacion, panel pines 13-15
set_property -dict { PACKAGE_PIN B15 IOSTANDARD LVCMOS33 } [get_ports HUB_CLK] ;# JB3 -> HUB75 pin 13 CLK/SCK
set_property -dict { PACKAGE_PIN B16 IOSTANDARD LVCMOS33 } [get_ports HUB_LAT] ;# JB4 -> HUB75 pin 14 LAT
set_property -dict { PACKAGE_PIN A15 IOSTANDARD LVCMOS33 } [get_ports HUB_OE]  ;# JB7 -> HUB75 pin 15 OE

# GND no se asigna en XDC: panel pin 4 a GND de JA; pin 16 a GND de JB.
# Panel pin 8 figura sin conectar en el cableado informado.
# Alimentar panel con fuente externa de 5 V, NO con pines Pmod.

# Puntaje: los 16 LED individuales LD0-LD15 de Basys3
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[3]}]
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[4]}]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[5]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[6]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[7]}]
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[8]}]
set_property -dict { PACKAGE_PIN V3 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[9]}]
set_property -dict { PACKAGE_PIN W3 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[10]}]
set_property -dict { PACKAGE_PIN U3 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[11]}]
set_property -dict { PACKAGE_PIN P3 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[12]}]
set_property -dict { PACKAGE_PIN N3 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[13]}]
set_property -dict { PACKAGE_PIN P1 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[14]}]
set_property -dict { PACKAGE_PIN L1 IOSTANDARD LVCMOS33 } [get_ports {leds_puntaje[15]}]

# Estado del juego: dos pines VGA libres (NO encienden LED internos).
# Se asignan para completar todos los puertos del top; si se quieren ver,
# habra que modificar el top para usar otro indicador fisico.
set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports {leds_estado[0]}]
set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS33 } [get_ports {leds_estado[1]}]
