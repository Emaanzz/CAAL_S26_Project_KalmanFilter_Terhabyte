.file "lkf_asm.s"
    .option nopic


    .section .rodata
    .align 3

msg_start:      .string "Starting LKF processing...\n"
msg_frame:      .string "Processed frame %d\n"
msg_done:       .string "\n=== LKF COMPLETE ===\nFrames: %d\n"
msg_err_in:     .string "ERROR: Cannot open input CSV.\n"
msg_err_out:    .string "ERROR: Cannot open output CSV.\n"

file_in:        .string "3D Full Body Humain Gait Walking Dataset (Noisy Values).csv"
mode_r:         .string "r"
file_out:       .string "lkf_output.csv"
mode_w:         .string "w"

fmt_newline:    .string "\n"

    .align 3
const_dt:       .double 0.01
const_dt2:      .double 0.0001
const_dt3:      .double 0.000001
const_half:     .double 0.5
const_sixth:    .double 0.16666666666666666667
const_one:      .double 1.0
const_1e_neg12: .double 1.0e-12
const_1e_neg9:  .double 1.0e-9
const_sigma_pos:.double 0.05

    .align 3
q_block:
    .double  1.3888888888888892e-14
    .double  4.1666666666666676e-12
    .double  8.3333333333333345e-10
    .double  8.3333333333333352e-08
    .double  4.1666666666666676e-12
    .double  1.2500000000000002e-09
    .double  2.5000000000000004e-07
    .double  2.5000000000000001e-05
    .double  8.3333333333333345e-10
    .double  2.5000000000000004e-07
    .double  5.0000000000000002e-05
    .double  5.0000000000000001e-03
    .double  8.3333333333333352e-08
    .double  2.5000000000000001e-05
    .double  5.0000000000000001e-03
    .double  5.0000000000000000e-01

jname0:  .string "Pelvis"
jname1:  .string "L5"
jname2:  .string "L3"
jname3:  .string "T12"
jname4:  .string "T8"
jname5:  .string "Neck"
jname6:  .string "Head"
jname7:  .string "RightShoulder"
jname8:  .string "RightUpperArm"
jname9:  .string "RightForearm"
jname10: .string "RightHand"
jname11: .string "LeftShoulder"
jname12: .string "LeftUpperArm"
jname13: .string "LeftForearm"
jname14: .string "LeftHand"
jname15: .string "RightUpperLeg"
jname16: .string "RightLowerLeg"
jname17: .string "RightFoot"
jname18: .string "RightToe"
jname19: .string "LeftUpperLeg"
jname20: .string "LeftLowerLeg"
jname21: .string "LeftFoot"
jname22: .string "LeftToe"

    .align 3
bone_table:
    .quad jname0, jname1, jname2,  jname3,  jname4,  jname5,  jname6
    .quad jname7, jname8, jname9,  jname10, jname11, jname12, jname13, jname14
    .quad jname15,jname16,jname17, jname18, jname19, jname20, jname21, jname22

fmt_hdr_x:    .string "%s_pos_x,%s_vel_x,%s_acc_x,%s_jerk_x,"
fmt_hdr_y:    .string "%s_pos_y,%s_vel_y,%s_acc_y,%s_jerk_y,"
fmt_hdr_z_c:  .string "%s_pos_z,%s_vel_z,%s_acc_z,%s_jerk_z,"
fmt_hdr_z_nl: .string "%s_pos_z,%s_vel_z,%s_acc_z,%s_jerk_z\n"

fmt_val_comma: .string "%.17g,"
fmt_val_last:  .string "%.17g\n"

    .section .bss
    .align 3
ptr_F:      .skip 8
ptr_Q:      .skip 8
ptr_H:      .skip 8
ptr_Ht:     .skip 8
ptr_R:      .skip 8
ptr_X:      .skip 8
ptr_P:      .skip 8
ptr_Xp:     .skip 8
ptr_Pp:     .skip 8
ptr_S:      .skip 8
ptr_PHt:    .skip 8
ptr_K:      .skip 8
ptr_Kt:     .skip 8
ptr_Y:      .skip 8
ptr_IKH:    .skip 8
ptr_tmp1:   .skip 8
ptr_tmp2:   .skip 8
ptr_tmp3:   .skip 8
ptr_tmp4:   .skip 8
ptr_ycol:   .skip 8

fp_in:      .skip 8
fp_out:     .skip 8
frame_cnt:  .skip 8
first_frame:.skip 4
    .align 3
csv_line_buf: .skip 8192

    .section .text
    .align 2

    .globl main
    .type  main, @function
main:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s0, 48(sp)
    sd      s1, 40(sp)
    sd      s2, 32(sp)
    sd      s3, 24(sp)
    sd      s4, 16(sp)
    sd      s5,  8(sp)

    la      a0, msg_start
    call    printf

    la      a0, file_in
    la      a1, mode_r
    call    fopen
    beqz    a0, err_in
    la      t0, fp_in
    sd      a0, 0(t0)

    la      a0, file_out
    la      a1, mode_w
    call    fopen
    beqz    a0, err_out
    la      t0, fp_out
    sd      a0, 0(t0)

    call    alloc_matrices
    call    build_F
    call    build_Q
    call    build_H
    call    build_Ht
    call    build_R
    call    init_X
    call    init_P_identity
    call    write_header
    call    skip_header_line

    la      t0, frame_cnt
    sd      zero, 0(t0)
    la      t0, first_frame
    li      t1, 1
    sw      t1, 0(t0)

