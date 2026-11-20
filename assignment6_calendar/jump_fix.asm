; jump_fix.asm -- fix: invert the condition and use a near jump (rel16)
stack segment stack stack
    db 256 dup(0)
stack ends

code segment
    assume cs:code, ss:stack
start:
    mov ax, 1
    cmp ax, 0
    jne short skip          ; inverted condition, only skips 3 bytes
    jmp near ptr target     ; near jump uses a 16-bit displacement (+/-32K)
skip:
    nop
    db 197 dup(90h)         ; filler, target still ~200 bytes away
target:
    mov ax, 4C00h
    int 21h
code ends
end start
