; input.asm —— 作业7：输入模块
; 提供两个远过程：read_year / read_month
; 两者都从键盘逐字符读，数字回显，回车结束；非法输入会提示重来。
; DS 由 main 设好，本模块只按 EXTRN 的偏移访问数据段。

        include macros.inc

        extrn year:word, month:word
        extrn p_year:byte, p_mon:byte, badmsg:byte, crlf:byte

INPUT   segment para public 'CODE'
        assume cs:INPUT

; ---------------- 读年份（1900-2099） ----------------
        public read_year
read_year proc far
ry_again:
        PRINTSTR p_year
        xor si, si                  ; si = 累加值
        xor bp, bp                  ; bp = 位数
ry_loop:
        mov ah, 08h                 ; 无回显读字符
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

        mov dl, al                  ; 回显数字
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
        NEWLINE
        ret
ry_bad:
        PRINTSTR badmsg
        jmp ry_again
read_year endp

; ---------------- 读月份（1-12） ----------------
        public read_month
read_month proc far
rm_again:
        PRINTSTR p_mon
        xor si, si
        xor bp, bp
rm_loop:
        mov ah, 08h
        int 21h
        cmp al, 0Dh
        jne rm_notcr
        cmp bp, 0
        je rm_loop                  ; 空行（行尾残留的回车）跳过
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
        NEWLINE
        ret
rm_bad:
        PRINTSTR badmsg
        jmp rm_again
read_month endp

INPUT   ends
        end
