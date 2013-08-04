#ifndef DNS_H
#define DNS_H
//////////////////////////////////////////////////////////////////////////////
// dns.h: header file for direct numerical simulation solver.
//
// Copyright (c) 1994 <--> $Date: 2013/02/26 05:04:49 $, Hugh Blackburn
//
// $Id: dns.h,v 1.1 2013/02/26 05:04:49 hmb Exp $
//////////////////////////////////////////////////////////////////////////////

#include <sem.h>
#include <fieldforce.h>

class DNSAnalyser : public Analyser
// ===========================================================================
// Implement step-by-step processing and output control for flow solver.
// ===========================================================================
{
public:
  DNSAnalyser  (Domain*, BCmgr*, FEML*);
  void analyse (AuxField**, AuxField**);

private:
  ofstream       _flx_strm;

  bool           _wss; // -- Shorthand for Wall Shear Stress/traction.
  ofstream       _wss_strm;
  int_t          _nline;
  int_t          _nwall;
  int_t          _npad;

  vector<real_t> _work;

  void extract_wall ();
};

#endif
