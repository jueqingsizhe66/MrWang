Group {
  DefineGroup[ DomainM, DomainB, DomainS ];
  DefineGroup[ DomainL, DomainNL, Dummy ];
  DefineGroup[ Rotor_Inds, Rotor_IndsP, Rotor_IndsN, Rotor_Magnets, Rotor_Bars ];
  DefineGroup[ Surf_bn0, Rotor_Bnd_MBaux] ;
  DefineGroup[ Resistance_Cir, Inductance_Cir, Capacitance_Cir, DomainZt_Cir, DomainSource_Cir ];
}

Function{

  DefineConstant[ Flag_Cir, Flag_NL, Flag_ParkTransformation, Flag_ComputeLosses ];
  DefineConstant[ Flag_ImposedSpeed = {1, Visible 0} ];
  DefineConstant[ Term_vxb = {0, Visible 0},
                  NbPhases = {3, Visible 0}];
  DefineConstant[ AxialLength        = {1, Visible 0},
                  FillFactor_Winding = {1, Visible 0},
                  Factor_R_3DEffects = {1, Visible 0},
                  SymmetryFactor     = {1, Visible 0} ];

  Flag_Symmetry = (SymmetryFactor==1) ? 0 : 1 ;

  DefineConstant[ Nb_max_iter        = {20, Visible 0},
                  relaxation_factor  = {1, Visible 0},
                  stop_criterion     = {1e-5, Visible 0},
                  reltol             = {1e-7, Visible 0},
                  abstol             = {1e-5, Visible 0} ];

  DefineConstant[ T = {1/Freq, Visible 0} ] ; // Fundamental period in s

  DefineConstant[ time0      = {0, Visible 0},
                  NbT        = {1, Visible 0},
                  timemax    = {NbT*T, Visible 0},
                  NbSteps    = {100, Visible 0},
                  delta_time = {T/NbSteps, Visible 0}
  ];

  DefineConstant[ II, VV, pA, pB, pC, Ie, ID, IQ, I0 ];
  DefineFunction[ br, js, Resistance, Inductance, Capacitance ];
  DefineFunction[ Theta_Park, Theta_Park_deg, RotorPosition, RotorPosition_deg ] ;

  DefineConstant[ Inertia  ];
  DefineFunction[ Friction, Torque_mec ];

  DefineConstant[ Flag_SrcType_Rotor = {0, Visible 0} ];

  DefineConstant[ Clean_Results = { 1, Choices {0,1},
    Label "Remove previous result files",
    Path "Input/1", Visible 1 } ] ;

  DefineConstant[ Flag_SaveAllSteps = {0, Label "Save all time steps",
      Path "Input/0", Choices {0,1}} ];

  DefineConstant[ my_output={"Output/40T_rotor", Visible 0}];
}

Include "BH.pro"; // nonlinear BH caracteristic of magnetic material

Group {

  Inds = Region[ {Stator_Inds, Rotor_Inds} ] ;

  DomainB = Region[ {Inds} ] ;
  DomainM = Region[ {Rotor_Magnets} ] ;

  Stator  = Region[{ StatorC, StatorCC }] ;
  Rotor   = Region[{ RotorC,  RotorCC }] ;

  Rotor_Moving = Region[{ Rotor, Rotor_Air, Rotor_Airgap, Rotor_Inds, Rotor_Bnd_MBaux} ] ; // Use in ChangeOfCoordinates

  MB  = MovingBand2D[ MovingBand_PhysicalNb, Stator_Bnd_MB, Rotor_Bnd_MB, SymmetryFactor] ;
  Air = Region[{ Rotor_Air, Rotor_Airgap, Stator_Air, Stator_Airgap, MB } ] ;
  Inds = Region[{ Rotor_Inds, Stator_Inds } ] ;

  DomainV = Region[{}]; // Speed considered either with term v/\b
  If(Term_vxb) // or not dynamics in time domain + mechanics
    DomainV = Region[{ RotorC }];
  EndIf

  DomainCC = Region[{ Air, Inds, StatorCC, RotorCC }];
  DomainC  = Region[{ StatorC, RotorC }];
  Domain  = Region[{ DomainCC, DomainC }] ;

  If(Flag_NL)
    DomainNL = Region[ {Stator_Fe, Rotor_Fe } ];
    DomainL  = Region[ {Domain,-DomainNL} ];
  EndIf

  DomainKin = #1234 ; // Dummy region number for mechanical equation
  DomainDummy = #12345 ; // Dummy region number for mechanical equation
}

