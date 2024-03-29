##############################################################################
# Makefile for spectral element Helmholtz solver.
#
# $Id: Makefile,v 6.6 2006/03/13 23:48:57 hmb Exp $
##############################################################################

SEM   = ..
VPATH = $(SEM)/src

ifdef MPI
  PROG = elliptic_mp
else
  PROG = elliptic
endif

# ----------------------------------------------------------------------------
#

SEMFILES  = auxfield bcmgr boundary bsys condition domain edge element \
            family feml field geometry integration matrix mesh misc pressure
SEMOBJ    = $(addsuffix .o,$(SEMFILES))
SEMHDR    = sem.h

# ----------------------------------------------------------------------------
# Default build.
#
ELLOBJ = drive.o helmholtz.o

$(PROG): sem $(SEMOBJ) $(ELLOBJ)
	$(LD) -o $@ $(ELLOBJ) $(SEMOBJ) $(LDFLAGS)

$(SEMOBJ): $(SEMHDR)

# ----------------------------------------------------------------------------
# Standard rules and definitions.
#
include $(VPATH)/Makefile

# ----------------------------------------------------------------------------
# Clean up executables and anything else
#
distclean:
	$(MAKE) clean
	rm -f elliptic elliptic_mp


# ----------------------------------------------------------------------------
# Special machine-dependent compilations.

ifeq ($(ARCH),SUPER-UX)
mesh.o: $(VPATH)/mesh.C
	$(CXX) $(CPPFLAGS) $(NOVEC) $(VPATH)/mesh.C
endif
