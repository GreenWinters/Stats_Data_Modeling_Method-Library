/* 
    Please include compiler name below (you may also include any other modules you would like to be loaded)

COMPILER= gnu

    Please include All compiler flags and libraries as you want them run. You can simply copy this over from the Makefile's first few lines
 
CC = cc
OPT = -O3
CFLAGS = -Wall -std=gnu99 $(OPT)
MKLROOT = /opt/intel/composer_xe_2013.1.117/mkl
LDLIBS = -lrt -Wl,--start-group $(MKLROOT)/lib/intel64/libmkl_intel_lp64.a $(MKLROOT)/lib/intel64/libmkl_sequential.a $(MKLROOT)/lib/intel64/libmkl_core.a -Wl,--end-group -lpthread -lm

*/

const char* dgemm_desc = "Blocked dgemm with Transposed A and UnLooped Outer Loops.";

#if !defined(BLOCK_SIZE)
#define BLOCK_SIZE 70
#endif

#define min(a,b) (((a)<(b))?(a):(b))

/* This auxiliary subroutine performs a smaller dgemm operation
 *  C := C + A * B
 * where C is M-by-N, A is M-by-K, and B is K-by-N. */
static void do_block (int lda, int M, int N, int K, double* A_Transpose, double* B, double* C)
{
  /* For each row i of A */
  for (int i = 0; i < M; (i += 2))
    /* For each column j of B */ 
    for (int j = 0; j < N; (j += 2)) 
    {
     double cij_1, cij_2 , cij_3, cij_4, a_1, a_2, b_1, b_2;
      cij_1 = C[i+j*lda];
      cij_2 = C[(i+1)+j*lda];
      cij_3 = C[i+(j+1)*lda];
      cij_4 = C[(i+1)+(j+1)*lda];
          for (int k = 0; k < K; ++k)
             { a_1 = A_Transpose[i*lda+k];
              a_2 = A_Transpose[(i+1)*lda+k];
              b_1 = B[j*lda+k];
              b_2 = B[(j+1)*lda+k];
              cij_1 += a_1 * b_1;
              cij_2 += a_2 * b_1;
              cij_3 += a_1 * b_2;
              cij_4 += a_2 * b_2;
              }
                        
      C[i+j*lda] = cij_1;
      C[i+(j+1)*lda] = cij_3;
      C[(i+1)+j*lda] = cij_2;
      C[(i+1)+(j+1)*lda] = cij_4;
    }
}

/* This routine performs a dgemm operation
 *  C := C + A * B
 * where A, B, and C are lda-by-lda matrices stored in column-major format. 
 * On exit, A and B maintain their input values. */  
void square_dgemm (int lda, double* A_Transpose, double* B, double* C)
{
  /* For each block-row of A */ 
  for (int i = 0; i < lda; i += BLOCK_SIZE)
    /* For each block-column of B */
    for (int j = 0; j < lda; j += BLOCK_SIZE)
      /* Accumulate block dgemms into block of C */
      for (int k = 0; k < lda; k += BLOCK_SIZE)
      {
	/* Correct block dimensions if block "goes off edge of" the matrix */
	int M = min (BLOCK_SIZE, lda-i);
	int N = min (BLOCK_SIZE, lda-j);
	int K = min (BLOCK_SIZE, lda-k);

	/* Perform individual block dgemm */
	do_block(lda, M, N, K, A_Transpose + k + i*lda, B + k + j*lda, C + i + j*lda);
      }
}
