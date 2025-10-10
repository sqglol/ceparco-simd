# CEPARCO Deep Dive: SIMD programming project

## Performance analysis

![](img/table.png)

### C implementation

The C implementation was a basic if/else branch inside a for loop. The program will linearly go through each pair of elements in the arrays and compare them directly; `C[i]` gets whichever is higher and `idx[i]` gets zero if `A[i] >= B[i]`. As expected, this was the **worst-performing** implementation, as this linear performance compounded with the additional overhead of the C language.

### x86-64 assembly implementation (no SIMD)

The x86-64 assembly implementation without SIMD was fundamentally very similar to the C implementation and thus shares its linear performance, as it still checks every pair of elements in order. It performed slightly better than C, as it did not have the aforementioned program overhead.

### x86-64 assembly implementation (XMM)

The x86-64 assembly implementation using XMM registers performed much better than the non-SIMD implementation. Here, the program goes through four elements at a time instead of one. The `VMAXPS` instruction efficiently stores the max elements in its two operand vectors into a destination vector, in this case `XMM0`. Then, we opted to use the `VCMPPS` instruction with a predicate of `0` to compare this new vector with the `B` vector to implement the behavior when checking for `A[i] >= B[i]`.

In cases where the input vector size is not a multiple of 4, allowing the SIMD implementations to keep going will result in writing to memory that is out of bounds, which *may* cause unpredictable behavior. This was addressed with a simple solution: when there are less than four elements remaining, the program switches to the SIMD-less implementation for the remaining elements (that is, performing a linear search).

### x86-64 assembly implementation (YMM)

The x86-64 assembly implementation using YMM registers, in all cases, performed very closely to the XMM implementation, but **slightly worse**. YMM **theoretically** offers twice the throughput as the XMM approach, as YMM can hold eight single-precision values as opposed to four. However, numerous possible explanations exist for why the YMM approach may have been slower, e.g. [additional latency introduced by the higher-order 128 bits in 256-bit register-to-register transfers](https://stackoverflow.com/a/60173277). This is likely processor-dependent, and may not be the case for all machines. Note that the YMM implementation used the same handling of boundary cases as with the XMM implementation, but with 8 instead of 4.

## Problems encountered

One of the encountered problems is the overwriting of memory outside of the intended arrays and variables of the program. Although our original implementation of SIMD ensures that the "boundary" elements are included, memory outside of these "boundary" elements may be written into since SIMD instructions assume they perform operations on memory that is either 128 bits wide for XMM registers of 256 bits wide for YMM registers. When performing operations on boundary elements that take up less total space than 128 or 256 bits, the surrounding memory is also altered. Visual Studio also returned warnings when this occurred. Thus, to account for this, we adapted the individual placement of values from the non-SIMD implementation for the final few "boundary" elements to ensure memory safety.

## Screenshots

The following screenshots include average execution times over 30 runs as well as the correctness checks.

### $2^{20}$

![](img/2_20.png)

### $2^{26}$

![](img/2_26.png)

### $2^{28}$

![](img/2_28.png)

### SIMD boundary test

![](img/2_20_boundary.png)