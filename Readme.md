# UART to DDR Data Path (AXI-Based)

-- This project implements a **UART-to-DDR write pipeline** using **Verilog RTL**.
-- It is designed to safely transfer low-speed serial data into high-speed DDR memory using FIFOs and AXI.

---

## Data Flow

-- The complete data path is shown below:

UART → Byte FIFO → Packer → Word FIFO → AXI → DDR

---

## Overview

-- **UART**
-- Receives serial data byte-by-byte.

-- **Byte FIFO**
-- Buffers incoming 8-bit UART data.
-- Handles baud-rate and clock-domain mismatch.

-- **Packer**
-- Collects multiple bytes from the Byte FIFO.
-- Packs them into a wide word (for example, 128-bit).

-- **Word FIFO**
-- Stores packed wide words.
-- Helps in burst-based data transfer.

-- **AXI Interface**
-- Transfers data from Word FIFO to DDR.
-- Uses efficient AXI write transactions.

-- **DDR Memory**
-- Acts as high-capacity storage.
-- Stores incoming UART data reliably.

---

## Use Case

-- Suitable for data logging and streaming applications.
-- Useful when slow serial data must be stored in high-speed DDR memory.

