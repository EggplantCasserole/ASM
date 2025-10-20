#include<stdio.h>

int main()
{
	char begin = 'a';
	int count = 0;
	while (begin != 'z' + 1) {
		printf("%c", begin);
		begin++;
		count++;
		if (count % 13 == 0) {
			printf("\n");
		}
		else {
			printf(" ");
		}
	}
	return 0;
}