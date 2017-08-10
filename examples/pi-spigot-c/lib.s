MACRO   ASL( _reg_)
        add _reg_,_reg_
ENDMACRO

MACRO   ROL( _reg_)
        adc _reg_,_reg_
ENDMACRO

MACRO   PUSH( _data_, _ptr_)
        push    _data_, _ptr_
ENDMACRO

MACRO   PUSH4( _d0_,_d1_,_d2_,_d3_, _ptr_)
        push     _d0_,_ptr_
        push     _d1_,_ptr_
        push     _d2_,_ptr_
        push     _d3_,_ptr_
ENDMACRO

MACRO   POP( _data_, _ptr_)
        pop  _data_, _ptr_
ENDMACRO

MACRO   POP4( _d0_,_d1_,_d2_,_d3_, _ptr_)
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

MACRO   ROL( _reg_ )
        adc   _reg_, _reg_
ENDMACRO
MACRO   LSL( _reg_ )
        add   _reg_, _reg_
ENDMACRO



# --------------------------------------------------------------
#
# mul16
#
# Multiply 2 16 bit numbers to yield a 32b result
#
# Entry:
#       r1    16 bit multiplier (A)
#       r2    16 bit multiplicand (B)
#       r13   holds return address
#       r14   is global stack pointer
# Exit
#       r6    upwards preserved
#       r3,r5 uses as workspace registers and trashed
#       r1,r2 holds 32b result (LSB in r1)
#
#
#   A = |___r3___|____r1____|  (lsb)
#   B = |___r2___|____0_____|  (lsb)
#
#   NB no need to actually use a zero word for LSW of B - just skip
#   additions of A_L + B_L and use R2 in addition of A_H + B_H
# --------------------------------------------------------------
__mul:
    PUSH    (r3, r14)
    PUSH    (r4, r14)
    PUSH    (r5, r14)
                                    # Get B into [r2,-]
    mov     r3,r0                   # Get A into [r3,r1]
    mov     r4,r0,-16               # Setup a loop counter
    mov     r5,r0,1                 # Constant 1 for incrementing
    add     r0,r0                   # Clear carry outside of loop - reentry from bottom will always have carry clear
mulstep16:
    ror     r3,r3                   # Shift right A
    ror     r1,r1
    c.add   r3,r2                   # Add [r2,-] + [r3,r1] if carry
    add     r4,r5                   # increment counter
    nz.mov  pc,r0,mulstep16         # next iteration if not zero
    add     r0,r0                   # final shift needs clear carry
    ror     r3,r3
    ror     r1,r1

    POP     (r5, r14)
    POP     (r4, r14)
    POP     (r3, r14)
    mov     pc,r13                  # and return


# --------------------------------------------------------------
#
# udiv16
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
# - r6  upwards preserved
# - r3-5 trashed
# - r2 = quotient
# - r1 = remainder
# --------------------------------------------------------------
__mod:
    PUSH    (r13, r14)
    jsr     r13, r0, divmod
    mov     r1, r2
    POP     (r13, r14)
    mov     pc, r13 

__div:
        
divmod:
    PUSH    (r3, r14)
    PUSH    (r4, r14)
    PUSH    (r5, r14)
        
    mov     r3,r2                   # Get divisor into r3
    mov     r2,r0                   # Get dividend/quotient into double word r1,2
    mov     r4,r0, udiv16_loop      # Stash loop target in r4
    mov     r5,r0,-16               # Setup a loop counter
