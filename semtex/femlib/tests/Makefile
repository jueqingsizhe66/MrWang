##############################################################################
# Compile test codes for femlib library functions.
#
# $Id: Makefile,v 6.3 2009/01/29 03:16:04 hmb Exp $
##############################################################################

SEM  = ../..

# ----------------------------------------------------------------------------
# Pattern rules are enough for all codes here:
#
% : %.c
	$(CC) $(CFLAGS) -o $@ $@.c -I$(SEM)/include -I. \
	-L$(SEM)/lib/$(ARCH) -lfem -lvec -lm

% : %.C
	$(CXX) -o $@ $@.C $(CXXFLAGS) -I$(SEM)/include -I. \
	$(LDFLAGS)
#	-L$(SEMHOME)/lib/$(ARCH) -lfem -lvec $(F77LIBS) -lm


# ----------------------------------------------------------------------------
# Standard rules and definitions.
#
include $(SEM)/src/Makefile
