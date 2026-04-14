.option pic
        .text
        .align  2

        .section .rodata
        .align  3
C_ZERO:     .double 0.0
C_HALF:     .double 0.5
C_ONE:      .double 1.0
C_TWO:      .double 2.0
C_EPS:      .double 1.0e-9
C_TINY:     .double 1.0e-12
C_0_28125:  .double 0.28125
C_PI:       .double 3.14159265358979323846
C_PI_2:     .double 1.57079632679489661923
C_TPI:      .double 6.28318530717958647692
C_SENSOR_OX:.double -7.0
C_SENSOR_OY:.double -8.0
C_SENSOR_OZ: .double 0.0
C_ADAPT_THR:.double 1.5
C_ADAPT_SCL:.double 10.0
C_GATE_SIG: .double 3.0

        .text

        .globl mat_zero
mat_zero:
        beqz    a1, .Lmz_end
        la      t0, C_ZERO
        fld     ft0, 0(t0)
.Lmz_loop:
        fsd     ft0, 0(a0)
        addi    a0, a0, 8
        addi    a1, a1, -1
        bnez    a1, .Lmz_loop
.Lmz_end:
        ret

        .globl mat_copy
mat_copy:
        beqz    a2, .Lmc_end
.Lmc_loop:
        fld     ft0, 0(a1)
        fsd     ft0, 0(a0)
        addi    a0, a0, 8
        addi    a1, a1, 8
        addi    a2, a2, -1
        bnez    a2, .Lmc_loop
.Lmc_end:
        ret

        .globl mat_eye
mat_eye:
        addi    sp, sp, -32
        sd      ra, 24(sp)
        sd      s0, 16(sp)
        sd      s1, 8(sp)
        sd      s2, 0(sp)
        mv      s0, a0
        mv      s1, a1
        mul     s2, a1, a1
        mv      a0, s0
        mv      a1, s2
        call    mat_zero
        la      t0, C_ONE
        fld     ft0, 0(t0)
        mv      t1, s0
        mv      t2, s1
        addi    t3, s1, 1
        slli    t3, t3, 3
        beqz    t2, .Lme_end
.Lme_loop:
        fsd     ft0, 0(t1)
        add     t1, t1, t3
        addi    t2, t2, -1
        bnez    t2, .Lme_loop
.Lme_end:
        ld      s2, 0(sp)
        ld      s1, 8(sp)
        ld      s0, 16(sp)
        ld      ra, 24(sp)
        addi    sp, sp, 32
        ret

        .globl mat_add
mat_add:
        beqz    a3, .Lma_end
.Lma_loop:
        fld     ft0, 0(a1)
        fld     ft1, 0(a2)
        fadd.d  ft2, ft0, ft1
        fsd     ft2, 0(a0)
        addi    a0, a0, 8
        addi    a1, a1, 8
        addi    a2, a2, 8
        addi    a3, a3, -1
        bnez    a3, .Lma_loop
.Lma_end:
        ret

        .globl mat_sub
mat_sub:
        beqz    a3, .Lms_end
.Lms_loop:
        fld     ft0, 0(a1)
        fld     ft1, 0(a2)
        fsub.d  ft2, ft0, ft1
        fsd     ft2, 0(a0)
        addi    a0, a0, 8
        addi    a1, a1, 8
        addi    a2, a2, 8
        addi    a3, a3, -1
        bnez    a3, .Lms_loop
.Lms_end:
        ret

        .globl mat_scale
mat_scale:
        beqz    a1, .Lmscl_end
.Lmscl_loop:
        fld     ft0, 0(a0)
        fmul.d  ft0, ft0, fa0
        fsd     ft0, 0(a0)
        addi    a0, a0, 8
        addi    a1, a1, -1
        bnez    a1, .Lmscl_loop
.Lmscl_end:
        ret

        .globl mat_transpose
mat_transpose:
        addi    sp, sp, -32
        sd      s0, 24(sp)
        sd      s1, 16(sp)
        sd      s2, 8(sp)
        sd      s3, 0(sp)
        mv      s0, a0
        mv      s1, a1
        mv      s2, a2
        mv      s3, a3
        li      t0, 0
.Lmt_i:
        bge     t0, s2, .Lmt_done
        li      t1, 0
.Lmt_j:
        bge     t1, s3, .Lmt_next_i
        mul     t2, t0, s3
        add     t2, t2, t1
        slli    t2, t2, 3
        add     t2, t2, s1
        fld     ft0, 0(t2)
        mul     t3, t1, s2
        add     t3, t3, t0
        slli    t3, t3, 3
        add     t3, t3, s0
        fsd     ft0, 0(t3)
        addi    t1, t1, 1
        j       .Lmt_j
.Lmt_next_i:
        addi    t0, t0, 1
        j       .Lmt_i
.Lmt_done:
        ld      s3, 0(sp)
        ld      s2, 8(sp)
        ld      s1, 16(sp)
        ld      s0, 24(sp)
        addi    sp, sp, 32
        ret

        .globl mat_mul
mat_mul:
        addi    sp, sp, -112
        sd      ra, 104(sp)
        sd      s0, 96(sp)
        sd      s1, 88(sp)
        sd      s2, 80(sp)
        sd      s3, 72(sp)
        sd      s4, 64(sp)
        sd      s5, 56(sp)
        sd      s6, 48(sp)
        sd      s7, 40(sp)
        sd      s8, 32(sp)
        sd      s9, 24(sp)
        sd      s10, 16(sp)
        fsd     fs0, 8(sp)
        mv      s0, a0
        mv      s1, a1
        mv      s2, a2
        mv      s3, a3
        mv      s4, a4
        mv      s5, a5
        mul     t0, s3, s5
        mv      a0, s0
        mv      a1, t0
        call    mat_zero
        li      s6, 0
.Lmm_i:
        bge     s6, s3, .Lmm_done
        mul     t0, s6, s5
        slli    t0, t0, 3
        add     s9, s0, t0
        li      s7, 0
.Lmm_k:
        bge     s7, s4, .Lmm_next_i
        mul     t0, s6, s4
        add     t0, t0, s7
        slli    t0, t0, 3
        add     t0, t0, s1
        fld     fs0, 0(t0)
        la      t1, C_ZERO
        fld     ft1, 0(t1)
        feq.d   t2, fs0, ft1
        bnez    t2, .Lmm_next_k
        mul     t0, s7, s5
        slli    t0, t0, 3
        add     s10, s2, t0
        li      s8, 0
        mv      t3, s9
        mv      t4, s10
.Lmm_j:
        bge     s8, s5, .Lmm_next_k
        fld     ft0, 0(t3)
        fld     ft1, 0(t4)
        fmadd.d ft0, fs0, ft1, ft0
        fsd     ft0, 0(t3)
        addi    t3, t3, 8
        addi    t4, t4, 8
        addi    s8, s8, 1
        j       .Lmm_j
.Lmm_next_k:
        addi    s7, s7, 1
        j       .Lmm_k
.Lmm_next_i:
        addi    s6, s6, 1
        j       .Lmm_i
.Lmm_done:
        fld     fs0, 8(sp)
        ld      s10, 16(sp)
        ld      s9, 24(sp)
        ld      s8, 32(sp)
        ld      s7, 40(sp)
        ld      s6, 48(sp)
        ld      s5, 56(sp)
        ld      s4, 64(sp)
        ld      s3, 72(sp)
        ld      s2, 80(sp)
        ld      s1, 88(sp)
        ld      s0, 96(sp)
        ld      ra, 104(sp)
        addi    sp, sp, 112
        ret

        .globl enforce_symmetry
enforce_symmetry:
        addi    sp, sp, -48
        sd      ra, 40(sp)
        sd      s0, 32(sp)
        sd      s1, 24(sp)
        sd      s2, 16(sp)
        sd      s3, 8(sp)
        mv      s0, a0
        mv      s1, a1
        la      t0, C_HALF
        fld     ft3, 0(t0)
        li      s2, 0
.Les_i:
        bge     s2, s1, .Les_done
        addi    s3, s2, 1
.Les_j:
        bge     s3, s1, .Les_next_i
        mul     t0, s2, s1
        add     t0, t0, s3
        slli    t0, t0, 3
        add     t1, s0, t0
        fld     ft0, 0(t1)
        mul     t0, s3, s1
        add     t0, t0, s2
        slli    t0, t0, 3
        add     t2, s0, t0
        fld     ft1, 0(t2)
        fadd.d  ft2, ft0, ft1
        fmul.d  ft2, ft2, ft3
        fsd     ft2, 0(t1)
        fsd     ft2, 0(t2)
        addi    s3, s3, 1
        j       .Les_j
