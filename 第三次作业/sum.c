#define _CRT_SECURE_NO_WARNINGS
#include<stdio.h>

int main()
{
	int n;
	int i=1;
	int sum = 0;
	printf("Enter a num:");
	scanf("%d", &n);
	while (i <= n) {
		sum = sum + i;
		i++;
	}
	printf("%d", sum);

	return 0;
}