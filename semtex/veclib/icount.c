/*****************************************************************************
 * icount:  number of non-zero values in x.
 *
 * $Id: icount.c,v 6.2 2004/04/01 10:28:39 hmb Exp $
 *****************************************************************************/

#include <cfemdef.h>


integer icount (integer n, const integer* x, integer incx)
{
  register integer i, sum = 0;

  x += (incx<0) ? (-n+1)*incx : 0;

  for (i = 0; i < n; i++ ) sum += (x[i*incx]) ? 1 : 0;

  return sum;
}