.Les_next_i:
        addi    s2, s2, 1
        j       .Les_i
.Les_done:
        ld      s3, 8(sp)
        ld      s2, 16(sp)
        ld      s1, 24(sp)
        ld      s0, 32(sp)
        ld      ra, 40(sp)
        addi    sp, sp, 48
        ret

        .globl solve_cholesky
solve_cholesky:
        addi    sp, sp, -144
        sd      ra, 136(sp)
        sd      s0, 128(sp)
        sd      s1, 120(sp)
        sd      s2, 112(sp)
        sd      s3, 104(sp)
        sd      s4, 96(sp)
        sd      s5, 88(sp)
        sd      s6, 80(sp)
        sd      s7, 72(sp)
        sd      s8, 64(sp)
        sd      s9, 56(sp)
        sd      s10, 48(sp)
        sd      s11, 40(sp)
        fsd     fs0, 32(sp)
        fsd     fs1, 24(sp)
        fsd     fs2, 16(sp)
        fsd     fs3, 8(sp)
        mv      s0, a0
        mv      s1, a1
        mv      s2, a2
        mv      s3, a3
        mv      s4, a4
        mv      s5, a5
        mul     t0, s3, s3
        mv      a0, s5
        mv      a1, t0
        call    mat_zero
        li      s6, 0
.Lch_i:
        bge     s6, s3, .Lch_decomp_done
        li      s7, 0
.Lch_j:
        bgt     s7, s6, .Lch_next_i
        la      t0, C_ZERO
        fld     fs0, 0(t0)
        bne     s6, s7, .Lch_off_diag
        li      s8, 0
.Lch_diag_k:
        bge     s8, s7, .Lch_diag_after_k
        mul     t0, s7, s3
        add     t0, t0, s8
        slli    t0, t0, 3
        add     t0, t0, s5
        fld     ft0, 0(t0)
        fmadd.d fs0, ft0, ft0, fs0
        addi    s8, s8, 1
        j       .Lch_diag_k
.Lch_diag_after_k:
        mul     t0, s7, s3
        add     t0, t0, s7
        slli    t0, t0, 3
        add     t0, t0, s0
        fld     ft0, 0(t0)
        fsub.d  ft0, ft0, fs0
        la      t1, C_TINY
        fld     ft1, 0(t1)
        flt.d   t2, ft1, ft0
        beqz    t2, .Lch_diag_tiny
        fsqrt.d ft0, ft0
        j       .Lch_store_diag
.Lch_diag_tiny:
        la      t1, C_EPS
        fld     ft0, 0(t1)
.Lch_store_diag:
        mul     t0, s7, s3
        add     t0, t0, s7
        slli    t0, t0, 3
        add     t0, t0, s5
        fsd     ft0, 0(t0)
        j       .Lch_after_col
.Lch_off_diag:
        li      s8, 0
.Lch_off_k:
        bge     s8, s7, .Lch_off_after_k
        mul     t0, s6, s3
        add     t0, t0, s8
        slli    t0, t0, 3
        add     t0, t0, s5
        fld     ft0, 0(t0)
        mul     t0, s7, s3
        add     t0, t0, s8
        slli    t0, t0, 3
        add     t0, t0, s5
        fld     ft1, 0(t0)
        fmadd.d fs0, ft0, ft1, fs0
        addi    s8, s8, 1
        j       .Lch_off_k
.Lch_off_after_k:
        mul     t0, s6, s3
        add     t0, t0, s7
        slli    t0, t0, 3
        add     t0, t0, s0
        fld     ft0, 0(t0)
        fsub.d  ft0, ft0, fs0
        mul     t0, s7, s3
        add     t0, t0, s7
        slli    t0, t0, 3
        add     t0, t0, s5
        fld     ft1, 0(t0)
        fdiv.d  ft0, ft0, ft1
        mul     t0, s6, s3
        add     t0, t0, s7
        slli    t0, t0, 3
        add     t0, t0, s5
        fsd     ft0, 0(t0)
.Lch_after_col:
        addi    s7, s7, 1
        j       .Lch_j
.Lch_next_i:
        addi    s6, s6, 1
        j       .Lch_i
.Lch_decomp_done:
        slli    t0, s3, 3
        addi    t0, t0, 15
        andi    t0, t0, -16
        sub     sp, sp, t0
        mv      s10, sp
        sd      t0, -8(s10)
        mv      s11, zero
        li      s9, 0
.Lch_col:
        bge     s9, s4, .Lch_cols_done
        li      s6, 0
.Lch_fwd_i:
        bge     s6, s3, .Lch_fwd_done
        la      t0, C_ZERO
        fld     fs0, 0(t0)
        li      s8, 0
.Lch_fwd_k:
        bge     s8, s6, .Lch_fwd_k_done
        mul     t0, s6, s3
        add     t0, t0, s8
        slli    t0, t0, 3
        add     t0, t0, s5
        fld     ft0, 0(t0)
        slli    t0, s8, 3
        add     t0, t0, s10
        fld     ft1, 0(t0)
        fmadd.d fs0, ft0, ft1, fs0
        addi    s8, s8, 1
        j       .Lch_fwd_k
.Lch_fwd_k_done:
        mul     t0, s6, s4
        add     t0, t0, s9
        slli    t0, t0, 3
        add     t0, t0, s1
        fld     ft0, 0(t0)
        fsub.d  ft0, ft0, fs0
        mul     t0, s6, s3
        add     t0, t0, s6
        slli    t0, t0, 3
        add     t0, t0, s5
        fld     ft1, 0(t0)
        fdiv.d  ft0, ft0, ft1
        slli    t0, s6, 3
        add     t0, t0, s10
        fsd     ft0, 0(t0)
        addi    s6, s6, 1
        j       .Lch_fwd_i
.Lch_fwd_done:
        addi    s6, s3, -1
.Lch_bk_i:
        bltz    s6, .Lch_bk_done
        la      t0, C_ZERO
        fld     fs0, 0(t0)
        addi    s8, s6, 1
.Lch_bk_k:
        bge     s8, s3, .Lch_bk_k_done
        mul     t0, s8, s3
        add     t0, t0, s6
        slli    t0, t0, 3
        add     t0, t0, s5
        fld     ft0, 0(t0)
        mul     t0, s8, s4
        add     t0, t0, s9
        slli    t0, t0, 3
        add     t0, t0, s2
        fld     ft1, 0(t0)
        fmadd.d fs0, ft0, ft1, fs0
        addi    s8, s8, 1
        j       .Lch_bk_k
.Lch_bk_k_done:
        slli    t0, s6, 3
        add     t0, t0, s10
        fld     ft0, 0(t0)
        fsub.d  ft0, ft0, fs0
        mul     t0, s6, s3
        add     t0, t0, s6
        slli    t0, t0, 3
        add     t0, t0, s5
        fld     ft1, 0(t0)
        fdiv.d  ft0, ft0, ft1
        mul     t0, s6, s4
        add     t0, t0, s9
        slli    t0, t0, 3
        add     t0, t0, s2
        fsd     ft0, 0(t0)
        addi    s6, s6, -1
        j       .Lch_bk_i
.Lch_bk_done:
        addi    s9, s9, 1
        j       .Lch_col
.Lch_cols_done:
        slli    t0, s3, 3
        addi    t0, t0, 15
        andi    t0, t0, -16
        add     sp, sp, t0
        fld     fs3, 8(sp)
        fld     fs2, 16(sp)
        fld     fs1, 24(sp)
        fld     fs0, 32(sp)
        ld      s11, 40(sp)
        ld      s10, 48(sp)
        ld      s9, 56(sp)
        ld      s8, 64(sp)
        ld      s7, 72(sp)
        ld      s6, 80(sp)
        ld      s5, 88(sp)
        ld      s4, 96(sp)
        ld      s3, 104(sp)
        ld      s2, 112(sp)
        ld      s1, 120(sp)
        ld      s0, 128(sp)
        ld      ra, 136(sp)
        addi    sp, sp, 144
        ret

        .globl manual_arctan2
