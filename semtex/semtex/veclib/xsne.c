/*****************************************************************************
 * xsne:  y[i] = alpha != x[i].
 *
 * $Id: xsne.c,v 6.2 2004/04/01 10:28:39 hmb Exp $
 *****************************************************************************/

#include <cfemdef.h>

#if defined(__uxp__)
#pragma global novrec
#pragma global noalias
#endif

void dsne (integer n, double alpha,
	   const double* x, integer incx,
	         double* y, integer incy)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;

  for (i = 0; i < n; i++) y[i*incy] = (alpha != x[i*incx]) ? 1 : 0;
}


void isne (integer n, integer alpha,
	   const integer* x, integer incx,
	         integer* y, integer incy)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;

  for (i = 0; i < n; i++) y[i*incy] = (alpha != x[i*incx]) ? 1 : 0;
}


void ssne (integer n, float alpha,
	   const float* x, integer incx,
	         float* y, integer incy)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;

  for (i = 0; i < n; i++) y[i*incy] = (alpha != x[i*incx]) ? 1 : 0;
}
