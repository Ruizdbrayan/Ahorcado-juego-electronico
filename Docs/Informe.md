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
Módulo UART
El módulo UART implementa la comunicación serial entre la FPGA y un dispositivo externo, utilizando una frecuencia de reloj configurable y un baud rate de 115200 baudios por defecto. Su funcionamiento se divide en dos procesos principales: transmisión y recepción. Además, incorpora una interfaz de registros que permite que otros módulos del sistema accedan a los datos transmitidos, consulten los datos recibidos y controlen las operaciones de comunicación. Para ello, utiliza señales como write_enable, addr, wdata y rdata, que permiten realizar operaciones de escritura y lectura desde el controlador del juego. La comunicación física se realiza mediante rx_fisico y tx_fisico, mientras que la señal rst permite inicializar los registros y los procesos internos del módulo.
Transmisión de datos
El proceso de transmisión comienza cuando el controlador escribe el carácter que desea enviar en el registro registro_tx, mediante una operación de escritura en la dirección 00. Posteriormente, para iniciar la transmisión, escribe un valor que activa el bit 0 del registro de control, ubicado en la dirección 10. Esta operación genera la señal tx_pendiente, siempre que el transmisor no se encuentre activo ni tenga otra transmisión pendiente. Cuando el módulo detecta que existe una transmisión pendiente y el transmisor está disponible, construye la trama serial en el registro registro_tx_serial, utilizando un bit de inicio en nivel bajo, los ocho bits del carácter y un bit de parada en nivel alto. De esta manera, se prepara una trama de 10 bits correspondiente al formato 8N1.
Una vez preparada la trama, el transmisor activa la señal tx_activo e inicia el contador contador_tx, que determina cuánto tiempo debe permanecer cada bit en la salida serial. El registro bit_tx permite seleccionar progresivamente los bits de la trama, mientras que el contador determina cuándo debe avanzarse al siguiente. Para una frecuencia de reloj de 100 MHz y un baud rate de 115200, el módulo utiliza aproximadamente 868 ciclos de reloj por bit. Cuando el contador alcanza el valor establecido, se reinicia y se incrementa el índice del bit transmitido. Este proceso continúa hasta completar los 10 bits de la trama; entonces, tx_activo se desactiva y la línea tx_fisico vuelve al nivel lógico alto, indicando que el transmisor está en reposo y disponible para una nueva operación.
Recepción de datos
El proceso de recepción comienza con la detección del bit de inicio en la entrada rx_fisico. Debido a que esta señal proviene de un dispositivo externo y no está sincronizada con el reloj de la FPGA, el módulo utiliza dos registros, rx_sync1 y rx_sync2, para sincronizarla antes de procesarla. Cuando se detecta un nivel bajo en la señal sincronizada y el receptor no está activo, se inicia la recepción y se reinician el contador contador_rx y el índice bit_rx. Primero se espera medio período de bit para comprobar que la señal continúe en nivel bajo, validando así el inicio de la trama y reduciendo la posibilidad de interpretar una perturbación breve como una transmisión válida.
Después de validar el bit de inicio, el receptor espera intervalos completos de bit y almacena los ocho bits recibidos en registro_rx_serial, desde el menos significativo hasta el más significativo. Una vez recuperados los datos, se espera el bit de parada y se comprueba que la señal se encuentre en nivel alto. Si esta condición se cumple, el contenido del registro serial se copia a registro_rx y se activa la bandera rx_recibido, indicando que existe un nuevo dato disponible. Si el bit de parada no es válido, el módulo desactiva la recepción sin actualizar el registro de datos ni indicar una recepción correcta. De esta forma, se realiza una validación básica de la trama antes de entregar el carácter al resto del sistema.
Interfaz de registros y control de comunicación
El módulo UART dispone de tres direcciones principales de acceso. La dirección 00 permite escribir o consultar el registro de transmisión; la dirección 01 permite leer el último dato recibido; y la dirección 10 corresponde al registro de estado y control. En este último, el bit 0 indica si el transmisor está activo o tiene una transmisión pendiente, el bit 1 indica que se ha recibido un dato y el bit 2 refleja el estado de la salida física de transmisión. Asimismo, una escritura con el bit 1 activado en el registro de control permite limpiar la bandera rx_recibido, preparando al módulo para indicar una recepción posterior. Esta organización permite que el Controlador_UART gestione las operaciones sin intervenir directamente en los contadores y registros internos de transmisión y recepción.
Controlador UART
El módulo Controlador_UART se encarga de coordinar la comunicación entre el juego de ahorcado y el periférico UART, administrando tanto la recepción de letras como el envío de información relacionada con la partida. Su funcionamiento se basa en una máquina de estados finitos que controla las operaciones de lectura y escritura mediante las señales write_enable, addr, wdata y rdata. Además, recibe información de otros módulos, como la dificultad seleccionada, la cantidad de letras, la palabra actual, los fallos acumulados y el resultado de la validación de cada letra. Con estos datos, el controlador organiza los eventos del juego y prepara los mensajes que posteriormente serán transmitidos al dispositivo externo.
Recepción de letras
El proceso de recepción se realiza mediante los estados LEER_RX, CAPTURAR_RX y LIMPIAR_RX. Cuando la máquina de estados se encuentra en ESPERA, verifica que la partida esté activa y que no exista una letra pendiente de procesamiento. Si se cumplen estas condiciones, pasa a LEER_RX, donde consulta el registro de estado del periférico UART mediante la dirección 10. Si el bit 1 de rdata está activado, significa que existe un dato recibido y el controlador avanza a CAPTURAR_RX. En este estado, lee el registro de datos de recepción mediante la dirección 01, almacena el carácter en letra_guardada y activa la señal letra_disponible, que permite informar al resto del sistema que existe una nueva letra para procesar. Finalmente, pasa a LIMPIAR_RX, donde activa write_enable y escribe el valor 32'h00000002 en el registro de control para limpiar la bandera de recepción del UART. La letra permanece almacenada hasta que el módulo correspondiente activa consumir_letra, indicando que ya fue procesada.
Almacenamiento y gestión de eventos
El controlador incorpora registros de eventos pendientes que permiten conservar la información necesaria para preparar los mensajes de comunicación. Entre ellos se encuentran pendiente_inicio, pendiente_resultado, pendiente_final y pendiente_reset. Cuando se activa enviar_inicio, se guarda la dificultad y la cantidad de letras de la partida; cuando se activa enviar_resultado, se almacenan la letra ingresada, la palabra en su estado actual, los fallos acumulados y las señales que indican si la letra fue correcta, incorrecta o repetida. Por su parte, cuando se activa enviar_final, se guarda la palabra completa y el resultado de la partida, además de cancelar los eventos pendientes de inicio y resultado. Esta información permite preparar los mensajes utilizando los datos registrados durante cada evento, evitando depender exclusivamente de las señales que pueden cambiar posteriormente.
Preparación de los mensajes
La preparación de los mensajes se realiza mediante los estados PREPARAR_RESET, PREPARAR_INICIO, PREPARAR_RESULTADO y PREPARAR_FINAL. En cada uno se selecciona el tipo de mensaje, se reinicia el índice de transmisión y se establece la longitud correspondiente. Para ello, el controlador utiliza la señal mensaje_actual, que identifica el contenido que se desea transmitir, y base_memoria, que indica la posición inicial de los caracteres almacenados. En el caso del inicio de partida, se selecciona un mensaje diferente según la dificultad; para los resultados de letras, se distingue entre caracteres repetidos, correctos e incorrectos; y al finalizar se determina si corresponde enviar el mensaje de victoria o derrota. También se contempla un mensaje de reinicio que se prepara automáticamente después de liberar la señal rst.
Acceso a memoria y selección de caracteres
Una vez definido el mensaje, el controlador determina qué carácter debe transmitirse mediante la combinación de base_memoria e indice_mensaje. La señal direccion_memoria proporciona la dirección calculada para acceder a la memoria, mientras que dato_memoria contiene el carácter almacenado en esa posición. El módulo utiliza además la señal interna caracter_actual para seleccionar entre los datos obtenidos de memoria y los caracteres generados directamente mediante lógica combinacional. Por ejemplo, la función ascii_numero convierte valores numéricos a su representación ASCII, mientras que obtener_byte_palabra permite extraer un carácter específico de una palabra almacenada en un registro de 64 bits. Asimismo, la función vidas_restantes calcula las vidas disponibles a partir de los fallos acumulados y las convierte a formato ASCII. De esta manera, el controlador puede construir mensajes que contienen información variable, como la palabra actual, la letra ingresada y las vidas restantes.
Transmisión y control del periférico UART
La transmisión se realiza mediante los estados ENVIAR_DATO, INICIAR_TX y ESPERAR_TX. En ENVIAR_DATO, el controlador activa write_enable, selecciona la dirección 00 y escribe el carácter actual en el registro de transmisión del periférico UART. A continuación, en INICIAR_TX, escribe el valor 32'h00000001 en la dirección 10, activando la solicitud de envío. Posteriormente, pasa a ESPERAR_TX, donde consulta el bit 0 de rdata para determinar si el transmisor continúa ocupado o tiene una transmisión pendiente. Cuando dicho bit se encuentra en cero, el controlador incrementa indice_mensaje y vuelve a ENVIAR_DATO para transmitir el siguiente carácter. Este proceso continúa hasta alcanzar la longitud establecida para el mensaje, momento en el que regresa al estado ESPERA y queda disponible para atender nuevos eventos o recibir otra letra.
En conjunto, el Controlador_UART permite integrar la comunicación serial con los diferentes módulos del juego, transformando los eventos de la partida en mensajes organizados y gestionando la recepción de los caracteres ingresados por el usuario. Su máquina de estados coordina el acceso a los registros del periférico, la lectura de memoria y el envío secuencial de cada carácter, permitiendo comunicar información sobre el inicio, el desarrollo y la finalización de la partida.


