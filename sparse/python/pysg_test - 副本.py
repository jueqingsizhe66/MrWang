import pysg
import unittest
import math
class testFunctest(unittest.TestCase):
  """ simple test of sparse grid for sparse grid in 3d of level 3 """
  def testSGNoBound2D(self):
#
#  SG is a sparse grid of dimension 2 and level 3.
#  Create sg.indices which stores level and position for each point.
#    
    sg = pysg.sparseGrid(2,4)
#
#  Determine sg.gP with the coordinates of the points 
#  associated with the sparse grid index set.
#
    sg.generatePoints()
#
#  Print the points in the grid.
#
    print ""
    print "Coordinates of points in 2D sparse grid of level 3."
    print ""
    for i in range ( len(sg.indices) ):
      sg.gP[tuple(sg.indices[i])].printPoint()

#
#  Evaluate 4x(1-x)*4y(1-y) at each grid point.
#
    for i in range(len(sg.indices)):
      sum = 1.0
      pos = sg.gP[tuple(sg.indices[i])].pos
      for j in range(len(pos)):
        sum *= 1.0-pos[j]
      sg.gP[tuple(sg.indices[i])].fv = sum
#
#  Convert to hierarchical values.
#
    sg.nodal2Hier()
#
#  Does the evaluation of sparse grid function in
#  hierarchical values give the correct value gv?
#
    for i in range(len(sg.indices)):
      self.assertEqual(sg.gP[tuple(sg.indices[i])].fv,\
        sg.evalFunct(sg.gP[tuple(sg.indices[i])].pos))

if __name__=="__main__":
  unittest.main()
    


