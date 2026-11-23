; calc.asm —— 作业7：日期计算模块
; compute：算当月 1 号是星期几（0=周日）和当月天数，结果写回数据段。
; 内部把 1900 到 year-1 的天数“边加边 mod 7”，避免 16 位累加溢出。

        include macros.inc

        extrn year:word, month:word, first:word, ndays:word
        extrn mdays:byte

CALC    segment para public 'CODE'
        assume cs:CALC

; ---------------- 对外接口 ----------------
        public compute
compute proc far
        xor dx, dx                  ; dx = 天数 mod 7

        mov bx, 1900
cy_loop:
        cmp bx, year
        jae cy_done
        inc dx                      ; 平年 365 mod 7 = 1
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
        cmp word ptr month, 2
        jbe cm_noleap
        mov ax, year
        call is_leap
        cmp al, 0
        je cm_noleap
        inc dx
cm_noleap:
        inc dx                      ; 加上 1 号当天
        mov ax, dx
        xor dx, dx
        div bx
        mov first, dx

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

; ---------------- 内部过程：闰年判断 ----------------
; 入口 AX=年份，出口 AL=1 闰年 / 0 平年
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

CALC    ends
        end