manual_arctan2:
        la      t0, C_ZERO
        fld     ft4, 0(t0)
        la      t0, C_ONE
        fld     ft5, 0(t0)
        la      t0, C_0_28125
        fld     ft6, 0(t0)
        la      t0, C_PI_2
        fld     ft7, 0(t0)
        la      t0, C_PI
        fld     ft8, 0(t0)
        feq.d   t1, fa1, ft4
        beqz    t1, .Lat_x_nonzero
        flt.d   t1, ft4, fa0
        beqz    t1, .Lat_x0_not_pos
        fmv.d   fa0, ft7
        ret
.Lat_x0_not_pos:
        flt.d   t1, fa0, ft4
        beqz    t1, .Lat_x0_zero
        fsub.d  fa0, ft4, ft7
        ret
.Lat_x0_zero:
        fmv.d   fa0, ft4
        ret
.Lat_x_nonzero:
        fdiv.d  ft0, fa0, fa1
        fabs.d  ft1, ft0
        fle.d   t1, ft1, ft5
        beqz    t1, .Lat_big
        fmul.d  ft2, ft1, ft1
        fmadd.d ft2, ft6, ft2, ft5
        fdiv.d  ft3, ft0, ft2
        j       .Lat_have_theta
.Lat_big:
        fdiv.d  ft2, ft5, ft0
        fabs.d  ft9, ft2
        fmul.d  fa2, ft9, ft9
        fmadd.d fa2, ft6, fa2, ft5
        fdiv.d  fa3, ft2, fa2
        flt.d   t1, ft4, ft0
        beqz    t1, .Lat_big_neg
        fsub.d  ft3, ft7, fa3
        j       .Lat_have_theta
.Lat_big_neg:
        fsub.d  ft3, ft4, ft7
        fsub.d  ft3, ft3, fa3
.Lat_have_theta:
        flt.d   t1, fa1, ft4
        beqz    t1, .Lat_done
        fle.d   t1, ft4, fa0
        beqz    t1, .Lat_add_negpi
        fadd.d  ft3, ft3, ft8
        j       .Lat_done
.Lat_add_negpi:
        fsub.d  ft3, ft3, ft8
.Lat_done:
        fmv.d   fa0, ft3
        ret

        .globl wrap_angle
wrap_angle:
        la      t0, C_PI
        fld     ft0, 0(t0)
        la      t0, C_TPI
        fld     ft1, 0(t0)
.Lwa_hi:
        fle.d   t1, fa0, ft0
        bnez    t1, .Lwa_lo
        fsub.d  fa0, fa0, ft1
        j       .Lwa_hi
.Lwa_lo:
        fneg.d  ft2, ft0
        fle.d   t1, ft2, fa0
        bnez    t1, .Lwa_done
        fadd.d  fa0, fa0, ft1
        j       .Lwa_lo
.Lwa_done:
        ret

        .globl compute_hx
compute_hx:
        addi    sp, sp, -96
        sd      ra, 88(sp)
        sd      s0, 80(sp)
        sd      s1, 72(sp)
        sd      s2, 64(sp)
        fsd     fs0, 56(sp)
        fsd     fs1, 48(sp)
        fsd     fs2, 40(sp)
        fsd     fs3, 32(sp)
        fsd     fs4, 24(sp)
        mv      s0, a0
        mv      s1, a1
        li      s2, 0
.Lhx_loop:
        li      t0, 23
        bge     s2, t0, .Lhx_done
        li      t0, 96
        mul     t1, s2, t0
        add     t2, s0, t1
        li      t0, 24
        mul     t1, s2, t0
        add     t3, s1, t1
        fld     fs0, 0(t2)
        fld     fs1, 32(t2)
        fld     fs2, 64(t2)
        la      t0, C_SENSOR_OX
        fld     ft0, 0(t0)
        fsub.d  fs0, fs0, ft0
        la      t0, C_SENSOR_OY
        fld     ft0, 0(t0)
        fsub.d  fs1, fs1, ft0
        la      t0, C_SENSOR_OZ
        fld     ft0, 0(t0)
        fsub.d  fs2, fs2, ft0
        la      t0, C_EPS
        fld     ft7, 0(t0)
        fmul.d  ft0, fs0, fs0
        fmadd.d ft0, fs1, fs1, ft0
        fadd.d  ft0, ft0, ft7
        fsqrt.d fs3, ft0
        fmul.d  ft0, fs0, fs0
        fmadd.d ft0, fs1, fs1, ft0
        fmadd.d ft0, fs2, fs2, ft0
        fadd.d  ft0, ft0, ft7
        fsqrt.d fs4, ft0
        fsd     fs4, 0(t3)
        fmv.d   fa0, fs1
        fmv.d   fa1, fs0
        call    manual_arctan2
        li      t0, 24
        mul     t1, s2, t0
        add     t3, s1, t1
        fsd     fa0, 8(t3)
        fmv.d   fa0, fs2
        fmv.d   fa1, fs3
        call    manual_arctan2
        li      t0, 24
        mul     t1, s2, t0
        add     t3, s1, t1
        fsd     fa0, 16(t3)
        addi    s2, s2, 1
        j       .Lhx_loop
.Lhx_done:
        fld     fs4, 24(sp)
        fld     fs3, 32(sp)
        fld     fs2, 40(sp)
        fld     fs1, 48(sp)
        fld     fs0, 56(sp)
        ld      s2, 64(sp)
        ld      s1, 72(sp)
        ld      s0, 80(sp)
        ld      ra, 88(sp)
        addi    sp, sp, 96
        ret

        .globl compute_jacobian
compute_jacobian:
        addi    sp, sp, -112
        sd      ra, 104(sp)
        sd      s0, 96(sp)
        sd      s1, 88(sp)
        sd      s2, 80(sp)
        fsd     fs0, 72(sp)
        fsd     fs1, 64(sp)
        fsd     fs2, 56(sp)
        fsd     fs3, 48(sp)
        fsd     fs4, 40(sp)
        fsd     fs5, 32(sp)
        fsd     fs6, 24(sp)
        mv      s0, a0
        mv      s1, a1
        li      a1, 19044
        mv      a0, s1
        call    mat_zero
        li      s2, 0
.Lj_loop:
        li      t0, 23
        bge     s2, t0, .Lj_done
        li      t0, 96
        mul     t1, s2, t0
        add     t2, s0, t1
        fld     fs0, 0(t2)
        fld     fs1, 32(t2)
        fld     fs2, 64(t2)
        la      t0, C_SENSOR_OX
        fld     ft0, 0(t0)
        fsub.d  fs0, fs0, ft0
        la      t0, C_SENSOR_OY
        fld     ft0, 0(t0)
        fsub.d  fs1, fs1, ft0
        la      t0, C_SENSOR_OZ
        fld     ft0, 0(t0)
        fsub.d  fs2, fs2, ft0
        la      t0, C_EPS
        fld     ft7, 0(t0)
        fmul.d  fs5, fs0, fs0
        fmadd.d fs5, fs1, fs1, fs5
        fmadd.d fs5, fs2, fs2, fs5
        fadd.d  fs5, fs5, ft7
        fsqrt.d fs4, fs5
        fmul.d  fs6, fs0, fs0
        fmadd.d fs6, fs1, fs1, fs6
        fadd.d  fs6, fs6, ft7
        fsqrt.d fs3, fs6
        li      t5, 2208
        li      t4, 8
        li      t0, 3
        mul     t1, s2, t0
        mul     t3, t1, t5
        add     t3, t3, s1
        li      t0, 12
        mul     t1, s2, t0
        slli    t2, t1, 3
        add     t6, t3, t2
        fdiv.d  ft0, fs0, fs4
        fsd     ft0, 0(t6)
        fdiv.d  ft0, fs1, fs4
        fsd     ft0, 32(t6)
        fdiv.d  ft0, fs2, fs4
        fsd     ft0, 64(t6)
        add     t3, t3, t5
        add     t6, t3, t2
        fneg.d  ft0, fs1
        fdiv.d  ft0, ft0, fs6
        fsd     ft0, 0(t6)
        fdiv.d  ft0, fs0, fs6
        fsd     ft0, 32(t6)
        add     t3, t3, t5
        add     t6, t3, t2
        fmul.d  ft0, fs0, fs2
        fneg.d  ft0, ft0
        fmul.d  ft1, fs5, fs3
        fdiv.d  ft0, ft0, ft1
        fsd     ft0, 0(t6)
        fmul.d  ft0, fs1, fs2
        fneg.d  ft0, ft0
        fdiv.d  ft0, ft0, ft1
        fsd     ft0, 32(t6)
        fdiv.d  ft0, fs3, fs5
        fsd     ft0, 64(t6)
        addi    s2, s2, 1
        j       .Lj_loop
