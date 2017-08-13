MACRO   PUSH( _data_, _ptr_)
        push    _data_, _ptr_
ENDMACRO

MACRO   PUSH2( _d0_,_d1_, _ptr_)
        push     _d0_,_ptr_
        push     _d1_,_ptr_
ENDMACRO

MACRO   PUSH3( _d0_,_d1_,_d2_, _ptr_)
        push     _d0_,_ptr_
        push     _d1_,_ptr_
        push     _d2_,_ptr_
ENDMACRO

MACRO   PUSH4( _d0_,_d1_,_d2_,_d3_, _ptr_)
        push     _d0_,_ptr_
        push     _d1_,_ptr_
        push     _d2_,_ptr_
        push     _d3_,_ptr_
ENDMACRO

MACRO   PUSH5( _d0_,_d1_,_d2_,_d3_, _d4_, _ptr_)
        push     _d0_,_ptr_
        push     _d1_,_ptr_
        push     _d2_,_ptr_
        push     _d3_,_ptr_
        push     _d4_,_ptr_
ENDMACRO

MACRO   POP( _data_, _ptr_)
        pop  _data_, _ptr_
ENDMACRO

MACRO   POP2( _d0_,_d1_, _ptr_)
        pop      _d1_, _ptr_
        pop      _d0_, _ptr_
ENDMACRO

MACRO   POP3( _d0_,_d1_,_d2_, _ptr_)
        pop      _d2_, _ptr_
        pop      _d1_, _ptr_
        pop      _d0_, _ptr_
ENDMACRO

MACRO   POP4( _d0_,_d1_,_d2_,_d3_, _ptr_)
        pop      _d3_, _ptr_
        pop      _d2_, _ptr_
        pop      _d1_, _ptr_
        pop      _d0_, _ptr_
ENDMACRO

MACRO   POP5( _d0_,_d1_,_d2_,_d3_, _d4_, _ptr_)
        pop      _d4_, _ptr_
        pop      _d3_, _ptr_
        pop      _d2_, _ptr_
        pop      _d1_, _ptr_
        pop      _d0_, _ptr_
ENDMACRO

MACRO   CLC()
        c.add r0,r0
ENDMACRO

MACRO   SEC()
        nc.dec r0,1
ENDMACRO

MACRO   ASL( _reg_)
        add _reg_,_reg_
ENDMACRO

MACRO   ROL( _reg_)
        adc _reg_,_reg_
ENDMACRO

MACRO   NEG( _reg_)
        not _reg_,_reg_
        inc _reg_, 1
ENDMACRO

MACRO   NEG2( _regmsw_, _reglsw_)
        not _reglsw_,_reglsw_
        not _regmsw_,_regmsw_
        inc _reglsw_, 1
        adc _regmsw_, r0
ENDMACRO

# --------------------------------------------------------------
#
# __mulu
#
# Multiply 2 16 bit numbers to yield a 32b result
#
# Entry:
#       r1    16 bit multiplier (A)
#       r2    16 bit multiplicand (B)
#       r13   holds return address
#       r14   is global stack pointer
# Exit
#       r3    upwards preserved
#       r1,r2 holds 32b result (LSB in r1)
#
#
#   A = |___r3___|____r1____|  (lsb)
#   B = |___r2___|____0_____|  (lsb)
#
#   NB no need to actually use a zero word for LSW of B - just skip
#   additions of A_L + B_L and use R2 in addition of A_H + B_H
# --------------------------------------------------------------
__mulu:
        PUSH2   (r3, r4, r14)
                                    # Get B into [r2,-]
        mov     r3, r0              # Get A into [r3,r1]
        mov     r4, r0, -16         # Setup a loop counter
        add     r0, r0              # Clear carry outside of loop - reentry from bottom will always have carry clear
mulstep16:
        ror     r3, r3              # Shift right A
        ror     r1, r1
        c.add   r3, r2              # Add [r2,-] + [r3,r1] if carry
        inc     r4, 1               # increment counter
        nz.mov  pc, r0, mulstep16   # next iteration if not zero
        add     r0, r0              # final shift needs clear carry
        ror     r3, r3
        ror     r1, r1

        POP2    (r3, r4, r14)
        mov     pc, r13             # and return