### Módulo Debouncer
El módulo Debouncer se encarga de eliminar las fluctuaciones eléctricas que se producen al presionar o liberar los botones físicos de la FPGA. Debido a que un botón mecánico puede generar varios cambios rápidos de nivel lógico durante una sola pulsación, el módulo utiliza un contador para comprobar que la señal se mantenga estable durante un intervalo determinado. En este diseño, el tiempo de rebote se establece mediante el parámetro TIEMPO_REBOTE_MS, configurado por defecto en 20 ms, mientras que FRECUENCIA_RELOJ permite calcular la cantidad de ciclos necesarios según la frecuencia del reloj del sistema.
El funcionamiento se realiza de manera independiente para cada uno de los dos botones. Cuando la señal de entrada cambia respecto a la muestra anterior, el contador correspondiente se reinicia; si permanece sin cambios, el contador aumenta hasta alcanzar el tiempo establecido. Una vez cumplido este intervalo, el valor se actualiza en botones_estables, y finalmente se entrega mediante la salida estado_botones. Además, el módulo cuenta con un reinicio asíncrono que establece las señales y los contadores en cero. De esta manera, se obtiene una señal más confiable para que los demás módulos interpreten las pulsaciones sin reaccionar a cambios eléctricos momentáneos.


### Módulo LSFR
El módulo LFSR (Linear Feedback Shift Register o registro de desplazamiento con retroalimentación lineal) genera una secuencia pseudoaleatoria que se utiliza para seleccionar las palabras del juego. Está compuesto por un registro de 5 bits, cuya salida numero_aleatorio se actualiza en cada flanco positivo del reloj. Para obtener el nuevo valor, se desplazan los bits del registro y se calcula un bit de retroalimentación mediante la operación XOR entre las posiciones 4 y 2 del estado actual. Este resultado se introduce en el bit menos significativo, formando así el siguiente estado de la secuencia.
Al activarse la señal de reinicio, el registro se inicializa con el valor 5'b00001, evitando comenzar desde el estado de cero, que podría mantener el registro bloqueado en esa condición. Una vez iniciado, el LFSR continúa generando valores de manera secuencial y determinista, por lo que produce una secuencia pseudoaleatoria, pero no una aleatoriedad verdadera. En el proyecto, estos valores se utilizan como índices para acceder a las palabras almacenadas en la memoria, permitiendo variar la selección entre partidas sin implementar un generador aleatorio de mayor complejidad.


