#include <stdio.h>
#include <windows.h>

// Detect signed integer overflow
int check_signed_overflow(int a, int b) {
    int sum = a + b;
    // Overflow occurs if:
    // - Two positive numbers add to negative
    // - Two negative numbers add to positive
    return ((a > 0 && b > 0 && sum < 0) || (a < 0 && b < 0 && sum > 0));
}

// Simulate INTO instruction behavior
void simulate_into(int a, int b) {
    if (check_signed_overflow(a, b)) {
        printf("OF=1, Triggering simulated INTO interrupt service routine\n");
        printf("Custom interrupt service routine started...\n");
        printf("Handling overflow situation...\n");
        printf("Interrupt service routine completed\n");
    } else {
        printf("OF=0, No interrupt triggered\n");
    }
}

int main() {
    printf("INTO Interrupt Service Routine Simulation - 64-bit Version\n\n");

    // Test case 1: Will overflow
    printf("Test 1: Signed overflow case\n");
    int a = 2147483647; // INT_MAX
    int b = 1;
    printf("a = %d, b = %d\n", a, b);
    
    int result;
    __asm__ (
        "movl %1, %%eax\n"
        "addl %2, %%eax\n"
        "movl %%eax, %0"
        : "=r" (result)
        : "r" (a), "r" (b)
        : "%eax"
    );
    
    printf("Calculation result: %d\n", result);
    simulate_into(a, b);

    printf("\nTest 2: No overflow case\n");
    a = 100;
    b = 200;
    printf("a = %d, b = %d\n", a, b);
    
    __asm__ (
        "movl %1, %%eax\n"
        "addl %2, %%eax\n"
        "movl %%eax, %0"
        : "=r" (result)
        : "r" (a), "r" (b)
        : "%eax"
    );
    
    printf("Calculation result: %d\n", result);
    simulate_into(a, b);

    printf("\nProgram demonstrates:");
    printf("\n1. Overflow detection for signed integers");
    printf("\n2. Simulation of INTO interrupt behavior");
    printf("\n3. Custom interrupt service routine execution");

    return 0;
}