# --------------------------------------------------------------
#
# __modu
#
# Divide a 16 bit number by a 16 bit number to yield a 16 b quotient and
# remainder
#
# Entry:
# - r1 16 bit dividend (A)
# - r2 16 bit divisor (B)
# - r13 holds return address
# - r14 is global stack pointer
# Exit
# - r3  upwards preserved
# - r1 = remainder
# - r2 = trashed
# --------------------------------------------------------------

__modu:
    PUSH    (r13, r14)
    jsr     r13, r0, divmod
    mov     r1, r2
    POP     (r13, r14)
    mov     pc, r13

# --------------------------------------------------------------
#
# __div
#
# Divide a 16 bit number by a 16 bit number to yield a 16 b quotient and
# remainder
#
# Entry:
# - r1 16 bit dividend (A)
# - r2 16 bit divisor (B)
# - r13 holds return address
# - r14 is global stack pointer
# Exit
# - r3  upwards preserved
# - r1 = quotient
# - r2 = remainder
# --------------------------------------------------------------

__divu:

divmod:
        PUSH3   (r3, r4, r5, r14)

        mov     r3, r2              # Get divisor into r3
        mov     r2, r0              # Get dividend/quotient into double word r1,2
        mov     r4, r0, udiv16_loop # Stash loop target in r4
        mov     r5, r0, -16         # Setup a loop counter
udiv16_loop:
        ASL     (r1)                # shift left the quotient/dividend
        ROL     (r2)                #
        cmp     r2, r3              # check if quotient is larger than divisor
        c.sub   r2, r3              # if yes then do the subtraction for real
        c.adc   r1, r0              # ... set LSB of quotient using (new) carry
        inc     r5, 1               # increment loop counter zeroing carry
        nz.mov  pc, r4              # loop again if not finished (r5=udiv16_loop)

        POP3    (r3, r4, r5, r14)
        mov     pc,r13              # and return with quotient/remainder in r1/r2

# --------------------------------------------------------------
#
# __mulu32
#
# Entry:
#       r1, r2 hold 32 bit multiplier (A), LSB in r1
#       r3, r4 hold 32 bit multiplicand (B), LSB in r3
#       r13 holds return address
#       (r14 is global stack pointer)
# Exit
#       r1, r2, r3, r4 hold 64-bit result of A * B
# --------------------------------------------------------------

__mulu32:
        PUSH5   (r5, r6, r7, r8, r9, r14)
        mov     r8, r4              # Get B into r7,r8 (pre-shifted)
        mov     r7, r3
        mov     r6, r0
        mov     r5, r0
        mov     r4, r0              # Get A into r1..r4
        mov     r3, r0
        mov     r9, r0,-32          # Setup a loop counter
mulstep32:
        lsr     r4, r4
        ror     r3, r3
        ror     r2, r2
        ror     r1, r1
        nc.inc  pc, mcont-PC
        add     r1, r5
        adc     r2, r6
        adc     r3, r7
        adc     r4, r8
mcont:  inc     r9, 1               # increment counter
        nz.dec  pc, PC-mulstep32    # next iteration if not zero
        lsr     r4, r4
        ror     r3, r3
        ror     r2, r2
        ror     r1, r1
        POP5    (r5, r6, r7, r8, r9, r14)
        mov     pc, r13             # and return

# --------------------------------------------------------------
#
# __modu32
#
# Divide a 32 bit number by a 32 bit number to yield a 32 b quotient and
# remainder
#
# Entry:
# - r1,2 hold 32 bit dividend (A), LSB in r1
# - r3,4 hold 32 bit divisor (B), LSB in r3
# - r13 holds return address
#   (r14 is global stack pointer)
# Exit
# - r5  upwards preserved
# - r1,2 = remainder
# - r3,4 = trashed
# --------------------------------------------------------------

__modu32:
        PUSH    (r13, r14)
        jsr     r13, r0, divmod32
        mov     r1, r3
        mov     r2, r4
        POP     (r13, r14)
        mov     pc, r13

# --------------------------------------------------------------
#
# __divu32
#
# Divide a 32 bit number by a 32 bit number to yield a 32 b quotient and
# remainder
#
# Entry:
# - r1,2 hold 32 bit dividend (A), LSB in r1
# - r3,4 hold 32 bit divisor (B), LSB in r3
# - r13 holds return address
#   (r14 is global stack pointer)
# Exit
# - r5  upwards preserved
# - r1,2 = quotient
# - r3,4 = remainder
# --------------------------------------------------------------

__divu32:

