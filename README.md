# 汇编语言课程作业

本仓库保存汇编语言课程各次作业的源码、说明和验证结果。

## 作业目录

- 第一次、第二次作业：仓库根目录下的 `hello.asm`、`ascii_loop.asm`、`ascii_jmp.asm.txt`、`ascii.c.txt`、`ascii.s.txt`
- 第三次作业：`assignment3_sum/`
- 第四次作业（九九乘法表输出）：`assignment4_multiplication/`
- 第四次作业（九九乘法表纠错）：`assignment4_table_check/`
- 第五次作业（递归调用）：`assignment5_fibonacci/`
- 第六次作业（输出日历）：`assignment6_calendar/`
- 第七次作业（多模块输出日历）：`assignment7_calendar_multi/`

## 第三次作业

第三次作业要求计算 `1 + 2 + ... + 100`，把结果以十进制输出为 `5050`，
并完成寄存器、数据段、栈三种存储方式，以及用户输入和 C 语言反汇编分析。

- [assignment3_sum/README.md](assignment3_sum/README.md)
- [assignment3_sum/verification.txt](assignment3_sum/verification.txt)
- [assignment3_sum/docs/dosbox_demo.png](assignment3_sum/docs/dosbox_demo.png)

## 第四次作业

### 九九乘法表输出

使用双循环和乘法指令输出降序九九乘法表，演示 `CALL`/`RET`、
寄存器保护和 C 语言反汇编。

- [assignment4_multiplication/README.md](assignment4_multiplication/README.md)
- [assignment4_multiplication/verification.txt](assignment4_multiplication/verification.txt)
- [assignment4_multiplication/docs/dosbox_demo.png](assignment4_multiplication/docs/dosbox_demo.png)

### 九九乘法表纠错

检查数据段中的 9×9 乘法表，输出错误位置；包含双循环、二维数据寻址、
过程调用、寄存器保存恢复，以及全局表和局部表的反汇编对照。

- [assignment4_table_check/README.md](assignment4_table_check/README.md)
- [assignment4_table_check/verification.txt](assignment4_table_check/verification.txt)
- [assignment4_table_check/docs/dosbox_demo.png](assignment4_table_check/docs/dosbox_demo.png)

## 第五次作业

### 递归调用（斐波那契数列）

键盘输入 n（0~100），用递归求第 n 个斐波那契数；结果用记忆化 + 万进制存储，
并分析每层递归占用的栈空间（16 字节/层），用调试版打印每次调用/返回时的 SP。

- [assignment5_fibonacci/README.md](assignment5_fibonacci/README.md)
- [assignment5_fibonacci/verification.txt](assignment5_fibonacci/verification.txt)
- [assignment5_fibonacci/docs/dosbox_demo.png](assignment5_fibonacci/docs/dosbox_demo.png)

## 第六次作业

### 输出日历

输入年份（1900~2099）和月份，输出该月日历；两个代码段、段间 far call、
寄存器/数据段/堆栈三种传参方式对照，并演示条件跳转超出 -128~+127 时的处理。

- [assignment6_calendar/README.md](assignment6_calendar/README.md)
- [assignment6_calendar/verification.txt](assignment6_calendar/verification.txt)
- [assignment6_calendar/docs/calendar-run.png](assignment6_calendar/docs/calendar-run.png)

## 第七次作业

### 多模块输出日历

把第六次作业拆成 main / input / calc / print 四个源文件，用宏（`macros.inc`）
和远过程调用组织程序；对照同段近调用、跨段远调用、跨文件远调用的机器码
（`E8` / `9A` / `C3` / `CB` / `CA`），并用 `ct2.asm` 打印每次 call、ret 前后的
CS:IP、SP 变化。

- [assignment7_calendar_multi/README.md](assignment7_calendar_multi/README.md)
- [assignment7_calendar_multi/verification.txt](assignment7_calendar_multi/verification.txt)
- [assignment7_calendar_multi/docs/calendar-run.png](assignment7_calendar_multi/docs/calendar-run.png)
- [assignment7_calendar_multi/docs/calltrace.png](assignment7_calendar_multi/docs/calltrace.png)