.Lj_done:
        fld     fs6, 24(sp)
        fld     fs5, 32(sp)
        fld     fs4, 40(sp)
        fld     fs3, 48(sp)
        fld     fs2, 56(sp)
        fld     fs1, 64(sp)
        fld     fs0, 72(sp)
        ld      s2, 80(sp)
        ld      s1, 88(sp)
        ld      s0, 96(sp)
        ld      ra, 104(sp)
        addi    sp, sp, 112
        ret

        .globl ekf_step
ekf_step:
        addi    sp, sp, -128
        sd      ra, 120(sp)
        sd      s0, 112(sp)
        sd      s1, 104(sp)
        sd      s2, 96(sp)
        sd      s3, 88(sp)
        sd      s4, 80(sp)
        sd      s5, 72(sp)
        sd      s6, 64(sp)
        sd      s7, 56(sp)
        sd      s8, 48(sp)
        sd      s9, 40(sp)
        sd      s10, 32(sp)
        sd      s11, 24(sp)
        mv      s0, a0
        mv      s1, a1
        mv      s2, a2
        mv      s3, a3
        mv      s4, a4
        mv      s5, a5
        mv      s6, a6
        mv      s7, a7
        ld      s8, 0(s7)
        ld      s9, 8(s7)
        ld      s10, 32(s7)
        ld      s11, 120(s7)
        mv      a0, s8
        mv      a1, s2
        mv      a2, s0
        li      a3, 276
        li      a4, 276
        li      a5, 1
        call    mat_mul
        ld      t0, 24(s7)
        mv      a0, t0
        mv      a1, s2
        mv      a2, s1
        li      a3, 276
        li      a4, 276
        li      a5, 276
        call    mat_mul
        ld      t0, 16(s7)
        mv      a0, t0
        mv      a1, s2
        li      a2, 276
        li      a3, 276
        call    mat_transpose
        ld      a0, 8(s7)
        ld      a1, 24(s7)
        ld      a2, 16(s7)
        li      a3, 276
        li      a4, 276
        li      a5, 276
        call    mat_mul
        ld      a0, 8(s7)
        ld      a1, 8(s7)
        mv      a2, s3
        li      a3, 76176
        call    mat_add
        ld      s8, 48(s7)
        li      t6, 0
.Les_sph_loop:
        li      t0, 23
        bge     t6, t0, .Les_sph_done
        li      t0, 3
        mul     t1, t6, t0
        slli    t2, t1, 3
        add     t3, s6, t2
        fld     fs0, 0(t3)
        fld     fs1, 8(t3)
        fld     fs2, 16(t3)
        la      t0, C_SENSOR_OX
        fld     ft0, 0(t0)
        fsub.d  fs0, fs0, ft0
        la      t0, C_SENSOR_OY
        fld     ft0, 0(t0)
        fsub.d  fs1, fs1, ft0
        la      t0, C_SENSOR_OZ
        fld     ft0, 0(t0)
        fsub.d  fs2, fs2, ft0
        la      t0, C_EPS
        fld     ft7, 0(t0)
        fmul.d  ft0, fs0, fs0
        fmadd.d ft0, fs1, fs1, ft0
        fadd.d  ft0, ft0, ft7
        fsqrt.d fs3, ft0
        fmul.d  ft0, fs0, fs0
        fmadd.d ft0, fs1, fs1, ft0
        fmadd.d ft0, fs2, fs2, ft0
        fadd.d  ft0, ft0, ft7
        fsqrt.d ft0, ft0
        add     t4, s8, t2
        fsd     ft0, 0(t4)
        fmv.d   fa0, fs1
        fmv.d   fa1, fs0
        call    manual_arctan2
        li      t0, 3
        mul     t1, t6, t0
        slli    t2, t1, 3
        add     t4, s8, t2
        fsd     fa0, 8(t4)
        fmv.d   fa0, fs2
        fmv.d   fa1, fs3
        call    manual_arctan2
        li      t0, 3
        mul     t1, t6, t0
        slli    t2, t1, 3
        add     t4, s8, t2
        fsd     fa0, 16(t4)
        addi    t6, t6, 1
        j       .Les_sph_loop
.Les_sph_done:
        ld      s8, 0(s7)
        mv      a0, s8
        ld      a1, 32(s7)
        call    compute_jacobian
        mv      a0, s8
        ld      a1, 56(s7)
        call    compute_hx
        ld      a0, 64(s7)
        ld      a1, 48(s7)
        ld      a2, 56(s7)
        li      a3, 69
        call    mat_sub
        ld      t5, 64(s7)
        li      t6, 0
.Lwrap_loop:
        li      t0, 23
        bge     t6, t0, .Lwrap_done
        li      t0, 24
        mul     t1, t6, t0
        add     t2, t5, t1
        fld     fa0, 8(t2)
        addi    sp, sp, -16
        sd      t5, 0(sp)
        sd      t6, 8(sp)
        call    wrap_angle
        ld      t5, 0(sp)
        ld      t6, 8(sp)
        addi    sp, sp, 16
        li      t0, 24
        mul     t1, t6, t0
        add     t2, t5, t1
        fsd     fa0, 8(t2)
        fld     fa0, 16(t2)
        addi    sp, sp, -16
        sd      t5, 0(sp)
        sd      t6, 8(sp)
        call    wrap_angle
        ld      t5, 0(sp)
        ld      t6, 8(sp)
        addi    sp, sp, 16
        li      t0, 24
        mul     t1, t6, t0
        add     t2, t5, t1
        fsd     fa0, 16(t2)
        addi    t6, t6, 1
        j       .Lwrap_loop
.Lwrap_done:
        ld      a0, 72(s7)
        mv      a1, s4
        li      a2, 4761
        call    mat_copy
        ld      t5, 64(s7)
        ld      t4, 72(s7)
        la      t0, C_ADAPT_THR
        fld     ft8, 0(t0)
        la      t0, C_ADAPT_SCL
        fld     ft9, 0(t0)
        li      t6, 0
.Ladapt_loop:
        li      t0, 23
        bge     t6, t0, .Ladapt_done
        li      t0, 24
        mul     t1, t6, t0
        add     t2, t5, t1
        fld     ft0, 0(t2)
        fabs.d  ft0, ft0
        flt.d   t0, ft8, ft0
        beqz    t0, .Ladapt_next
        li      t0, 3
        mul     t1, t6, t0
        li      t3, 3
.Ladapt_k:
        beqz    t3, .Ladapt_next
        li      t0, 70
        mul     t2, t1, t0
        slli    t2, t2, 3
        add     t2, t4, t2
        fld     ft0, 0(t2)
        fmul.d  ft0, ft0, ft9
        fsd     ft0, 0(t2)
        addi    t1, t1, 1
        addi    t3, t3, -1
        j       .Ladapt_k
.Ladapt_next:
        addi    t6, t6, 1
        j       .Ladapt_loop
.Ladapt_done:
        ld      a0, 88(s7)
        ld      a1, 32(s7)
        ld      a2, 8(s7)
        li      a3, 69
        li      a4, 276
        li      a5, 276
        call    mat_mul
        ld      a0, 40(s7)
        ld      a1, 32(s7)
        li      a2, 69
        li      a3, 276
        call    mat_transpose
        ld      a0, 80(s7)
        ld      a1, 88(s7)
        ld      a2, 40(s7)
        li      a3, 69
        li      a4, 276
        li      a5, 69
        call    mat_mul
        ld      a0, 80(s7)
        ld      a1, 80(s7)
        ld      a2, 72(s7)
        li      a3, 4761
        call    mat_add
        ld      t5, 64(s7)
        ld      t4, 80(s7)
        la      t0, C_GATE_SIG
        fld     ft8, 0(t0)
        la      t0, C_ZERO
        fld     ft7, 0(t0)
        la      t0, C_ONE
        fld     ft6, 0(t0)
        li      t6, 0
