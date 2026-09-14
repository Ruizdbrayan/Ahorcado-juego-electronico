import serial
import time
import msvcrt


PUERTO = "COM4"
BAUDRATE = 115200


fpga = serial.Serial(
    PUERTO,
    BAUDRATE,
    timeout=0.05
)

time.sleep(0.2)

fpga.reset_input_buffer()
fpga.reset_output_buffer()


buffer_uart = bytearray()


def recibir():

    global buffer_uart

    if fpga.in_waiting:

        buffer_uart.extend(
            fpga.read(fpga.in_waiting)
        )

    if b"\n" not in buffer_uart:

        return None

    posicion = buffer_uart.index(b"\n")

    datos = buffer_uart[:posicion]

    del buffer_uart[:posicion + 1]

    return datos.decode(
        "ascii",
        errors="ignore"
    ).rstrip("\r")


def imprimir_espera():

    print()
    print("====================================================")
    print("       ESPERANDO NUEVA PARTIDA")
    print("====================================================")
    print("Seleccione la dificultad/modo en la FPGA.")


def imprimir_nueva_partida():

    print()
    print("====================================================")
    print("              NUEVA PARTIDA")
    print("====================================================")


def imprimir_fin_partida(resultado):

    print()
    print("====================================================")
    print("              FIN DE LA PARTIDA")
    print("====================================================")
    print("Resultado:", resultado)
    print()
    print("La FPGA regresará al selector de modo.")
    print()
    print("Esperando la siguiente partida...")


try:

    imprimir_espera()

    entrada = ""
    partida_activa = False
    fin_partida = False

    while True:

        mensaje = recibir()

        if mensaje is not None:

            # RESET vuelve al selector
            if mensaje == "RESET":

                entrada = ""
                partida_activa = False
                fin_partida = False

                imprimir_espera()

            # START inicia una nueva partida
            elif mensaje.startswith("START,"):

                if not partida_activa:

                    imprimir_nueva_partida()
                    partida_activa = True
                    fin_partida = False

                print("FPGA:", mensaje)

                print()
                print(
                    "Ingrese una letra:",
                    end=" ",
                    flush=True
                )

            # FINAL termina la partida
            elif mensaje.startswith("FINAL,"):

                print("FPGA:", mensaje)

                imprimir_fin_partida(mensaje)

                partida_activa = False
                fin_partida = True

                imprimir_espera()

            # Demas mensajes de la FPGA
            else:

                print()
                print("FPGA:", mensaje)

                if mensaje.startswith("RESULT,REP,"):

                    print("Letra repetida.")

                if partida_activa and not fin_partida:

                    print()
                    print(
                        "Ingrese una letra:",
                        end=" ",
                        flush=True
                    )


        # ------------------------------------------------
        # TECLADO
        # ------------------------------------------------

        while msvcrt.kbhit():

            caracter = msvcrt.getwch()

            if caracter in ("\r", "\n"):

                if len(entrada) == 1 and partida_activa:

                    fpga.write(
                        entrada.upper().encode("ascii")
                    )

                    print()

                    entrada = ""

                elif not partida_activa:

                    entrada = ""

            elif caracter == "\b":

                if entrada:

                    entrada = entrada[:-1]

                    print(
                        "\b \b",
                        end="",
                        flush=True
                    )

            elif caracter.isalpha():

                if len(entrada) == 0 and partida_activa:

                    entrada += caracter

                    print(
                        caracter,
                        end="",
                        flush=True
                    )


        time.sleep(0.01)


except KeyboardInterrupt:

    pass


finally:

    fpga.close()
