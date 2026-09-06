import serial
import time

PUERTO = "COM4"
BAUDRATE = 115200


def conectar_fpga():
    return serial.Serial(
        port=PUERTO,
        baudrate=BAUDRATE,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=0.1
    )


def enviar(fpga, letra):
    fpga.write(letra.encode("ascii"))
    fpga.flush()


def recibir_mensaje(fpga):
    datos = bytearray()

    ultimo_dato = time.time()

    while True:

        cantidad = fpga.in_waiting

        if cantidad > 0:

            datos.extend(fpga.read(cantidad))
            ultimo_dato = time.time()

        else:

            # Si pasaron 100 ms sin recibir nada,
            # consideramos terminado el mensaje.

            if len(datos) > 0 and time.time() - ultimo_dato > 0.1:
                break

            time.sleep(0.005)

    return datos.decode("ascii", errors="replace")


def main():

    print("====================================")
    print("             AHORCADO")
    print("====================================")

    fpga = conectar_fpga()

    print("FPGA conectada en", PUERTO)
    print("115200 8N1")

    # Esperar mensaje START de la FPGA
    time.sleep(0.1)

    mensaje = recibir_mensaje(fpga)

    if mensaje:
        print("\nFPGA:", mensaje)

    while True:

        letra = input("\nIngrese una letra: ").strip().upper()

        if len(letra) != 1 or not ("A" <= letra <= "Z"):
            print("Ingrese solamente una letra de A-Z.")
            continue

        enviar(fpga, letra)

        respuesta = recibir_mensaje(fpga)

        if respuesta:
            print("FPGA:", respuesta)


if __name__ == "__main__":
    main()