.Lgate_loop:
        li      t0, 69
        bge     t6, t0, .Lgate_done
        li      t0, 70
        mul     t1, t6, t0
        slli    t1, t1, 3
        add     t2, t4, t1
        fld     ft0, 0(t2)
        flt.d   t0, ft7, ft0
        bnez    t0, .Lgate_sqrt
        fmv.d   ft0, ft6
        j       .Lgate_have_std
.Lgate_sqrt:
        fsqrt.d ft0, ft0
.Lgate_have_std:
        fmul.d  ft0, ft0, ft8
        slli    t1, t6, 3
        add     t2, t5, t1
        fld     ft1, 0(t2)
        flt.d   t0, ft0, ft1
        beqz    t0, .Lgate_lo
        fsd     ft0, 0(t2)
        j       .Lgate_next
.Lgate_lo:
        fneg.d  ft2, ft0
        flt.d   t0, ft1, ft2
        beqz    t0, .Lgate_next
        fsd     ft2, 0(t2)
.Lgate_next:
        addi    t6, t6, 1
        j       .Lgate_loop
.Lgate_done:
        ld      a0, 96(s7)
        ld      a1, 8(s7)
        ld      a2, 40(s7)
        li      a3, 276
        li      a4, 276
        li      a5, 69
        call    mat_mul
        ld      a0, 104(s7)
        ld      a1, 96(s7)
        li      a2, 276
        li      a3, 69
        call    mat_transpose
        ld      a0, 80(s7)
        ld      a1, 104(s7)
        ld      a2, 112(s7)
        li      a3, 69
        li      a4, 276
        ld      a5, 208(s7)
        call    solve_cholesky
        ld      a0, 120(s7)
        ld      a1, 112(s7)
        li      a2, 69
        li      a3, 276
        call    mat_transpose
        ld      a0, 128(s7)
        ld      a1, 120(s7)
        ld      a2, 64(s7)
        li      a3, 276
        li      a4, 69
        li      a5, 1
        call    mat_mul
        mv      a0, s0
        ld      a1, 0(s7)
        ld      a2, 128(s7)
        li      a3, 276
        call    mat_add
        ld      a0, 136(s7)
        ld      a1, 120(s7)
        ld      a2, 32(s7)
        li      a3, 276
        li      a4, 69
        li      a5, 276
        call    mat_mul
        ld      a0, 144(s7)
        mv      a1, s5
        ld      a2, 136(s7)
        li      a3, 76176
        call    mat_sub
        ld      a0, 152(s7)
        ld      a1, 144(s7)
        ld      a2, 8(s7)
        li      a3, 276
        li      a4, 276
        li      a5, 276
        call    mat_mul
        ld      a0, 160(s7)
        ld      a1, 144(s7)
        li      a2, 276
        li      a3, 276
        call    mat_transpose
        ld      a0, 168(s7)
        ld      a1, 152(s7)
        ld      a2, 160(s7)
        li      a3, 276
        li      a4, 276
        li      a5, 276
        call    mat_mul
        ld      a0, 192(s7)
        ld      a1, 120(s7)
        ld      a2, 72(s7)
        li      a3, 276
        li      a4, 69
        li      a5, 69
        call    mat_mul
        ld      a0, 176(s7)
        ld      a1, 192(s7)
        ld      a2, 112(s7)
        li      a3, 276
        li      a4, 69
        li      a5, 276
        call    mat_mul
        mv      a0, s1
        ld      a1, 168(s7)
        ld      a2, 176(s7)
        li      a3, 76176
        call    mat_add
        mv      a0, s1
        li      a1, 276
        call    enforce_symmetry
        ld      s11, 24(sp)
        ld      s10, 32(sp)
        ld      s9, 40(sp)
        ld      s8, 48(sp)
        ld      s7, 56(sp)
        ld      s6, 64(sp)
        ld      s5, 72(sp)
        ld      s4, 80(sp)
        ld      s3, 88(sp)
        ld      s2, 96(sp)
        ld      s1, 104(sp)
        ld      s0, 112(sp)
        ld      ra, 120(sp)
        addi    sp, sp, 128
        ret

        .section .rodata
        .align 3

default_in_path:
        .asciz  "3D Full Body Humain Gait Walking Dataset (Noisy Values).csv"
default_out_path:
        .asciz  "ekf_output.csv"
mode_r:
        .asciz  "r"
mode_w:
        .asciz  "w"
fmt_double:
        .asciz  "%.15f"
fmt_double_comma:
        .asciz  "%.15f,"
msg_open_in_err:
        .asciz  "ERROR: cannot open input CSV\n"
msg_open_out_err:
        .asciz  "ERROR: cannot open output CSV\n"
msg_start:
        .asciz  "EKF starting...\n"
msg_done_prefix:
        .asciz  "EKF done. Frames processed: "
msg_newline:
        .asciz  "\n"
fmt_long:
        .asciz  "%ld\n"
fmt_progress:
        .asciz  "Frame %ld\n"

