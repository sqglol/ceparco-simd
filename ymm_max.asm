ones dd 1, 1, 1, 1, 1, 1, 1, 1

section .text
global ymm_max
default rel
bits 64
ymm_max:
    ; Set up stack frame
    PUSH RBP
    MOV RBP, RSP
    ADD RBP, 16

    ; Initialize index to 0
    XOR RSI, RSI

    ; Get address in 5th parameter
    MOV RBX, [RBP+32]

    L1:     VMOVDQU YMM0, [RDX+RSI*4] ; A[i] ~ A[i + 8]
            VMOVDQU YMM1, [R8+RSI*4]  ; B[i] ~ B[i + 8]
            VMAXPS YMM0, YMM1
            VMOVDQU [R9+RSI*4], YMM0  ; C[i] ~ C[i + 8]

            ; Compare each element
            VCMPPS YMM2, YMM0, YMM1, 0
            VPAND YMM2, YMM2, [ones]
            VMOVDQU [RBX+RSI*4], YMM2

            ADD RSI, 8
            CMP RSI, RCX
            JL L1

    ADD RCX, 8

    POP RBP
    RET