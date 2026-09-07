import serial
import time
import msvcrt

PUERTO = "COM4"
BAUDRATE = 115200


# ============================================================
# CONEXION FPGA
# ============================================================

def conectar_fpga():

    try:

        fpga = serial.Serial(
            PUERTO,
            BAUDRATE,
            timeout=0.05
        )

        time.sleep(0.2)

        fpga.reset_input_buffer()
        fpga.reset_output_buffer()

        print(f"FPGA conectada en {PUERTO}")
        print(f"{BAUDRATE} 8N1")

        return fpga

    except serial.SerialException as e:

        print("\nERROR: No se pudo conectar con la FPGA.")
        print(e)

        return None


# ============================================================
# RECIBIR MENSAJE DE LA FPGA
# ============================================================

def recibir_mensaje(fpga):

    datos = bytearray()

    while fpga.in_waiting:

        datos.extend(
            fpga.read(fpga.in_waiting)
        )

    if len(datos) == 0:
        return ""

    try:

        return datos.decode(
            "ascii",
            errors="ignore"
        ).strip()

    except Exception:

        return ""


# ============================================================
# ENVIAR LETRA
# ============================================================

def enviar_letra(fpga, letra):

    letra = letra.upper().strip()

    if len(letra) != 1 or not letra.isalpha():

        return False

    try:

        fpga.write(
            letra.encode("ascii")
        )

        return True

    except serial.SerialException as e:

        print("\nERROR enviando la letra:")
        print(e)

        return False


# ============================================================
# ESPERAR NUEVA PARTIDA
# ============================================================

def esperar_nueva_partida(fpga):

    print("\n====================================================")
    print("       ESPERANDO NUEVA PARTIDA")
    print("====================================================")

    print("Seleccione la dificultad/modo en la FPGA.")

    while True:

        mensaje = recibir_mensaje(fpga)

        if mensaje:

            print(f"FPGA: {mensaje}")

            if mensaje.startswith("START,"):

                return mensaje

        time.sleep(0.01)


# ============================================================
# JUGAR PARTIDA
# ============================================================

def jugar_partida(fpga, mensaje_start):

    print("\n====================================================")
    print("              NUEVA PARTIDA")
    print("====================================================")

    print(f"FPGA: {mensaje_start}")

    print("\nIngrese una letra: ", end="", flush=True)


    # --------------------------------------------------------
    # Buffer de teclado
    # --------------------------------------------------------

    entrada = ""


    while True:

        # ====================================================
        # 1. REVISAR SI LA FPGA ENVIO ALGO
        # ====================================================

        mensaje = recibir_mensaje(fpga)

        if mensaje:

            print(f"\nFPGA: {mensaje}")


            # ------------------------------------------------
            # FINAL
            # ------------------------------------------------

            if mensaje.startswith("FINAL,"):

                print("\n====================================================")
                print("              FIN DE LA PARTIDA")
                print("====================================================")

                print(f"Resultado: {mensaje}")

                print("\nLa FPGA regresará al selector de modo.")

                return True


        # ====================================================
        # 2. REVISAR TECLADO SIN BLOQUEAR
        # ====================================================

        while msvcrt.kbhit():

            caracter = msvcrt.getwch()


            # ------------------------------------------------
            # ENTER
            # ------------------------------------------------

            if caracter in ("\r", "\n"):

                letra = entrada.strip().upper()

                entrada = ""


                if len(letra) == 1 and letra.isalpha():

                    print()

                    if not enviar_letra(
                        fpga,
                        letra
                    ):

                        print(
                            "\nERROR: No se pudo enviar "
                            "la letra."
                        )

                        return False

                    # ------------------------------------------------
                    # NO esperamos aquí con input().
                    #
                    # Volvemos inmediatamente al while para
                    # poder detectar también un FINAL por timeout.
                    # ------------------------------------------------

                    print(
                        "\nIngrese una letra: ",
                        end="",
                        flush=True
                    )

                else:

                    print(
                        "\nIngrese solamente una letra."
                    )

                    print(
                        "Ingrese una letra: ",
                        end="",
                        flush=True
                    )


            # ------------------------------------------------
            # BACKSPACE
            # ------------------------------------------------

            elif caracter == "\b":

                if len(entrada) > 0:

                    entrada = entrada[:-1]

                    print(
                        "\b \b",
                        end="",
                        flush=True
                    )


            # ------------------------------------------------
            # CARACTER NORMAL
            # ------------------------------------------------

            elif caracter.isalpha():

                entrada += caracter

                print(
                    caracter,
                    end="",
                    flush=True
                )


        # ====================================================
        # PEQUEÑA ESPERA
        # ====================================================

        time.sleep(0.01)


# ============================================================
# MAIN
# ============================================================

def main():

    print("\n")

    print("====================================")
    print("             AHORCADO")
    print("====================================")


    fpga = conectar_fpga()


    if fpga is None:

        return


    try:

        while True:

            # ------------------------------------------------
            # Esperar START
            # ------------------------------------------------

            mensaje_start = esperar_nueva_partida(
                fpga
            )


            # ------------------------------------------------
            # Jugar
            # ------------------------------------------------

            partida_ok = jugar_partida(
                fpga,
                mensaje_start
            )


            if not partida_ok:

                print(
                    "\nSe perdió la comunicación "
                    "con la FPGA."
                )

                break


            print(
                "\nEsperando la siguiente partida..."
            )


    except KeyboardInterrupt:

        print(
            "\n\nPrograma detenido por el usuario."
        )


    finally:

        if fpga is not None and fpga.is_open:

            fpga.close()

        print("Puerto FPGA cerrado.")


# ============================================================
# EJECUCION
# ============================================================

if __name__ == "__main__":

    main()