header_line:
        .ascii  "Pelvis_pos_x,Pelvis_vel_x,Pelvis_acc_x,Pelvis_jerk_x,Pelvis_pos_y,Pelvis_vel_y,Pelvis_acc_y,Pelvis_jerk_y,Pelvis_pos_z,Pelvis_vel_z,Pelvis_acc_z,Pelvis_jerk_z,"
        .ascii  "L5_pos_x,L5_vel_x,L5_acc_x,L5_jerk_x,L5_pos_y,L5_vel_y,L5_acc_y,L5_jerk_y,L5_pos_z,L5_vel_z,L5_acc_z,L5_jerk_z,"
        .ascii  "L3_pos_x,L3_vel_x,L3_acc_x,L3_jerk_x,L3_pos_y,L3_vel_y,L3_acc_y,L3_jerk_y,L3_pos_z,L3_vel_z,L3_acc_z,L3_jerk_z,"
        .ascii  "T12_pos_x,T12_vel_x,T12_acc_x,T12_jerk_x,T12_pos_y,T12_vel_y,T12_acc_y,T12_jerk_y,T12_pos_z,T12_vel_z,T12_acc_z,T12_jerk_z,"
        .ascii  "T8_pos_x,T8_vel_x,T8_acc_x,T8_jerk_x,T8_pos_y,T8_vel_y,T8_acc_y,T8_jerk_y,T8_pos_z,T8_vel_z,T8_acc_z,T8_jerk_z,"
        .ascii  "Neck_pos_x,Neck_vel_x,Neck_acc_x,Neck_jerk_x,Neck_pos_y,Neck_vel_y,Neck_acc_y,Neck_jerk_y,Neck_pos_z,Neck_vel_z,Neck_acc_z,Neck_jerk_z,"
        .ascii  "Head_pos_x,Head_vel_x,Head_acc_x,Head_jerk_x,Head_pos_y,Head_vel_y,Head_acc_y,Head_jerk_y,Head_pos_z,Head_vel_z,Head_acc_z,Head_jerk_z,"
        .ascii  "RightShoulder_pos_x,RightShoulder_vel_x,RightShoulder_acc_x,RightShoulder_jerk_x,RightShoulder_pos_y,RightShoulder_vel_y,RightShoulder_acc_y,RightShoulder_jerk_y,RightShoulder_pos_z,RightShoulder_vel_z,RightShoulder_acc_z,RightShoulder_jerk_z,"
        .ascii  "RightUpperArm_pos_x,RightUpperArm_vel_x,RightUpperArm_acc_x,RightUpperArm_jerk_x,RightUpperArm_pos_y,RightUpperArm_vel_y,RightUpperArm_acc_y,RightUpperArm_jerk_y,RightUpperArm_pos_z,RightUpperArm_vel_z,RightUpperArm_acc_z,RightUpperArm_jerk_z,"
        .ascii  "RightForearm_pos_x,RightForearm_vel_x,RightForearm_acc_x,RightForearm_jerk_x,RightForearm_pos_y,RightForearm_vel_y,RightForearm_acc_y,RightForearm_jerk_y,RightForearm_pos_z,RightForearm_vel_z,RightForearm_acc_z,RightForearm_jerk_z,"
        .ascii  "RightHand_pos_x,RightHand_vel_x,RightHand_acc_x,RightHand_jerk_x,RightHand_pos_y,RightHand_vel_y,RightHand_acc_y,RightHand_jerk_y,RightHand_pos_z,RightHand_vel_z,RightHand_acc_z,RightHand_jerk_z,"
        .ascii  "LeftShoulder_pos_x,LeftShoulder_vel_x,LeftShoulder_acc_x,LeftShoulder_jerk_x,LeftShoulder_pos_y,LeftShoulder_vel_y,LeftShoulder_acc_y,LeftShoulder_jerk_y,LeftShoulder_pos_z,LeftShoulder_vel_z,LeftShoulder_acc_z,LeftShoulder_jerk_z,"
        .ascii  "LeftUpperArm_pos_x,LeftUpperArm_vel_x,LeftUpperArm_acc_x,LeftUpperArm_jerk_x,LeftUpperArm_pos_y,LeftUpperArm_vel_y,LeftUpperArm_acc_y,LeftUpperArm_jerk_y,LeftUpperArm_pos_z,LeftUpperArm_vel_z,LeftUpperArm_acc_z,LeftUpperArm_jerk_z,"
        .ascii  "LeftForearm_pos_x,LeftForearm_vel_x,LeftForearm_acc_x,LeftForearm_jerk_x,LeftForearm_pos_y,LeftForearm_vel_y,LeftForearm_acc_y,LeftForearm_jerk_y,LeftForearm_pos_z,LeftForearm_vel_z,LeftForearm_acc_z,LeftForearm_jerk_z,"
        .ascii  "LeftHand_pos_x,LeftHand_vel_x,LeftHand_acc_x,LeftHand_jerk_x,LeftHand_pos_y,LeftHand_vel_y,LeftHand_acc_y,LeftHand_jerk_y,LeftHand_pos_z,LeftHand_vel_z,LeftHand_acc_z,LeftHand_jerk_z,"
        .ascii  "RightUpperLeg_pos_x,RightUpperLeg_vel_x,RightUpperLeg_acc_x,RightUpperLeg_jerk_x,RightUpperLeg_pos_y,RightUpperLeg_vel_y,RightUpperLeg_acc_y,RightUpperLeg_jerk_y,RightUpperLeg_pos_z,RightUpperLeg_vel_z,RightUpperLeg_acc_z,RightUpperLeg_jerk_z,"
        .ascii  "RightLowerLeg_pos_x,RightLowerLeg_vel_x,RightLowerLeg_acc_x,RightLowerLeg_jerk_x,RightLowerLeg_pos_y,RightLowerLeg_vel_y,RightLowerLeg_acc_y,RightLowerLeg_jerk_y,RightLowerLeg_pos_z,RightLowerLeg_vel_z,RightLowerLeg_acc_z,RightLowerLeg_jerk_z,"
        .ascii  "RightFoot_pos_x,RightFoot_vel_x,RightFoot_acc_x,RightFoot_jerk_x,RightFoot_pos_y,RightFoot_vel_y,RightFoot_acc_y,RightFoot_jerk_y,RightFoot_pos_z,RightFoot_vel_z,RightFoot_acc_z,RightFoot_jerk_z,"
        .ascii  "RightToe_pos_x,RightToe_vel_x,RightToe_acc_x,RightToe_jerk_x,RightToe_pos_y,RightToe_vel_y,RightToe_acc_y,RightToe_jerk_y,RightToe_pos_z,RightToe_vel_z,RightToe_acc_z,RightToe_jerk_z,"
        .ascii  "LeftUpperLeg_pos_x,LeftUpperLeg_vel_x,LeftUpperLeg_acc_x,LeftUpperLeg_jerk_x,LeftUpperLeg_pos_y,LeftUpperLeg_vel_y,LeftUpperLeg_acc_y,LeftUpperLeg_jerk_y,LeftUpperLeg_pos_z,LeftUpperLeg_vel_z,LeftUpperLeg_acc_z,LeftUpperLeg_jerk_z,"
        .ascii  "LeftLowerLeg_pos_x,LeftLowerLeg_vel_x,LeftLowerLeg_acc_x,LeftLowerLeg_jerk_x,LeftLowerLeg_pos_y,LeftLowerLeg_vel_y,LeftLowerLeg_acc_y,LeftLowerLeg_jerk_y,LeftLowerLeg_pos_z,LeftLowerLeg_vel_z,LeftLowerLeg_acc_z,LeftLowerLeg_jerk_z,"
        .ascii  "LeftFoot_pos_x,LeftFoot_vel_x,LeftFoot_acc_x,LeftFoot_jerk_x,LeftFoot_pos_y,LeftFoot_vel_y,LeftFoot_acc_y,LeftFoot_jerk_y,LeftFoot_pos_z,LeftFoot_vel_z,LeftFoot_acc_z,LeftFoot_jerk_z,"
        .asciz  "LeftToe_pos_x,LeftToe_vel_x,LeftToe_acc_x,LeftToe_jerk_x,LeftToe_pos_y,LeftToe_vel_y,LeftToe_acc_y,LeftToe_jerk_y,LeftToe_pos_z,LeftToe_vel_z,LeftToe_acc_z,LeftToe_jerk_z\n"

C_DT:       .double 0.01
C_SIGMA_JSQ:.double 0.001
C_SIGMA_R:  .double 0.1
C_SIGMA_AZ: .double 1.0e-3
C_SIGMA_EL: .double 5.0e-6
C_SIX:      .double 6.0
C_TWELVE:   .double 12.0
C_FOUR:     .double 4.0
C_THIRTYSIX:.double 36.0

        .text

        .globl build_F
build_F:
        addi    sp, sp, -64
        sd      ra, 56(sp)
        sd      s0, 48(sp)
        sd      s1, 40(sp)
        sd      s2, 32(sp)
        fsd     fs0, 24(sp)
        fsd     fs1, 16(sp)
        fsd     fs2, 8(sp)
        mv      s0, a0
        fmv.d   fs0, fa0
        li      a1, 76176
        call    mat_zero
        fmul.d  fs1, fs0, fs0
        fmul.d  fs2, fs1, fs0
        la      t0, C_TWO
        fld     ft8, 0(t0)
        la      t0, C_SIX
        fld     ft9, 0(t0)
        la      t0, C_ONE
        fld     ft10, 0(t0)
        fdiv.d  ft5, fs1, ft8
        fdiv.d  ft6, fs2, ft9
        li      s1, 0
.LbF_i:
        li      t0, 23
        bge     s1, t0, .LbF_done
        li      s2, 0
.LbF_ax:
        li      t0, 3
        bge     s2, t0, .LbF_next_i
        li      t0, 12
        mul     t1, s1, t0
        li      t0, 4
        mul     t2, s2, t0
        add     t3, t1, t2
        slli    a2, t3, 3
        li      t4, 2208
        mul     t5, t3, t4
        add     t5, t5, s0
        add     t6, t5, a2
        fsd     ft10, 0(t6)
        fsd     fs0,  8(t6)
        fsd     ft5,  16(t6)
        fsd     ft6,  24(t6)
        add     t5, t5, t4
        add     t6, t5, a2
        fsd     ft10, 8(t6)
        fsd     fs0,  16(t6)
        fsd     ft5,  24(t6)
        add     t5, t5, t4
        add     t6, t5, a2
        fsd     ft10, 16(t6)
        fsd     fs0,  24(t6)
        add     t5, t5, t4
        add     t6, t5, a2
        fsd     ft10, 24(t6)
        addi    s2, s2, 1
        j       .LbF_ax
.LbF_next_i:
        addi    s1, s1, 1
        j       .LbF_i
.LbF_done:
        fld     fs2, 8(sp)
        fld     fs1, 16(sp)
        fld     fs0, 24(sp)
        ld      s2, 32(sp)
        ld      s1, 40(sp)
        ld      s0, 48(sp)
        ld      ra, 56(sp)
        addi    sp, sp, 64
        ret

        .globl build_Q