Function {
  mu0 = 4.e-7 * Pi ;

  sigma_al = 3.72e7 ; // conductivity of aluminum [S/m]
  sigma_cu = 5.9e7  ; // conductivity of copper [S/m]

  nu [#{Air, Inds, Stator_Al, Rotor_Al, Stator_Cu, Rotor_Cu, Rotor_Magnets, Rotor_Bars}]  = 1. / mu0 ;

  If(!Flag_NL)
    nu [#{Stator_Fe, Rotor_Fe }]  = 1 / (mur_fe * mu0) ;
  EndIf
  If(Flag_NL)
   nu [#{Stator_Fe, Rotor_Fe }] = nu_1a[$1] ;
  EndIf
  dhdb_NL [ DomainNL ] = dhdb_1a_NL[$1];

  sigma[#{Rotor_Fe}] = sigma_fe ;
  sigma[#{Rotor_Al, Stator_Al}] = sigma_al ;
  sigma[#{Rotor_Cu, Stator_Cu}] = sigma_cu ;
  sigma[#{Inds}] = sigma_cu ;

  rho[] = 1/sigma[] ;

  Rb[] = Factor_R_3DEffects*AxialLength*FillFactor_Winding*NbWires[]^2/SurfCoil[]/sigma[] ;
  Resistance[#{Stator_Inds, Rotor_Inds}] = Rb[] ;

  Idir[#{Stator_IndsP, Rotor_IndsP}] =  1 ;
  Idir[#{Stator_IndsN, Rotor_IndsN}] = -1 ;

  // Functions for Park transformation
  Idq0[] = Vector[ ID, IQ, I0 ] ;
  Pinv[] = Tensor[ Sin[Theta_Park[]],        Cos[Theta_Park[]],        1,
                   Sin[Theta_Park[]-2*Pi/3], Cos[Theta_Park[]-2*Pi/3], 1,
                   Sin[Theta_Park[]+2*Pi/3], Cos[Theta_Park[]+2*Pi/3], 1 ];

  P[] = 2/3 * Tensor[ Sin[Theta_Park[]], Sin[Theta_Park[]-2*Pi/3], Sin[Theta_Park[]+2*Pi/3],
                      Cos[Theta_Park[]], Cos[Theta_Park[]-2*Pi/3], Cos[Theta_Park[]+2*Pi/3],
                      1/2, 1/2, 1/2 ] ;

  Iabc[]     = Pinv[] * Idq0[] ;
  Flux_dq0[] = P[] * Vector[#11, #22, #33] ;

  If(Flag_ParkTransformation)
    II = 1 ;
    IA[] = CompX[ Iabc[] ] ;
    IB[] = CompY[ Iabc[] ] ;
    IC[] = CompZ[ Iabc[] ] ;
  EndIf
  If(!Flag_ParkTransformation)
    IA[] = F_Sin_wt_p[]{2*Pi*Freq, pA} ;
    IB[] = F_Sin_wt_p[]{2*Pi*Freq, pB} ;
    IC[] = F_Sin_wt_p[]{2*Pi*Freq, pC} ;

    js[PhaseA] = II * NbWires[]/SurfCoil[] * IA[] * Idir[] * Vector[0, 0, 1] ;
    js[PhaseB] = II * NbWires[]/SurfCoil[] * IB[] * Idir[] * Vector[0, 0, 1] ;
    js[PhaseC] = II * NbWires[]/SurfCoil[] * IC[] * Idir[] * Vector[0, 0, 1] ;
  EndIf

  Velocity[] = wr*XYZ[]/\Vector[0,0,-1] ;

  // Maxwell stress tensor
  T_max[] = ( SquDyadicProduct[$1] - SquNorm[$1] * TensorDiag[0.5, 0.5, 0.5] ) / mu0 ;
  // Average value computed in the frequency domain:
  T_max_cplx[] = 0.5*Re[ (TensorV[CompX[$1]*Conj[$1], CompY[$1]*Conj[$1], CompZ[$1]*Conj[$1]] - $1*Conj[$1] * TensorDiag[0.5, 0.5, 0.5] ) / mu0] ;

  AngularPosition[] = (Atan2[$Y,$X]#7 >= 0.)? #7 : #7+2*Pi ;

  RotatePZ[] = Rotate[ Vector[$X,$Y,$Z], 0, 0, $1 ] ;//Watch out: Do not use XYZ[]!

  Torque_mag[] = #55 ; // Torque computed in postprocessing (Trotor in #54, Tstator in #55, Tmb in #56)
}

//-------------------------------------------------------------------------------------

Jacobian {
  { Name Vol; Case { { Region All ; Jacobian Vol; } } }
}

Integration {
  { Name I1 ; Case {
      { Type Gauss ;
        Case {
          { GeoElement Triangle   ; NumberOfPoints  6 ; }
	  { GeoElement Quadrangle ; NumberOfPoints  4 ; }
	  { GeoElement Line       ; NumberOfPoints  13 ; }
        }
      }
    }
  }
}

//-------------------------------------------------------------------------------------

Constraint {

  { Name MVP_2D ;
    Case {
      { Region Surf_Inf ; Type Assign; Value 0. ; }
      { Region Surf_bn0 ; Type Assign; Value 0. ; }

      If(Flag_Symmetry)
        { Region Surf_cutA1; SubRegion Region[{Surf_Inf,Surf_bn0}]; Type Link;
          RegionRef Surf_cutA0; SubRegionRef Region[{Surf_Inf,Surf_bn0}];
          Coefficient (NbrPoles%2)?-1:1 ; Function RotatePZ[-NbrPoles*2*Pi/NbrPolesTot]; }
        { Region Surf_cutA1; Type Link; RegionRef Surf_cutA0;
          Coefficient (NbrPoles%2)?-1:1 ; Function RotatePZ[-NbrPoles*2*Pi/NbrPolesTot]; }

        //For the moving band
        For k In {1:SymmetryFactor-1}
        { Region Rotor_Bnd_MB~{k+1} ; SubRegion Rotor_Bnd_MB~{(k!=SymmetryFactor-1)?k+2:1}; Type Link;
          RegionRef Rotor_Bnd_MB_1; SubRegionRef Rotor_Bnd_MB_2;
          Coefficient ((NbrPoles%2)?-1:1)^(k); Function RotatePZ[-k*NbrPoles*2*Pi/NbrPolesTot]; }
        EndFor

      EndIf
    }
  }

  { Name Current_2D ;
    Case {
      If(Flag_SrcType_Stator==1)
        { Region PhaseA     ; Value II*Idir[] ; TimeFunction IA[]; }
        { Region PhaseB     ; Value II*Idir[] ; TimeFunction IB[]; }
        { Region PhaseC     ; Value II*Idir[] ; TimeFunction IC[]; }
      EndIf
      If(Flag_SrcType_Rotor==1)
        { Region Rotor_Inds ; Value Ie*Idir[] ; }
      EndIf
    }
  }

  { Name Voltage_2D ;
    Case {
      { Region RotorC  ; Value 0. ; } // Not needed if Global equation not in formulation
      { Region StatorC ; Value 0. ; } // Not needed if Global equation not in formulation
    }
  }

  { Name Current_Cir ;
    Case {
      If(Flag_Cir && Flag_SrcType_Stator==1)
        { Region Input1  ; Value II  ; TimeFunction IA[]; }
        { Region Input2  ; Value II  ; TimeFunction IB[]; }
        { Region Input3  ; Value II  ; TimeFunction IC[]; }
      EndIf
    }
  }

  { Name Voltage_Cir ; // Example induction machine
    Case {
      If(Flag_Cir && Flag_SrcType_Stator==2 && !Flag_NL)
        { Region Input1  ; Value VV  ; TimeFunction IA[]; }
        { Region Input2  ; Value VV  ; TimeFunction IB[]; }
        { Region Input3  ; Value VV  ; TimeFunction IC[]; }
      EndIf
      If(Flag_Cir && Flag_SrcType_Stator==2 && Flag_NL)
        { Region Input1  ; Value VV  ; TimeFunction IA[]*Frelax[]; }
        { Region Input2  ; Value VV  ; TimeFunction IB[]*Frelax[]; }
        { Region Input3  ; Value VV  ; TimeFunction IC[]*Frelax[]; }
      EndIf
    }
  }


  //Kinetics
  { Name CurrentPosition ;
    Case {
      { Region DomainKin ; Type Init ; Value 0.#66 ; }
    }
  }

  { Name CurrentVelocity ;
    Case {
      { Region DomainKin ; Type Init ; Value 0. ; } // in rads/s
    }
  }

}

//-----------------------------------------------------------------------------------------------

FunctionSpace {

  { Name Hcurl_a_2D ; Type Form1P ;
    BasisFunction {
      { Name se1 ; NameOfCoef ae1 ; Function BF_PerpendicularEdge ;
        Support Region[{ Domain, Rotor_Bnd_MBaux }] ; Entity NodesOf [ All ] ; }
   }
    Constraint {
      { NameOfCoef ae1 ; EntityType NodesOf ; NameOfConstraint MVP_2D ; }
    }
  }

  // Gradient of Electric scalar potential (2D)
  { Name Hregion_u_Mag_2D ; Type Form1P ;
    BasisFunction {
      { Name sr ; NameOfCoef ur ; Function BF_RegionZ ;
        Support DomainC ; Entity DomainC ; }
    }
    GlobalQuantity {
      { Name U ; Type AliasOf        ; NameOfCoef ur ; }
      { Name I ; Type AssociatedWith ; NameOfCoef ur ; }
    }
    Constraint {
      { NameOfCoef U ; EntityType GroupsOfNodesOf ; NameOfConstraint Voltage_2D ; }
      { NameOfCoef I ; EntityType GroupsOfNodesOf ; NameOfConstraint Current_2D ; }
    }
  }

  { Name Hregion_i_Mag_2D ; Type Vector ;
    BasisFunction {
      { Name sr ; NameOfCoef ir ; Function BF_RegionZ ;
        Support DomainB ; Entity DomainB ; }
    }
    GlobalQuantity {
      { Name Ib ; Type AliasOf        ; NameOfCoef ir ; }
      { Name Ub ; Type AssociatedWith ; NameOfCoef ir ; }
    }
    Constraint {
      { NameOfCoef Ub ; EntityType Region ; NameOfConstraint Voltage_2D ; }
      { NameOfCoef Ib ; EntityType Region ; NameOfConstraint Current_2D ; }
    }
  }

  { Name Hregion_Z ; Type Scalar ; // Circuit equations
    BasisFunction {
      { Name sr ; NameOfCoef ir ; Function BF_Region ;
        Support DomainZt_Cir ; Entity DomainZt_Cir ; }
    }
    GlobalQuantity {
      { Name Iz ; Type AliasOf        ; NameOfCoef ir ; }
      { Name Uz ; Type AssociatedWith ; NameOfCoef ir ; }
    }
    Constraint {
      { NameOfCoef Uz ; EntityType Region ; NameOfConstraint Voltage_Cir ; }
      { NameOfCoef Iz ; EntityType Region ; NameOfConstraint Current_Cir ; }
    }
  }

  // For use in Mechanical equation
  { Name Position ; Type Scalar ;
    BasisFunction {
      { Name sr ; NameOfCoef ir ; Function BF_Region ;
        Support DomainKin ; Entity DomainKin ; }
    }
    GlobalQuantity {
      { Name P ; Type AliasOf  ; NameOfCoef ir ; }
    }
    Constraint {
      { NameOfCoef P ; EntityType Region ; NameOfConstraint CurrentPosition ; }
    }
  }


  { Name Velocity ; Type Scalar ;
    BasisFunction {
      { Name sr ; NameOfCoef ir ; Function BF_Region ;
        Support DomainKin ; Entity DomainKin ; } }
    GlobalQuantity {
      { Name V ; Type AliasOf ; NameOfCoef ir ; }
    }
    Constraint {
      { NameOfCoef V ; EntityType Region ; NameOfConstraint CurrentVelocity ; }
    }
  }

}

//-----------------------------------------------------------------------------------------------

Formulation {

  { Name MagStaDyn_a_2D ; Type FemEquation ;
    Quantity {
      { Name a  ; Type Local  ; NameOfSpace Hcurl_a_2D ; }
      { Name ur ; Type Local  ; NameOfSpace Hregion_u_Mag_2D ; }
      { Name I  ; Type Global ; NameOfSpace Hregion_u_Mag_2D [I] ; }
      { Name U  ; Type Global ; NameOfSpace Hregion_u_Mag_2D [U] ; }

      { Name ir ; Type Local  ; NameOfSpace Hregion_i_Mag_2D ; }
      { Name Ub ; Type Global ; NameOfSpace Hregion_i_Mag_2D [Ub] ; }
      { Name Ib ; Type Global ; NameOfSpace Hregion_i_Mag_2D [Ib] ; }

      { Name Uz ; Type Global ; NameOfSpace Hregion_Z [Uz] ; }
      { Name Iz ; Type Global ; NameOfSpace Hregion_Z [Iz] ; }
    }
    Equation {
      Galerkin { [ nu[{d a}] * Dof{d a}  , {d a} ] ;
        In Domain ; Jacobian Vol ; Integration I1 ; }
      Galerkin { JacNL [ dhdb_NL[{d a}] * Dof{d a} , {d a} ] ;
        In DomainNL ; Jacobian Vol ; Integration I1 ; }

      Galerkin {  [  0*Dof{d a} , {d a} ]  ; // DO NOT REMOVE!!! - Keeping track of Dofs in auxiliar line of MB if Symmetry=1
        In Rotor_Bnd_MBaux; Jacobian Vol; Integration I1; }

      Galerkin { [ -nu[] * br[] , {d a} ] ;
        In DomainM ; Jacobian Vol ; Integration I1 ; }

      Galerkin { DtDof[ sigma[] * Dof{a} , {a} ] ;
        In DomainC ; Jacobian Vol ; Integration I1 ; }
      Galerkin { [ sigma[] * Dof{ur}, {a} ] ;
        In DomainC ; Jacobian Vol ; Integration I1 ; }

      Galerkin { [ -sigma[] * (Velocity[] *^ Dof{d a}) , {a} ] ;
        In DomainV ; Jacobian Vol ; Integration I1 ; }

      Galerkin { [ -js[] , {a} ] ;
        In DomainS ; Jacobian Vol ; Integration I1 ; }

      Galerkin { DtDof[ sigma[] * Dof{a} , {ur} ] ;
        In DomainC ; Jacobian Vol ; Integration I1 ; }
      Galerkin { [ sigma[] * Dof{ur} , {ur} ] ;
        In DomainC ; Jacobian Vol ; Integration I1 ; }
      GlobalTerm { [ Dof{I} , {U} ] ; In DomainC ; }

      Galerkin { [ -NbWires[]/SurfCoil[] * Dof{ir} , {a} ] ;
        In DomainB ; Jacobian Vol ; Integration I1 ; }
      Galerkin { DtDof [ AxialLength * NbWires[]/SurfCoil[] * Dof{a} , {ir} ] ;
        In DomainB ; Jacobian Vol ; Integration I1 ; }
      GlobalTerm { [ Dof{Ub}/SymmetryFactor , {Ib} ] ; In DomainB ; }
      Galerkin { [ Rb[]/SurfCoil[]* Dof{ir} , {ir} ] ;
        In DomainB ; Jacobian Vol ; Integration I1 ; } // Resistance term

      // GlobalTerm { [ Resistance[]  * Dof{Ib} , {Ib} ] ; In DomainB ; }
      // The above term can replace the resistance term:
      // if we have an estimation of the resistance of DomainB, via e.g. measurements
      // which is better to account for the end windings...

      If(Flag_Cir)
	GlobalTerm { NeverDt[ Dof{Uz}                , {Iz} ] ; In Resistance_Cir ; }
        GlobalTerm { NeverDt[ Resistance[] * Dof{Iz} , {Iz} ] ; In Resistance_Cir ; }

	GlobalTerm { [ Dof{Uz}                      , {Iz} ] ; In Inductance_Cir ; }
	GlobalTerm { DtDof [ Inductance[] * Dof{Iz} , {Iz} ] ; In Inductance_Cir ; }

	GlobalTerm { NeverDt[ Dof{Iz}        , {Iz} ] ; In Capacitance_Cir ; }
	GlobalTerm { DtDof [ Capacitance[] * Dof{Uz} , {Iz} ] ; In Capacitance_Cir ; }

	GlobalTerm { [ 0. * Dof{Iz} , {Iz} ] ; In DomainZt_Cir ; }
        GlobalTerm { [ 0. * Dof{Uz} , {Iz} ] ; In DomainZt_Cir ; }

        GlobalEquation {
          Type Network ; NameOfConstraint ElectricalCircuit ;
          { Node {I};  Loop {U};  Equation {I};  In DomainC ; }
          { Node {Ib}; Loop {Ub}; Equation {Ub}; In DomainB ; }
          { Node {Iz}; Loop {Uz}; Equation {Uz}; In DomainZt_Cir ; }
         }
      EndIf
    }
  }

  //-----------------------------------------------------------------------------------------------
  // Mechanics
  //-----------------------------------------------------------------------------------------------

  { Name Mechanical ; Type FemEquation ;
    Quantity {
      { Name V ; Type Global ; NameOfSpace Velocity [V] ; } // velocity
      { Name P ; Type Global ; NameOfSpace Position [P] ; } // position
    }
    Equation {
      GlobalTerm { DtDof [ Inertia * Dof{V} , {V} ] ; In DomainKin ; }
      GlobalTerm { [ Friction[] * Dof{V} , {V} ] ; In DomainKin ; }
      GlobalTerm { [        Torque_mec[] , {V} ] ; In DomainKin ; }
      GlobalTerm { [       -Torque_mag[] , {V} ] ; In DomainKin ; }

      GlobalTerm { DtDof [ Dof{P} , {P} ] ; In DomainKin ; }
      GlobalTerm {       [-Dof{V} , {P} ] ; In DomainKin ; }
    }
  }

}

//-----------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------

Resolution {

  { Name Static ;
    System {
      { Name A ; NameOfFormulation MagStaDyn_a_2D ; }
    }
    Operation {
      CreateDir["res/"];
      If[ Clean_Results==1 ]{
        DeleteFile["res/temp.dat"];
        DeleteFile["res/Tr.dat"]; DeleteFile["res/Ts.dat"]; DeleteFile["res/Tmb.dat"];
        DeleteFile["res/Ua.dat"]; DeleteFile["res/Ub.dat"]; DeleteFile["res/Uc.dat"];
        DeleteFile["res/Ia.dat"]; DeleteFile["res/Ib.dat"]; DeleteFile["res/Ic.dat"];
        DeleteFile["res/Flux_a.dat"]; DeleteFile["res/Flux_b.dat"]; DeleteFile["res/Flux_c.dat"];
        DeleteFile["res/Flux_d.dat"]; DeleteFile["res/Flux_q.dat"]; DeleteFile["res/Flux_0.dat"];
      }

      InitMovingBand2D[MB] ;
      MeshMovingBand2D[MB] ;
      InitSolution[A] ;

      If(Flag_ParkTransformation && Flag_SrcType_Stator==1)
        PostOperation[ThetaPark_IABC] ; EndIf
      If(!Flag_NL)
        Generate[A] ; Solve[A] ;
      EndIf
      If(Flag_NL)
        //IterativeLoopN[ Nb_max_iter, relaxation_factor, System { {A, reltol, abstol, Solution MeanL2Norm}}]{
        IterativeLoop[Nb_max_iter, stop_criterion, relaxation_factor]{
          GenerateJac[A] ; SolveJac[A] ; }
      EndIf
      SaveSolution[A] ;

      PostOperation[Get_LocalFields] ;
      PostOperation[Get_GlobalQuantities] ;
      PostOperation[Get_Torque];
    }
  }

  { Name TimeDomain ;
    System {
      { Name A ; NameOfFormulation MagStaDyn_a_2D ; }
      If(!Flag_ImposedSpeed) // Full dynamics
        { Name M ; NameOfFormulation Mechanical ; }
      EndIf
    }
    Operation {
      CreateDir["res/"];
      If(Clean_Results==1)
          DeleteFile["res/temp.dat"];
          DeleteFile["res/Tr.dat"]; DeleteFile["res/Ts.dat"]; DeleteFile["res/Tmb.dat"];
          DeleteFile["res/Ua.dat"]; DeleteFile["res/Ub.dat"]; DeleteFile["res/Uc.dat"];
          DeleteFile["res/Ia.dat"]; DeleteFile["res/Ib.dat"]; DeleteFile["res/Ic.dat"];
          DeleteFile["res/Flux_a.dat"]; DeleteFile["res/Flux_b.dat"]; DeleteFile["res/Flux_c.dat"];
          DeleteFile["res/Flux_d.dat"]; DeleteFile["res/Flux_q.dat"]; DeleteFile["res/Flux_0.dat"];
          DeleteFile["res/JL.dat"]; DeleteFile["res/JL_Fe.dat"];
          DeleteFile["res/P.dat"]; DeleteFile["res/V.dat"];
      EndIf

      InitMovingBand2D[MB];
      MeshMovingBand2D[MB];
      InitSolution[A];

      If(!Flag_ImposedSpeed) // Full dynamics
        InitSolution[M]; InitSolution[M]; // Twice for avoiding warning (a = d_t^2 x)
      EndIf

      TimeLoopTheta[time0, timemax, delta_time, 1.]{ // Euler implicit (1) -- Crank-Nicolson (0.5)
        If(Flag_ParkTransformation && Flag_SrcType_Stator==1)
          PostOperation[ThetaPark_IABC];
        EndIf
        If(!Flag_NL)
            Generate[A]; Solve[A];
        EndIf
        If(Flag_NL)
          //IterativeLoopN[ Nb_max_iter, relaxation_factor, System { {A, reltol, abstol, Solution MeanL2Norm}} ]{
          IterativeLoop[Nb_max_iter, stop_criterion, relaxation_factor] {
            GenerateJac[A] ; SolveJac[A] ; }
        EndIf
        SaveSolution[A];

        PostOperation[Get_LocalFields] ;
        Test[ $TimeStep > 1 ]{
            PostOperation[Get_GlobalQuantities];
            PostOperation[Get_Torque];
        }

        If(!Flag_ImposedSpeed)
          Generate[M]; Solve[M]; SaveSolution[M];
          PostOperation[Mechanical] ;
        EndIf

        ChangeOfCoordinates[ NodesOf[Rotor_Moving], RotatePZ[delta_theta[]]];
        If(!Flag_ImposedSpeed)
          Evaluate[ #77#66 ]; //Keep track of previous angular position
        EndIf
        MeshMovingBand2D[MB] ;
      }
    }
  }

  { Name FrequencyDomain ;
    System {
      { Name A ; NameOfFormulation MagStaDyn_a_2D ; Type ComplexValue ; Frequency Freq ; }
    }
    Operation {
      CreateDir["res/"];
      If[ Clean_Results==1 && wr == 0.]{
        DeleteFile["res/Tr.dat"]; DeleteFile["res/Ts.dat"]; DeleteFile["res/Tmb.dat"];
        DeleteFile["res/Ua.dat"]; DeleteFile["res/Ub.dat"]; DeleteFile["res/Uc.dat"];
        DeleteFile["res/Ia.dat"]; DeleteFile["res/Ib.dat"]; DeleteFile["res/Ic.dat"];
        DeleteFile["res/Flux_a.dat"]; DeleteFile["res/Flux_b.dat"]; DeleteFile["res/Flux_c.dat"];
        DeleteFile["res/JL.dat"]; DeleteFile["res/JL_Fe.dat"];
      }
      SetTime[wr];
      InitMovingBand2D[MB] ;
      MeshMovingBand2D[MB] ;
      Generate[A] ; Solve[A] ; SaveSolution[A];
      PostOperation[Get_LocalFields] ;
      PostOperation[Get_GlobalQuantities] ;
      PostOperation[Get_Torque_cplx] ;
    }
  }

}

//-----------------------------------------------------------------------------------------------

PostProcessing {

  { Name MagStaDyn_a_2D ; NameOfFormulation MagStaDyn_a_2D ;
   PostQuantity {
     { Name a  ; Value { Term { [ {a} ] ; In Domain ; Jacobian Vol ; } } }
     { Name az ; Value { Term { [ CompZ[{a}] ] ; In Domain ; Jacobian Vol ; } } }

     { Name b  ; Value { Term { [ {d a} ] ; In Domain ; Jacobian Vol ; } } }
     { Name boundary  ; Value { Term { [ 1 ] ; In Dummy ; Jacobian Vol ; } } } // Dummy quantity - for visualization
     { Name b_radial  ; Value { Term { [ {d a}* Vector[  Cos[AngularPosition[]#4], Sin[#4], 0.] ] ; In Domain ; Jacobian Vol ; } } }
     { Name b_tangent ; Value { Term { [ {d a}* Vector[ -Sin[AngularPosition[]#4], Cos[#4], 0.] ] ; In Domain ; Jacobian Vol ; } } }

     { Name js ; Value { Term { [ js[] ] ; In DomainS ; Jacobian Vol ; } } }
     { Name br ; Value { Term { [ br[] ] ; In DomainM ; Jacobian Vol ; } } }

     { Name j  ; Value {
         Term { [ -sigma[]*(Dt[{a}]+{ur}) ]        ; In DomainC ; Jacobian Vol ; }
         Term { [  sigma[]*(Velocity[] *^ {d a}) ] ; In DomainV ; Jacobian Vol ; }
       }
     }
     { Name ir ; Value { Term { [ {ir} ] ; In Inds ; Jacobian Vol ; } } }

     { Name jz ; Value {
         Term { [ CompZ[-sigma[]*(Dt[{a}]+{ur})] ]       ; In DomainC ; Jacobian Vol ; }
         Term { [ CompZ[ sigma[]*(Velocity[]*^{d a}) ] ] ; In DomainV ; Jacobian Vol ; }
       }
     }

     { Name rhoj2 ;
       Value {
         Term { [ sigma[]*SquNorm[ Dt[{a}]+{ur}] ] ; In Region[{DomainC,-DomainV}] ; Jacobian Vol ; }
         Term { [ sigma[]*SquNorm[ Dt[{a}]+{ur}-Velocity[]*^{d a} ] ] ; In DomainV ; Jacobian Vol ; }
         Term { [ 1./sigma[]*SquNorm[ IA[]*{ir} ] ] ; In PhaseA  ; Jacobian Vol ; }
         Term { [ 1./sigma[]*SquNorm[ IB[]*{ir} ] ] ; In PhaseB  ; Jacobian Vol ; }
         Term { [ 1./sigma[]*SquNorm[ IC[]*{ir} ] ] ; In PhaseC  ; Jacobian Vol ; }
       }
     }

     { Name JouleLosses ;
       Value {
         Integral { [ sigma[] * SquNorm[ Dt[{a}]+{ur} ] ]   ; In Region[{DomainC,-DomainV}] ; Jacobian Vol ; Integration I1 ; }
         Integral { [ sigma[] * SquNorm[ Dt[{a}]+{ur}-Velocity[]*^{d a} ] ]   ; In DomainV ; Jacobian Vol ; Integration I1 ; }
         Integral { [ 1./sigma[]*SquNorm[ IA[]*{ir} ] ] ; In PhaseA  ; Jacobian Vol ; Integration I1 ; }
         Integral { [ 1./sigma[]*SquNorm[ IB[]*{ir} ] ] ; In PhaseB  ; Jacobian Vol ; Integration I1 ; }
         Integral { [ 1./sigma[]*SquNorm[ IC[]*{ir} ] ] ; In PhaseC  ; Jacobian Vol ; Integration I1 ; }
       }
     }

     { Name Flux ; Value { Integral { [ SymmetryFactor*AxialLength*Idir[]*NbWires[]/SurfCoil[]* CompZ[{a}] ] ;
           In Inds  ; Jacobian Vol ; Integration I1 ; } } }

     { Name Force_vw ; // Force computation by Virtual Works
       Value {
         Integral {
           Type Global ; [ 0.5 * nu[] * VirtualWork [{d a}] * AxialLength ];
           In ElementsOf[Rotor_Airgap, OnOneSideOf Rotor_Bnd_MB]; Jacobian Vol ; Integration I1 ; }
       }
     }

     { Name Torque_vw ; Value { // Torque computation via Virtual Works
         Integral { Type Global ;
           [ CompZ[ 0.5 * nu[] * XYZ[] /\ VirtualWork[{d a}] ] * AxialLength ];
           In ElementsOf[Rotor_Airgap, OnOneSideOf Rotor_Bnd_MB]; Jacobian Vol ; Integration I1 ; }
       }
     }

     { Name Torque_Maxwell ; // Torque computation via Maxwell stress tensor
       Value {
         Integral {
           [ CompZ [ XYZ[] /\ (T_max[{d a}] * XYZ[]) ] * 2*Pi*AxialLength/SurfaceArea[] ] ;
           In Domain ; Jacobian Vol  ; Integration I1; }
       }
     }

     { Name Torque_Maxwell_cplx ; // Torque computation via Maxwell stress tensor - frequency domain
       Value {
         Integral {
           [ CompZ [ XYZ[] /\ (T_max_cplx[{d a}] * XYZ[]) ] * 2*Pi*AxialLength/SurfaceArea[] ] ;
           In Domain ; Jacobian Vol  ; Integration I1; }
       }
     }

     { Name ComplexPower ; // S = P + i*Q
       Value {
         Integral { [ Complex[ sigma[]*SquNorm[Dt[{a}]+{ur}], nu[]*SquNorm[{d a}] ] ] ;
           In Region[{DomainC,-DomainV}] ; Jacobian Vol ; Integration I1 ; }
         Integral { [ Complex[ sigma[]*SquNorm[Dt[{a}]+{ur}-Velocity[]*^{d a}], nu[]*SquNorm[{d a}] ] ] ;
           In DomainV ; Jacobian Vol ; Integration I1 ; }
       }
     }

     { Name U ; Value {
         Term { [ {U} ]   ; In DomainC ; }
         Term { [ {Ub} ]  ; In DomainB ; }
         Term { [ {Uz} ]  ; In DomainZt_Cir ; }
     } }

     { Name I ; Value {
         Term { [ {I} ]   ; In DomainC ; }
         Term { [ {Ib} ]  ; In DomainB ; }
         Term { [ {Iz} ]  ; In DomainZt_Cir ; }
     } }

     { Name S ; Value {
         Term { [ {U}*Conj[{I}] ]    ; In DomainC ; }
         Term { [ {Ub}*Conj[{Ib}] ]  ; In DomainB ; }
         Term { [ {Uz}*Conj[{Iz}] ]  ; In DomainZt_Cir ; }
     } }

     { Name Velocity  ; Value {
         Term { [ Velocity[] ] ; In Domain ; Jacobian Vol ; }
       }
     }

     // For getting the value of some functions:
     { Name RotorPosition_deg ; Value { Term { Type Global; [ RotorPosition_deg[] ] ; In DomainDummy ; } } }
     { Name Theta_Park_deg    ; Value { Term { Type Global; [ Theta_Park_deg[] ] ; In DomainDummy ; } } }
     { Name IA  ; Value { Term { Type Global; [ IA[] ] ; In DomainDummy ; } } }
     { Name IB  ; Value { Term { Type Global; [ IB[] ] ; In DomainDummy ; } } }
     { Name IC  ; Value { Term { Type Global; [ IC[] ] ; In DomainDummy ; } } }

     { Name Flux_d  ; Value { Term { Type Global; [ CompX[Flux_dq0[]] ] ; In DomainDummy ; } } }
     { Name Flux_q  ; Value { Term { Type Global; [ CompY[Flux_dq0[]] ] ; In DomainDummy ; } } }
     { Name Flux_0  ; Value { Term { Type Global; [ CompZ[Flux_dq0[]] ] ; In DomainDummy ; } } }
   }
 }

 { Name Mechanical ; NameOfFormulation Mechanical ;
   PostQuantity {
     { Name P ; Value { Term { [ {P} ]  ; In DomainKin ; } } } //Position
     { Name V ; Value { Term { [ {V} ]  ; In DomainKin ; } } } //Velocity
     { Name Vrpm ; Value { Term { [ {V}*30/Pi ]  ; In DomainKin ; } } } //Velocity in rpm
   }
 }

}

//-----------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------

If (Flag_ParkTransformation)
PostOperation ThetaPark_IABC UsingPost MagStaDyn_a_2D {
  Print[ RotorPosition_deg, OnRegion DomainDummy, Format Table, LastTimeStepOnly, File StrCat[Dir, StrCat["temp",ExtGnuplot]],
         SendToServer "Output/1RotorPosition", Color "LightYellow" ];
  Print[ Theta_Park_deg, OnRegion DomainDummy, Format Table, LastTimeStepOnly, File StrCat[Dir, StrCat["temp",ExtGnuplot]],
         SendToServer "Output/1Theta_Park", Color "LightYellow" ];
  Print[ IA, OnRegion DomainDummy, Format Table, LastTimeStepOnly, File StrCat[Dir, StrCat["temp",ExtGnuplot]], SendToServer "Output/2IA", Color "Pink" ];
  Print[ IB, OnRegion DomainDummy, Format Table, LastTimeStepOnly, File StrCat[Dir, StrCat["temp",ExtGnuplot]], SendToServer "Output/2IB", Color "Yellow" ];
  Print[ IC, OnRegion DomainDummy, Format Table, LastTimeStepOnly, File StrCat[Dir, StrCat["temp",ExtGnuplot]], SendToServer "Output/2IC", Color "LightGreen"  ];
}
EndIf
PostOperation Get_LocalFields UsingPost MagStaDyn_a_2D {
  Print[ ir, OnElementsOf Stator_Inds, File StrCat[Dir, StrCat["ir_stator",ExtGmsh]], LastTimeStepOnly, AppendTimeStepToFileName Flag_SaveAllSteps] ;
  Print[ ir, OnElementsOf Rotor_Inds,  File StrCat[Dir, StrCat["ir_rotor",ExtGmsh]], LastTimeStepOnly, AppendTimeStepToFileName Flag_SaveAllSteps] ;
  //Print[ br,  OnElementsOf #{DomainM}, File StrCat[Dir, StrCat["b",ExtGmsh]], LastTimeStepOnly, AppendTimeStepToFileName Flag_SaveAllSteps] ;
  Print[ b,  OnElementsOf Domain, File StrCat[Dir, StrCat["b",ExtGmsh]], LastTimeStepOnly, AppendTimeStepToFileName Flag_SaveAllSteps] ;
  Print[ boundary, OnElementsOf Dummy,  File StrCat[Dir, StrCat["bnd",ExtGmsh]], LastTimeStepOnly, AppendTimeStepToFileName Flag_SaveAllSteps] ;
  Print[ az, OnElementsOf Domain, File StrCat[Dir, StrCat["a",ExtGmsh]], LastTimeStepOnly, AppendTimeStepToFileName Flag_SaveAllSteps ] ;
}

PostOperation Get_GlobalQuantities UsingPost MagStaDyn_a_2D {
  If(!Flag_Cir)
    If(!Flag_ParkTransformation)
      Print[ I, OnRegion PhaseA_pos, Format Table,
        File > StrCat[Dir, StrCat["Ia",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/2IA", Color "Pink" ];
      If(NbPhases==3)
        Print[ I, OnRegion PhaseB_pos, Format Table,
          File > StrCat[Dir, StrCat["Ib",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/2IB", Color "Yellow" ];
        Print[ I, OnRegion PhaseC_pos, Format Table,
          File > StrCat[Dir, StrCat["Ic",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/2IC", Color "LightGreen" ];
      EndIf
    EndIf

    Print[ U, OnRegion PhaseA_pos, Format Table,
      File > StrCat[Dir, StrCat["Ua",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/30UA", Color "Pink" ];
    If(NbPhases==3)
      Print[ U, OnRegion PhaseB_pos, Format Table,
        File > StrCat[Dir, StrCat["Ub",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/31UB", Color "Yellow" ];
      Print[ U, OnRegion PhaseC_pos, Format Table,
        File > StrCat[Dir, StrCat["Uc",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/32UC", Color "LightGreen" ];
    EndIf
  EndIf
  If(Flag_Cir && Flag_SrcType_Stator==2)
    Print[ I, OnRegion Input1, Format Table,
           File > StrCat[Dir, StrCat["Ia",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/2IA", Color "Pink" ];
    Print[ I, OnRegion Input2, Format Table,
           File > StrCat[Dir, StrCat["Ib",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/2IB", Color "Yellow" ];
    Print[ I, OnRegion Input3, Format Table,
           File > StrCat[Dir, StrCat["Ic",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/2IC", Color "LightGreen" ];
    Print[ U, OnRegion Input1, Format Table,
           File > StrCat[Dir, StrCat["Ua",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/30UA", Color "Pink" ];
    Print[ U, OnRegion Input2, Format Table,
           File > StrCat[Dir, StrCat["Ub",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/31UB", Color "Yellow" ];
    Print[ U, OnRegion Input3, Format Table,
           File > StrCat[Dir, StrCat["Uc",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/32UC", Color "LightGreen" ];
  EndIf
  If(Flag_Cir && Flag_SrcType_Stator==0)
    Print[ I, OnRegion R1, Format Table,
           File > StrCat[Dir, StrCat["Ia",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/2IA", Color "Pink" ];
    Print[ I, OnRegion R2, Format Table,
           File > StrCat[Dir, StrCat["Ib",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/2IB", Color "Yellow" ];
    Print[ I, OnRegion R3, Format Table,
           File > StrCat[Dir, StrCat["Ic",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/2IC", Color "LightGreen" ];
    Print[ U, OnRegion R1, Format Table,
           File > StrCat[Dir, StrCat["Ua",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/30UA", Color "Pink" ];
    Print[ U, OnRegion R2, Format Table,
           File > StrCat[Dir, StrCat["Ub",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/31UB", Color "Yellow" ];
    Print[ U, OnRegion R3, Format Table,
           File > StrCat[Dir, StrCat["Uc",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/32UC", Color "LightGreen" ];
  EndIf

  Print[ I, OnRegion RotorC, Format Table,
         File > StrCat[Dir, StrCat["Irotor",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/2Ir", Color "LightYellow" ];

  If(Flag_SrcType_Stator)
    Print[ Flux[PhaseA], OnGlobal, Format TimeTable,
      File > StrCat[Dir, StrCat["Flux_a",ExtGnuplot]], LastTimeStepOnly, Store 11, SendToServer "Output/50Flux_a",  Color "Pink" ];
    If(NbPhases==3)
      Print[ Flux[PhaseB], OnGlobal, Format TimeTable,
        File > StrCat[Dir, StrCat["Flux_b",ExtGnuplot]], LastTimeStepOnly, Store 22, SendToServer "Output/51Flux_b",  Color "Yellow" ];
      Print[ Flux[PhaseC], OnGlobal, Format TimeTable,
        File > StrCat[Dir, StrCat["Flux_c",ExtGnuplot]], LastTimeStepOnly, Store 33, SendToServer "Output/52Flux_c", Color "LightGreen"];
    EndIf
    If(Flag_ParkTransformation && Flag_SrcType_Stator)
      Print[ Flux_d, OnRegion DomainDummy, Format TimeTable,
        File > StrCat[Dir, StrCat["Flux_d",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/60Flux_d", Color "LightYellow" ];
      Print[ Flux_q, OnRegion DomainDummy, Format TimeTable,
        File > StrCat[Dir, StrCat["Flux_q",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/61Flux_q", Color "LightYellow" ];
      Print[ Flux_0, OnRegion DomainDummy, Format TimeTable,
        File > StrCat[Dir, StrCat["Flux_0",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/62Flux_0", Color "LightYellow" ];
    EndIf
  EndIf

  If(Flag_ComputeLosses)
    Print[ JouleLosses[Rotor], OnGlobal, Format TimeTable,
           File > StrCat[Dir, StrCat["JL",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/70JL_rotor", Color "LightYellow" ];
    Print[ JouleLosses[Rotor_Fe], OnGlobal, Format TimeTable,
           File > StrCat[Dir, StrCat["JL_Fe",ExtGnuplot]], LastTimeStepOnly, SendToServer "Output/71JL_rotor_fe", Color "LightYellow" ];
  EndIf
}

PostOperation Get_Torque UsingPost MagStaDyn_a_2D {
  Print[ Torque_Maxwell[Rotor_Airgap], OnGlobal, Format TimeTable,
         File > StrCat[Dir, StrCat["Tr",ExtGnuplot]], LastTimeStepOnly, Store 54, SendToServer my_output, Color "LightYellow" ];
  Print[ Torque_Maxwell[Stator_Airgap], OnGlobal, Format TimeTable,
         File > StrCat[Dir, StrCat["Ts",ExtGnuplot]], LastTimeStepOnly, Store 55, SendToServer "Output/41T_stator", Color "LightYellow" ];
  Print[ Torque_Maxwell[MB], OnGlobal, Format TimeTable,
         File > StrCat[Dir, StrCat["Tmb",ExtGnuplot]], LastTimeStepOnly, Store 56, SendToServer "Output/42T_mb", Color "LightYellow" ];
 //Print[ Torque_vw, OnRegion NodesOf[Rotor_Bnd_MB], Format RegionValue,
  //       File > StrCat[Dir, StrCat["Tr_vw",ExtGnuplot]], LastTimeStepOnly, Store 54, SendToServer "Output/1T_rotor_vw" ];
}

PostOperation Get_Torque_cplx UsingPost MagStaDyn_a_2D {
  Print[ Torque_Maxwell_cplx[Rotor_Airgap], OnGlobal, Format TimeTable,
         File > StrCat[Dir, StrCat["Tr",ExtGnuplot]], LastTimeStepOnly, Store 54, SendToServer my_output, Color "LightYellow" ];
  Print[ Torque_Maxwell_cplx[Stator_Airgap], OnGlobal, Format TimeTable,
         File > StrCat[Dir, StrCat["Ts",ExtGnuplot]], LastTimeStepOnly, Store 55, SendToServer "Output/41T_stator", Color "LightYellow" ];
  Print[ Torque_Maxwell_cplx[MB], OnGlobal, Format TimeTable,
         File > StrCat[Dir, StrCat["Tmb",ExtGnuplot]], LastTimeStepOnly, Store 56, SendToServer "Output/42T_mb", Color "LightYellow" ];
}

PostOperation Mechanical UsingPost Mechanical {
  Print[ P, OnRegion DomainKin, File > StrCat[Dir, StrCat["Position", ExtGnuplot]],
         Format Table, Store 77, LastTimeStepOnly, SendToServer "Output/90Position", Color "Cyan"] ;
  Print[ V, OnRegion DomainKin, File > StrCat[Dir, StrCat["V", ExtGnuplot]],
         Format Table, LastTimeStepOnly, SendToServer "Output/91Velocity", Color "Cyan"] ;
}

