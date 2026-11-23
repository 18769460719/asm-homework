; ct2.asm —— 观察 call/ret 前后 CS、IP、SP 的变化
; 每次打印一行：标签 + CS:IP + SP
; IP 取的是“call 压栈的返回地址”，也就是调用返回后要执行的那条指令的偏移。
; SP 取的是“call 之前”的栈顶，方便对比压栈/弹栈。

DATA    segment para public 'DATA'
    m1  db 'main entry        $'
    m2  db 'before near call  $'
    m3  db 'inside near proc  $'
    m4  db 'after  near call  $'
    m5  db 'before far  call  $'
    m6  db 'inside far proc   $'
    m7  db 'after  far  call  $'
    cmsg db '  CS:IP=$'
    smsg db '  SP=$'
    crlf db 0Dh,0Ah,'$'
DATA    ends

STACK   segment para stack 'STACK'
    db 512 dup(0)
STACK   ends

SEG1    segment para public 'CODE'
        assume cs:SEG1, ds:DATA, ss:STACK

start:
        mov ax, DATA
        mov ds, ax
        mov ax, STACK
        mov ss, ax
        mov sp, 512

        mov dx, offset m1
        call show_near

        mov dx, offset m2
        call show_near

        call near_proc

        mov dx, offset m4
        call show_near

        mov dx, offset m5
        call show_near

        call far ptr far_proc

        mov dx, offset m7
        call show_near

        mov ax, 4C00h
        int 21h

near_proc proc near
        push dx
        mov dx, offset m3
        call show_near
        pop dx
        ret
near_proc endp

; 打印当前（近过程内）的 CS、返回地址、调用前 SP
show_near proc near
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push si

        mov ah, 09h          ; DX 里是调用者给的标签
        int 21h

        mov bx, [bp+2]       ; 返回地址 = call 之后的 IP
        mov si, bp
        add si, 4            ; 调用前的 SP

        mov dx, offset cmsg
        mov ah, 09h
        int 21h

        mov ax, cs
        call hex4
        mov dl, ':'
        call putc
        mov ax, bx
        call hex4

        mov dx, offset smsg
        mov ah, 09h
        int 21h
        mov ax, si
        call hex4

        mov dx, offset crlf
        mov ah, 09h
        int 21h

        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret
show_near endp

putc proc near
        mov ah, 02h
        int 21h
        ret
putc endp

hex4 proc near
        push ax
        push bx
        push cx
        push dx
        mov bx, ax
        mov cx, 4
h4:
        rol bx, 1
        rol bx, 1
        rol bx, 1
        rol bx, 1
        mov dl, bl
        and dl, 0Fh
        cmp dl, 9
        jbe h4d
        add dl, 7
h4d:
        add dl, '0'
        call putc
        loop h4
        pop dx
        pop cx
        pop bx
        pop ax
        ret
hex4 endp

SEG1    ends

; ================= 第二个代码段 =================
SEG2    segment para public 'CODE'
        assume cs:SEG2

far_proc proc far
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push si
        push ds

        mov ax, seg DATA
        mov ds, ax

        mov si, bp
        add si, 6            ; 远调用前的 SP
        mov bx, [bp+2]       ; 返回 IP
        mov cx, [bp+4]       ; 返回 CS（调用者）

        mov dx, offset m6
        mov ah, 09h
        int 21h

        mov dx, offset cmsg
        mov ah, 09h
        int 21h

        mov ax, cs
        call hex4f
        mov dl, ':'
        mov ah, 02h
        int 21h
        mov ax, offset far_next
far_next:
        call hex4f

        mov dx, offset smsg
        mov ah, 09h
        int 21h
        mov ax, si
        call hex4f

        mov dx, offset crlf
        mov ah, 09h
        int 21h

        pop ds
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret
far_proc endp

hex4f proc near
        push ax
        push bx
        push cx
        push dx
        mov bx, ax
        mov cx, 4
h4f:
        rol bx, 1
        rol bx, 1
        rol bx, 1
        rol bx, 1
        mov dl, bl
        and dl, 0Fh
        cmp dl, 9
        jbe h4fd
        add dl, 7
h4fd:
        add dl, '0'
        mov ah, 02h
        int 21h
        loop h4f
        pop dx
        pop cx
        pop bx
        pop ax
        ret
hex4f endp

SEG2    ends
        end start

