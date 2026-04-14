# ============================================================
# Makefile — Kalman Filter Milestone 3
# RISC-V Scalar Assembly (LKF + EKF)
# ============================================================

CC      = riscv64-linux-gnu-gcc
CFLAGS  = -march=rv64g -mabi=lp64d -g -O0
# Link math library for sqrt/fgets/strtod etc.
LDFLAGS = -lm
EMU     = qemu-riscv64 -L /usr/riscv64-linux-gnu

.PHONY: all lkf ekf run-lkf run-ekf clean

all: lkf ekf

# ---- LKF ----
lkf: lkf_asm.s
	$(CC) $(CFLAGS) -o lkf lkf_asm.s $(LDFLAGS)

run-lkf: lkf
	$(EMU) ./lkf

# ---- EKF ----
ekf: ekf_asm.s
	$(CC) $(CFLAGS) -o ekf ekf_asm.s $(LDFLAGS)

run-ekf: ekf
	$(EMU) ./ekf

# ---- Run both ----
run-all: run-lkf run-ekf

clean:
	rm -f lkf ekf *.o lkf_output.csv ekf_output.csv