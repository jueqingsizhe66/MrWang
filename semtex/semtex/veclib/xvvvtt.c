/*****************************************************************************
 * xvvvtt:  z[i] = w[i] * x[i] * y[i]
 *
 * $Id: xvvvtt.c,v 6.1 2005/09/08 05:28:41 hmb Exp $
 *****************************************************************************/

#include <cfemdef.h>

#if defined(__uxp__)
#pragma global novrec
#pragma global noalias
#endif

void dvvvtt (integer n,
	     const double* w, integer incw,
	     const double* x, integer incx,
	     const double* y, integer incy,
	           double* z, integer incz)
{
  register integer  i;
  
  w += (incw<0) ? (-n+1)*incw : 0;
  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;
  z += (incz<0) ? (-n+1)*incz : 0;

  for (i = 0; i < n; i++) z[i*incz] = w[i*incw] * x[i*incx] * y[i*incy];
}


void svvvtt (integer n,
	     const float* w, integer incw,
	     const float* x, integer incx,
	     const float* y, integer incy,
	           float* z, integer incz)
{
  register integer  i;
  
  w += (incw<0) ? (-n+1)*incw : 0;
  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;
  z += (incz<0) ? (-n+1)*incz : 0;

  for (i = 0; i < n; i++) z[i*incz] = w[i*incw] * x[i*incx] * y[i*incy];
}
