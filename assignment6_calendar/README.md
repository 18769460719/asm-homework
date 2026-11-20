# 作业 6：输出日历

## 题目要求

输入年份（1900~2099）和月份（1~12），输出该月日历。

1. 从键盘输入年份和月份；
2. 功能尽量封装为过程，过程中使用寄存器；
3. 过程调用传递参数时，尝试寄存器、数据段、堆栈等不同方式，比较优缺点；
4. 至少用两个代码段封装程序，注意段间跳转/调用时的细节；
5. 代码量增加后，条件跳转是否还能成功？（短跳转位移只有 1 字节，-128~+127）
6. 体会短跳转、近跳转、远跳转，段内/段间跳转，机器码里位移与 IP、CS 的封装；
7. 用 C 语言实现后查看反汇编并加注释。

## 运行环境

- DOSBox 0.74
- MASM 5.0（`masm.exe`）、LINK 3.60（`link.exe`）
- 源文件按 UTF-8 保存，中文只出现在 `;` 注释里；MASM 5.0 不会解析注释内容，所以能正常汇编（换到 GBK 环境的 DOS 里如果花屏，把注释改成英文即可）。

## 文件说明

| 文件 | 说明 |
| --- | --- |
| `cal.asm` | 汇编主程序：两个代码段 + 数据段 + 栈段 |
| `jump_bad.asm` | 演示条件跳转超出 -128~+127 的报错 |
| `jump_fix.asm` | 用“条件取反 + JMP near”绕过短跳转限制 |
| `cal_c.c` | C 语言版（同样的算法） |
| `cal_c.asm` | `cl /FA` 生成的汇编清单 |
| `cal_c_obj_disasm.txt` | `dumpbin /disasm cal_c.obj` 的反汇编 |
| `cal_c_disasm_notes.txt` | 反汇编逐段注释 |
| `verification.txt` | 9 组日期的核对记录、跳转实验记录 |
| `bin/CAL.EXE` | 汇编版可执行文件 |
| `bin/cal_c.exe`、`bin/cal_c.dll` | C 版（本机被 SAC 拦截，见 verification） |
| `docs/` | 运行截图与跳转实验截图 |

## 设计思路

### 1. 分段

```
DATA   数据段：year/month/first/ndays、月份名表、每月天数表、提示串
STACK  栈段：2048 字节
CSEG1  主流程 + 输入 + 计算（read_year、read_month、compute、is_leap）
CSEG2  输出（putc、print_dec_far、print_year、print_title_far、
              print_head_far、print_body_far）
```

CSEG1 用 `call far ptr print_title_far` 进入 CSEG2，返回用 `retf`
（`ret 4` / `ret 6` 顺便把参数弹掉）。far call 会把 CS 和 IP 一起压栈，
所以两个段之间跳转不用自己保存段寄存器。

### 2. 参数传递的三种方式（要求 3）

| 方式 | 用在哪 | 优点 | 缺点 |
| --- | --- | --- | --- |
| 寄存器 | `read_year` 返回年份放 AX；`compute` 用 AX 传年份、返回 AL | 最快，不占内存，代码短 | 寄存器数量有限，嵌套调用要自己保护；参数多时不够用 |
| 数据段 | `compute` 把结果写回 `year/month/first/ndays`，打印过程直接读 | 不受寄存器个数限制，过程之间耦合松 | 全局变量，谁都能改，调试时不好追踪；不可重入 |
| 堆栈 | `print_title_far` 收 `year/month`，`print_body_far` 收 `first/ndays`，`ret 4/6` 清栈 | 支持嵌套和递归，参数随调用走 | 访问要走 BP 相对寻址，写起来啰嗦；忘了清栈会跑飞 |

实际程序里三种都用了：输入/计算用寄存器和数据段，打印用堆栈，
正好各演示一次。

### 3. 星期几怎么算

从 1900-01-01（星期一）开始累加天数：

```
days = Σ(1900..year-1) 365+is_leap(i) + Σ(1..month-1) days_of(i)
first = (days + 1) % 7          ; 0=周日
```

16 位寄存器最大 65535，而 1900~2099 最多约 73000 天，直接累加会溢出。
所以汇编版改成“边加边对 7 取余”，每一步只保留 0~6：

```
inc dx / 闰年再 inc dx / cmp dx,7 / jb ok / sub dx,7
```

C 版用 int（32 位）直接累加，不存在这个问题——这也是对比赛时要讲的一点。

### 4. 输入

`int 21h` 的 `AH=08h` 逐字符读（不回显），读到回车结束；
数字自己回显（`AH=02h`），遇非数字字符直接跳过，长度不对就提示重输。
月份读到空行（行尾残留的回车）时跳回继续读，不报错。

## 编译运行

```bat
masm cal.asm;
link cal.obj;
cal
```

在 DOSBox 里先 `mount c` 到本目录，`mount d` 到 `D:\huibian\myasm`
（masm/link 在 D 盘根目录）。

## 运行结果

```
Please input year (1900-2099): 2026
Please input month (1-12): 11
2026  November
Su Mo Tu We Th Fr Sa
  1  2  3  4  5  6  7
  8  9 10 11 12 13 14
 15 16 17 18 19 20 21
 22 23 24 25 26 27 28
 29 30
```

## 跳转范围实验（要求 5、6）

`jump_bad.asm` 里在 `je` 后面塞了 200 个 NOP：

```
jump_bad.asm(7): error A2053: Jump out of range by 73 byte(s)
```

改成：

```asm
    jne short skip
    jmp near ptr target
skip:
```

汇编通过，清单里的机器码：

```
75 03        JNE  +3        ; 8 位位移
E9 00D1 R    JMP  +00D1h    ; 16 位位移
```

结论：Jcc 只有 8 位位移，范围 -128~+127；超出就报 A2053，
要么改成“条件取反 + 近跳转”，要么把目标挪近。

## C 版本与反汇编

`cal_c.c` 与汇编版算法一致；`cl /FA` 生成 `cal_c.asm`，
`dumpbin /disasm` 生成 `cal_c_obj_disasm.txt`，注释见
`cal_c_disasm_notes.txt`。重点看：

- `is_leap` 里 `idiv` 取余、`and edx,3` 优化 `%4`；
- `first_weekday` 里 `lea eax,[rcx+rax+16Dh]`（365 + 闰年标志）；
- `print_cal` 里 `%3d` 交给 printf，和汇编版手写数字转字符的对比。

## 踩过的坑

1. 8086 不支持 `push 立即数`（`push word ptr 7` → A2056），要先 `mov ax,7`。
2. 1900~2099 的天数超过 16 位，直接累加会溢出，必须边加边取余。
3. `int 21h AH=0Ah` 在重定向输入时表现异常（输出变成一堆 0），
   最后改成 `AH=08h` 逐字符读，稳定且可回显。
4. 长文件名在 DOS 下会截断，`cal_trace.asm` 这种名字 MASM 认不出，
   源文件一律用 8.3 短名。
5. 本机开了“智能应用控制”，新编译的 C 程序会被拦（WinError 4551），
   所以 C 版只提供了源码、清单和反汇编；汇编版在 DOSBox 里正常跑。

## 截图

- `docs/calendar-run.png`：汇编、链接、运行 2026 年 11 月
- `docs/jump-range-error.png`：A2053 报错
- `docs/jump-range-fix.png`：改成 near 跳转后通过
