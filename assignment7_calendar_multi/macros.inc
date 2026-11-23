; macros.inc —— 作业7 公共宏定义
; 宏汇编：把常用的一段指令序列起个名字，展开时直接替换成指令，
; 不产生 call/ret 的开销，也不占额外的代码段。

; 保存/恢复常用寄存器（打印类过程里反复用到）
PUSHALL macro
    push ax
    push bx
    push cx
    push dx
    push si
    push di
endm

POPALL macro
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
endm

; 打印以 '$' 结尾的字符串
PRINTSTR macro msg
    mov dx, offset msg
    mov ah, 09h
    int 21h
endm

; 换行
NEWLINE macro
    PRINTSTR crlf
endm
