; print.asm —— 作业7：输出模块
; 对外三个远过程：print_title / print_head / print_body
; 内部有近过程 putc、print_dec、print_year。
; 这里用宏 PUSHALL/POPALL 保护寄存器，用 NEWLINE 宏换行。

        include macros.inc

        extrn year:word, month:word, first:word, ndays:word
        extrn mnames:byte, crlf:byte, whead:byte

PRINT   segment para public 'CODE'
        assume cs:PRINT

; ---------------- 内部：输出 DL 中的一个字符 ----------------
putc proc near
        mov ah, 02h
        int 21h
        ret
putc endp

; ---------------- 内部：输出 AX（0-99），占 3 列右对齐 ----------------
print_dec proc near
        PUSHALL
        mov bx, ax
        cmp bx, 10
        jae pd_two

        mov dl, ' '
        call putc
        mov dl, ' '
        call putc
        mov dl, bl
        add dl, '0'
        call putc
        jmp pd_done

pd_two:
        mov dl, ' '
        call putc
        mov ax, bx
        xor dx, dx
        mov bx, 10
        div bx
        mov bl, dl
        mov dl, al
        add dl, '0'
        call putc
        mov dl, bl
        add dl, '0'
        call putc

pd_done:
        POPALL
        ret
print_dec endp

; ---------------- 内部：输出四位年份 ----------------
print_year proc near
        PUSHALL
        mov si, ax

        mov ax, si
        xor dx, dx
        mov bx, 1000
        div bx
        mov cx, dx
        mov dl, al
        add dl, '0'
        call putc

        mov ax, cx
        xor dx, dx
        mov bx, 100
        div bx
        mov cx, dx
        mov dl, al
        add dl, '0'
        call putc

        mov ax, cx
        xor dx, dx
        mov bx, 10
        div bx
        mov cx, dx
        mov dl, al
        add dl, '0'
        call putc

        mov dl, cl
        add dl, '0'
        call putc

        POPALL
        ret
print_year endp

; ---------------- 对外：标题 “2026  November” ----------------
; 参数在堆栈：[bp+6]=year, [bp+8]=month
        public print_title
print_title proc far
        push bp
        mov bp, sp
        PUSHALL

        mov ax, [bp+6]
        call print_year

        mov dl, ' '
        call putc
        mov dl, ' '
        call putc

        mov ax, [bp+8]
        dec ax
        mov bx, 9
        mul bx
        mov si, offset mnames
        add si, ax
        mov cx, 9
pt_name:
        mov dl, [si]
        cmp dl, ' '
        je pt_done
        call putc
        inc si
        dec cx
        jnz pt_name
pt_done:
        NEWLINE

        POPALL
        pop bp
        ret 4
print_title endp

; ---------------- 对外：星期表头 ----------------
        public print_head
print_head proc far
        push dx
        PRINTSTR whead
        NEWLINE
        pop dx
        ret
print_head endp

; ---------------- 对外：日历主体 ----------------
; 参数：[bp+6]=first, [bp+8]=ndays
        public print_body
print_body proc far
        push bp
        mov bp, sp
        PUSHALL

        mov cx, [bp+6]
        cmp cx, 0
        je pb_row
pb_blank:
        mov dl, ' '
        call putc
        mov dl, ' '
        call putc
        mov dl, ' '
        call putc
        dec cx
        jnz pb_blank

pb_row:
        mov cx, [bp+6]
        mov si, 1
        mov bx, [bp+8]
pb_loop:
        mov ax, si
        call print_dec
        inc si
        inc cx
        cmp cx, 7
        jne pb_next
        NEWLINE
        xor cx, cx
pb_next:
        dec bx
        jnz pb_loop

        cmp cx, 0
        je pb_done
        NEWLINE
pb_done:
        POPALL
        pop bp
        ret 4
print_body endp

PRINT   ends
        end