### Módulo de Memoria
El módulo Memoria almacena las palabras disponibles para el juego y los caracteres de los mensajes que se muestran en la pantalla LCD y se transmiten mediante UART. Para seleccionar una palabra, recibe las señales dificultad e indice_palabra, y utiliza una estructura case para asignar la palabra correspondiente a la salida palabra_actual. En el modo fácil se encuentran palabras como GATO, CASA y PERRO, mientras que en el modo difícil se incluyen términos como COMPUTO, CIRCUITO y HARDWARE. Cada palabra ocupa un espacio de 64 bits, equivalente a ocho caracteres ASCII, y las posiciones restantes se completan con espacios en blanco para mantener una longitud uniforme.
Adicionalmente, el módulo incorpora dos memorias combinacionales independientes para proporcionar los caracteres destinados a la pantalla LCD y a la comunicación UART. La salida dato_lcd entrega los caracteres según la dirección direccion_lcd, organizando los mensajes correspondientes a la selección de dificultad, el desarrollo de la partida y los resultados de victoria o derrota. Por su parte, dato_uart utiliza direccion_uart para acceder a los caracteres de mensajes como el inicio de partida, los resultados de las letras ingresadas y la finalización del juego. En ambos casos, las direcciones permiten que los controladores correspondientes obtengan los caracteres necesarios para construir y presentar los mensajes, mientras que las posiciones no definidas devuelven un espacio en blanco.


