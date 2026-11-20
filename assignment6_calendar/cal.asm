; cal.asm —— 作业6：输出日历（1900-2099）
; 结构：两个代码段 CSEG1 / CSEG2，主程序在 CSEG1，打印过程在 CSEG2，
;       段间用 far call / retf 调用，参数分别用寄存器、数据段、堆栈三种方式传递。
; 汇编：MASM 5.0    链接：LINK 3.60   运行：DOSBox

DATA segment para public 'DATA'
    year    dw 0
    month   dw 0
    first   dw 0                ; 当月1号是星期几（0=周日）
    ndays   dw 0                ; 当月天数

    ; 12 个月名，每个固定 9 字节，方便用“序号*9”算偏移
    mnames  db 'January  '
            db 'February '
            db 'March    '
            db 'April    '
            db 'May      '
            db 'June     '
            db 'July     '
            db 'August   '
            db 'September'
            db 'October  '
            db 'November '
            db 'December '

    mdays   db 31,28,31,30,31,30,31,31,30,31,30,31

    p_year  db 'Please input year (1900-2099): $'
    p_mon   db 'Please input month (1-12): $'
    badmsg  db 0Dh,0Ah,'Invalid input, try again.',0Dh,0Ah,'$'
    crlf    db 0Dh,0Ah,'$'
    whead   db 'Su Mo Tu We Th Fr Sa$'
DATA ends

STACK segment para stack 'STACK'
    db 2048 dup(0)
STACK ends

; ============================ 代码段 1：主流程 ============================
CSEG1 segment para public 'CODE'
    assume cs:CSEG1, ds:DATA, ss:STACK

start:
    mov ax, DATA
    mov ds, ax
    mov ax, STACK
    mov ss, ax
    mov sp, 2048

    call read_year              ; 参数走寄存器（AX/SI）
    call read_month
    call compute                ; 结果写回数据段的 year/month/first/ndays

    push month                  ; 堆栈传参：先 push 后一个参数
    push year
    call far ptr print_title_far

    call far ptr print_head_far

    push ndays
    push first
    call far ptr print_body_far

    mov ax, 4C00h
    int 21h

; ---------------- 读年份：逐字符读入，遇到回车结束 ----------------
read_year proc near
ry_again:
    mov dx, offset p_year
    mov ah, 09h
    int 21h

    xor si, si
    xor bp, bp
ry_loop:
    mov ah, 08h
    int 21h
    cmp al, 0Dh
    je ry_done
    cmp al, 0Ah
    je ry_loop
    cmp al, 1Ah
    je ry_done
    cmp al, '0'
    jb ry_loop
    cmp al, '9'
    ja ry_loop

    mov dl, al
    mov ah, 02h
    int 21h

    sub al, '0'
    xor ah, ah
    mov cx, ax
    mov ax, si
    mov bx, 10
    mul bx
    add ax, cx
    mov si, ax
    inc bp
    jmp ry_loop

ry_done:
    cmp bp, 0
    je ry_again
    cmp bp, 4
    jne ry_bad
    cmp si, 1900
    jb ry_bad
    cmp si, 2099
    ja ry_bad
    mov year, si
    mov dx, offset crlf
    mov ah, 09h
    int 21h
    ret

ry_bad:
    mov dx, offset badmsg
    mov ah, 09h
    int 21h
    jmp ry_again
read_year endp

; ---------------- 读月份：1-12 ----------------
read_month proc near
rm_again:
    mov dx, offset p_mon
    mov ah, 09h
    int 21h

    xor si, si
    xor bp, bp
rm_loop:
    mov ah, 08h
    int 21h
    cmp al, 0Dh
    jne rm_notcr
    cmp bp, 0
    je rm_loop                  ; 空行（行尾残留的回车）直接跳过
    jmp rm_done
rm_notcr:
    cmp al, 0Ah
    je rm_loop
    cmp al, 1Ah
    je rm_eof
    cmp al, '0'
    jb rm_loop
    cmp al, '9'
    ja rm_loop

    mov dl, al
    mov ah, 02h
    int 21h

    sub al, '0'
    xor ah, ah
    mov cx, ax
    mov ax, si
    mov bx, 10
    mul bx
    add ax, cx
    mov si, ax
    inc bp
    jmp rm_loop

rm_eof:
    cmp bp, 0
    je rm_bad
rm_done:
    cmp si, 1
    jb rm_bad
    cmp si, 12
    ja rm_bad
    mov month, si
    mov dx, offset crlf
    mov ah, 09h
    int 21h
    ret

rm_bad:
    mov dx, offset badmsg
    mov ah, 09h
    int 21h
    jmp rm_again
read_month endp


; ---------------- 计算：1号星期几 + 当月天数 ----------------
compute proc near
    ; 1) 累加 1900 到 year-1 的整年天数（只保留 mod 7，避免 16 位溢出）
    xor dx, dx                  ; dx = 天数 mod 7
    mov bx, 1900
