# 汇编语言课程作业

本仓库保存汇编语言课程各次作业的源码、说明和验证结果。

## 作业目录

- 第一次、第二次作业：仓库根目录下的 `hello.asm`、`ascii_loop.asm`、`ascii_jmp.asm.txt`、`ascii.c.txt`、`ascii.s.txt`
- 第三次作业：`assignment3_sum/`
- 第四次作业（九九乘法表输出）：`assignment4_multiplication/`
- 第四次作业（九九乘法表纠错）：`assignment4_table_check/`

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
