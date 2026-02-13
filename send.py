import serial
import time

# ---------------- Configuration ----------------
UART_PORT = "/dev/ttyUSB0"
BAUD_RATE = 115200        # Change if needed
TIMEOUT   = 2.0           # seconds (read timeout)
TX_FILE   = "raw_data.bin"
# -----------------------------------------------

def main():
    try:
        # Open UART
        ser = serial.Serial(
            port=UART_PORT,
            baudrate=BAUD_RATE,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=TIMEOUT
        )

        print(f"[INFO] Opened {UART_PORT} @ {BAUD_RATE} baud")

        # Read raw data from file
        with open(TX_FILE, "rb") as f:
            tx_data = f.read()

        print(f"[INFO] Sending {len(tx_data)} bytes")
        ser.write(tx_data)
        ser.flush()

        # Optional small delay to allow UART TX to complete
        time.sleep(0.1)

        print("[INFO] Waiting for response...")

        # Read response (blocking until timeout)
        rx_data = ser.read(ser.in_waiting or 1)

        # Continue reading if more data arrives
        start_time = time.time()
        while time.time() - start_time < TIMEOUT:
            if ser.in_waiting:
                rx_data += ser.read(ser.in_waiting)

        if rx_data:
            print(f"[INFO] Received {len(rx_data)} bytes:")
            print(rx_data.decode("ascii", errors="replace"))
        else:
            print("[WARN] No response received")

        ser.close()
        print("[INFO] UART closed")

    except serial.SerialException as e:
        print(f"[ERROR] UART error: {e}")
    except FileNotFoundError:
        print(f"[ERROR] File not found: {TX_FILE}")

if __name__ == "__main__":
    main()
