/*****************************************************************************
 * y[i] = (float) x[i]
 *
 * $Id: vsngl.c,v 6.3 2004/08/26 21:19:40 hmb Exp $
 *****************************************************************************/

#include <cfemdef.h>

void vsngl (integer n, const double *x, integer incx, float *y, integer incy)
{
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;
  y += (incy<0) ? (-n+1)*incy : 0;

  for (i = 0; i < n; i++) y[i*incy] = (float) x[i*incx];
}