build_Q:
        addi    sp, sp, -192
        sd      ra, 184(sp)
        sd      s0, 176(sp)
        sd      s1, 168(sp)
        sd      s2, 160(sp)
        fsd     fs0, 152(sp)
        fsd     fs1, 144(sp)
        mv      s0, a0
        fmv.d   fs0, fa0
        fmv.d   fs1, fa1
        li      a1, 76176
        call    mat_zero
        fmul.d  ft0, fs0, fs0
        fmul.d  ft1, ft0, fs0
        fmul.d  ft2, ft1, fs0
        fmul.d  ft3, ft2, fs0
        fmul.d  ft4, ft3, fs0
        la      t0, C_THIRTYSIX
        fld     ft5, 0(t0)
        la      t0, C_TWELVE
        fld     ft6, 0(t0)
        la      t0, C_SIX
        fld     ft7, 0(t0)
        la      t0, C_FOUR
        fld     ft8, 0(t0)
        la      t0, C_TWO
        fld     ft9, 0(t0)
        la      t0, C_ONE
        fld     ft10, 0(t0)
        fdiv.d  ft11, ft4, ft5
        fsd     ft11, 0(sp)
        fdiv.d  ft11, ft3, ft6
        fsd     ft11, 8(sp)
        fdiv.d  ft11, ft2, ft7
        fsd     ft11, 16(sp)
        fdiv.d  ft11, ft1, ft7
        fsd     ft11, 24(sp)
        fdiv.d  ft11, ft3, ft6
        fsd     ft11, 32(sp)
        fdiv.d  ft11, ft2, ft8
        fsd     ft11, 40(sp)
        fdiv.d  ft11, ft1, ft9
        fsd     ft11, 48(sp)
        fdiv.d  ft11, ft0, ft9
        fsd     ft11, 56(sp)
        fdiv.d  ft11, ft2, ft7
        fsd     ft11, 64(sp)
        fdiv.d  ft11, ft1, ft9
        fsd     ft11, 72(sp)
        fsd     ft0, 80(sp)
        fsd     fs0, 88(sp)
        fdiv.d  ft11, ft1, ft7
        fsd     ft11, 96(sp)
        fdiv.d  ft11, ft0, ft9
        fsd     ft11, 104(sp)
        fsd     fs0, 112(sp)
        fsd     ft10, 120(sp)
        li      t0, 0
.LbQ_scale:
        li      t1, 16
        bge     t0, t1, .LbQ_scale_done
        slli    t2, t0, 3
        add     t3, sp, t2
        fld     ft11, 0(t3)
        fmul.d  ft11, ft11, fs1
        fsd     ft11, 0(t3)
        addi    t0, t0, 1
        j       .LbQ_scale
.LbQ_scale_done:
        li      s1, 0
.LbQ_i:
        li      t0, 23
        bge     s1, t0, .LbQ_done
        li      s2, 0
.LbQ_ax:
        li      t0, 3
        bge     s2, t0, .LbQ_next_i
        li      t0, 12
        mul     t1, s1, t0
        li      t0, 4
        mul     t2, s2, t0
        add     t3, t1, t2
        li      t4, 0
.LbQ_r:
        li      t0, 4
        bge     t4, t0, .LbQ_next_ax
        li      t5, 0
.LbQ_c:
        li      t0, 4
        bge     t5, t0, .LbQ_next_r
        li      t0, 4
        mul     t6, t4, t0
        add     t6, t6, t5
        slli    t6, t6, 3
        add     a3, sp, t6
        fld     ft11, 0(a3)
        add     a4, t3, t4
        add     a5, t3, t5
        li      a6, 276
        mul     a4, a4, a6
        add     a4, a4, a5
        slli    a4, a4, 3
        add     a4, a4, s0
        fsd     ft11, 0(a4)
        addi    t5, t5, 1
        j       .LbQ_c
.LbQ_next_r:
        addi    t4, t4, 1
        j       .LbQ_r
.LbQ_next_ax:
        addi    s2, s2, 1
        j       .LbQ_ax
.LbQ_next_i:
        addi    s1, s1, 1
        j       .LbQ_i
.LbQ_done:
        fld     fs1, 144(sp)
        fld     fs0, 152(sp)
        ld      s2, 160(sp)
        ld      s1, 168(sp)
        ld      s0, 176(sp)
        ld      ra, 184(sp)
        addi    sp, sp, 192
        ret

        .globl build_R
build_R:
        addi    sp, sp, -48
        sd      ra, 40(sp)
        sd      s0, 32(sp)
        fsd     fs0, 24(sp)
        fsd     fs1, 16(sp)
        fsd     fs2, 8(sp)
        mv      s0, a0
        fmv.d   fs0, fa0
        fmv.d   fs1, fa1
        fmv.d   fs2, fa2
        li      a1, 4761
        call    mat_zero
        li      t0, 0
.LbR_loop:
        li      t1, 23
        bge     t0, t1, .LbR_done
        li      t2, 3
        mul     t3, t0, t2
        li      t2, 70
        mul     t4, t3, t2
        slli    t4, t4, 3
        add     t4, t4, s0
        fsd     fs0, 0(t4)
        addi    t3, t3, 1
        li      t2, 70
        mul     t4, t3, t2
        slli    t4, t4, 3
        add     t4, t4, s0
        fsd     fs1, 0(t4)
        addi    t3, t3, 1
        li      t2, 70
        mul     t4, t3, t2
        slli    t4, t4, 3
        add     t4, t4, s0
        fsd     fs2, 0(t4)
        addi    t0, t0, 1
        j       .LbR_loop
.LbR_done:
        fld     fs2, 8(sp)
        fld     fs1, 16(sp)
        fld     fs0, 24(sp)
        ld      s0, 32(sp)
        ld      ra, 40(sp)
        addi    sp, sp, 48
        ret

        .globl main
main:
        addi    sp, sp, -80
        sd      ra, 72(sp)
        sd      s0, 64(sp)
        sd      s1, 56(sp)
        sd      s2, 48(sp)
        sd      s3, 40(sp)
        sd      s4, 32(sp)
        sd      s5, 24(sp)
        sd      s6, 16(sp)
        sd      s7, 8(sp)
        sd      s8, 0(sp)
        mv      s0, a0
        mv      s1, a1
        li      t0, 2
        blt     s0, t0, .Lmain_default_in
        ld      a0, 8(s1)
        j       .Lmain_in_got
.Lmain_default_in:
        la      a0, default_in_path
.Lmain_in_got:
        la      a1, mode_r
        call    fopen
        beqz    a0, .Lmain_err_in
        mv      s2, a0
        li      t0, 3
        blt     s0, t0, .Lmain_default_out
        ld      a0, 16(s1)
        j       .Lmain_out_got
.Lmain_default_out:
        la      a0, default_out_path
.Lmain_out_got:
        la      a1, mode_w
        call    fopen
        beqz    a0, .Lmain_err_out
        mv      s3, a0
        li      a0, 12582912
        call    malloc
        beqz    a0, .Lmain_err_in
        mv      s4, a0
        mv      s5, s4
        addi    t0, s4, 216
        sd      t0, 0(s5)
        li      t6, 2208
        add     t0, t0, t6
        sd      t0, 8(s5)
        li      t1, 609408
        add     t0, t0, t1
        sd      t0, 16(s5)
        add     t0, t0, t1
        sd      t0, 24(s5)
        add     t0, t0, t1
        sd      t0, 32(s5)
        li      t2, 152352
        add     t0, t0, t2
        sd      t0, 40(s5)
        add     t0, t0, t2
        sd      t0, 48(s5)
        addi    t0, t0, 552
        sd      t0, 56(s5)
        addi    t0, t0, 552
        sd      t0, 64(s5)
        addi    t0, t0, 552
        sd      t0, 72(s5)
        li      t3, 38088
        add     t0, t0, t3
        sd      t0, 80(s5)
        add     t0, t0, t3
        sd      t0, 88(s5)
        add     t0, t0, t2
        sd      t0, 96(s5)
        add     t0, t0, t2
        sd      t0, 104(s5)
        add     t0, t0, t2
        sd      t0, 112(s5)
        add     t0, t0, t2
        sd      t0, 120(s5)
        add     t0, t0, t2
        sd      t0, 128(s5)
        li      t6, 2208
        add     t0, t0, t6
        sd      t0, 136(s5)
        add     t0, t0, t1
        sd      t0, 144(s5)
        add     t0, t0, t1
        sd      t0, 152(s5)
        add     t0, t0, t1
        sd      t0, 160(s5)
        add     t0, t0, t1
        sd      t0, 168(s5)
        add     t0, t0, t1
        sd      t0, 176(s5)
        add     t0, t0, t1
        sd      t0, 184(s5)
        add     t0, t0, t2
        sd      t0, 192(s5)
        add     t0, t0, t2
        sd      t0, 200(s5)
        add     t0, t0, t1
        sd      t0, 208(s5)
        add     t0, t0, t1
        mv      s6, t0
        mv      a0, s6
        li      a1, 609408
        mv      s8, t0
        mv      t4, s8
        add     s8, s8, t1
        mv      t5, s8
        add     s8, s8, t1
        mv      t2, s8
        add     s8, s8, t3
        mv      a0, s8
        add     s8, s8, t1
        mv      a1, s8
        li      t6, 2208
        add     s8, s8, t6
        mv      a2, s8
        add     s8, s8, t1
        mv      a3, s8
        addi    s8, s8, 552
        mv      a4, s8
        li      t6, 8192
        add     s8, s8, t6
        mv      t0, s8
        sd      t4, 0(t0)
        sd      t5, 8(t0)
        sd      t2, 16(t0)
        sd      a0, 24(t0)
        sd      a1, 32(t0)
        sd      a2, 40(t0)
        sd      a3, 48(t0)
        sd      a4, 56(t0)
        mv      s8, t0
        ld      a0, 0(s8)
        la      t0, C_DT
        fld     fa0, 0(t0)
        call    build_F
        ld      a0, 8(s8)
        la      t0, C_DT
        fld     fa0, 0(t0)
        la      t0, C_SIGMA_JSQ
        fld     fa1, 0(t0)
        call    build_Q
        ld      a0, 16(s8)
        la      t0, C_SIGMA_R
        fld     fa0, 0(t0)
        la      t0, C_SIGMA_AZ
        fld     fa1, 0(t0)
        la      t0, C_SIGMA_EL
        fld     fa2, 0(t0)
        call    build_R
        ld      a0, 24(s8)
        li      a1, 276
        call    mat_eye
        ld      a0, 32(s8)
        li      a1, 276
        call    mat_zero
        ld      a0, 40(s8)
        li      a1, 276
        call    mat_eye
        la      a0, header_line
        mv      a1, s3
        call    fputs
        ld      a0, 56(s8)
        li      a1, 8192
        mv      a2, s2
        call    fgets
        li      s6, 0
        li      s7, 1
