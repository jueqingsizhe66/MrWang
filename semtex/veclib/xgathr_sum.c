/*****************************************************************************
 *  xgathr_sum:  vector gather, with summation:  z[i] += x[y[i]].
 *
 * $Id: xgathr_sum.c,v 6.2 2004/04/01 10:28:39 hmb Exp $
 *****************************************************************************/

#include <cfemdef.h>

#if defined(__uxp__)
#pragma global novrec
#pragma global noalias
#endif

void dgathr_sum (integer n, const double* x, const integer* y, double* z)
{
  register integer i;

  for (i = 0; i < n; i++) z[i] += x[y[i]];
}


void igathr_sum (integer n, const integer* x, const integer* y, integer* z)
{
  register integer i;

  for (i = 0; i < n; i++) z[i] += x[y[i]];
}


void sgathr_sum (integer n, const float* x, const integer* y, float* z)
{
  register integer i;

  for (i = 0; i < n; i++) z[i] += x[y[i]];
}