udiv16_loop:
    ASL     (r1)                    # shift left the quotient/dividend
    ROL     (r2)                    #
    cmp     r2,r3                   # check if quotient is larger than divisor
    c.sub   r2,r3                   # if yes then do the subtraction for real
    c.adc   r1,r0                   # ... set LSB of quotient using (new) carry
    add     r5,r0,1                 # increment loop counter zeroing carry
    nz.mov  pc,r4                   # loop again if not finished (r5=udiv16_loop)
    POP     (r5, r14)
    POP     (r4, r14)
    POP     (r3, r14)
    mov     pc,r13                  # and return with quotient/remainder in r1/r2

        # --------------------------------------------------------------
        #
        # multiply32
        #
        # Entry:
        #       r1 points to block of two bytes holding 32 bit multiplier (A), LSB in lowest byte
        #       r2 points to block of two bytes holding 32 bit multiplicand (B), LSB in lowest byte
        #       r3 points to area of memory large enough to take the 4 byte result
        #       r13 holds return address
        #       (r14 is global stack pointer)
        # Exit
        #       r1..9 uses as workspace registers and trashed
        #       Result written to memory (see above)
        # --------------------------------------------------------------
x__mul32:
        PUSH    (r3, r14)
        
        ld      r8, r2, 1       # Get B into r7,r8 (pre-shifted)
        ld      r7, r2
        mov    r6, r0
        mov    r5, r0
        mov    r4, r0          # Get A into r1..r4
        mov    r3, r0
        ld      r2, r1, 1
        ld      r1, r1
        mov    r9, r0,-32      # Setup a loop counter
mulstep32:
        lsr   r4,r4
        ror   r3,r3
        ror   r2,r2
        ror   r1,r1
        nc.inc pc,mcont-PC
        add   r1,r5
        adc   r2,r6
        adc   r3,r7
        adc   r4,r8
mcont:  inc   r9,1                  # increment counter
        nz.dec pc,PC-mulstep32      # next iteration if not zero
        lsr   r4,r4
        ror   r3,r3
        ror   r2,r2
        ror   r1,r1
        POP     (r5, r14)
        sto     r1,r5,0         # save results
        sto     r2,r5,1
        sto     r3,r5,2
        sto     r4,r5,3
        mov    pc,r13          # and return

# --------------------------------------------------------------
#
# udiv32
#
# Divide a 32 bit number by a 32 bit number to yield a 32 b quotient and
# remainder
#
# Entry:
# - r1 points to block of two words holding 32 bit dividend (A), LSB in lowest word
# - r2 points to block of two words holding 32 bit divisor (B), LSB in lowest word
# - r3 points to area of memory large enough to take the 2 word quotient + 2 word remainder
# - r13 holds return address
#   (r14 is global stack pointer)
# Exit
# - r10-13 preserved, r1-9 trashed
# - Result written to memory (see above)
# --------------------------------------------------------------

x__div32:
        PUSH    (r13, r14)      # save return address
        PUSH    (r10, r14)   
        PUSH    (r3, r14)      
        ld      r6, r2          # Get divisor into r6,r7
        ld      r7, r2,1

        mov    r5, r0          # Get divident/quotient into r2,3,4,5
        mov    r4, r0
        ld      r3, r1,1
        ld      r2, r1

        mov    r1, r0, 1            # r1 = constant 1
        mov    r10, r0,-32          # Setup a loop counter
udiv32_loop:
        # shift left the quotient/dividend
        LSL(r2)
        ROL(r3)
        ROL(r4)
        ROL(r5)
        # Check if quotient is larger than divisor
        cmp    r4,r6
        cmpc   r5,r7
        # If carry not set then dont copy the result and dont update the quotient
        nc.inc  pc,udiv32_next-PC
        sub   r4,r6
        sbc   r5,r7
        inc   r2,1           # set LSB of quotient
udiv32_next:
        inc    r10, 1                # increment loop counter
        nz.dec pc, PC-udiv32_loop    # loop again if not finished
        # remainder/quotient in r2,3,4,5
        POP     (r1, r14)       # Get results pointer from stack
        sto     r2,r1,0         # save results
        sto     r3,r1,1
        sto     r4,r1,2
        sto     r5,r1,3
        # restore other registers
        POP     (r10, r14)
        POP     (r13, r14)        
        mov    pc,r13          # and return
#endif

