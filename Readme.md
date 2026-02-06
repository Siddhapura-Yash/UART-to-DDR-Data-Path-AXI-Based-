# UART to DDR Data Path (AXI-Based)

This project implements a **UART-to-DDR loopback data pipeline** using **Verilog RTL**.  
It safely transfers low-speed serial data into high-speed DDR memory and reads it back using FIFOs and an AXI interface.

---

## Data Flow

The complete loopback path is shown below:

UART → Byte FIFO → Packer → Word FIFO → AXI → DDR → AXI → Word FIFO → Depacker → Byte FIFO → UART

---

## Overview

- **UART:** Receives and sends serial data one byte at a time.  
- **Byte FIFO:** Stores incoming and outgoing 8-bit UART data and handles speed differences.  
- **Packer:** Combines multiple bytes into a wide word (e.g., 128-bit) for DDR writing.  
- **Word FIFO:** Stores packed wide words and allows efficient burst transfers.  
- **AXI Interface:** Manages read and write operations between FIFOs and DDR using handshake signals.  
- **DDR Memory:** High-capacity memory that stores the data and returns it during readback.  
- **Depacker:** Converts wide DDR words back into 8-bit data for UART transmission.
  
---

## Hardware Verification

The complete loopback system was **verified on the physical Vaaman FPGA board with onboard DDR**, not just in simulation.

---

## Challenges Faced

### 1. DDR Reset Sequencing
The DDR controller required a strict reset order and timing.  
Incorrect sequencing prevented proper initialization.

### 2. AXI Handshake Issues
Initial read/write transactions were not completing.  
Fixed by correctly managing valid/ready handshake signals.

### 3. Data Alignment Between Packer and AXI
Misalignment caused incorrect DDR writes.  
Resolved by fixing packer counters and word boundaries.

### 4. Simulation vs Hardware Behavior
The design worked in simulation but failed on hardware initially.  
Issues were traced to reset timing and handshake logic.

---


## Note
The AXI DDR interface was based on a vendor reference example; all other modules and system integration were implemented in this project.
