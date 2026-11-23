# 第七次作业：多模块实现输出日历

## 一、题目要求

1. 改写作业 6，采用多模块方式（按逻辑功能至少 3 个源程序），在多模块下尝试过程调用及宏汇编（Macro）机制。
2. 比较一个代码段中、多个代码段间、多个文件间 `call` 指令对应的机器码有什么不同；执行时 CS、IP 的保存和恢复方式有什么不同；单步执行时观察 `call` 和 `ret` 前后 CS、IP、SP 等寄存器和栈内容的变化。

## 二、运行环境

- 汇编：MASM 5.0（`masm.exe`）
- 链接：LINK 3.60（`link.exe`）
- 运行：DOSBox 0.74（16 位 DOS 环境）

## 三、文件说明

| 文件 | 作用 |
|---|---|
| `main.asm` | 主模块：定义数据段和堆栈段，按顺序调用输入、计算、输出模块，最后退出 |
| `input.asm` | 输入模块：`read_year`、`read_month` 两个远过程，逐字符读入并回显，非法输入重来 |
| `calc.asm` | 计算模块：`compute` 远过程，算当月 1 号是星期几、当月天数；内部有近过程 `is_leap` |
| `print.asm` | 输出模块：`print_title`、`print_head`、`print_body` 三个远过程，内部有 `putc`、`print_dec`、`print_year` |
| `macros.inc` | 公共宏：`PUSHALL` / `POPALL` / `PRINTSTR` / `NEWLINE` |
| `ct2.asm` | 附加实验：打印每次 `call`、`ret` 前后的 CS:IP、SP（用于第 2 项要求） |
| `bin/CAL7.EXE` | 多模块日历程序（由 main + input + calc + print 链接而成） |
| `bin/CT2.EXE` | `ct2.asm` 生成的可执行文件 |
| `docs/calendar-run.png` | 运行结果截图（2026 年 11 月） |
| `docs/calltrace.png` | `ct2.exe` 的 CS:IP、SP 输出截图 |
| `docs/call-compare.md` | call 机器码与 CS/IP/SP 变化的整理（第 2 项要求） |
| `docs/*.lst` | 各模块的汇编清单（含机器码），用于核对 `E8` / `9A` / `C3` / `CB` / `CA` |
| `verification.txt` | 9 组日期的验证记录和机器码摘录 |

## 四、模块划分与调用关系

```
main.asm（主模块，CSEG MAIN）
  ├─ call far ptr read_year     → input.asm   （远调用，9A）
  ├─ call far ptr read_month    → input.asm   （远调用，9A）
  ├─ call far ptr compute       → calc.asm    （远调用，9A）
  ├─ call far ptr print_title   → print.asm   （远调用，9A，堆栈传参）
  ├─ call far ptr print_head    → print.asm   （远调用，9A）
  └─ call far ptr print_body    → print.asm   （远调用，9A，堆栈传参）
```

各模块只通过两种方式交换数据：

- 数据段：`year`、`month`、`first`、`ndays` 定义在主模块的 `DATA` 段，其它模块用 `EXTRN` 声明、直接访问；
- 寄存器/堆栈：输入结果放 AX 返回，`print_dec` 用 AX 传要打印的数，`print_title` / `print_body` 用堆栈传参。

这样四个模块可以分别汇编、最后一起链接，`main.obj + input.obj + calc.obj + print.obj → cal7.exe`。

## 五、三种参数传递方式的比较

| 方式 | 本作业里的例子 | 优点 | 缺点 |
|---|---|---|---|
| 寄存器 | `print_dec` 入口 AX = 待打印的数；`is_leap` 入口 AX = 年份 | 最快，不访问内存，代码短 | 寄存器个数有限（AX/BX/CX/DX/SI/DI），参数一多就不够；过程内部容易把参数寄存器用掉，必须先保存 |
| 数据段 | `year`、`month`、`first`、`ndays` 全局变量，各模块直接读写 | 写法简单，参数多也不怕，跨模块方便 | 耦合大，谁都能改；不支持重入和递归；调试时不容易看出“这个值是谁改的” |
| 堆栈 | `print_title` 前 `push month / push year`，过程里 `[bp+6]`、`[bp+8]` 取参，`ret 4` 清栈 | 支持嵌套和递归，参数随调用帧走，天然可重入 | 要注意 SP 平衡：push 几个就要清几个；`[bp+偏移]` 算错就会取到返回地址或旧 BP |

