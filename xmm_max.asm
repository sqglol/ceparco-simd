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
            
            ; Avoid "overshooting"
            MOV RAX, RCX
            SUB RAX, RSI
            JE FIN          ; If RSI == RCX, terminate
            CMP RAX, 4      ; If RCX - RSI < 8, handle boundary case
            JG L1
    
    ; This part is adapted from x86_64_max.asm
    ; Handles boundary cases when array size is not a perfect multiple of 4

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