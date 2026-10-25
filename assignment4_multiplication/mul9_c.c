#include <stdio.h>

int main(void)
{
    int row;
    int col;

    printf("The 9mul9 table:\n");

    for (row = 9; row >= 1; row--) {
        for (col = 1; col <= row; col++) {
            printf("%d*%d=%d", row, col, row * col);
            if (col == row) {
                putchar('\n');
            } else {
                putchar('\t');
            }
        }
    }

    return 0;
}
