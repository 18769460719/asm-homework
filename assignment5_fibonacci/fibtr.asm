; 作业题目 5：递归调用（斐波那契数列）
; MASM 5.0，16 位 DOS 程序
; 输入 n（0~100），输出 F(n)

.8086

WORDS   equ 6           ; 大数用 6 个万进制位组保存
MAXN    equ 100
ENTSZ   equ 12          ; 每个数占 6 个字 = 12 字节

data segment
    prompt      db 'n = $'
    bad_msg     db 13,10,'input error, n should be 0..100',13,10,'$'
    crlf        db 13,10,'$'
    res_msg     db 'F(n) = $'
    tr_call     db 'call n=$'
    tr_ret      db 'ret  n=$'
    sp_msg      db '  sp=$'
    inbuf       db 4, 0, 4 dup(0)

    cur_n       dw 0
    valid       db MAXN+1 dup(0)
    memo        dw (MAXN+1)*WORDS dup(0)
    divisors    dw 1000,100,10,1
data ends

stack_seg segment stack 'stack'
    db 4096 dup(0)      ; 栈开 4KB，够递归 100 层用
stack_seg ends

code segment
    assume cs:code, ds:data, ss:stack_seg

start:
    mov ax, data
    mov ds, ax

    lea dx, prompt
    mov ah, 09h
    int 21h

    ; 读一行，最多 3 位数字
    lea dx, inbuf
    mov ah, 0Ah
    int 21h

    lea dx, crlf
    mov ah, 09h
    int 21h

    mov cl, [inbuf+1]
    xor ch, ch
    cmp cx, 0
    je  bad_input
    cmp cx, 3
    ja  bad_input

    lea si, inbuf+2
    xor bx, bx
parse_loop:
    mov al, [si]
    sub al, '0'
    cmp al, 9
    ja  bad_input
    xor ah, ah
    push ax
    mov ax, bx
    mov dx, 10
    mul dx
    pop dx
    add ax, dx
    mov bx, ax
    inc si
    loop parse_loop

    cmp bx, MAXN
    ja  bad_input
    mov cur_n, bx

    mov ax, bx
    call fib

    lea dx, res_msg
    mov ah, 09h
    int 21h

    mov ax, cur_n
    mov cx, ENTSZ
    mul cx
    lea si, memo
    add si, ax
    call print_big

    lea dx, crlf
    mov ah, 09h
    int 21h

    mov ax, 4C00h
    int 21h

bad_input:
    lea dx, bad_msg
    mov ah, 09h
    int 21h
    mov ax, 4C01h
    int 21h

; ------------------------------------------------------------
; fib：递归计算 F(n)，结果写入 memo[n]
; 入口：AX = n
; 为了不做重复计算，算过的结果留在 memo 里，进来先查表
; ------------------------------------------------------------
fib proc near
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov bp, ax

    ; 临时调试输出：进入时打印 n 和 SP（正式版没有这几行）
    lea dx, tr_call
    mov ah, 09h
    int 21h
    mov ax, bp
    call print_trim
    lea dx, sp_msg
    mov ah, 09h
    int 21h
    mov ax, sp
    call print_hex16
    lea dx, crlf
    mov ah, 09h
    int 21h

    cmp bp, 1
    ja  fib_check

    ; n = 0 或 1，直接填表
    mov ax, bp
    mov cx, ENTSZ
    mul cx
    mov di, ax
    mov ax, bp
    mov memo[di], ax
    mov word ptr memo[di+2], 0
    mov word ptr memo[di+4], 0
    mov word ptr memo[di+6], 0
    mov word ptr memo[di+8], 0
    mov word ptr memo[di+10], 0
    mov di, bp
    mov byte ptr valid[di], 1
    jmp fib_ret

fib_check:
    mov di, bp
    cmp byte ptr valid[di], 1
    je  fib_ret

    ; 先算 F(n-1)，再算 F(n-2)
    mov ax, bp
    dec ax
    call fib

    mov ax, bp
    sub ax, 2
    call fib

    ; 三个偏移：bx 存结果，si 指向 n-1，di 指向 n-2
    mov ax, bp
    mov cx, ENTSZ
    mul cx
    mov bx, ax

    mov ax, bp
    dec ax
    mov cx, ENTSZ
    mul cx
    mov si, ax

    mov ax, bp
    sub ax, 2
    mov cx, ENTSZ
    mul cx
    mov di, ax

    xor dx, dx
    mov cx, WORDS
fib_add:
    mov ax, memo[si]
    add ax, memo[di]
    add ax, dx
    xor dx, dx
    cmp ax, 10000
    jb  fib_store
    sub ax, 10000
    mov dx, 1
fib_store:
    mov memo[bx], ax
    lea si, [si+2]
    lea di, [di+2]
    lea bx, [bx+2]
    loop fib_add

    mov di, bp
    mov byte ptr valid[di], 1

fib_ret:
    ; 临时调试输出：返回前再打印一次 SP
    push ax
    lea dx, tr_ret
    mov ah, 09h
    int 21h
    mov ax, bp
    call print_trim
    lea dx, sp_msg
    mov ah, 09h
    int 21h
    mov ax, sp
    call print_hex16
    lea dx, crlf
    mov ah, 09h
    int 21h
    pop ax
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
fib endp

; ------------------------------------------------------------
; print_big：打印 5 个字的无符号大数
; 入口：SI = 数值首地址（低字在前）
; ------------------------------------------------------------
print_big proc near
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di, WORDS-1
find_top:
    mov bx, di
    shl bx, 1
    add bx, si
    cmp word ptr [bx], 0
    jne got_top
    dec di
    jns find_top

    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp pb_ret

got_top:
    mov bx, di
    shl bx, 1
    add bx, si
    mov ax, [bx]
    call print_trim

    dec di
    js  pb_ret
next_word:
    mov bx, di
    shl bx, 1
    add bx, si
    mov ax, [bx]
    call print_4
    dec di
    jns next_word

pb_ret:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_big endp

; ------------------------------------------------------------
; print_trim：打印一个字，不补前导零
; 入口：AX = 非零值
; ------------------------------------------------------------
print_trim proc near
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    test ax, ax
    jnz pt_nonzero
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp pt_done
pt_nonzero:

    lea si, divisors
    mov cx, 4
    xor di, di
pt_loop:
    mov bx, [si]
    xor dx, dx
    div bx
    mov bx, ax
    or  di, bx
    jz  pt_skip
    push dx
    mov dl, bl
    add dl, '0'
    mov ah, 02h
    int 21h
    pop dx
pt_skip:
    mov ax, dx
    add si, 2
    loop pt_loop

pt_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_trim endp

; ------------------------------------------------------------
; print_4：打印一个字，固定 4 位（不足补零）
; 入口：AX = 值
; ------------------------------------------------------------
print_4 proc near
    push ax
    push bx
    push cx
    push dx
    push si

    lea si, divisors
    mov cx, 4
p4_loop:
    mov bx, [si]
    xor dx, dx
    div bx
    push dx
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    pop ax
    add si, 2
    loop p4_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_4 endp


print_hex16 proc near
    push ax
    push bx
    push cx
    push dx
    mov bx, ax
    mov cx, 4
ph_loop:
    rol bx, 1
    rol bx, 1
    rol bx, 1
    rol bx, 1
    mov dl, bl
    and dl, 0Fh
    cmp dl, 9
    jbe ph_digit
    add dl, 7
ph_digit:
    add dl, '0'
    mov ah, 02h
    int 21h
    loop ph_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_hex16 endp

code ends
end start