main_loop:
    call    read_csv_row
    beqz    a0, main_done

    la      t0, first_frame
    lw      t1, 0(t0)
    beqz    t1, do_filter

    call    init_X_from_Z
    la      t0, first_frame
    sw      zero, 0(t0)
    call    write_state_row
    j       main_increment

do_filter:

    la      a0, ptr_F;    ld a0, 0(a0)
    la      a1, ptr_X;    ld a1, 0(a1)
    la      a2, ptr_Xp;   ld a2, 0(a2)
    li      a3, 276
    li      a4, 276
    li      a5, 1
    call    matrix_mult

    la      a0, ptr_F;    ld a0, 0(a0)
    la      a1, ptr_P;    ld a1, 0(a1)
    la      a2, ptr_tmp1; ld a2, 0(a2)
    li      a3, 276
    li      a4, 276
    li      a5, 276
    call    matrix_mult

    la      a0, ptr_tmp1; ld a0, 0(a0)
    la      a1, ptr_F;    ld a1, 0(a1)
    la      a2, ptr_Pp;   ld a2, 0(a2)
    li      a3, 276
    li      a4, 276
    li      a5, 276
    call    matrix_mult_transB

    la      a0, ptr_Pp;   ld a0, 0(a0)
    la      a1, ptr_Q;    ld a1, 0(a1)
    la      a2, ptr_Pp;   ld a2, 0(a2)
    li      a3, 76176
    call    matrix_add_inplace_safe


    la      a0, ptr_Pp;   ld a0, 0(a0)
    la      a1, ptr_Ht;   ld a1, 0(a1)
    la      a2, ptr_PHt;  ld a2, 0(a2)
    li      a3, 276
    li      a4, 276
    li      a5, 69
    call    matrix_mult

    la      a0, ptr_H;    ld a0, 0(a0)
    la      a1, ptr_PHt;  ld a1, 0(a1)
    la      a2, ptr_S;    ld a2, 0(a2)
    li      a3, 69
    li      a4, 276
    li      a5, 69
    call    matrix_mult

    la      a0, ptr_S;    ld a0, 0(a0)
    la      a1, ptr_R;    ld a1, 0(a1)
    la      a2, ptr_S;    ld a2, 0(a2)
    li      a3, 4761
    call    matrix_add_inplace_safe

    la      a0, ptr_S;    ld a0, 0(a0)
    la      a1, ptr_PHt;  ld a1, 0(a1)
    la      a2, ptr_Kt;   ld a2, 0(a2)
    call    solve_cholesky_for_Kt

    la      a0, ptr_Kt;   ld a0, 0(a0)
    la      a1, ptr_K;    ld a1, 0(a1)
    li      a2, 69
    li      a3, 276
    call    matrix_transpose


    la      a0, ptr_H;    ld a0, 0(a0)
    la      a1, ptr_Xp;   ld a1, 0(a1)
    la      a2, ptr_tmp3; ld a2, 0(a2)
    li      a3, 69
    li      a4, 276
    li      a5, 1
    call    matrix_mult

    la      a0, ptr_Y;    ld a0, 0(a0)
    la      a1, ptr_tmp3; ld a1, 0(a1)
    la      a2, ptr_Y;    ld a2, 0(a2)
    li      a3, 69
    call    matrix_sub_inplace_safe

    la      a0, ptr_K;    ld a0, 0(a0)
    la      a1, ptr_Y;    ld a1, 0(a1)
    la      a2, ptr_tmp3; ld a2, 0(a2)
    li      a3, 276
    li      a4, 69
    li      a5, 1
    call    matrix_mult

    la      a0, ptr_Xp;   ld a0, 0(a0)
    la      a1, ptr_tmp3; ld a1, 0(a1)
    la      a2, ptr_X;    ld a2, 0(a2)
    li      a3, 276
    call    matrix_add


    la      a0, ptr_K;    ld a0, 0(a0)
    la      a1, ptr_H;    ld a1, 0(a1)
    la      a2, ptr_tmp1; ld a2, 0(a2)
    li      a3, 276
    li      a4, 69
    li      a5, 276
    call    matrix_mult

    la      a0, ptr_IKH;  ld a0, 0(a0)
    call    set_identity_276

    la      a0, ptr_IKH;  ld a0, 0(a0)
    la      a1, ptr_tmp1; ld a1, 0(a1)
    la      a2, ptr_IKH;  ld a2, 0(a2)
    li      a3, 76176
    call    matrix_sub_inplace_safe

    la      a0, ptr_IKH;  ld a0, 0(a0)
    la      a1, ptr_Pp;   ld a1, 0(a1)
    la      a2, ptr_tmp1; ld a2, 0(a2)
    li      a3, 276
    li      a4, 276
    li      a5, 276
    call    matrix_mult

    la      a0, ptr_tmp1; ld a0, 0(a0)
    la      a1, ptr_IKH;  ld a1, 0(a1)
    la      a2, ptr_tmp2; ld a2, 0(a2)
    li      a3, 276
    li      a4, 276
    li      a5, 276
    call    matrix_mult_transB

    la      a0, ptr_K;    ld a0, 0(a0)
    la      a1, ptr_R;    ld a1, 0(a1)
    la      a2, ptr_tmp3; ld a2, 0(a2)
    li      a3, 276
    li      a4, 69
    li      a5, 69
    call    matrix_mult

    la      a0, ptr_tmp3; ld a0, 0(a0)
    la      a1, ptr_K;    ld a1, 0(a1)
    la      a2, ptr_tmp1; ld a2, 0(a2)
    li      a3, 276
    li      a4, 69
    li      a5, 276
    call    matrix_mult_transB

    la      a0, ptr_tmp2; ld a0, 0(a0)
    la      a1, ptr_tmp1; ld a1, 0(a1)
    la      a2, ptr_P;    ld a2, 0(a2)
    li      a3, 76176
    call    matrix_add

    call    write_state_row

