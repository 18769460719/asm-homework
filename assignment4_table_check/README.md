# 作业题目 4（二）：九九乘法表纠错

## 作业要求

1. 检查提供的 9×9 乘法表数据，找出错误位置并显示到屏幕。
2. 使用 `CALL` 和 `RET` 实现过程调用。
3. 过程使用主过程提供的寄存器资源，并在调用前后保存和恢复寄存器。
4. 使用双循环遍历二维表。
5. 使用数据段寻址和二维表偏移计算。
6. 使用 C 语言实现、查看反汇编并注释，观察全局表与局部表的差异。

## 汇编实现

### 文件

- `mulchk.asm`：MASM 5.00 源程序。
- `bin/MULCHK.EXE`：已经汇编、链接和运行验证的 DOS 可执行文件。
- `docs/dosbox_demo.png`：DOSBox 实际运行截图。

### 二维表寻址

表在数据段中连续存放：

```asm
table db 7,2,3,4,5,6,7,8,9
      db 2,4,7,8,10,12,14,16,18
      ...
```

主过程把表首地址放入 `SI`，把行列数放入 `CX`：

```asm
lea si,table
mov cx,table_dim
call check_table
```

`check_table` 使用以下方式定位每一行：

```asm
mov ax,di
dec ax
mov dx,row_limit
mul dx
add si,ax
```

也就是：

```text
当前行首地址 = 表首地址 + (行号 - 1) × 每行元素数
```

### 双循环

- 外层循环：`DI` 表示行号，范围 `1~9`。
- 内层循环：`BX` 表示列号，范围 `1~9`。
- 每行开始时用 `SI` 指向该行首字节，列循环中执行 `INC SI` 顺序访问。
- 每次读取 `DS:[SI]`，计算期望值 `行号 × 列号` 并比较。

### 过程调用和寄存器保护

`check_table` 进入时保存：

```asm
push ax
push bx
push cx
push dx
push si
push di
push bp
```

返回前按相反顺序恢复，并使用 `RET`。行过程和十进制输出过程都遵守同一规则。

## 检测结果

错误位置：

| 行 | 列 | 表中数据 | 正确结果 |
|---|---:|---:|---:|
| 1 | 1 | 7 | 1 |
| 2 | 3 | 7 | 6 |
| 4 | 5 | 7 | 20 |
| 6 | 6 | 7 | 36 |
| 8 | 8 | 7 | 64 |

程序输出：

```text
x y    result
1 1    error
2 3    error
4 5    error
6 6    error
8 8    error
accomplish!
```

## C 语言与反汇编

- `mulchk_c.c`：C 实现，分别检查全局表 `g_table` 和局部表 `local_table`。
- `bin/mulchk_c.exe`：已经编译和运行的 Windows x64 程序。
- `mulchk_c_compiler.asm`：Microsoft C 编译器生成的完整汇编清单。
- `mulchk_c_disasm_notes.txt`：真实反汇编及全局/局部数据差异说明。

### 全局表与局部表

- 全局 `g_table` 位于只读常量段。`main` 只把它的地址传给 `check_table`。
- 局部 `local_table` 位于 `main` 的栈帧。编译器会先扩大栈空间，再用 81 条字节写入指令初始化局部表。
- 两者逻辑检查结果相同，但存储位置、初始化成本和生命周期不同。

## DOSBox 中重新汇编

```dos
masm mulchk.asm;
link mulchk.obj;
mulchk
```

## 验证

- 汇编程序实际输出 5 个错误位置和 `accomplish!`。
- C 程序对全局表和局部表分别输出相同的 5 个错误位置。
- 错误位置、期望值和程序结果见 `verification.txt`。