cy_loop:
    cmp bx, year
    jae cy_done
    inc dx                      ; 365 mod 7 = 1
    mov ax, bx
    call is_leap
    cmp al, 0
    je cy_next
    inc dx                      ; 闰年 366 mod 7 = 2
cy_next:
    cmp dx, 7
    jb cy_ok
    sub dx, 7
cy_ok:
    inc bx
    jmp cy_loop

cy_done:
    ; 2) 加上当年 1 月到 month-1 月的天数
    mov si, 0
    mov cx, month
    dec cx
    mov bx, 7
cm_loop:
    cmp si, cx
    jae cm_done
    mov al, mdays[si]
    xor ah, ah
    add dx, ax
    mov ax, dx
    xor dx, dx
    div bx
    inc si
    jmp cm_loop

cm_done:
    ; 3) 闰年且超过 2 月，补一天
    cmp word ptr month, 2
    jbe cm_noleap
    mov ax, year
    call is_leap
    cmp al, 0
    je cm_noleap
    inc dx
cm_noleap:
    ; 4) 再加“1号”这一天，mod 7 得星期（0=周日）
    inc dx
    mov ax, dx
    xor dx, dx
    div bx
    mov first, dx

    ; 5) 当月天数
    mov si, month
    dec si
    mov al, mdays[si]
    xor ah, ah
    mov ndays, ax
    cmp word ptr month, 2
    jne cd_done
    mov ax, year
    call is_leap
    cmp al, 0
    je cd_done
    inc ndays
cd_done:
    ret
compute endp

; ---------------- 闰年判断：入口 AX=年，出口 AL=1/0 ----------------
is_leap proc near
    push bx
    push cx
    push dx
    mov cx, ax

    mov ax, cx
    xor dx, dx
    mov bx, 400
    div bx
    cmp dx, 0
    je lp_yes

    mov ax, cx
    xor dx, dx
    mov bx, 100
    div bx
    cmp dx, 0
    je lp_no

    mov ax, cx
    xor dx, dx
    mov bx, 4
    div bx
    cmp dx, 0
    je lp_yes

lp_no:
    xor al, al
    jmp lp_end
lp_yes:
    mov al, 1
lp_end:
    pop dx
    pop cx
    pop bx
    ret
is_leap endp

CSEG1 ends

; ============================ 代码段 2：打印过程 ============================
CSEG2 segment para public 'CODE'
    assume cs:CSEG2, ds:DATA

; 输出 DL 中的一个字符
putc proc near
    mov ah, 02h
    int 21h
    ret
putc endp

; 输出 AX（0-99），固定占 3 列，右对齐
print_dec_far proc far
    push ax
    push bx
    push dx
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
    div bx                      ; ax=十位, dx=个位
    mov bl, dl                  ; 保存个位
    mov dl, al
    add dl, '0'
    call putc
    mov dl, bl
    add dl, '0'
    call putc

pd_done:
    pop dx
    pop bx
    pop ax
    ret
print_dec_far endp

; 输出 AX（1900-2099）的四位年份
print_year proc near
    push ax
    push bx
    push cx
    push dx
    push si
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

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_year endp

; 标题：<年>  <月名>，参数在堆栈：[bp+6]=year, [bp+8]=month
print_title_far proc far
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si

    mov ax, [bp+6]
    call print_year

    mov dl, ' '
    call putc
    mov dl, ' '
    call putc

    mov ax, [bp+8]
    dec ax
    mov bx, 9
    mul bx                      ; ax = 月名偏移
    mov si, offset mnames
    add si, ax
    mov cx, 9
pt_name:
    mov dl, [si]
    cmp dl, ' '                 ; 名字后面补的空格不打印
    je pt_done
    call putc
    inc si
    dec cx
    jnz pt_name
pt_done:
    mov dx, offset crlf
    mov ah, 09h
    int 21h

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 4
print_title_far endp

; 星期表头（无参数）
print_head_far proc far
    push dx
    mov dx, offset whead
    mov ah, 09h
    int 21h
    mov dx, offset crlf
    mov ah, 09h
    int 21h
    pop dx
    ret
print_head_far endp

; 日历主体，参数：[bp+6]=first, [bp+8]=ndays
print_body_far proc far
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si

    mov cx, [bp+6]              ; 前面要空几格
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
    mov cx, [bp+6]              ; 当前列
    mov si, 1                   ; 日期
    mov bx, [bp+8]              ; 当月天数

pb_loop:
    mov ax, si
    call far ptr print_dec_far

    inc si
    inc cx
    cmp cx, 7
    jne pb_next
    mov dx, offset crlf
    mov ah, 09h
    int 21h
    xor cx, cx
pb_next:
    dec bx
    jnz pb_loop

    cmp cx, 0
    je pb_done
    mov dx, offset crlf
    mov ah, 09h
    int 21h
pb_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 4
print_body_far endp

CSEG2 ends

end start