main_increment:
    la      t0, frame_cnt
    ld      t1, 0(t0)
    addi    t1, t1, 1
    sd      t1, 0(t0)
    li      t2, 100
    rem     t3, t1, t2
    bnez    t3, main_loop
    la      a0, msg_frame
    mv      a1, t1
    call    printf
    j       main_loop

main_done:
    la      t0, fp_in;  ld a0, 0(t0);  call fclose
    la      t0, fp_out; ld a0, 0(t0);  call fclose
    la      t0, frame_cnt;  ld a1, 0(t0)
    la      a0, msg_done
    call    printf
    li      a0, 0
    j       main_exit

err_in:
    la      a0, msg_err_in;  call printf
    li      a0, 1;  j main_exit

err_out:
    la      a0, msg_err_out; call printf
    li      a0, 1

main_exit:
    ld      ra, 56(sp)
    ld      s0, 48(sp)
    ld      s1, 40(sp)
    ld      s2, 32(sp)
    ld      s3, 24(sp)
    ld      s4, 16(sp)
    ld      s5,  8(sp)
    addi    sp, sp, 64
    ret

    .globl alloc_matrices
    .type  alloc_matrices, @function
alloc_matrices:
    addi    sp, sp, -16
    sd      ra, 8(sp)

    li a0,609408; call malloc; la t0,ptr_F;    sd a0,0(t0)
    li a0,609408; call malloc; la t0,ptr_Q;    sd a0,0(t0)
    li a0,152352; call malloc; la t0,ptr_H;    sd a0,0(t0)
    li a0,152352; call malloc; la t0,ptr_Ht;   sd a0,0(t0)
    li a0,38088;  call malloc; la t0,ptr_R;    sd a0,0(t0)
    li a0,2208;   call malloc; la t0,ptr_X;    sd a0,0(t0)
    li a0,609408; call malloc; la t0,ptr_P;    sd a0,0(t0)
    li a0,2208;   call malloc; la t0,ptr_Xp;   sd a0,0(t0)
    li a0,609408; call malloc; la t0,ptr_Pp;   sd a0,0(t0)
    li a0,38088;  call malloc; la t0,ptr_S;    sd a0,0(t0)
    li a0,152352; call malloc; la t0,ptr_PHt;  sd a0,0(t0)
    li a0,152352; call malloc; la t0,ptr_K;    sd a0,0(t0)
    li a0,152352; call malloc; la t0,ptr_Kt;   sd a0,0(t0)
    li a0,552;    call malloc; la t0,ptr_Y;    sd a0,0(t0)
    li a0,609408; call malloc; la t0,ptr_IKH;  sd a0,0(t0)
    li a0,609408; call malloc; la t0,ptr_tmp1; sd a0,0(t0)
    li a0,609408; call malloc; la t0,ptr_tmp2; sd a0,0(t0)
    li a0,152352; call malloc; la t0,ptr_tmp3; sd a0,0(t0)
    li a0,38088;  call malloc; la t0,ptr_tmp4; sd a0,0(t0)
    li a0,552;    call malloc; la t0,ptr_ycol; sd a0,0(t0)

    ld      ra, 8(sp)
    addi    sp, sp, 16
    ret

    .globl zero_matrix_n
    .type  zero_matrix_n, @function
zero_matrix_n:
    addi    sp, sp, -16
    sd      s0,  8(sp)
    sd      s1,  0(sp)

    mv      s0, a0
    mv      s1, a1
    fcvt.d.w ft0, zero
    li      t0, 0
zm_loop:
    bge     t0, s1, zm_done
    slli    t1, t0, 3
    add     t2, s0, t1
    fsd     ft0, 0(t2)
    addi    t0, t0, 1
    j       zm_loop
zm_done:
    ld      s0,  8(sp)
    ld      s1,  0(sp)
    addi    sp, sp, 16
    ret

    .globl build_F
    .type  build_F, @function
build_F:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      s0, 32(sp)
    sd      s1, 24(sp)
    sd      s2, 16(sp)

    la      s0, ptr_F;  ld s0, 0(s0)

    mv      a0, s0;  li a1, 76176
    call    zero_matrix_n

    la      t0, const_dt;    fld ft1, 0(t0)
    la      t0, const_dt2;   fld ft2, 0(t0)
    la      t0, const_half;  fld ft3, 0(t0)
    fmul.d  ft2, ft2, ft3
    la      t0, const_dt3;   fld ft3, 0(t0)
    la      t0, const_sixth; fld ft4, 0(t0)
    fmul.d  ft3, ft3, ft4
    la      t0, const_one;   fld ft4, 0(t0)

    li      s1, 0
bF_joint:
    li      t5, 23;  bge s1, t5, bF_done
    li      s2, 0
