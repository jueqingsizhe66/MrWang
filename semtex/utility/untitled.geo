DefineConstant[ lc = { 0.1, Path "Gmsh/Parameters"}];
DefineConstant[ lc = { 0.1, Label "a", Path "Gmsh/Parameters"}];
Point(1) = {0.4, 0.6, 0, 1.0};
Point(2) = {0.5, 0.6, 0, 1.0};
Point(3) = {0.6, 0.6, 0, 1.0};
Point(4) = {0.7, 0.6, 0, 1.0};
Point(5) = {0.8, 0.6, 0, 1.0};
Point(6) = {0.9, 0.6, 0, 1.0};
Point(7) = {1, 0.6, 0, 1.0};
Point(8) = {0.7, 0.7, 0, 1.0};
Point(9) = {0.7, 0.8, 0, 1.0};
Point(10) = {0.7, 0.9, 0, 1.0};
Point(11) = {0.7, 0.5, 0, 1.0};
Point(12) = {0.7, 0.4, 0, 1.0};
Point(13) = {0.7, 0.3, 0, 1.0};
Circle(1) = {1, 4, 10};
Circle(2) = {1, 4, 13};
Circle(3) = {13, 4, 7};
Circle(4) = {10, 4, 7};