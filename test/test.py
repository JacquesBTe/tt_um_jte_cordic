# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# ---------------------------------------------------------------------------
# Golden CORDIC model (bit-exact to the RTL, same model as golden_ref.py).
# Q2.6: 1.0 = 64. Returns (sin, cos) as unsigned bytes (two's-complement).
# ---------------------------------------------------------------------------
ARCTAN = [32, 19, 10, 5, 3, 1, 1, 0]   # arctan(2^-i), 90deg = 64 counts
CORDIC_GAIN = 39                        # 1/K * 64  (x_init)


def to_s8(v):
    v &= 0xFF
    return v - 256 if v & 0x80 else v


def asr8(v, sh):
    return to_s8(v) >> sh                # arithmetic shift, like >>> in RTL


def golden_cordic(angle):
    q = (angle >> 6) & 0x3
    pos = angle & 0x3F
    z = (64 - pos) if (q & 1) else pos   # odd quadrants reflect
    flip_x = q in (1, 2)
    flip_y = q in (2, 3)
    x, y, z = to_s8(CORDIC_GAIN), 0, to_s8(z)
    for i in range(8):
        arc = ARCTAN[i]
        if z >= 0:
            xn = to_s8(x - asr8(y, i)); yn = to_s8(y + asr8(x, i)); zn = to_s8(z - arc)
        else:
            xn = to_s8(x + asr8(y, i)); yn = to_s8(y - asr8(x, i)); zn = to_s8(z + arc)
        x, y, z = xn, yn, zn
    cos_v = to_s8(-x) if flip_x else x
    sin_v = to_s8(-y) if flip_y else y
    return (sin_v & 0xFF, cos_v & 0xFF)


async def run_angle(dut, code):
    """Drive one 7-bit angle code through the design and read sin, cos."""
    dut.ui_in.value = (1 << 7) | (code & 0x7F)   # start=1, angle on [6:0]
    await ClockCycles(dut.clk, 2)
    dut.ui_in.value = code & 0x7F                # drop start, hold angle stable
    await ClockCycles(dut.clk, 15)               # wait out the compute latency
    return int(dut.uo_out.value), int(dut.uio_out.value)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")   # cocotb 2.0; for cocotb 1.9 use units="us"
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # Sweep all 128 reachable input angles and check bit-exact vs the golden model
    dut._log.info("Sweeping all 128 input angles")
    for code in range(128):
        sin, cos = await run_angle(dut, code)
        exp_sin, exp_cos = golden_cordic(code << 1)   # internal angle = code << 1
        if (sin, cos) != (exp_sin, exp_cos):
            dut._log.error(
                f"angle code={code} (internal={code << 1}): "
                f"DUT sin=0x{sin:02X} cos=0x{cos:02X}  "
                f"expected sin=0x{exp_sin:02X} cos=0x{exp_cos:02X}")
        assert (sin, cos) == (exp_sin, exp_cos), f"mismatch at angle code {code}"

    dut._log.info("All 128 angles matched the golden model (bit-exact)")
