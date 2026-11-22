<div align="center">

# 🐍 SNAKE — BASYS 3

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

## 📖 Descripción del proyecto

Este proyecto consiste en la implementación del videojuego **Snake** sobre una tarjeta FPGA **Basys 3**, equipada con un dispositivo Artix-7 XC7A35T y un reloj de 100 MHz.

La visualización se realiza mediante una matriz LED RGB **HUB75 de 32 × 32 píxeles**, con barrido 1/16. El jugador controla la serpiente utilizando un teclado USB conectado a la interfaz PS/2 de la tarjeta.

El diseño está desarrollado completamente en **Verilog**, sin utilizar procesador.

Se utiliza un único reloj de 100 MHz y pulsos de habilitación para sincronizar los diferentes módulos.

El sistema está dividido en **12 módulos**, correspondientes a 11 módulos funcionales y un módulo principal de integración.

---

## 📑 Tabla de contenido

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

## 1. 🎮 Reglas del juego

El objetivo es controlar una serpiente que se desplaza por un tablero de **32 × 32 casillas**, recolectando comida y evitando las colisiones.