bF_axis:
    li      t5, 3;  bge s2, t5, bF_axis_done

    li      t0, 12;  mul t0, s1, t0
    li      t1,  4;  mul t1, s2, t1
    add     t0, t0, t1

    li      t2, 276

    mul     t3, t0, t2;  add t3, t3, t0;  slli t3, t3, 3;  add t4, s0, t3;  fsd ft4, 0(t4)
    mul     t3, t0, t2;  addi t6, t0, 1;  add t3, t3, t6;  slli t3, t3, 3;  add t4, s0, t3;  fsd ft1, 0(t4)
    mul     t3, t0, t2;  addi t6, t0, 2;  add t3, t3, t6;  slli t3, t3, 3;  add t4, s0, t3;  fsd ft2, 0(t4)
    mul     t3, t0, t2;  addi t6, t0, 3;  add t3, t3, t6;  slli t3, t3, 3;  add t4, s0, t3;  fsd ft3, 0(t4)
    addi    t5, t0, 1
    mul     t3, t5, t2;  add t3, t3, t5;  slli t3, t3, 3;  add t4, s0, t3;  fsd ft4, 0(t4)
    addi    t5, t0, 1;  addi t6, t0, 2
    mul     t3, t5, t2;  add t3, t3, t6;  slli t3, t3, 3;  add t4, s0, t3;  fsd ft1, 0(t4)
    addi    t5, t0, 1;  addi t6, t0, 3
    mul     t3, t5, t2;  add t3, t3, t6;  slli t3, t3, 3;  add t4, s0, t3;  fsd ft2, 0(t4)
    addi    t5, t0, 2
    mul     t3, t5, t2;  add t3, t3, t5;  slli t3, t3, 3;  add t4, s0, t3;  fsd ft4, 0(t4)
    addi    t5, t0, 2;  addi t6, t0, 3
    mul     t3, t5, t2;  add t3, t3, t6;  slli t3, t3, 3;  add t4, s0, t3;  fsd ft1, 0(t4)
    addi    t5, t0, 3
    mul     t3, t5, t2;  add t3, t3, t5;  slli t3, t3, 3;  add t4, s0, t3;  fsd ft4, 0(t4)

    addi    s2, s2, 1;  j bF_axis
bF_axis_done:
    addi    s1, s1, 1;  j bF_joint
bF_done:
    ld      ra, 40(sp)
    ld      s0, 32(sp)
    ld      s1, 24(sp)
    ld      s2, 16(sp)
    addi    sp, sp, 48
    ret

    .globl build_Q
    .type  build_Q, @function
build_Q:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      s0, 32(sp)
    sd      s1, 24(sp)
    sd      s2, 16(sp)
    sd      s3,  8(sp)
    sd      s4,  0(sp)

    la      s0, ptr_Q;  ld s0, 0(s0)
    mv      a0, s0;  li a1, 76176
    call    zero_matrix_n

    la      s1, q_block

    li      s2, 0
bQ_joint:
    li      t5, 23;  bge s2, t5, bQ_done
    li      s3, 0
bQ_axis:
    li      t5, 3;  bge s3, t5, bQ_axis_done

    li      t0, 12;  mul t0, s2, t0
    li      t1,  4;  mul t1, s3, t1
    add     t0, t0, t1

    li      s4, 0
bQ_r:
    li      t5, 4;  bge s4, t5, bQ_r_done
    li      a5, 0
bQ_c:
    li      t5, 4;  bge a5, t5, bQ_c_done

    li      t2, 4;  mul t3, s4, t2;  add t3, t3, a5
    slli    t3, t3, 3;  add t4, s1, t3
    fld     ft0, 0(t4)

    add     t2, t0, s4
    add     t3, t0, a5
    li      t4, 276
    mul     t5, t2, t4;  add t5, t5, t3
    slli    t5, t5, 3;  add t6, s0, t5
    fsd     ft0, 0(t6)

    addi    a5, a5, 1;  j bQ_c
bQ_c_done:
    addi    s4, s4, 1;  j bQ_r
bQ_r_done:
    addi    s3, s3, 1;  j bQ_axis
bQ_axis_done:
    addi    s2, s2, 1;  j bQ_joint
bQ_done:
    ld      s4,  0(sp)
    ld      s3,  8(sp)
    ld      ra, 40(sp)
    ld      s0, 32(sp)
    ld      s1, 24(sp)
    ld      s2, 16(sp)
    addi    sp, sp, 48
    ret

    .globl build_H
    .type  build_H, @function
build_H:
    addi    sp, sp, -16
    sd      ra,  8(sp)
    sd      s0,  0(sp)

    la      s0, ptr_H;  ld s0, 0(s0)
    mv      a0, s0;  li a1, 19044
    call    zero_matrix_n

    la      t6, const_one;  fld ft1, 0(t6)

    li      t0, 0
bH_joint:
    li      t5, 23;  bge t0, t5, bH_done

    li      t3, 276

    li      t1, 3;  mul t1, t0, t1
    li      t2, 12; mul t2, t0, t2
    mul     t4, t1, t3;  add t4, t4, t2;  slli t4, t4, 3;  add t4, s0, t4
    fsd     ft1, 0(t4)

    li      t1, 3;  mul t1, t0, t1;  addi t1, t1, 1
    li      t2, 12; mul t2, t0, t2;  addi t2, t2, 4
    mul     t4, t1, t3;  add t4, t4, t2;  slli t4, t4, 3;  add t4, s0, t4
    fsd     ft1, 0(t4)

    li      t1, 3;  mul t1, t0, t1;  addi t1, t1, 2
    li      t2, 12; mul t2, t0, t2;  addi t2, t2, 8
    mul     t4, t1, t3;  add t4, t4, t2;  slli t4, t4, 3;  add t4, s0, t4
    fsd     ft1, 0(t4)

    addi    t0, t0, 1;  j bH_joint
