/*****************************************************************************
 * xvadd:  z[i] = x[i] + y[i].
 *
 * $Id: xvadd.c,v 6.2 2004/04/01 10:28:39 hmb Exp $
 *****************************************************************************/

#include <cfemdef.h>


#if defined(__uxp__)
#pragma global novrec
#pragma global noalias
#endif

void dvadd (integer n,
	    const double* x, integer incx,
	    const double* y, integer incy,
	          double* z, integer incz)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;
  z += (incz<0) ? (-n+1)*incz : 0;

  for (i = 0; i < n; i++) z[i*incz] = x[i*incx] + y[i*incy];
}


void ivadd (integer n,
	    const integer* x, integer incx,
	    const integer* y, integer incy,
	          integer* z, integer incz)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;
  z += (incz<0) ? (-n+1)*incz : 0;

  for (i = 0; i < n; i++) z[i*incz] = x[i*incx] + y[i*incy];
}


void svadd (integer n,
	    const float* x, integer incx,
	    const float* y, integer incy,
	          float* z, integer incz)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;
  z += (incz<0) ? (-n+1)*incz : 0;

  for (i = 0; i < n; i++) z[i*incz] = x[i*incx] + y[i*incy];
}
