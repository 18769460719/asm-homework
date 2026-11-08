#include <stdio.h>

/* 作业题目 5：递归求斐波那契数列
   汇编版用的是 6 个万进制位组（最多 24 位十进制），
   这里用同样的表示，方便和汇编对照。 */

#define MAXN   100
#define WORDS  6
#define BASE   10000

static unsigned short memo[MAXN + 1][WORDS];
static unsigned char  done[MAXN + 1];

static void fib(int n)
{
    int i;
    int carry;
    int t;

    if (done[n]) {
        return;
    }

    if (n <= 1) {
        memo[n][0] = (unsigned short)n;
        for (i = 1; i < WORDS; i++) {
            memo[n][i] = 0;
        }
        done[n] = 1;
        return;
    }

    fib(n - 1);
    fib(n - 2);

    carry = 0;
    for (i = 0; i < WORDS; i++) {
        t = (int)memo[n - 1][i] + (int)memo[n - 2][i] + carry;
        carry = 0;
        if (t >= BASE) {
            t -= BASE;
            carry = 1;
        }
        memo[n][i] = (unsigned short)t;
    }
    done[n] = 1;
}

static void print_fib(int n)
{
    int i;

    i = WORDS - 1;
    while (i > 0 && memo[n][i] == 0) {
        i--;
    }
    printf("%u", memo[n][i]);
    for (i = i - 1; i >= 0; i--) {
        printf("%04u", memo[n][i]);
    }
    printf("\n");
}

int main(void)
{
    int n;

    printf("n = ");
    if (scanf("%d", &n) != 1) {
        printf("input error\n");
        return 1;
    }
    if (n < 0 || n > MAXN) {
        printf("input error, n should be 0..100\n");
        return 1;
    }

    fib(n);
    printf("F(n) = ");
    print_fib(n);
    return 0;
}
