; 作业2 part1：loop实现，打印小写字母，每行13个
data segment
    msg db ' $'
data ends

code segment
assume cs:code,ds:data
start:
    mov ax,data
    mov ds,ax

    mov bl,'a'
    mov cx,26

print_char:
    ;==== 先判断是否换行，再打印字符 ====
    push ax
    push dx
    push bx
    mov ax,26
    sub ax,cx   ; ax = 已经输出的个数
    mov dx,0
    mov bx,13
    div bx
    cmp ax,0
    jz no_newline ; 0个字符，不换行
    cmp dx,0
    jnz no_newline
    ; 换行
    mov dl,0ah
    mov ah,02h
    int 21h
    mov dl,0dh
    mov ah,02h
    int 21h
no_newline:
    pop bx
    pop dx
    pop ax

    ;输出字母
    mov dl,bl
    mov ah,02h
    int 21h

    ;输出空格
    mov dl,' '
    mov ah,02h
    int 21h

    inc bl
    loop print_char

    mov ah,4ch
    int 21h
code ends
end start
