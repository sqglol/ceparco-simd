section .text
global x86_64_max
default rel
bits 64
x86_64_max:
    ; Set up stack frame
    PUSH RBP
    MOV RBP, RSP
    ADD RBP, 16

    ; Initialize index to 0
    XOR RSI, RSI

    ; Get address in 5th parameter
    MOV RBX, [RBP+32]

    L1:     MOVSS XMM0, [RDX+4*RSI] ; A[i]
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
            JL L1

    POP RBP

    RET