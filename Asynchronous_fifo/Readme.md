# Asynchronous FIFO (Async FIFO)

This project implements an **Asynchronous FIFO (First-In First-Out) buffer** designed to safely transfer data between **two different clock domains**.

It uses **dual-clock operation**, where the write side and read side work on independent clocks, and applies **Gray-code pointer synchronization** to avoid metastability and data corruption.

This FIFO is suitable for **CDC (Clock Domain Crossing)** based designs.

---

## How It Works

- Write and Read pointers operate in **different clock domains**
- Each pointer is converted to **Gray code**
- Gray pointers are passed through **two flip-flop synchronizers**
- Full and Empty are generated using **synchronized Gray pointers**

This prevents metastability and ensures safe data transfer across clock domains.

---

## Full / Empty Logic

| Condition | Meaning |
|----------|---------|
| **EMPTY** | Read Gray Pointer == Synchronized Write Gray Pointer |
| **FULL**  | Next Write Gray Pointer equals inverted MSBs of synchronized Read Gray Pointer |

---

This design follows the **industry-standard asynchronous FIFO architecture** used in real CDC hardware paths.

