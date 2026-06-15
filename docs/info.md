<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project computes the **sine and cosine** of an input angle using an iterative
**CORDIC** (COordinate Rotation DIgital Computer) algorithm.

The angle is supplied as a 7-bit value on `ui[6:0]`, where `0`–`127` maps linearly to
`0°`–`360°` (so each step is `360 / 128 ≈ 2.81°`). Asserting `start` on `ui[7]` begins a
computation.

Internally the design works in **Q2.6 fixed-point** (8-bit two's-complement, where
`1.0 = 64 = 0x40`):

1. **Quadrant fold** — the angle is reduced to the first quadrant (0°–90°), and per-quadrant
   sign flags are recorded so the result can be reflected back into the correct quadrant.
2. **Rotation** — a vector is pre-scaled by the CORDIC gain (`1/K ≈ 0.607`) and rotated through
   **8 fixed micro-rotations** of `arctan(2^-i)`, each taken from a small lookup table. A small
   FSM (`IDLE → LOAD → 8× COMPUTE → DONE`) sequences the iterations; each iteration drives a
   residual-angle accumulator toward zero while the vector's X and Y components converge to
   `cos` and `sin`.
3. **Sign correction** — the recorded quadrant flags are applied, producing the final signed
   `sin` and `cos`.

A result is ready roughly **11 clock cycles** after `start` is asserted. `start` is a level:
hold it high to recompute continuously, release it to freeze and hold the last result.

The outputs are 8-bit two's-complement Q2.6 values:

| Raw (hex) | Decimal | Real value |
|-----------|---------|------------|
| `0x40`    | +64     | +1.0       |
| `0x00`    | 0       | 0.0        |
| `0xC0`    | −64     | −1.0       |

(Convert any output to its real value with `raw / 64`.)

`sin` appears on `uo[7:0]`, `cos` on `uio[7:0]` (the bidirectional pins, configured as outputs).

## How to test

1. Put a 7-bit angle on `ui[6:0]` (0–127 = 0°–360°).
2. Drive `start` (`ui[7]`) high to trigger a computation, then low to latch the result.
3. After ~11 clock cycles, read `sin` on `uo[7:0]` and `cos` on `uio[7:0]`. Interpret both as
   signed Q2.6 (`value = raw / 64`).

Example angles (input code → angle → expected outputs):

| `ui[6:0]` | Angle | `sin` (uo) | `cos` (uio) |
|-----------|-------|------------|-------------|
| 0         | 0°    | `0x00` (0)    | `0x40` (+1.0) |
| 16        | 45°   | `0x2E` (≈0.72)| `0x2C` (≈0.69) |
| 32        | 90°   | `0x41` (≈+1.0)| `0x01` (≈0)   |
| 64        | 180°  | `0x00` (≈0)   | `0xC0` (−1.0) |
| 96        | 270°  | `0xBF` (≈−1.0)| `0x01` (≈0)   |

Outputs are within ±a few LSB of the ideal due to the 8-iteration, 8-bit fixed-point
approximation. The included cocotb test (`test/test.py`) sweeps all 128 angles and checks
them bit-exactly against a golden CORDIC model.

## External hardware

No external hardware is required to *drive* the design — the angle and `start` come from the
demo board's input switches.

To *view* the outputs:
- **`sin`** is on `uo[7:0]`, which drives the demo board's 8 on-board LEDs directly.
- **`cos`** is on `uio[7:0]` (the bidirectional/PMOD pins). To see it, attach an **8-bit LED
  PMOD** (or any 8-LED breakout) to the `uio` header. This is optional — `cos` is still
  readable via the RP2040/test harness without it.
