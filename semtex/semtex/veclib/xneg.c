/*****************************************************************************
 * xneg:  x[i] = -x[i].
 *
 * $Id: xneg.c,v 6.2 2004/04/01 10:28:39 hmb Exp $
 *****************************************************************************/

#include <cfemdef.h>


#if defined(__uxp__)
#pragma global novrec
#pragma global noalias
#endif

void dneg (integer n, double* x, integer incx)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;

#if defined(_SX)
#pragma vdir nodep
#endif

  for (i = 0; i < n; i++) x[i*incx] = -x[i*incx];
}


void ineg (integer n, integer* x, integer incx)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;

#if defined(_SX)
#pragma vdir nodep
#endif

  for (i = 0; i < n; i++) x[i*incx] = -x[i*incx];
}


void sneg (integer n, float* x, integer incx)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;

#if defined(_SX)
#pragma vdir nodep
#endif

  for (i = 0; i < n; i++) x[i*incx] = -x[i*incx];
}
