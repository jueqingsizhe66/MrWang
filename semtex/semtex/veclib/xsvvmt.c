/*****************************************************************************
 * xsvvmt:  z[i] = alpha * (x[i] - y[i]).
 *
 * $Id: xsvvmt.c,v 6.2 2004/04/01 10:28:39 hmb Exp $
 *****************************************************************************/

#include <cfemdef.h>

#if defined(__uxp__)
#pragma global novrec
#pragma global noalias
#endif

void dsvvmt (integer n, double alpha,
	     const double* x, integer incx,
	     const double* y, integer incy,
	           double* z, integer incz)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;
  z += (incz<0) ? (-n+1)*incz : 0;
  
  for (i = 0; i < n; i++) z[i*incz] = alpha * (x[i*incx] - y[i*incy]);
}


void ssvvmt (integer n, float alpha,
	     const float* x, integer incx,
	     const float* y, integer incy,
	           float* z, integer incz)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;
  z += (incz<0) ? (-n+1)*incz : 0;
  
  for (i = 0; i < n; i++) z[i*incz] = alpha * (x[i*incx] - y[i*incy]);
}
