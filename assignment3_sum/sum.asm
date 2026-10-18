; Course assignment 3: 1 + 2 + ... + 100
; Assembled with MASM 5.x and linked as a 16-bit DOS EXE.
; Output:
;   5050

.8086

data segment
    sum_data dw ?
    crlf     db 13,10,'$'
data ends

stack_seg segment stack
    db 128 dup(0)
stack_seg ends

code segment
assume cs:code, ds:data, ss:stack_seg

start:
    mov ax,data
    mov ds,ax

    ; Register storage: AX accumulates 1 + 2 + ... + 100.
    xor ax,ax
    mov cx,100
sum_loop:
    add ax,cx
    loop sum_loop

    ; Store the same result in a register, in the data segment, and on the stack.
    mov bx,ax
    mov sum_data,ax
    push ax

    ; Read it back from the stack and print the value kept in memory.
    pop dx
    mov ax,sum_data
    call print_dec

    lea dx,crlf
    mov ah,09h
    int 21h

    mov ax,4c00h
    int 21h

; Print the unsigned value in AX as decimal.
print_dec proc near
    push ax
    push bx
    push cx
    push dx

    mov bx,10
    xor cx,cx
divide_loop:
    xor dx,dx
    div bx
    push dx
    inc cx
    test ax,ax
    jnz divide_loop

write_loop:
    pop dx
    add dl,'0'
    mov ah,02h
    int 21h
    loop write_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_dec endp

code ends
end start
