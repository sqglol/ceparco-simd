#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <time.h>
#include <windows.h>

#define MIN_VAL -20
#define MAX_VAL 20

#define FG_CYAN "\x1b[0;36m"
#define RESET "\x1b[0m"

// Prints the first and last 5 elements of any array
#define print_array(type, n, arr, fmt) \
    do { \
        size_t i; \
        type *array = (type *)arr; \
        printf("["); \
        for (i = 0; i < 5; i++) { \
            printf(fmt, array[i]); \
        } \
        printf("..., "); \
        for (i = n - 5; i < n; i++) { \
            printf(fmt, array[i]); \
        } \
        printf("\b\b]\n"); \
    } while (0)

typedef void (*kernel_t)(size_t, float[], float[], float[], int[]);

// x86-64 implementation, no SIMD
extern void x86_64_max(size_t n, float A[], float B[], float C[], int idx[]);

// x86-64 implementation, SIMD with XMM
extern void xmm_max(size_t n, float A[], float B[], float C[], int idx[]);

// x86-64 implementation, SIMD with YMM
extern void ymm_max(size_t n, float A[], float B[], float C[], int idx[]);

// C implementation
void C_max(size_t n, float A[], float B[], float C[], int idx[]) {
    for (size_t i = 0; i < n; i++) {
        if (A[i] >= B[i]) {
            C[i] = A[i];
            idx[i] = 0;
        }
        else {
            C[i] = B[i];
            idx[i] = 1;
        }
    }
}

// Dynamically allocates an array of size n and fills it with random float values
// WARNING: Pointer returned by this function must be freed!
float* malloc_rand(size_t n) {
    float* array = (float*) malloc(n * sizeof(float));

    // Gracefully exit in case malloc() fails
    if (array == NULL)
        return;

    for (int i = 0; i < n; i++) {
        // Generates a random floating-point value between MIN_VAL and MAX_VAL
        array[i] = MIN_VAL + ((float) rand() / (float) RAND_MAX) * (MAX_VAL - MIN_VAL);
    }

    return array;
}

// Measures the execution time of an implementation
// windows.h's QueryPerformanceCounter() is more precise than time.h's clock()
void measure_time(const char* name, kernel_t kernel, size_t n, float A[], float B[], float C[], int idx[]) {
    LARGE_INTEGER frequency, start, end;
    double execution_time = 0;
    int i;

    memset(C, 0, n*sizeof(float));
    memset(idx, 0, n*sizeof(int));

    // Display name of kernel
    printf(FG_CYAN "%s\n" RESET, name);

    // Perform the test 30 times
    for (i = 0; i < 30; i++) {
        QueryPerformanceFrequency(&frequency);
        QueryPerformanceCounter(&start);

        // Execute the kernel
        (*kernel)(n, A, B, C, idx);

        QueryPerformanceCounter(&end);

        execution_time += (double)(end.QuadPart - start.QuadPart) / frequency.QuadPart * 1000;
    }

    // Average the execution time
    execution_time = execution_time / i;

    printf("C = ");
    print_array(float, n, C, "%.2f, ");
    printf("idx = ");
    print_array(int, n, idx, "%d, ");

    printf("Average execution time (30 runs): %f ms\n\n", execution_time);
}

int main() {
    size_t size = 0;
    int input;

    printf("Select input size: [1] 2^20 [2] 2^26 [3] 2^28 [4] Manual input: ");
    scanf_s("%d", &input);

    if (input == 1 || input == 2 || input == 3) {
        printf("Set number of extra elements (SIMD boundary test): ");
        scanf_s("%zu", &size);
    }

    switch (input) {
    case 1: // 2^20
        size += 1048576;
        printf("\nInitializing array with ~2^20 elements...\n\n");
        break; 
    case 2: // 2^26
        size += 67108864;
        printf("\nInitializing array with ~2^26 elements...\n\n");
        break; 
    case 3: // 2^28
        size += 268435456;
        printf("\nInitializing array with ~2^28 elements...\n\n");
        break; 
    case 4:
        printf("Manual input: ");
        scanf_s("%zu", &size);
        printf("\nInitializing array with %zu elements...\n\n", size);
        break;
    default:
        printf("\nInvalid input!");
        return 0; // Terminate the program
    }

    // Initialize time
    srand(time(NULL));

    float* A = malloc_rand(size);
    float* B = malloc_rand(size);
    float* C = (float*) malloc(size * sizeof(float));
    int* idx = (int*) malloc(size * sizeof(float));

    // Prints INput arrays
    printf("A = ");
    print_array(float, size, A, "%.2f, ");
    printf("B = ");
    print_array(float, size, B, "%.2f, ");

    printf("\nExecuting...\n\n");

    // Measure execution time per implementation
    measure_time("C", & C_max, size, A, B, C, idx);
    measure_time("x86-64 Assembly (no SIMD)", &x86_64_max, size, A, B, C, idx);
    measure_time("x86-64 Assembly (SIMD, XMM)", &xmm_max, size, A, B, C, idx);
    measure_time("x86-64 Assembly (SIMD, YMM)", &ymm_max, size, A, B, C, idx);

    // Free malloc'd pointers
    free(A);
    free(B);
    free(C);
    free(idx);

    return 0;
}