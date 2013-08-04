/*****************************************************************************
 * ifirst:  index of first non-zero value in x.
 *
 * $Id: ifirst.c,v 6.2 2004/04/01 10:28:39 hmb Exp $
 *****************************************************************************/

#include <cfemdef.h>


integer ifirst (integer n, const integer* x, integer incx)
{ 
  register integer i;

  x += (incx<0) ? (-n+1)*incx : 0;

  for (i = 0; i < n; i++) if (x[i*incx]) return i;
  
  return -1;
}
