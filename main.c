#include <stdio.h>
#include <time.h>

// x86-64 implementation, no SIMD
extern void x86_64_max(int n, float A[], float B[], float C[], int idx[]);

// Prints the results of the program execution
// TODO: First and last five only
void print_results(int n, float C[], int idx[]) {
    for (int i = 0; i < n; i++)
        printf("%f ", C[i]);

    printf("\n");

    for (int i = 0; i < n; i++)
        printf("%d ", idx[i]);

    printf("\n");
}

// C implementation
void C_max(int n, float A[], float B[], float C[], int idx[]) {
    for (int i = 0; i < n; i++) {
        if (A[i] >= B[i]) {
            C[i] = A[i];
            idx[i] = 0;
        } else {
            C[i] = B[i];
            idx[i] = 0;
        }
    }
}

int main() {
    int n = 5;
    float A[5] = {4, 3, 5, 8, 12};
    float B[5] = {2, 4, 4, 8, 69};
    float C[5] = {0};
    int idx[5] = {0};

    clock_t start_time, end_time;

    // C
    start_time = clock();
    C_max(n, A, B, C, idx);
    end_time = clock();

    print_results(n, C, idx);
    printf("%f\n\n", (double) (end_time - start_time) / CLOCKS_PER_SEC);

    // x86-64, no SIMD
    start_time = clock();
    x86_64_max(n, A, B, C, idx);
    end_time = clock();

    print_results(n, C, idx);
    printf("%f\n\n", (double) (end_time - start_time) / CLOCKS_PER_SEC);

    return 0;
}