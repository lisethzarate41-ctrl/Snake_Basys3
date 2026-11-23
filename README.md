<div align="center">

#  SNAKE — BASYS 3

### Proyecto Final de Electrónica Digital


[![Verilog](https://img.shields.io/badge/Lenguaje-Verilog-blue)](https://en.wikipedia.org/wiki/Verilog)

[![FPGA](https://img.shields.io/badge/FPGA-Basys_3-green)](https://digilent.com/reference/programmable-logic/basys-3/start)

[![Vivado](https://img.shields.io/badge/Software-Vivado-orange)](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vivado.html)

[![HUB75](https://img.shields.io/badge/Matriz_RGB-HUB75_32x32-purple)](https://github.com/hzeller/rpi-rgb-led-matrix)

[![Proyecto](https://img.shields.io/badge/Proyecto-Académico-blue)](docs/informe_snake.pdf)


**Escuela Colombiana de Ingeniería Julio Garavito**

Ingeniería Electrónica | Electrónica Digital | 2026

---

**Implementación del videojuego Snake en una FPGA Basys 3 utilizando Verilog y una matriz LED RGB HUB75 de 32 × 32 píxeles.**

</div>

---

##  Descripción del proyecto

Este proyecto consiste en la implementación del videojuego **Snake** sobre una tarjeta FPGA **Basys 3**, equipada con un dispositivo Artix-7 XC7A35T y un reloj de 100 MHz.

La visualización se realiza mediante una matriz LED RGB **HUB75 de 32 × 32 píxeles**, con barrido 1/16. El jugador controla la serpiente utilizando un teclado USB conectado a la interfaz PS/2 de la tarjeta.

El diseño está desarrollado completamente en **Verilog**, sin utilizar procesador.

Se utiliza un único reloj de 100 MHz y pulsos de habilitación para sincronizar los diferentes módulos.

El sistema está dividido en **12 módulos**, correspondientes a 11 módulos funcionales y un módulo principal de integración.

---

##  Tabla de contenido

1. [Reglas del juego](#1--reglas-del-juego)
2. [Controles y salidas](#2--controles-y-salidas)
3. [Estructura del repositorio](#3--estructura-del-repositorio)
4. [Hardware y montaje](#4--hardware-y-montaje)
5. [Arquitectura del sistema](#5--arquitectura-del-sistema)
6. [Cómo reproducir el proyecto](#6--cómo-reproducir-el-proyecto)
7. [Verificación y testbenches](#7--verificación-y-testbenches)
8. [Resultados](#8--resultados)
9. [Limitaciones conocidas](#9--limitaciones-conocidas)
10. [Declaración de uso de IA](#10--declaración-de-uso-de-inteligencia-artificial)
11. [Documentación](#11--documentación)
12. [Autores](#12--autores)

---

## 1. Reglas del juego

El objetivo es controlar una serpiente que se desplaza por un tablero de **32 × 32 casillas**, recolectando comida y evitando las colisiones.
###  Elementos del juego

| Elemento | Color en el panel | Función |
|:---:|:---:|---|
|  Cabeza | 🟡 Amarillo | Avanza una casilla cada 0,2 segundos |
| Cuerpo | 🟢 Verde | Sigue el movimiento de la cabeza |
|  Comida | 🔴 Rojo | Aumenta la longitud en una casilla y el puntaje en una unidad |
|  Veneno | 🟣 Magenta | Disminuye la longitud en una casilla |

###  Inicio

- El juego comienza en el estado **ESPERA**.
- La cabeza se ubica inicialmente en la posición **(15, 15)**.
- La primera tecla de dirección inicia el movimiento.

###  Condiciones de derrota

El jugador pierde cuando:

- La serpiente choca contra los bordes del tablero.
- La cabeza colisiona con su propio cuerpo.
- Consume veneno cuando únicamente queda la cabeza.

Cuando ocurre una derrota, el puntaje aparece en **rojo**.

###  Condición de victoria

El jugador gana cuando la serpiente ocupa las **1024 casillas del tablero**.

En este caso, el puntaje aparece en **verde**.

###  Reglas adicionales

- No se permiten giros de 180°.
- Las direcciones opuestas al movimiento actual se ignoran.
- La comida y el veneno se generan mediante un **LFSR de 11 bits**.
- Los objetos se ubican en casillas libres del tablero.

---

## 2. Controles y salidas

###  Controles del teclado

| Tecla / botón | Acción |
|:---:|---|
| W / ↑ | Mover hacia arriba |
| A / ← | Mover hacia la izquierda |
| S / ↓ | Mover hacia abajo |
| D / → | Mover hacia la derecha |
| Enter | Reiniciar el juego |
| BTNC | Reset general |

###  Salidas de la FPGA

| Salida | Función |
|---|---|
| LD0–LD15 | Representación del puntaje en binario |
| `leds_estado[1:0]` | Indicación del estado del juego |

### Estados del sistema

| Código | Estado |
|:---:|---|
| `00` | ESPERA |
| `01` | JUGANDO |
| `10` | PERDIÓ |
| `11` | GANÓ |

**Nota:** las señales `leds_estado[1:0]` están asignadas a los pines G19 y H19, correspondientes al conector VGA de la Basys 3.

Por esta razón, el estado puede observarse mediante simulación o utilizando indicadores externos conectados adecuadamente.

---
## 3. Estructura del repositorio

El proyecto se encuentra organizado en carpetas que separan los módulos de hardware, las simulaciones, las restricciones y la documentación.

```text
Snake_Basys3/
│
├── rtl/
│   └── Módulos Verilog
│
├── tb/
│   └── Testbenches
│
├── constraints/
│   └── Snake_Basys3_JA_JB.xdc
│
├── sim/
│   └── run_all.sh
│
├── prueba/
│   └── hub75_prueba_top.v
│
├── docs/
│   ├── informe_snake.pdf
│   └── esquemas/
│       ├── Esquemas_bloques_Snake.pdf
│       ├── png/
│       └── drawio/
│
└── README.md
```

### Descripción de las carpetas

| Carpeta | Contenido |
|---|---|
| `rtl/` | Módulos Verilog del sistema, incluido `snake_top.v` |
| `tb/` | Testbenches de los módulos y pruebas de integración |
| `constraints/` | Restricciones de reloj y asignación de pines |
| `sim/` | Script de ejecución de simulaciones |
| `prueba/` | Diseño de prueba de la matriz HUB75 |
| `docs/` | Informe, diagramas y documentación técnica |

---
## 4.  Hardware y montaje

###  Materiales utilizados

- Tarjeta FPGA **Basys 3** de Digilent.
- Cable micro-USB.
- Matriz LED RGB **HUB75 de 32 × 32 píxeles**, barrido 1/16.
- Fuente ATX **Codegen 250XA1, 450 W**.
- Teclado USB.
- 16 cables jumper hembra-hembra.

La fuente ATX proporciona el riel de **+5 V**, con una capacidad máxima indicada de 40 A, para alimentar el panel.

###  Conexiones del panel HUB75

Las conexiones corresponden al conector de **ENTRADA** del panel.

| Pin HUB75 | Señal | Pmod Basys 3 | Pin FPGA |
|:---:|---|---|---|
| 1, 2, 3 | R1, G1, B1 | JA1, JA2, JA3 | J1, L2, J2 |
| 4 | GND | GND de JA | — |
| 5, 6, 7 | R2, G2, B2 | JA4, JA7, JA8 | G2, H1, K2 |
| 8 | Sin conectar | — | — |
| 9, 10 | A, B | JA9, JA10 | H2, G3 |
| 11, 12 | C, D | JB1, JB2 | A14, A16 |
| 13, 14, 15 | CLK, LAT, OE | JB3, JB4, JB7 | B15, B16, A15 |
| 16 | GND | GND de JB | — |

### Otras conexiones

| Señal | Pin FPGA | Función |
|---|---|---|
| `clk` | W5 | Reloj de 100 MHz |
| `rst` | U18 | Botón central BTNC |
| `ps2_clk` | C17 | Reloj del teclado |
| `ps2_data` | B17 | Datos del teclado |

###  Precauciones de alimentación

- El panel HUB75 se alimenta desde la fuente ATX, **nunca desde el VCC del Pmod**.
- La fuente y la Basys 3 deben compartir una referencia de tierra común.
- Se debe verificar la polaridad y las conexiones antes de energizar el circuito.
- Para encender: primero la fuente y después la Basys 3.
- Para apagar: primero la Basys 3 y después la fuente.

---
