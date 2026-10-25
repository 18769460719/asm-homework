; Course assignment 4: multiplication instruction and procedure calls
; Output the 9x9 multiplication table in descending rows.
; MASM 5.x, 16-bit DOS EXE.

.8086

data segment
    title_msg db 'The 9mul9 table:',13,10,'$'
    crlf      db 13,10,'$'
data ends

stack_seg segment stack
    db 256 dup(0)
stack_seg ends

code segment
assume cs:code, ds:data, ss:stack_seg

start:
    mov ax,data
    mov ds,ax

    lea dx,title_msg
    mov ah,09h
    int 21h

    ; Outer loop: BX is the current row, from 9 down to 1.
    mov bx,9
outer_loop:
    mov cx,bx                 ; Inner loop count equals the row number.
    call print_row            ; Procedure uses BX and CX from the main procedure.

    cmp bx,1
    je finished
    dec bx
    jmp outer_loop

finished:
    mov ax,4c00h
    int 21h

; ------------------------------------------------------------
; print_row
; Input: BX = row number, CX = number of columns in this row
; All registers changed by this procedure are saved and restored.
; ------------------------------------------------------------
print_row proc near
    push ax
    push bx
    push cx
    push dx
    push si

    mov si,1                  ; SI is the multiplier (column number).

row_loop:
    ; AX = BX * SI. MUL performs unsigned multiplication.
    mov ax,bx
    mul si
    push ax                   ; Save the product while printing the equation.

    mov ax,bx                 ; Print row number.
    call print_unsigned

    mov dl,'*'
    mov ah,02h
    int 21h

    mov ax,si                 ; Print column number.
    call print_unsigned

    mov dl,'='
    mov ah,02h
    int 21h

    pop ax                    ; Restore and print the calculated product.
    call print_unsigned

    cmp si,bx                 ; BX stays fixed; CX is reduced by LOOP.
    je row_last_item
    mov dl,09h                ; Align the next equation with a tab.
    mov ah,02h
    int 21h

row_last_item:
    inc si
    loop row_loop

    lea dx,crlf
    mov ah,09h
    int 21h

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_row endp

; ------------------------------------------------------------
; print_unsigned
; Input: AX = unsigned value to print as decimal
; The procedure preserves all registers used by its caller.
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
