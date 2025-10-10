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

    ; Initialize index to 0
    XOR RSI, RSI

    ; Get address in 5th parameter
    MOV RBX, [RBP+32]

    L1:     VMOVDQU XMM0, [RDX+RSI*4] ; A[i] ~ A[i + 8]
            VMOVDQU XMM1, [R8+RSI*4]  ; B[i] ~ B[i + 8]
            VMAXPS XMM0, XMM1
            VMOVDQU [R9+RSI*4], XMM0  ; C[i] ~ C[i + 8]

            ; Compare each element
            VCMPPS XMM2, XMM0, XMM1, 0
            VPAND XMM2, XMM2, [ones]
            VMOVDQU [RBX+RSI*4], XMM2

            ADD RSI, 4
            CMP RSI, RCX
            JL L1

    ADD RCX, 4

    POP RBP
    RET