bH_done:
    ld      s0,  0(sp)
    ld      ra,  8(sp)
    addi    sp, sp, 16
    ret

    .globl build_Ht
    .type  build_Ht, @function
build_Ht:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    la      a0, ptr_H;   ld a0, 0(a0)
    la      a1, ptr_Ht;  ld a1, 0(a1)
    li      a2, 69
    li      a3, 276
    call    matrix_transpose
    ld      ra, 8(sp)
    addi    sp, sp, 16
    ret

    .globl build_R
    .type  build_R, @function
build_R:
    addi    sp, sp, -16
    sd      ra,  8(sp)
    sd      s0,  0(sp)

    la      s0, ptr_R;  ld s0, 0(s0)
    mv      a0, s0;  li a1, 4761
    call    zero_matrix_n

    la      t6, const_sigma_pos;  fld ft1, 0(t6)

    li      t0, 0
bR_diag:
    li      t5, 69;  bge t0, t5, bR_done
    li      t2, 69
    mul     t3, t0, t2;  add t3, t3, t0;  slli t3, t3, 3;  add t4, s0, t3
    fsd     ft1, 0(t4)
    addi    t0, t0, 1;  j bR_diag
bR_done:
    ld      s0,  0(sp)
    ld      ra,  8(sp)
    addi    sp, sp, 16
    ret

    .globl init_X
    .type  init_X, @function
init_X:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    la      a0, ptr_X;  ld a0, 0(a0)
    li      a1, 276
    call    zero_matrix_n
    ld      ra, 8(sp)
    addi    sp, sp, 16
    ret

    .globl init_P_identity
    .type  init_P_identity, @function
init_P_identity:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    la      a0, ptr_P;  ld a0, 0(a0)
    call    set_identity_276
    ld      ra, 8(sp)
    addi    sp, sp, 16
    ret

    .globl set_identity_276
    .type  set_identity_276, @function
set_identity_276:
    addi    sp, sp, -16
    sd      ra,  8(sp)
    sd      s0,  0(sp)

    mv      s0, a0

    li      a1, 76176
    call    zero_matrix_n

    la      t5, const_one;  fld ft1, 0(t5)

    li      t0, 0
sI_diag:
    li      t5, 276;  bge t0, t5, sI_done
    li      t2, 276
    mul     t3, t0, t2;  add t3, t3, t0;  slli t3, t3, 3;  add t4, s0, t3
    fsd     ft1, 0(t4)
    addi    t0, t0, 1;  j sI_diag
sI_done:
    ld      s0,  0(sp)
    ld      ra,  8(sp)
    addi    sp, sp, 16
    ret

    .globl init_X_from_Z
    .type  init_X_from_Z, @function
init_X_from_Z:
    addi    sp, sp, -16
    sd      ra,  8(sp)
    sd      s0,  0(sp)

    la      t0, ptr_X;  ld t0, 0(t0)
    la      t1, ptr_Y;  ld t1, 0(t1)

    li      s0, 0
iXZ_loop:
    li      t5, 23;  bge s0, t5, iXZ_done

    li      t2, 3;  mul t3, s0, t2;  slli t4, t3, 3;  add t4, t1, t4
    fld     ft0,  0(t4)
    fld     ft1,  8(t4)
    fld     ft2, 16(t4)

    li      t2, 12; mul t3, s0, t2;  slli t4, t3, 3;  add t4, t0, t4
    fsd     ft0,  0(t4)
    fsd     ft1, 32(t4)
    fsd     ft2, 64(t4)

    addi    s0, s0, 1;  j iXZ_loop
iXZ_done:
    ld      s0,  0(sp)
    ld      ra,  8(sp)
    addi    sp, sp, 16
    ret

    .globl skip_header_line
    .type  skip_header_line, @function
skip_header_line:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    la      a0, csv_line_buf
    li      a1, 8192
    la      a2, fp_in;  ld a2, 0(a2)
    call    fgets
    ld      ra, 8(sp)
    addi    sp, sp, 16
    ret

    .globl write_header
    .type  write_header, @function
write_header:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s0, 16(sp)
    sd      s1,  8(sp)

    la      t0, fp_out;  ld s0, 0(t0)
    li      s1, 0

wh_loop:
    li      t5, 23;  bge s1, t5, wh_done

    la      t0, bone_table;  slli t1, s1, 3;  add t0, t0, t1;  ld t2, 0(t0)
    mv      a0, s0;  la a1, fmt_hdr_x
    mv      a2, t2;  mv a3, t2;  mv a4, t2;  mv a5, t2
    call    fprintf

    la      t0, bone_table;  slli t1, s1, 3;  add t0, t0, t1;  ld t2, 0(t0)
    mv      a0, s0;  la a1, fmt_hdr_y
    mv      a2, t2;  mv a3, t2;  mv a4, t2;  mv a5, t2
    call    fprintf

    la      t0, bone_table;  slli t1, s1, 3;  add t0, t0, t1;  ld t2, 0(t0)
    addi    t3, s1, 1;  li t4, 23
    beq     t3, t4, wh_z_last
    mv      a0, s0;  la a1, fmt_hdr_z_c
    mv      a2, t2;  mv a3, t2;  mv a4, t2;  mv a5, t2
    call    fprintf
    addi    s1, s1, 1;  j wh_loop

