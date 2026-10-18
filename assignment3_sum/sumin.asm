; Course assignment 3, part 2 (DOS 8.3-compatible file name: sumin.asm):
; Read an integer N (1..100) with DOS INT 21h/AH=0Ah,
; calculate 1 + 2 + ... + N, and print the decimal result.

.8086

data segment
    prompt      db 'Input N (1-100): $'
    invalid_msg db 'Invalid input. Please enter 1-100.',13,10,'$'
    result_msg  db 'Sum(1..N) = $'
    crlf        db 13,10,'$'
    sum_value   dw ?
    input_buffer db 5,0,6 dup(?)

IFDEF SELFTEST
    test_file   db 'TEST.OUT',0
    pass_text   db 'PASS',13,10
    fail_text   db 'FAIL',13,10
    result_ptr  dw ?
    result_len  dw ?
    test_handle dw ?
    case_1      db 4,1,'1',13
    case_10     db 5,2,'10',13
    case_100    db 4,3,'100',13
    case_0      db 4,1,'0',13
    case_101    db 4,3,'101',13
    case_1000   db 6,4,'1000',13
    case_empty  db 4,0,13
    case_bad    db 4,1,'A',13
ENDIF
data ends

stack_seg segment stack
    db 256 dup(0)
stack_seg ends

code segment
assume cs:code, ds:data, ss:stack_seg

IFDEF SELFTEST
jfail macro inverse_condition
    local no_fail
    &inverse_condition no_fail
    jmp test_fail
no_fail:
endm

start:
    mov ax,data
    mov ds,ax

    ; Valid case 1: N = 1, sum = 1.
    lea si,case_1+2
    mov cx,1
    call parse_number
    jfail jnc
    cmp bx,1
    jfail je
    call sum_to_n
    cmp ax,1
    jfail je

    ; Valid case 2: N = 10, sum = 55.
    lea si,case_10+2
    mov cx,2
    call parse_number
    jfail jnc
    cmp bx,10
    jfail je
    call sum_to_n
    cmp ax,55
    jfail je

    ; Valid case 3: N = 100, sum = 5050.
    lea si,case_100+2
    mov cx,3
    call parse_number
    jfail jnc
    cmp bx,100
    jfail je
    call sum_to_n
    cmp ax,5050
    jfail je

    ; Invalid cases: 0, 101, empty input, and a non-digit.
    lea si,case_0+2
    mov cx,1
    call parse_number
    jfail jc

    lea si,case_101+2
    mov cx,3
    call parse_number
    jfail jc

    lea si,case_1000+2
    mov cx,4
    call parse_number
    jfail jc

    lea si,case_empty+2
    xor cx,cx
    call parse_number
    jfail jc

    lea si,case_bad+2
    mov cx,1
    call parse_number
    jfail jc

    mov word ptr result_ptr,offset pass_text
    mov word ptr result_len,4
    jmp write_result

test_fail:
    mov word ptr result_ptr,offset fail_text
    mov word ptr result_len,4

write_result:
    mov ah,3ch
    xor cx,cx
    lea dx,test_file
    int 21h
    jc test_exit
    mov test_handle,ax

    mov bx,ax
    mov cx,result_len
    mov dx,result_ptr
    mov ah,40h
    int 21h

    mov bx,test_handle
    mov ah,3eh
    int 21h

test_exit:
    mov ax,4c00h
    int 21h
ELSE
start:
    mov ax,data
    mov ds,ax

read_input:
    lea dx,prompt
    mov ah,09h
    int 21h

    mov ah,0ah
    lea dx,input_buffer
    int 21h

    lea dx,crlf
    mov ah,09h
    int 21h

    mov cl,input_buffer+1
    xor ch,ch
    lea si,input_buffer+2
    call parse_number
    jc invalid_input
    call sum_to_n

    mov sum_value,ax
    lea dx,result_msg
    mov ah,09h
    int 21h
    mov ax,sum_value
    call print_dec

    lea dx,crlf
    mov ah,09h
    int 21h
    mov ax,4c00h
    int 21h

invalid_input:
    lea dx,invalid_msg
    mov ah,09h
    int 21h
    jmp read_input
ENDIF

; Parse CX decimal digits at DS:SI.
; Output: BX = value and CF = 0 when the value is in 1..100.
;         CF = 1 for empty, non-digit, or out-of-range input.
parse_number proc near
    push ax
    push dx
    xor bx,bx
    test cx,cx
    jz parse_bad

parse_loop:
    mov al,[si]
    cmp al,'0'
    jb parse_bad
    cmp al,'9'
    ja parse_bad

    mov ah,0
    sub al,'0'
    push ax

    mov ax,bx
    mov dx,10
    mul dx
    mov bx,ax

    pop ax
    add bx,ax
    inc si
    loop parse_loop

    cmp bx,1
    jb parse_bad
    cmp bx,100
    ja parse_bad
    clc
    jmp parse_done

parse_bad:
    stc
parse_done:
    pop dx
    pop ax
    ret
parse_number endp

; Input: BX = N (1..100). Output: AX = 1 + 2 + ... + N.
sum_to_n proc near
    mov cx,bx
    xor ax,ax
sum_loop:
    add ax,cx
    loop sum_loop
    ret
sum_to_n endp

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
