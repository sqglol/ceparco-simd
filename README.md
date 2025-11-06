# CEPARCO Deep Dive: CUDA programming project



## Table of Execution Times

| :--- | :--- | :--- |
| x86-64 | 349.7 | |
| X86-64 SIMD XMM | | |
| x86-64 SIMD YMM | | |
| CUDA Unified | | |
| CUDA Prefetch | | |
| CUDA Prefetch+page creation | | |
| CUDA Prefetch+Page creitition+memadvise | | |
| CUDA classic MEMCPY | | |
| CUDA data init in a CUDA kernel | | |

For C and AVX kernels, they were timed from the start of their function's execution until they returned. For all implementations except grid-stride loop, the total host-to-device transfer time is not included in the final estimate of the overall execution time as the data has already been prefetched and transferred into the GPU by the time the kernel is executed. This can be viewed in the Nsight Systems reports; for these implementations, **no further host-to-device transfers occur during and after the period in which the kernel is executed ten times**. Classic MEMCPY required hefty host-to-device and device-to-host transfers, while initializing the array within the CUDA device meant that we only needed to transfer from the device to the host *after* the program's execution.

## Observations (SIMD)

### Result Analysis

The execution times across these implementations reveal a clear performance hierarchy driven by parallelism and memory management overhead. The slowest baseline is C, which is significantly improved by basic compiler optimizations. The introduction of SIMD Vectorization provides a massive speedup by processing 4 to 8 floating-point numbers simultaneously on the CPU. However, the very minimal change in performance between XMM and YMM suggests the CPU implementation becomes memory-bound the CPU is waiting for data more than it's executing arithmetic.

The shift to the GPU delivers the most dramatic gains, with the highly optimized CUDA classic memCPY achieving the fastest time. This showcases the immense power of the GPU's thousands of threads, which easily outweighs the overhead of two explicit memory transfers (Host to Device and Device to Host). In contrast, the unoptimized CUDA implementation is significantly slower. This high overhead is primarily due to page-faulting the GPU incurring latency as it fetches data pages on demand from the CPU memory upon first access, this is fixed by the mor eoptimized implementations, shown by the fact that not only is the kernal time significantly faster, the transfer time from Host to Device is also not included with the total execution time.

The data demonstrates that Unified Memory requires explicit optimization to be competitive. Simply using CUDA Prefetch reduces the time by eliminating runtime page faults, and the combination of Prefetch, page creation, and memAdvise further lowers the time. This optimized Unified Memory performance is almost identical to the Classic MemCopy method, confirming that memory management overhead can be minimized with fine-grained control. Finally, Data initialization in a CUDA kernel is inefficient suggesting that the overhead of using the GPU's Random Number Generator is significantly greater than simply having the CPU initialize the data and then transferring it via cudaMemcpy.


## Observations (CUDA)

### SIMD and SIMT

SIMD (single instruction, multiple *data*) and SIMT (single instruction, multiple *threads*) are two forms of data parallelism. AVX instructions are an example of the former, while CUDA is an example of the latter. The key difference between the two is that AVX makes use only of a single thread with multiple data paths to handle multiple data at a time. On the other hand, CUDA makes use of multiple threads to accomplish a similar task. For cases such as this one, where the data is highly structured and the operation performed is basic (arithmetic), CUDA may be overkill and SIMD solutions may be preferred, especially when power efficiency is of concern. Solutions such as CUDA shine when, among other reasons, (1) power efficiency is irrelevant, (2) data might be more *complex* in structure, as threads could be more flexible with how they handle multiple data (with the caveat that a basic grid-stride loop like demonstrated here might no longer be applicable in such cases).

### Prefetching

From an intuitive standpoint, prefetching might only be truly beneficial for tasks where the GPU is often idle and waiting for data. In cases where the execution time bottleneck is instead computational speed (that is, for very complex tasks), prefetching will likely be not as effective and in extreme cases might only introduce additional overhead to the program; allowing CUDA to manage its own memory might be better in such cases. Another thing to consider might be the memory (VRAM) available on the device in the first place, as if working with a lower-end device attempting to prefetch all your data ahead of time might "clog" up the device and potentially impede other data transfers. For this project, however, prefetching appears to have been strictly beneficial.


## Problems encountered

### SIMD boundary conditions

One of the encountered problems is the overwriting of memory outside of the intended arrays and variables of the program. Although our original implementation of SIMD ensures that the "boundary" elements are included, memory outside of these "boundary" elements may be written into since SIMD instructions assume they perform operations on memory that is either 128 bits wide for XMM registers of 256 bits wide for YMM registers. When performing operations on boundary elements that take up less total space than 128 or 256 bits, the surrounding memory is also altered. Visual Studio also returned warnings when this occurred. Thus, to account for this, we adapted the individual placement of values from the non-SIMD implementation for the final few "boundary" elements to ensure memory safety.

### `cudaMemcpy()`

It was a bit difficult to implement classic `cudaMemcpy()` as it was not covered in class. However, the basic idea was very simple --- allocate memory on the host and device and manually transfer data between the two as needed.

### Random number generation on CUDA device

When initializing the arrays on the CUDA device, we (obviously) lose access to host library functions, such as the C standard library's `rand()` function. As there was no easy alternative without having to bloat our program with extra dependencies (CUDA has specific random number libraries), we opted to simply use a value of `i` and `i * 2` for `A` and `B` respectively. This appeared to be okay as doing so did not diminish the goal of the program, which was to measure performance.














## Screenshots

### $2^{20}$

![](img/2_20.png)

### $2^{26}$

![](img/2_26.png)

### $2^{28}$

![](img/2_28.png)

### SIMD boundary test

![](img/2_20_boundary.png)

### GSL

![](img/GSL.png)

### GSL + PF

![](img/GSL_PF.png)

### GSL + PF + PC

![](img/GSL_PF_PC.png)

### GSL + PF + PC + MA

![](img/GSL_PF_PC_MA.png)

### MEMCPY

![](img/MEMCPY.png)

### INIT

![](img/MAX_INIT.png)