wh_z_last:
    mv      a0, s0;  la a1, fmt_hdr_z_nl
    mv      a2, t2;  mv a3, t2;  mv a4, t2;  mv a5, t2
    call    fprintf
    addi    s1, s1, 1;  j wh_loop

wh_done:
    ld      s1,  8(sp)
    ld      s0, 16(sp)
    ld      ra, 24(sp)
    addi    sp, sp, 32
    ret

    .globl read_csv_row
    .type  read_csv_row, @function
read_csv_row:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      s0, 32(sp)
    sd      s1, 24(sp)
    sd      s2, 16(sp)

    la      a0, csv_line_buf
    li      a1, 8192
    la      a2, fp_in;  ld a2, 0(a2)
    call    fgets
    beqz    a0, rcr_eof

    la      s0, csv_line_buf
    la      s1, ptr_Y;  ld s1, 0(s1)
    li      s2, 0

rcr_loop:
    li      t4, 69;  bge s2, t4, rcr_ok

    mv      a0, s0
    addi    a1, sp, 0
    call    strtod

    slli    t3, s2, 3;  add t3, s1, t3
    fsd     fa0, 0(t3)

    ld      s0, 0(sp)
    lb      t3, 0(s0)
    li      t4, 44
    bne     t3, t4, rcr_advance
    addi    s0, s0, 1
rcr_advance:
    addi    s2, s2, 1;  j rcr_loop

rcr_ok:  li a0, 1;  j rcr_ret
rcr_eof: li a0, 0
rcr_ret:
    ld      s2, 16(sp)
    ld      s1, 24(sp)
    ld      s0, 32(sp)
    ld      ra, 40(sp)
    addi    sp, sp, 48
    ret

    .globl write_state_row
    .type  write_state_row, @function
write_state_row:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s0, 16(sp)
    sd      s1,  8(sp)
    sd      s2,  0(sp)

    la      s0, ptr_X;   ld s0, 0(s0)
    la      t0, fp_out;  ld s1, 0(t0)
    li      s2, 0

wsr_loop:
    li      t4, 276;  bge s2, t4, wsr_done

    slli    t3, s2, 3;  add t3, s0, t3
    fld     fa0, 0(t3)
    fmv.x.d a2, fa0

    mv      a0, s1
    addi    t4, s2, 1;  li t3, 276
    beq     t4, t3, wsr_last
    la      a1, fmt_val_comma
    call    fprintf
    j       wsr_inc
wsr_last:
    la      a1, fmt_val_last
    call    fprintf
wsr_inc:
    addi    s2, s2, 1;  j wsr_loop

wsr_done:
    ld      s2,  0(sp)
    ld      s1,  8(sp)
    ld      s0, 16(sp)
    ld      ra, 24(sp)
    addi    sp, sp, 32
    ret

    .globl matrix_transpose
    .type  matrix_transpose, @function
matrix_transpose:
    addi    sp, sp, -32
    sd      s0, 24(sp)
    sd      s1, 16(sp)
    sd      s2,  8(sp)
    sd      s3,  0(sp)

    mv      s0, a0;  mv s1, a1
    mv      s2, a2;  mv s3, a3

    li      t0, 0
mt_i:
    bge     t0, s2, mt_done
    li      t1, 0
mt_j:
    bge     t1, s3, mt_i_inc
    mul     t2, t0, s3;  add t2, t2, t1;  slli t2, t2, 3;  add t3, s0, t2;  fld ft0, 0(t3)
    mul     t2, t1, s2;  add t2, t2, t0;  slli t2, t2, 3;  add t3, s1, t2;  fsd ft0, 0(t3)
    addi    t1, t1, 1;  j mt_j
mt_i_inc:
    addi    t0, t0, 1;  j mt_i
mt_done:
    ld      s3,  0(sp)
    ld      s2,  8(sp)
    ld      s1, 16(sp)
    ld      s0, 24(sp)
    addi    sp, sp, 32
    ret

    .globl matrix_mult
    .type  matrix_mult, @function
matrix_mult:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s0, 48(sp)
    sd      s1, 40(sp)
    sd      s2, 32(sp)
    sd      s3, 24(sp)
    sd      s4, 16(sp)
    sd      s5,  8(sp)
    sd      s6,  0(sp)

    mv      s0, a0;  mv s1, a1;  mv s2, a2
    mv      s3, a3;  mv s4, a4;  mv s5, a5

    li      s6, 0
mm_i:
    bge     s6, s3, mm_end
    li      t6, 0
mm_j:
    bge     t6, s5, mm_i_inc
    fcvt.d.w ft0, zero
    li      t5, 0
mm_k:
    bge     t5, s4, mm_store
    mul     t0, s6, s4;  add t0, t0, t5;  slli t0, t0, 3;  add t1, s0, t0;  fld ft1, 0(t1)
    mul     t0, t5, s5;  add t0, t0, t6;  slli t0, t0, 3;  add t2, s1, t0;  fld ft2, 0(t2)
    fmadd.d ft0, ft1, ft2, ft0
    addi    t5, t5, 1;  j mm_k
