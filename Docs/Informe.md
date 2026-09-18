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

Los módulos LCD y controlador_LCD son los encargados de coordinar la comunicación del juego con respecto al periférico, donde como función general, el módulo del controlador, que funciona como máquina de estados interna del LCD, quien le comunica al módulo LCD cuando y cuál caracter escribir en la pantalla del LCD.
El controlador_LCD detecta un cambio relevante (cambio_pantalla), únicamente cuando el LCD está libre (rdata[0] == 0). Esto ocurre cuando cambia estado_actual, dificultad, victoria, derrota, fallos, o el contenido de palabra_estado/palabra_actual. En cada paso de escritura, lee el carácter correspondiente desde el módulo de Memoria (vía direccion_memoria / dato_memoria), revelando la letra como parte de la palabra(letra correcta) o como fallo.
El controlador también maneja el bus hacia el LCD, activando wenable=1, con addr fija, habilitando y dándole lugar al byte a escribir en wdata[7:0].
Ahora bien, el módulo LCD captura la escritura solo si está en estado "LISTO", solo si wenable = 1 mientras estado == LISTO, dando lugar a registrar rs_actual, saliendo del estdo "LISTO". En el mismo flanco rdata[0]=1, indicando el bit de "BUSY" como activo.
Se debe aclarar que para el módulo LCD por diseño, en su escritura, del bus que viene del módulo controlador del LCD, la señal lcd_datos[3:0] es la encargada de generar lo pasos a seguir para el periférico, con lcd_rs y lcd_en, ejecutandose con lcd_en en bajo.
Finalmente el módulo LCD vuelte a un estado "LISTO" y rdata[0] cae a 0, siguiendo a un estado de "ESPERAR", detectando el cambio y avanzandi al siguiente caracter, repitiendo el ciclo hasta conseguir adivinar la palabra, fallar 6 veces o time out.
En la siguiente imagen se evidencia las interconexiones existentes entre la FPGA que maneja los módulos involucrados con el periférico LCD.

![FPGA con periférico LCD](../images/LCD.jpg)

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