# Proyecto 2: Ahorcado-juego-electrónico

**Integrantes**

**Steven Sancho Orozco**  
*Escuela de Ingeniería Electrónica*
*Tecnológico de Costa Rica*  
Carné: 2019015506

**Joan Franco Sandoval**
*Escuela de Ingeniería Electrónica*
*Tecnológico de Costa Rica*
Carné: 2020248356

**Brayan Díaz Ruiz**
*Escuela de Ingeniería Electrónica*
*Tecnológico de Costa Rica*
Carné: 2018203585

**Dennis Manuel Arce Alvarez**
*Escuela de Ingeniería Electrónica*
*Tecnológico de Costa Rica*
Carné: 2018151568

*Fecha : 17/09/2026
---


## Introducción




--- 


## Fundamentación teórica


/////////Acá va la investigación previa////////////


---

## Presentación de resultados

### Módulo Validador_Letra
Este módulo tiene varias funciones, primero, cuando se activa la señal "procesar_letra", el módulo verifica primero que "letra_recibida" se encuentre dentro del rango válido de 0 a 25 que representan las letras mayúsculas entre la "A" y la "Z". Utiliza un registro interno de 26 bits llamado "letras_usadas" para recordar qué letras ya se han usado en la partida actual. Si la letra ingresada ya tiene su bit activado en este registro, el módulo levanta la bandera de salida "letra_repetida" y omite cualquier penalización.
El módulo también compara la letra ingresa simultáneamente con las 8 posibles posiciones de la palabra secreta. Si existe una coincidencia, se actualiza la señal "palabra_estado" sustituyendo los guiones bajos por la letra correspondiente y se emite un pulso en la salida "letra_correcta". En caso contrario, se incrementa el registro de fallos hasta un máximo de 6 intentos y se emite un pulso en la señal "letra_incorrecta".
Por último, el módulo evalúa, de manera combinacional, si el registro "palabra_estado" ya contiene todas las letras. Si todas las posiciones en "cantidad_letras" son caracteres válidos entre la 'A' y la 'Z', activa la señal de salida "palabra_completa" para indicarle a la FSM principal que se ha adivinado la palabra con éxito.

### Módulo UART y Controlador_UART



### Módulo Debouncer




### Módulo LSFR



### Módulo de Memoria



### Módulo Selector_dificultad



### Módulo Selector_palabra




### Módulo de 7 segmentos




### Módulo Temporizador




### Módulo LCD y Controlado_LCD





### Módulo de LED de estado

Este es un módulo pequeño que tiene como función principal comunicar al jugador que su partida ha finalizado y que el juego se va a reiniciar por medio de una señal de reset.

### Módulo Buzzer




### Módulo FSM



### Módulo TOP



### Script ahorcado.py





## Análisis de resultados



---

### Conclusión



---

### Referencias

1. David Harris y Sarah Harris. Digital Design and Computer Architecture. RISC-V
Edition. Morgan Kaufmann, 2022, p ´agina 564. ISBN: 978-0-12-820064-3
2. Pong P. Chu. FPGA Prototyping by SystemVerilog Examples. Wiley, 2018, p ´agi-
na 656. ISBN: 978-1-119-28266-2.