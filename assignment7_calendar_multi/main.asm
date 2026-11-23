; main.asm —— 作业7：多模块输出日历（主模块）
; 本模块只做三件事：建立数据段/堆栈、按顺序调用各功能模块、退出。
; 其它模块：input.asm（输入）、calc.asm（日期计算）、print.asm（输出）。
; 汇编：MASM 5.0  链接：LINK 3.60  运行：DOSBox

        include macros.inc

; ---------------- 公共数据段（各模块通过 EXTRN 访问） ----------------
DATA    segment para public 'DATA'
        public year, month, first, ndays, mnames, mdays
        public p_year, p_mon, badmsg, crlf, whead

year    dw 0
month   dw 0
first   dw 0                    ; 当月 1 号是星期几，0=周日
ndays   dw 0                    ; 当月天数

; 12 个月名，每个固定 9 字节，用 (月份-1)*9 算偏移
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
DATA    ends

; ---------------- 堆栈段 ----------------
STACK   segment para stack 'STACK'
        db 2048 dup(0)
STACK   ends

; ---------------- 其它模块提供的过程 ----------------
        extrn read_year:far, read_month:far, compute:far
        extrn print_title:far, print_head:far, print_body:far

; ---------------- 主代码段 ----------------
MAIN    segment para public 'CODE'
        assume cs:MAIN, ds:DATA, ss:STACK

start:
        mov ax, DATA
        mov ds, ax
        mov ax, STACK
        mov ss, ax
        mov sp, 2048

        call far ptr read_year          ; 输入年份，结果写 year
        call far ptr read_month         ; 输入月份，结果写 month
        call far ptr compute            ; 算 first / ndays

        push month                      ; 堆栈传参：先压后一个参数
        push year
        call far ptr print_title        ; print_title 用 ret 4 清栈

        call far ptr print_head         ; 星期表头

        push ndays
        push first
        call far ptr print_body         ; 日历主体，ret 4 清栈

        mov ax, 4C00h
        int 21h

MAIN    ends
        end start
