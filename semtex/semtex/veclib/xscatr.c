/*****************************************************************************
 * xscatr:  vector scatter:  z[y[i]] = x[i].
 *
 * NB:  It is assumed that this operation is vectorizable, i.e. that there
 * are no repeated indices in the indirection vector y --- y is a permutator.
 *
 * $Id: xscatr.c,v 6.2 2004/04/01 10:28:39 hmb Exp $
 *****************************************************************************/

#include <cfemdef.h>

#if defined(__uxp__)
#pragma global novrec
#pragma global noalias
#endif
  
void dscatr (integer n, const double* x, const integer* y, double* z)
{
  register integer i;

  for (i = 0; i < n; i++) z[y[i]] = x[i];
}


void iscatr (integer n, const integer* x, const integer* y, integer* z)
{
  register integer i;

  for (i = 0; i < n; i++) z[y[i]] = x[i];
}


void sscatr (integer n, const float* x, const integer* y, float* z)
{
  register integer i;

  for (i = 0; i < n; i++) z[y[i]] = x[i];
}
