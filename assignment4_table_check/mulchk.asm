; Course assignment 4, part 2: check a 9x9 multiplication table
; MASM 5.x, 16-bit DOS EXE.

.8086

data segment
    header_msg  db 'x y    result',13,10,'$'
    error_msg   db 'error',13,10,'$'
    done_msg    db 'accomplish!',13,10,'$'
    space_msg   db '    $'
    table_dim   dw 9
    row_limit   dw ?
    error_count dw 0

    ; The deliberately incorrect table shown in the assignment.
    table db 7,2,3,4,5,6,7,8,9
          db 2,4,7,8,10,12,14,16,18
          db 3,6,9,12,15,18,21,24,27
          db 4,8,12,16,7,24,28,32,36
          db 5,10,15,20,25,30,35,40,45
          db 6,12,18,24,30,7,42,48,54
          db 7,14,21,28,35,42,49,56,63
          db 8,16,24,32,40,48,56,7,72
          db 9,18,27,36,45,54,63,72,81
data ends

stack_seg segment stack
    db 256 dup(0)
stack_seg ends

code segment
assume cs:code, ds:data, ss:stack_seg

start:
    mov ax,data
    mov ds,ax

    lea dx,header_msg
    mov ah,09h
    int 21h

    ; Main procedure supplies the table base in SI and dimension in CX.
    lea si,table
    mov cx,table_dim
    call check_table

    lea dx,done_msg
    mov ah,09h
    int 21h
    mov ax,4c00h
    int 21h

; ------------------------------------------------------------
; check_table
; Input: SI = table base, CX = row/column count
; The procedure saves and restores every register it uses.
; ------------------------------------------------------------
check_table proc near
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov bp,si                 ; BP keeps the table base.
    mov row_limit,cx          ; Use the dimension supplied by main.
    mov di,1                  ; DI is the row number, 1..9.

row_loop:
    ; DS:SI points to the first element of the current row.
    mov si,bp
    mov ax,di
    dec ax
    mov dx,row_limit
    mul dx
    add si,ax

    mov bx,1                  ; BX is the column number, 1..9.
    mov cx,row_limit          ; Inner loop count.

column_loop:
    ; Load the byte stored at the current row and column.
    mov al,[si]
    xor ah,ah
    push ax                   ; Save the actual table value.

    ; Calculate the expected value: row * column.
    mov ax,di
    mul bl
    pop dx                    ; DX = actual table value.
    cmp ax,dx
    je next_item

    ; Print the row number.
    mov ax,di
    call print_unsigned

    mov dl,' '
    mov ah,02h
    int 21h

    ; Print the column number.
    mov ax,bx
    call print_unsigned

    lea dx,space_msg
    mov ah,09h
    int 21h

    lea dx,error_msg
    mov ah,09h
    int 21h
    inc error_count

next_item:
    inc si
    inc bx
    loop column_loop

    inc di
    cmp di,row_limit
    jbe row_loop

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
check_table endp

; ------------------------------------------------------------
; print_unsigned
; Input: AX = unsigned decimal value
; Preserves all registers used by its caller.
; ------------------------------------------------------------
print_unsigned proc near
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
print_unsigned endp

code ends
end start