mm_store:
    mul     t0, s6, s5;  add t0, t0, t6;  slli t0, t0, 3;  add t3, s2, t0
    fsd     ft0, 0(t3)
    addi    t6, t6, 1;  j mm_j
mm_i_inc:
    addi    s6, s6, 1;  j mm_i
mm_end:
    ld      s6,  0(sp)
    ld      s5,  8(sp)
    ld      s4, 16(sp)
    ld      s3, 24(sp)
    ld      s2, 32(sp)
    ld      s1, 40(sp)
    ld      s0, 48(sp)
    ld      ra, 56(sp)
    addi    sp, sp, 64
    ret

    .globl matrix_mult_transB
    .type  matrix_mult_transB, @function
matrix_mult_transB:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s0, 48(sp)
    sd      s1, 40(sp)
    sd      s2, 32(sp)
    sd      s3, 24(sp)
    sd      s4, 16(sp)
    sd      s5,  8(sp)
    sd      s6,  0(sp)

    mv      s0, a0;  mv s1, a1;  mv s2, a2
    mv      s3, a3;  mv s4, a4;  mv s5, a5

    li      s6, 0
mmtb_i:
    bge     s6, s3, mmtb_end
    li      t6, 0
mmtb_j:
    bge     t6, s5, mmtb_i_inc
    fcvt.d.w ft0, zero
    li      t5, 0
mmtb_k:
    bge     t5, s4, mmtb_store
    mul     t0, s6, s4;  add t0, t0, t5;  slli t0, t0, 3;  add t1, s0, t0;  fld ft1, 0(t1)
    mul     t0, t6, s4;  add t0, t0, t5;  slli t0, t0, 3;  add t2, s1, t0;  fld ft2, 0(t2)
    fmadd.d ft0, ft1, ft2, ft0
    addi    t5, t5, 1;  j mmtb_k
mmtb_store:
    mul     t0, s6, s5;  add t0, t0, t6;  slli t0, t0, 3;  add t3, s2, t0
    fsd     ft0, 0(t3)
    addi    t6, t6, 1;  j mmtb_j
mmtb_i_inc:
    addi    s6, s6, 1;  j mmtb_i
mmtb_end:
    ld      s6,  0(sp)
    ld      s5,  8(sp)
    ld      s4, 16(sp)
    ld      s3, 24(sp)
    ld      s2, 32(sp)
    ld      s1, 40(sp)
    ld      s0, 48(sp)
    ld      ra, 56(sp)
    addi    sp, sp, 64
    ret

    .globl matrix_add
    .type  matrix_add, @function
matrix_add:
    li      t0, 0
ma_loop:
    bge     t0, a3, ma_end
    slli    t1, t0, 3
    add     t2, a0, t1;  fld ft0, 0(t2)
    add     t3, a1, t1;  fld ft1, 0(t3)
    fadd.d  ft2, ft0, ft1
    add     t4, a2, t1;  fsd ft2, 0(t4)
    addi    t0, t0, 1;  j ma_loop
ma_end:
    ret

    .globl matrix_add_inplace_safe
    .type  matrix_add_inplace_safe, @function
matrix_add_inplace_safe:
    li      t0, 0
mais_loop:
    bge     t0, a3, mais_end
    slli    t1, t0, 3
    add     t2, a0, t1;  fld ft0, 0(t2)
    add     t3, a1, t1;  fld ft1, 0(t3)
    fadd.d  ft2, ft0, ft1
    add     t4, a2, t1;  fsd ft2, 0(t4)
    addi    t0, t0, 1;  j mais_loop
mais_end:
    ret

    .globl matrix_sub
    .type  matrix_sub, @function
matrix_sub:
    li      t0, 0
ms_loop:
    bge     t0, a3, ms_end
    slli    t1, t0, 3
    add     t2, a0, t1;  fld ft0, 0(t2)
    add     t3, a1, t1;  fld ft1, 0(t3)
    fsub.d  ft2, ft0, ft1
    add     t4, a2, t1;  fsd ft2, 0(t4)
    addi    t0, t0, 1;  j ms_loop
ms_end:
    ret

    .globl matrix_sub_inplace_safe
    .type  matrix_sub_inplace_safe, @function
matrix_sub_inplace_safe:
    li      t0, 0
msis_loop:
    bge     t0, a3, msis_end
    slli    t1, t0, 3
    add     t2, a0, t1;  fld ft0, 0(t2)
    add     t3, a1, t1;  fld ft1, 0(t3)
    fsub.d  ft2, ft0, ft1
    add     t4, a2, t1;  fsd ft2, 0(t4)
    addi    t0, t0, 1;  j msis_loop
msis_end:
    ret

    .globl solve_cholesky_for_Kt
    .type  solve_cholesky_for_Kt, @function
solve_cholesky_for_Kt:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s0, 48(sp)
    sd      s1, 40(sp)
    sd      s2, 32(sp)
    sd      s3, 24(sp)
    sd      s4, 16(sp)
    sd      s5,  8(sp)
    sd      s6,  0(sp)

    mv      s3, a0
    mv      s4, a1
    mv      s5, a2

    la      t0, ptr_tmp4;  ld s0, 0(t0)

    mv      a0, s0;  li a1, 4761
    call    zero_matrix_n

    la      t6, const_1e_neg12;  fld ft6, 0(t6)
    la      t6, const_1e_neg9;   fld ft7, 0(t6)

    li      s1, 0
