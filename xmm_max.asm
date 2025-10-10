ones dd 1, 1, 1, 1

section .text
global xmm_max
default rel
bits 64
xmm_max:
    ; Set up stack frame
    PUSH RBP
    MOV RBP, RSP
    ADD RBP, 16

    SUB RCX, 8

    ; Initialize index to 0
    XOR RSI, RSI

    ; Get address in 5th parameter
    MOV RBX, [RBP+32]

    L1:     VMOVDQU YMM0, [RDX+RSI*4] ; A[i]
            VMOVDQU YMM1, [R8+RSI*4]  ; B[i]
            VMAXPS YMM0, YMM1
            VMOVDQU [R9+RSI*4], YMM0

            VCMPPS YMM2, YMM0, YMM1, 0
            VPAND YMM2, YMM2, [ones]
            VMOVDQU [RBX+RSI*4], YMM2

            ADD RSI, 4
            CMP RSI, RCX
            JL L1

    ADD RCX, 4

    ; handle boundary cases
    ; to avoid corrupting memory near the array

    L2:     MOVSS XMM0, [RDX+4*RSI]
            MOVSS XMM1, [R8+4*RSI]
            UCOMISS XMM0, XMM1
            JB LESS

            MOVSS [R9+4*RSI], XMM0
            MOV dword[RBX+4*RSI], 0
            JMP NEXT

    LESS:   MOVSS [R9+4*RSI], XMM1 
            MOV dword[RBX+4*RSI], 1

    NEXT:   INC RSI
            CMP RSI, RCX
            JL L2

    POP RBP
    RET