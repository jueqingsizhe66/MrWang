/*****************************************************************************
 * xsadd:   y[i] = alpha + x[i].
 *
 * $Id: xsadd.c,v 6.2 2004/04/01 10:28:39 hmb Exp $
 *****************************************************************************/

#include <cfemdef.h>

#if defined(__uxp__)
#pragma global novrec
#pragma global noalias
#endif

void dsadd (integer n, double alpha, const double* x, integer incx,
	                                   double* y, integer incy)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;

  for (i = 0; i < n; i++) y[i*incy] = alpha + x[i*incx];
}


void isadd (integer n, integer alpha, const integer* x, integer incx,
	                                    integer* y, integer incy)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;

  for (i = 0; i < n; i++) y[i*incy] = alpha + x[i*incx];
}


void ssadd (integer n, float alpha, const float* x, integer incx,
	                                  float* y, integer incy)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;

  for (i = 0; i < n; i++) y[i*incy] = alpha + x[i*incx];
}
