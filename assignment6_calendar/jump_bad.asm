; jump_bad.asm -- negative example: conditional jump target is out of the 8-bit range
code segment
    assume cs:code
start:
    mov ax, 1
    cmp ax, 0
    je  target              ; target is ~200 bytes away, does not fit in rel8
    db 200 dup(90h)         ; 200 NOPs push target far away
target:
    mov ax, 4C00h
    int 21h
code ends
end start
