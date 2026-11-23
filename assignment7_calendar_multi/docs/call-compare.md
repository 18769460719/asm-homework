# 作业7 实验记录：call 的机器码与 CS、IP、SP 的变化

本文件配合 `main.asm` / `input.asm` / `calc.asm` / `print.asm` 的汇编清单（`docs/*.lst`）和 `ct2.asm` 的运行结果，记录作业第 2 项要求。

## 一、三种调用场景的机器码

| 场景 | 源码写法 | 机器码 | 汇编清单出处 |
|---|---|---|---|
| 同一代码段内调用（近调用） | `call putc` | `E8 00xx`（16 位相对位移） | `docs/print.lst` 0014 行 |
| 同一文件、不同代码段（远调用） | `call far ptr far_proc` | `9A 0000 0000`（偏移 + 段基址，链接时填） | `docs/ct2.lst` 0028 行 |
| 不同源文件、不同代码段（远调用） | `call far ptr read_year` | `9A 0000 ---- E`（段基址待链接重定位） | `docs/main.lst` 000D 行 |
| 近过程返回 | `ret` | `C3` | `docs/print.lst` 0004 行 |
| 远过程返回 | `ret`（far 过程内） | `CB` | `docs/ct2.lst` 0081 行 |
| 远过程返回并清栈 | `ret 4` | `CA 04 00` | `docs/print.lst` 00E4 行 |

结论：

1. 近调用只有 `E8` 一个操作码加 16 位相对位移，因为 CS 不变，只压入返回的 IP。
2. 远调用（不管跨段还是跨文件）都是 `9A` 加“偏移 + 段基址”，因为 CS 和 IP 都要换。**跨文件和跨段在机器码层面没有区别**：分段是链接时的事，汇编器只留一个段重定位项，LINK 再把段基址填进去（清单里的 `---- E` 就是重定位标记）。
3. 返回指令用 `C3` / `CB` 区分近、远；带参数的 `ret 4` 用 `CA 04 00`，在弹出 IP、CS 后再把 SP 加 4。

## 二、CS、IP、SP 的变化（ct2.asm 实测）

`ct2.asm` 在近调用、远调用前后打印 CS:IP 和 SP，运行结果（截图见 `docs/calltrace.png`）：

```
main entry          CS:IP=01CC:0013  SP=0200
before near call    CS:IP=01CC:0019  SP=0200
inside near proc    CS:IP=01CC:003F  SP=01FC
after  near call    CS:IP=01CC:0022  SP=0200
before far  call    CS:IP=01CC:0028  SP=0200
inside far proc     CS:IP=01D8:0035  SP=0200
after  far  call    CS:IP=01CC:0033  SP=0200
```

对照说明：

| 时刻 | CS | IP | SP | 发生了什么 |
|---|---|---|---|---|
| main entry | 01CC | 0013 | 0200 | 程序入口，栈顶在 0200 |
| before near call | 01CC | 0019 | 0200 | 下一条就是 `call` |
| inside near proc | 01CC | 003F | 01FC | 近调用压入 IP（SP-2）；过程里又 `push dx`，所以比调用前少 4 |
| after near call | 01CC | 0022 | 0200 | `ret` 弹出 IP，SP 复原；CS 一直没变 |
| before far call | 01CC | 0028 | 0200 | 下一条是 `call far ptr` |
| inside far proc | **01D8** | 0035 | 0200 | 远调用压入 CS、IP（SP-4）；CS 变成 far_proc 所在段 01D8；这里打印的 SP 是调用前的 0200 |
| after far call | **01CC** | 0033 | 0200 | `retf` 依次弹出 IP、CS，SP 复原，CS 回到 01CC |

要点：

- 近调用只压 IP，所以 SP 减 2；远调用压 CS 和 IP，SP 减 4，返回时再按相反顺序弹出。
- CS 只有远调用/远返回会变；近调用前后 CS 不变。
- 带参数的 `ret 4` 会在弹出返回地址后额外把 SP 加 4，用来丢掉调用者压入的两个参数。

## 三、手工单步验证方法（可选）

如果要在 DOS 下自己单步看寄存器，可以用 DEBUG：

```
debug cal7.exe
-u          ; 反汇编，找到 call 的地址
-t          ; 单步执行，每步都会显示 AX/BX/CX/DX/SP/BP/SI/DI/DS/ES/SS/CS/IP
```

`t` 执行到 `call` 时会进入被调用过程，`p` 则把整个调用当作一步执行完（适合跳过不想跟的过程）。本机 DOSBox 目录里没有带 DEBUG.EXE，所以作业里用 `ct2.asm` 把同样的信息打印出来。