## 六、宏汇编的使用

`macros.inc` 里定义了 4 个宏：

```asm
PUSHALL macro          ; 依次压入 ax bx cx dx si di
POPALL  macro          ; 反序弹出
PRINTSTR macro msg     ; 打印以 '$' 结尾的字符串
NEWLINE macro          ; 打印回车换行
```

`print.asm` 的 `print_dec`、`print_year`、`print_title`、`print_body` 都用 `PUSHALL/POPALL` 保护寄存器，`input.asm` 用 `NEWLINE` 换行。

宏和过程的区别：宏在汇编时展开成指令，不产生 `call/ret`，不压栈，执行快但代码体积会变大；过程只有一份代码，靠 `call` 调用，节省空间但有调用开销。本作业里“保存/恢复寄存器”和“打印字符串”这种短序列用宏，“读输入”“算日期”“打印整月”这种较长的逻辑用过程。

## 七、call 的机器码与 CS、IP、SP 的变化

详细对照见 `docs/call-compare.md`，这里只列结论：

| 场景 | 机器码 | 压栈内容 | CS 是否变化 |
|---|---|---|---|
| 同一代码段内 `call putc` | `E8 00xx`（近，相对位移） | 只压 IP（SP-2） | 不变 |
| 同一文件不同段 `call far ptr far_proc` | `9A 0000 0000`（远） | 压 CS、IP（SP-4） | 变 |
| 不同文件 `call far ptr read_year` | `9A 0000 ---- E`（远，段重定位） | 压 CS、IP（SP-4） | 变 |

`ct2.exe` 的实测输出：

```
main entry          CS:IP=01CC:0013  SP=0200
before near call    CS:IP=01CC:0019  SP=0200
inside near proc    CS:IP=01CC:003F  SP=01FC
after  near call    CS:IP=01CC:0022  SP=0200
before far  call    CS:IP=01CC:0028  SP=0200
inside far proc     CS:IP=01D8:0035  SP=0200
after  far  call    CS:IP=01CC:0033  SP=0200
```

可以看到：近调用前后 CS 一直是 01CC，只有 IP 和 SP 变；远调用进入 `far_proc` 时 CS 变成 01D8，返回后又回到 01CC。近过程返回用 `C3`，远过程返回用 `CB`，带参数的远返回用 `CA 04 00`（`ret 4`）。

## 八、编译与运行

在 DOSBox 里进入本目录（`D:\huibian\myasm\asm-homework\assignment7_calendar_multi`），依次执行：

```
masm main.asm;
masm input.asm;
masm calc.asm;
masm print.asm;
link main+input+calc+print,cal7.exe;
cal7
```

输入年份（1900-2099）和月份（1-12），即可输出该月日历。

附加实验：

```
masm ct2.asm;
link ct2.obj,ct2.exe;
ct2
```

## 九、运行结果

2026 年 11 月：

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

## 十、踩过的坑

1. **宏文件名不能超过 8.3**：一开始把观察程序叫 `calltrace.asm`，MASM 报 `Unable to open input file`，改成 `ct2.asm` 才正常。DOS 下主文件名最多 8 个字符、扩展名 3 个，`calltrace` 是 9 个字符。
2. **8086 不支持 `push 立即数`**：写测试程序时用 `push word ptr 7`，报 `A2056: Immediate mode illegal`，要先 `mov ax,7` 再 `push ax`；作业 6 里也踩过同样的坑。
3. **跨模块访问数据要 `EXTRN` 且段名/类别一致**：主模块的 `DATA` 段写成 `para public 'DATA'`，其它模块 `extrn year:word` 后直接 `mov year, si` 才能链接通过；如果段类别写成 `'DATA '`（多一个空格）就会变成两个不同的段，链接时报符号未定义。
4. **远过程返回要用 `ret` 还是 `retf`**：`proc far` 里的 `ret` 汇编成 `CB`（远返回），但手写 `ret` 放错位置就会只弹出 IP，CS 留在栈上，程序跑飞。带参数清栈要用 `ret 4`（`CA 04 00`），不要写成两条 `pop`。
5. **堆栈传参的偏移**：`print_title` / `print_body` 里先 `push bp / mov bp,sp`，参数在 `[bp+6]`、`[bp+8]`；如果漏了 `push bp`，偏移要整体减 2，很容易取到返回地址。
