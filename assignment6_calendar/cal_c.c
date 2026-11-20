/* assignment6: print a calendar for a given year (1900-2099) and month (1-12)
 * build: cl /nologo /Od /FA cal_c.c
 *        cl /nologo /LD /Od cal_c.c /Fe:bin\cal_c.dll   (used to call from Python)
 */
#include <stdio.h>

static const char *mon_name[12] = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
};
static const int mon_days[12] = { 31,28,31,30,31,30,31,31,30,31,30,31 };

/* 1 = leap year */
static int is_leap(int y)
{
    if (y % 400 == 0) return 1;
    if (y % 100 == 0) return 0;
    return (y % 4 == 0);
}

/* days in the given month */
static int days_of(int y, int m)
{
    if (m == 2 && is_leap(y)) return 29;
    return mon_days[m - 1];
}

/* weekday of the 1st: 0 = Sunday */
static int first_weekday(int y, int m)
{
    int days = 0, i;
    for (i = 1900; i < y; i++)
        days += 365 + is_leap(i);
    for (i = 1; i < m; i++)
        days += days_of(y, i);
    return (days + 1) % 7;
}

__declspec(dllexport) void print_cal(int year, int month)
{
    int first, ndays, d, col;

    if (year < 1900 || year > 2099 || month < 1 || month > 12) {
        printf("Invalid input\n");
        return;
    }

    first = first_weekday(year, month);
    ndays = days_of(year, month);

    printf("%d  %s\n", year, mon_name[month - 1]);
    printf("Su Mo Tu We Th Fr Sa\n");

    col = 0;
    for (d = 0; d < first; d++) {
        printf("   ");
        col++;
    }
    for (d = 1; d <= ndays; d++) {
        printf("%3d", d);
        col++;
        if (col == 7) {
            printf("\n");
            col = 0;
        }
    }
    if (col != 0) printf("\n");
}

int main(void)
{
    int year, month;
    printf("Please input year (1900-2099): ");
    if (scanf("%d", &year) != 1) return 1;
    printf("Please input month (1-12): ");
    if (scanf("%d", &month) != 1) return 1;
    print_cal(year, month);
    return 0;
}
