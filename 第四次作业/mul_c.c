#include<stdio.h>

void mul(int num1, int num2)
{
	int result = num1 * num2;
	printf("%d*%d=%d\t", num1, num2, result);
}
int main()
{
	for (int i = 9; i >= 1 ; i--) {
		for (int j = 1; j <= i; j++) {
			mul(i, j);
		}
		printf("\n");
	}
	return 0;
}