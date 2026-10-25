# 第四次作业：乘法指令和过程调用

## 作业要求

1. 输出降序排列的九九乘法表。
2. 至少实现一个过程调用，正确使用 `CALL` 和 `RET`。
3. 过程使用主过程中的寄存器资源，并在进入和返回时保存、恢复寄存器。
4. 复习双循环的实现。
5. 使用 C 语言实现，查看反汇编代码并添加注释。

## 文件说明

### DOS 汇编版本

- `mul9.asm`：MASM 5.00 源码。
- `bin/MUL9.EXE`：已汇编、链接和运行验证的 16 位 DOS 可执行文件。
- `docs/dosbox_demo.png`：DOSBox 实际运行截图。

主过程使用 `BX` 保存当前行号，范围为 9 到 1。对于每一行，把
`BX` 复制到 `CX` 作为内层循环次数，然后调用 `print_row`。

`print_row` 使用主过程传入的寄存器：

```asm
push ax
push bx
push cx
push dx
push si
...
pop si
pop dx
pop cx
pop bx
pop ax
ret
```

行过程使用 `SI` 作为乘数，用 `MUL SI` 计算当前乘积，并调用
`print_unsigned` 输出十进制数。最后通过 `LOOP` 完成内层循环。

外层循环使用 `BX` 控制行号，因此形成完整的双循环：

```asm
mov bx,9
outer_loop:
    mov cx,bx
    call print_row
    cmp bx,1
    je finished
    dec bx
    jmp outer_loop
```

### C 语言与反汇编

- `mul9_c.c`：C 语言实现，同样采用双循环和乘法表达式。
- `bin/mul9_c.exe`：已经编译并运行验证的 Windows x64 程序。
- `mul9_c_compiler.asm`：Microsoft C 编译器生成的完整汇编清单。
- `mul9_c_disasm_notes.txt`：`main` 函数真实反汇编和逐条注释。

## DOSBox 中重新汇编

将 DOSBox 工作目录映射到本目录：

```dos
masm mul9.asm;
link mul9.obj;
mul9
```

## 预期输出

```text
The 9mul9 table:
9*1=9   9*2=18  9*3=27  9*4=36  9*5=45  9*6=54  9*7=63  9*8=72  9*9=81
8*1=8   8*2=16  8*3=24  8*4=32  8*5=40  8*6=48  8*7=56  8*8=64
7*1=7   7*2=14  7*3=21  7*4=28  7*5=35  7*6=42  7*7=49
6*1=6   6*2=12  6*3=18  6*4=24  6*5=30  6*6=36
5*1=5   5*2=10  5*3=15  5*4=20  5*5=25
4*1=4   4*2=8   4*3=12  4*4=16
3*1=3   3*2=6   3*3=9
2*1=2   2*2=4
1*1=1
```

实际 DOS 输出使用水平制表符对齐各列。

## 验证结果

- `MUL9.EXE` 在 DOSBox 中实际运行，输出 9 行完整乘法表。
- 行号从 9 递减到 1，每行项目数与行号一致。
- 两个过程都正确使用保存/恢复寄存器，并通过 `RET` 返回。
- C 版本实际运行，归一化后的内容与汇编版本一致。

详细验证结果见 `verification.txt`。
