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

            ; Avoid "overshooting"
            MOV RAX, RCX
            SUB RAX, RSI
            JE FIN          ; If RSI == RCX, terminate
            CMP RAX, 8      ; If RCX - RSI < 8, handle boundary case
            JG L1
    
    ; This part is adapted from x86_64_max.asm
    ; Handles boundary cases when array size is not a perfect multiple of 4
    ; Use XMM register as we are only using a single value here

    L2:     MOVSS XMM0, [RDX+4*RSI] ; A[i]
            MOVSS XMM1, [R8+4*RSI]  ; B[i]
            UCOMISS XMM0, XMM1
            JB LESS

    ; Case when A[i] >= B[i]
            MOVSS [R9+4*RSI], XMM0
            MOV dword[RBX+4*RSI], 0
            JMP NEXT

    ; Case when A[i] < B[i]
    LESS:   MOVSS [R9+4*RSI], XMM1 
            MOV dword[RBX+4*RSI], 1

    NEXT:   INC RSI
            CMP RSI, RCX
            JL L2

    FIN:    POP RBP

    RET