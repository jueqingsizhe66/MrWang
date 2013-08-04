#ifndef FEMDEF_H
#define FEMDEF_H
/*****************************************************************************
 * Common names and typedefs for finite-element codes.
 *
 * $Id: cfemdef.h,v 6.5 2008/01/04 12:25:21 hmb Exp $
 *****************************************************************************/

#if defined(_SX)		/* NEC SX-4.        */
  typedef long int integer;
  typedef double   real;
#else                           /* Everything else. */
  typedef int     integer;
  typedef double  real;
#endif

typedef integer int_t;
typedef real    real_t;

typedef struct { real_t x, y, z; } Point;
typedef Point                      Vector;

#define STR_MAX    2048
#define F77NAME(x) x##_

typedef enum quadrature_kind {
  GJ  = 'G',	/* Gauss-Jacobi quadrature.         */
  GLJ = 'L',	/* Gauss-Lobatto-Jacobi quadrature. */
  GRJ = 'R',	/* Gauss-Radau-Jacobi quadrature.   */
  TRZ = 'U'	/* Trapezoidal (uniform mesh).      */
} QuadratureKind;

typedef enum solver_kind {
  DIRECT,	/* Cholesky back-substitution.                           */
  JACPCG,	/* Conjugate gradient, Jacobi (diagonal) preconditioner. */
  BLJPCG	/* Conjugate gradient, block Jacobi      preconditioner. */
} SolverKind;

typedef enum transform_kind {
  INVERSE = -1,	/* Basis    --> physical space. */
  FORWARD = +1	/* Physical --> basis    space. */
} TransformKind;

typedef enum exchange_kind {
  FULL,		/* Full exchange (preserves planar and element structure). */
  HALF		/* Half memory exchange across processes (planar only).    */
} ExchangeKind;

#endif
