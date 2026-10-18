#include <stdio.h>

int main(void)
{
    int n = 100;
    int sum = 0;
    int i;

    for (i = 1; i <= n; i++) {
        sum += i;
    }

    printf("%d\n", sum);
    return 0;
}