### Módulo Selector_dificultad
El módulo Selector_dificultad permite al usuario escoger el nivel de dificultad del juego y confirmar el inicio de una partida. Para ello, recibe las señales seleccionar y aceptar, que corresponden a las acciones de cambiar la dificultad e iniciar el juego, respectivamente. La variable dificultad almacena la selección actual mediante un bit: el valor cero representa el modo fácil y el valor uno representa el modo difícil. Al activarse el reinicio, la dificultad vuelve al modo fácil y la señal partida_iniciada se establece en cero.
Para evitar que una pulsación mantenida genere múltiples cambios o inicios consecutivos, el módulo conserva el estado anterior de cada botón mediante seleccionar_anterior y aceptar_anterior. De esta forma, detecta únicamente el flanco ascendente de cada señal, es decir, la transición de cero a uno. Cuando se detecta el flanco de seleccionar, se invierte el valor de la dificultad; cuando se detecta el flanco de aceptar, se activa partida_iniciada durante un ciclo de reloj. Esta señal permite que otros módulos, como el selector de palabras y el controlador del juego, reconozcan la confirmación del usuario y continúen con la preparación de la partida.


### Módulo Selector_palabra
El módulo Selector_palabra se encarga de seleccionar la palabra que se utilizará durante la partida, tomando en cuenta la dificultad elegida por el usuario. Para realizar esta función, incorpora una instancia del módulo LFSR, que genera una secuencia pseudoaleatoria de 5 bits, utilizada como índice para acceder a una palabra específica dentro del módulo Memoria. La señal dificultad determina cuál conjunto de palabras se consulta, mientras que palabra_memoria recibe la palabra seleccionada. De esta manera, se integra la generación del índice con el acceso a las palabras disponibles para cada nivel del juego.
Además, el módulo determina la cantidad de letras de la palabra seleccionada mediante una lógica combinacional que revisa cada uno de sus ocho espacios reservados. Cuando una posición contiene un carácter diferente al espacio en blanco (8'h20), se actualiza cantidad_letras_nueva para representar la longitud correspondiente. Finalmente, cuando se activa partida_iniciada, la palabra y su cantidad de letras se almacenan en los registros palabra_actual y cantidad_letras. Esto permite conservar la palabra seleccionada durante la partida, incluso si el índice generado por el LFSR continúa cambiando.


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