.Lmain_loop:
        ld      a0, 56(s8)
        li      a1, 8192
        mv      a2, s2
        call    fgets
        beqz    a0, .Lmain_eof
        ld      a0, 56(s8)
        ld      a1, 48(s8)
        li      a2, 69
        call    parse_doubles
        beqz    s7, .Lmain_not_first
        ld      t0, 32(s8)
        ld      t1, 48(s8)
        li      t2, 0
.Lmain_init_joint:
        li      t3, 23
        bge     t2, t3, .Lmain_init_done
        li      t3, 12
        mul     t4, t2, t3
        slli    t4, t4, 3
        add     t4, t4, t0
        li      t3, 3
        mul     t5, t2, t3
        slli    t5, t5, 3
        add     t5, t5, t1
        fld     ft0, 0(t5)
        fsd     ft0, 0(t4)
        fld     ft0, 8(t5)
        fsd     ft0, 32(t4)
        fld     ft0, 16(t5)
        fsd     ft0, 64(t4)
        addi    t2, t2, 1
        j       .Lmain_init_joint
.Lmain_init_done:
        li      s7, 0
        j       .Lmain_write_row
.Lmain_not_first:
        ld      a0, 32(s8)
        ld      a1, 40(s8)
        ld      a2, 0(s8)
        ld      a3, 8(s8)
        ld      a4, 16(s8)
        ld      a5, 24(s8)
        ld      a6, 48(s8)
        mv      a7, s5
        call    ekf_step
.Lmain_write_row:
        ld      s0, 32(s8)
        li      t0, 0
.Lmain_write_loop:
        li      t1, 276
        bge     t0, t1, .Lmain_write_done
        slli    t2, t0, 3
        add     t2, t2, s0
        ld      a2, 0(t2)
        li      t3, 275
        beq     t0, t3, .Lmain_write_last
        mv      a0, s3
        la      a1, fmt_double_comma
        addi    sp, sp, -16
        sd      t0, 0(sp)
        call    fprintf
        ld      t0, 0(sp)
        addi    sp, sp, 16
        j       .Lmain_write_next
.Lmain_write_last:
        mv      a0, s3
        la      a1, fmt_double
        addi    sp, sp, -16
        sd      t0, 0(sp)
        call    fprintf
        ld      t0, 0(sp)
        addi    sp, sp, 16
.Lmain_write_next:
        addi    t0, t0, 1
        j       .Lmain_write_loop
.Lmain_write_done:
        li      a0, 10
        mv      a1, s3
        call    fputc
        ld      s0, 64(sp)
        addi    s6, s6, 1
        li      t0, 100
        remu    t1, s6, t0
        bnez    t1, .Lmain_no_progress
        la      a0, fmt_progress
        mv      a1, s6
        call    printf
.Lmain_no_progress:
        j       .Lmain_loop
.Lmain_eof:
        la      a0, msg_done_prefix
        call    printf
        la      a0, fmt_long
        mv      a1, s6
        call    printf
        mv      a0, s2
        call    fclose
        mv      a0, s3
        call    fclose
        mv      a0, s4
        call    free
        li      a0, 0
        ld      s8, 0(sp)
        ld      s7, 8(sp)
        ld      s6, 16(sp)
        ld      s5, 24(sp)
        ld      s4, 32(sp)
        ld      s3, 40(sp)
        ld      s2, 48(sp)
        ld      s1, 56(sp)
        ld      s0, 64(sp)
        ld      ra, 72(sp)
        addi    sp, sp, 80
        ret
.Lmain_err_in:
        la      a0, msg_open_in_err
        call    printf
        li      a0, 1
        ld      s8, 0(sp)
        ld      s7, 8(sp)
        ld      s6, 16(sp)
        ld      s5, 24(sp)
        ld      s4, 32(sp)
        ld      s3, 40(sp)
        ld      s2, 48(sp)
        ld      s1, 56(sp)
        ld      s0, 64(sp)
        ld      ra, 72(sp)
        addi    sp, sp, 80
        ret
.Lmain_err_out:
        la      a0, msg_open_out_err
        call    printf
        mv      a0, s2
        call    fclose
        li      a0, 1
        ld      s8, 0(sp)
        ld      s7, 8(sp)
        ld      s6, 16(sp)
        ld      s5, 24(sp)
        ld      s4, 32(sp)
        ld      s3, 40(sp)
        ld      s2, 48(sp)
        ld      s1, 56(sp)
        ld      s0, 64(sp)
        ld      ra, 72(sp)
        addi    sp, sp, 80
        ret

        .globl parse_doubles
parse_doubles:
        addi    sp, sp, -48
        sd      ra, 40(sp)
        sd      s0, 32(sp)
        sd      s1, 24(sp)
        sd      s2, 16(sp)
        sd      s3, 8(sp)
        mv      s0, a0
        mv      s1, a1
        mv      s3, a2
        li      s2, 0
.Lpd_loop:
        bge     s2, s3, .Lpd_done
.Lpd_skip:
        lbu     t0, 0(s0)
        beqz    t0, .Lpd_zero
        li      t1, 10
        beq     t0, t1, .Lpd_zero
        li      t1, 13
        beq     t0, t1, .Lpd_zero
        li      t1, 44
        bne     t0, t1, .Lpd_call
        addi    s0, s0, 1
        j       .Lpd_skip
.Lpd_call:
        addi    sp, sp, -16
        mv      a0, s0
        mv      a1, sp
        call    strtod
        ld      t0, 0(sp)
        addi    sp, sp, 16
        beq     t0, s0, .Lpd_fail
        slli    t1, s2, 3
        add     t1, t1, s1
        fsd     fa0, 0(t1)
        mv      s0, t0
        addi    s2, s2, 1
        j       .Lpd_loop
.Lpd_fail:
        la      t0, C_ZERO
        fld     ft0, 0(t0)
        slli    t1, s2, 3
        add     t1, t1, s1
        fsd     ft0, 0(t1)
        addi    s2, s2, 1
        addi    s0, s0, 1
        j       .Lpd_loop
.Lpd_zero:
        la      t0, C_ZERO
        fld     ft0, 0(t0)
.Lpd_zero_loop:
        bge     s2, s3, .Lpd_done
        slli    t1, s2, 3
        add     t1, t1, s1
        fsd     ft0, 0(t1)
        addi    s2, s2, 1
        j       .Lpd_zero_loop
.Lpd_done:
        ld      s3, 8(sp)
        ld      s2, 16(sp)
        ld      s1, 24(sp)
        ld      s0, 32(sp)
        ld      ra, 40(sp)
        addi    sp, sp, 48
        ret