divmod32:
        PUSH3   (r5, r6, r7, r14)
        mov     r5, r3              # Get divisor into r5,r6
        mov     r6, r4
        mov     r4, r0              # Get divident/quotient into r1,2,3,4
        mov     r3, r0
        mov     r7, r0,-32          # Setup a loop counter
udiv32_loop:
        # shift left the quotient/dividend
        ASL     (r1)
        ROL     (r2)
        ROL     (r3)
        ROL     (r4)
        # Check if quotient is larger than divisor
        cmp     r3, r5
        cmpc    r4, r6
        # If carry not set then dont copy the result and dont update the quotient
        nc.inc  pc, udiv32_next-PC
        sub     r3, r5
        sbc     r4, r6
        inc     r1, 1               # set LSB of quotient
udiv32_next:
        inc     r7, 1               # increment loop counter
        nz.dec  pc, PC-udiv32_loop  # loop again if not finished

        # remainder/quotient in r1,2,3,4
        POP3    (r5, r6, r7, r14)
        mov     pc,r13              # and return

# --------------------------------------------------------------
# Signed wrappers
#
# __mul
# __div
# __mod
# __mul32
# __div32
# __mod32
#
# For mul and div, the sign of the result depends on the sign of both arguments
# - the A for of the wrapper achieves this

# For mod, the sign of the result depends only on the sign of the first arguments
# - the B for of the wrapper achieves this
#

MACRO SW16A ( _sub_ )
      PUSH2   (r13, r5, r14)
      mov     r5, r0         # keep track of signs
      add     r1, r0
      pl.inc  pc, l1_@ - PC
      NEG     (r1)
      inc     r5, 1
l1_@:
      add     r2, r0
      pl.inc  pc, l2_@ - PC
      NEG     (r2)
      dec     r5, 1
l2_@:
      jsr     r13, r0, _sub_
      cmp     r5, r0
      z.inc   pc, l3_@ - PC
      NEG2    (r2, r1)
l3_@:
      POP2    (r13, r5, r14)
      mov     pc, r13
ENDMACRO


MACRO SW32A ( _sub_ )
      PUSH2   (r13, r5, r14)
      mov     r5, r0         # keep track of signs
      add     r2, r0
      pl.inc  pc, l1_@ - PC
      NEG2    (r2, r1)
      inc     r5, 1
l1_@:
      add     r4, r0
      pl.inc  pc, l2_@ - PC
      NEG2    (r4, r3)
      dec     r5, 1
l2_@:
      jsr     r13, r0, _sub_
      cmp     r5, r0
      z.inc   pc, l3_@ - PC
      NEG2    (r2, r1)
l3_@:
      POP2    (r13, r5, r14)
      mov     pc, r13
ENDMACRO

MACRO SW16B ( _sub_ )
      PUSH2   (r13, r5, r14)
      mov     r5, r0         # keep track of signs
      add     r1, r0
      pl.inc  pc, l1_@ - PC
      NEG     (r1)
      inc     r5, 1
l1_@:
      add     r2, r0
      pl.inc  pc, l2_@ - PC
      NEG     (r2)
#     dec     r5, 1          # the second arg sign has no impact on the result sign
l2_@:
      jsr     r13, r0, _sub_
      cmp     r5, r0
      z.inc   pc, l3_@ - PC
      NEG2    (r2, r1)
l3_@:
      POP2    (r13, r5, r14)
      mov     pc, r13
ENDMACRO


MACRO SW32B ( _sub_ )
      PUSH2   (r13, r5, r14)
      mov     r5, r0         # keep track of signs
      add     r2, r0
      pl.inc  pc, l1_@ - PC
      NEG2    (r2, r1)
      inc     r5, 1
l1_@:
      add     r4, r0
      pl.inc  pc, l2_@ - PC
      NEG2    (r4, r3)
#     dec     r5, 1          # the second arg sign has no impact on the result sign
l2_@:
      jsr     r13, r0, _sub_
      cmp     r5, r0
      z.inc   pc, l3_@ - PC
      NEG2    (r2, r1)
l3_@:
      POP2    (r13, r5, r14)
      mov     pc, r13
ENDMACRO

__mul:
      SR16A(__mulu)

__div:
      SR16A(__divu)

__mod:
      SR16B(__modu)

__mul32:
      SR32A(__mulu32)

__div32:
      SR32A(__divu32)

__mod32:
      SR32B(__modu32)