chol_i:
    li      t5, 69;  bge s1, t5, chol_done
    li      s2, 0
chol_j:
    bgt     s2, s1, chol_j_done

    fcvt.d.w ft0, zero
    li      t0, 0
chol_k:
    bge     t0, s2, chol_k_done
    li      t1, 69
    mul     t2, s1, t1;  add t2, t2, t0;  slli t2, t2, 3;  add t3, s0, t2;  fld ft1, 0(t3)
    mul     t2, s2, t1;  add t2, t2, t0;  slli t2, t2, 3;  add t3, s0, t2;  fld ft2, 0(t3)
    fmadd.d ft0, ft1, ft2, ft0
    addi    t0, t0, 1;  j chol_k
chol_k_done:

    beq     s1, s2, chol_diag

    li      t1, 69
    mul     t2, s1, t1;  add t2, t2, s2;  slli t2, t2, 3;  add t3, s3, t2;  fld ft1, 0(t3)
    fsub.d  ft1, ft1, ft0
    mul     t2, s2, t1;  add t2, t2, s2;  slli t2, t2, 3;  add t3, s0, t2;  fld ft2, 0(t3)
    fdiv.d  ft1, ft1, ft2
    mul     t2, s1, t1;  add t2, t2, s2;  slli t2, t2, 3;  add t3, s0, t2
    fsd     ft1, 0(t3)
    j       chol_j_inc

chol_diag:
    li      t1, 69
    mul     t2, s2, t1;  add t2, t2, s2;  slli t2, t2, 3;  add t3, s3, t2;  fld ft1, 0(t3)
    fsub.d  ft1, ft1, ft0
    flt.d   t4, ft1, ft6
    beqz    t4, chol_ok_sqrt
    fmv.d   ft1, ft7
chol_ok_sqrt:
    fsqrt.d ft1, ft1
    mul     t2, s2, t1;  add t2, t2, s2;  slli t2, t2, 3;  add t3, s0, t2
    fsd     ft1, 0(t3)

chol_j_inc:
    addi    s2, s2, 1;  j chol_j
chol_j_done:
    addi    s1, s1, 1;  j chol_i
chol_done:

    la      t0, ptr_ycol;  ld s2, 0(t0)

    li      s6, 0
ck_col:
    li      t5, 276;  bge s6, t5, ck_all_done

    li      t0, 0
ck_fwd:
    li      t5, 69;  bge t0, t5, ck_fwd_done

    fcvt.d.w ft0, zero
    li      t1, 0
ck_fwd_k:
    bge     t1, t0, ck_fwd_k_done
    li      t2, 69
    mul     t3, t0, t2;  add t3, t3, t1;  slli t3, t3, 3;  add t4, s0, t3;  fld ft1, 0(t4)
    slli    t3, t1, 3;  add t4, s2, t3;  fld ft2, 0(t4)
    fmadd.d ft0, ft1, ft2, ft0
    addi    t1, t1, 1;  j ck_fwd_k
ck_fwd_k_done:
    li      t2, 69
    mul     t3, s6, t2;  add t3, t3, t0;  slli t3, t3, 3;  add t4, s4, t3;  fld ft1, 0(t4)
    fsub.d  ft1, ft1, ft0
    mul     t3, t0, t2;  add t3, t3, t0;  slli t3, t3, 3;  add t4, s0, t3;  fld ft2, 0(t4)
    fdiv.d  ft1, ft1, ft2
    slli    t3, t0, 3;  add t4, s2, t3
    fsd     ft1, 0(t4)

    addi    t0, t0, 1;  j ck_fwd
ck_fwd_done:

    li      t0, 68
ck_bwd:
    li      t5, 0;  blt t0, t5, ck_bwd_done

    fcvt.d.w ft0, zero
    addi    t1, t0, 1
ck_bwd_k:
    li      t5, 69;  bge t1, t5, ck_bwd_k_done
    li      t2, 69
    mul     t3, t1, t2;  add t3, t3, t0;  slli t3, t3, 3;  add t4, s0, t3;  fld ft1, 0(t4)
    li      t2, 276
    mul     t3, t1, t2;  add t3, t3, s6;  slli t3, t3, 3;  add t4, s5, t3;  fld ft2, 0(t4)
    fmadd.d ft0, ft1, ft2, ft0
    addi    t1, t1, 1;  j ck_bwd_k
ck_bwd_k_done:
    slli    t3, t0, 3;  add t4, s2, t3;  fld ft1, 0(t4)
    fsub.d  ft1, ft1, ft0
    li      t2, 69
    mul     t3, t0, t2;  add t3, t3, t0;  slli t3, t3, 3;  add t4, s0, t3;  fld ft2, 0(t4)
    fdiv.d  ft1, ft1, ft2
    li      t2, 276
    mul     t3, t0, t2;  add t3, t3, s6;  slli t3, t3, 3;  add t4, s5, t3
    fsd     ft1, 0(t4)

    addi    t0, t0, -1;  j ck_bwd
ck_bwd_done:
    addi    s6, s6, 1;  j ck_col
ck_all_done:
    ld      s6,  0(sp)
    ld      s5,  8(sp)
    ld      s4, 16(sp)
    ld      s3, 24(sp)
    ld      s2, 32(sp)
    ld      s1, 40(sp)
    ld      s0, 48(sp)
    ld      ra, 56(sp)
    addi    sp, sp, 64
    ret
