c.
c .    Program SMR to simulate the behavior of an Integral PWR
c.
      Real mu,k,Length,inertiac,inertiav,inertia1,inertia2,L,lloss
      Real Inertia
      Real LengthSG
      Real kw,kl,kc												
      Real lamda06
      Real Kappa
      Real Load
      Real MDNBR											 
c	show time information by shen
	REAL(4)  TA(2)
c.
      Integer WriteInterval,RestartInterval    
      Character*50 CaseFile,GeometryFile,ControllerGains
	Character*50 InitFile,RxDataFile,ComponentFile
      Character*50 SensorDataFile,ValveDataFile,TripSTPTFile
      Character*50 UpsetType,TripStatus(10)
      Character*50 LoadFile,SteamGeneratorType
      Character*50 BOPGeometryFile,CHFCorrelation
      Character*50 TESDataFile
c.
      Dimension nvessel(6),nloop1(10),nloop2(10),iinlet(26),ioutlet(26)
      Dimension qin(26),Pheated(26),DeltaH(26),Length(26),Area(26)
      Dimension As(26),GenFraction(26)
      Dimension Equiv_Diam(26),Aheated(26),Told(26),Tnew(26),lloss(26)
      Dimension UA(26),V(26),unew(26),uold(26)						 
      Dimension AA(26,26),SS(26)
      Dimension UAM(20,26),nodesSG(26)
      Dimension ICALLTRIP(10)
c.
      Dimension TfuelAVE(50),TfuelHOT(50)
c      Dimension rhouHOT(150),uHOT(150)
      Dimension uHOT(150)
c.
      Common/SGTemps/TSG(20,26),hSG(20,26),Tfeed,FlowSteam
      Common/SGUA/Ri,Ro,kw,Pitch,Fouling,DeSG,AxSG,ITYPESG
      Common/CriticalLocation/ICRIT1j,ICRIT1i,ICRIT2j,ICRIT2i,
     %       CriticalLength1,CriticalLength2,fraction1,fraction2
      Common/SteamGeneratorMass/SGMass1,SGMass2					
c.

      Common/FluidProperties/rhol,Cp,mu,k
      common/RCPs/QR,HeadR,TorqueR,omegaR,Inertia,npumps1,npumps2,
     %            omega1,omega2
      Common/Trips/ITRIPRCP1,ITRIPRCP2,ITRIPRX,ITRIPFP
c.***********************************************************************
c.
      Real KSHIMTES,KEXH
      Real KTAP,KTESTBV(4)
      Common/TESParameters/FlowAUX1,FlowAUX2,FlowAUX3,TESLoad
      Common/TESDemandParameters/TESSHIM,KSHIMTES
      Common/TESTapParameters/KEXH,PTAP,rhoTAP,hTAP
      Common/TESByPassControl/TES_TBVGain(3),RATETES_TBV
      Common/TESByPassControlSetPoints/TESFlowDEMAND0,TESSetPoint(4),
     %                                 IOPENTES(4),nTESByPass,ModeTES,
     %                                 ICLOSETBV,LockTBV
      Dimension TES_TBV(4),TES_TBVnew(4),GAUX1(4)
c.							
c.***********************************************************************
      Dimension BANKPOSITION(4)
      Real InchesPerStep
      Common/ControlBankData/BankWorthParameters(4,3),BankLength,
     %                       Overlap,InchesPerStep
      Common/RodWorthData/CummWorth,ShutDownWorth,RodLength
	Common/ControlRods/aref,bref,RodspeedMin,RodspeedMax,RefRxPwr,
     %                   TaveREF,RodGain							         
      Common /FuelProperties/rhoUO2,Diameter,Dpellet,FuelHeight,P_D,
     %                       Gammaf,tc,rhoc,Cpc,kc,HGAP,nrods
      Common /Reactivity/alphaTrx,alphamod,alphaBoron,alphaXe,
     %                   Trxref,Tref,Cref,NXref,
     %                   Rho0,Prompt,Rhocr,Rho,
     %                   DeltaRhoFuel,DeltaRhoMod,DeltaRhoB,Srx
      Common/DelayedNeutronData/Precursor(6),lamda06(6),beta06(6)
      Common/DecayHeatData/gammaDH(11)
      Common /HotRod/alamda,DeCore,AxCore,Fq,Fz,nodesHC,ICHF
c.***********************************************************************
      Common/XenonData/GammaX,lamdaX,sigmaX,
     %                 GammaI,lamdaI,SigmaF,psiX,Vfuel
      Common/XenonWorth/rhoX
      Real lamdaX,lamdaI,NX,NI,NXref,NIref
c.**********************************************************************
      Common/BOPGeometry/AreaMSL,nMSL,AreaSL
c.**********************************************************************
	real velocity_kk(60),pressure_kk(60),ie_kk(60),
     %	kafa_kk(60),aj_kk(60),density_kk(60)
	common /SGdata/ velocity_kk,pressure_kk,ie_kk,
     %	kafa_kk,aj_kk,density_kk
c	New Feed Model Data added by shen
c.**************************************************************************
      Real KFEED,Kvalve
      Real KFBV,KFCV,k_turb											  
c.**************************************************************************
      Common/FeedFlowinit/OmegaHWP,OmegaCP,OmegaFP,FCV,FBV,Qrx
      Common/ValveProperties/DeadBand(10),Tau(10),
     %                       Avalve(10),Kvalve(10),bvalve(10)
      Common/FeedGEOM/AxFEED(10),KFEED(10),KFCV,KFBV
      Common/FeedPARAMETERS/nHWP,nCP,nFP,nSG,Pcond
      Common/SFWSPARAMETERS/DeltaPSFWPump
      Common/FeedPumpControl/DeltaPREF,OmegaGAIN
      Common/DEGUG/IRESTART,IDEBUG
      Common/PumpData/OmegaR1(10),QR1(10),HR(10),
     %                a0P(10),b0P(10),c0P(10),d0P(10)
c.**************************************************************************
      Real KSHIM
      Common/FeedControl/FeedGain(3,3),G1Feed(3),G2Feed(3),RATEFCV
      Common/FeedByPassControl/FeedByPassGain(3,3),
     %                         G1FeedByPass(3),G2FeedByPass(3)
      Common/SFWSControl/SFWSGain(3)
      Common/FeedControlSetPoints/FlowDEMAND0,SGRefLVL0,SGRefLVL
      Common/FeedDemandParameters/FlowSG0,FeedSHIM,KSHIM                      
      Common/TurbineLoadData/aload,bload,RefLoad,RampDuration
      Common/LoadData/Hour(300),TurbineLoad(300),IDEMAND,ntimes 		  
c.**************************************************************************
      Common/ControlMODES/MODE(10)
      Common/UpsetParameters/ITYPEUpset,UPSETPARM(4)
c.**************************************************************************
      Common/TBVControl/TBVGain(3,3,4),RATETBV,nTBV
      Common/TCVControl/TCVGain(3,3,4),RATETCV,nTCV
      Common/PressureControlSetPoints/PSG_Ref
      Common/SteamFlowInit/TBVposition(4),TCVposition(4)
	Common/LowPower/QrxFINAL,HeatUpRate,StartupRATE,QrxRATE 
c.*******************************************************************
      Integer SensorID
      Integer SensorNode(10)
      Common/SensorData/SensorSpan(10),SensorBias(10),
     %                  SensorDriftRate(10),SensorDriftDuration(10),
     %                  SensorNoiseData(10,2)
c.*******************************************************************
      Real KPRZSRV,KPRZ
      Real mdotLD,mdotCHRG
      Real KSPRAY,KBYPASS,KSCV,LSPRAY
c.
      Common/PRZHTRINIT/QHTRP,QHTRB
      Common/PressurizerGeometry/RSRG,RDOME,HSRG,HCYL,
     %                           Ax3,Ax4,Ax5,AxVESSEL,
     %                           VSRG,VDOME,VHEAD,VPRZ,
     %                           VOL(4)
c.
      Common/PressurizerProperties/alphagPx(4),alphalPx(4),rholPx(4),
     %                             ulPx(4),rhogPx(4),ugPx(4),rhoPx(4),
     %                             rhouPx(4),VelPx(5),VSRVPx(4),
     %                             PRZMass(4),PRZE(4)
c.
      Common/PressurizerHeaterData/Qprop,Qbackup,TauHEATER,
     %                             PRZHTRGain0,PRZHTRGain1,PRZHTRGain2
      Common/PressurizerSprayData/rhoSPRAY,rhouSPRAY,Vspray,AxSPRAY
c.
      Common/PressurizerData/KPRZSRV(4),AxSRV(4),KPRZ(4),
     %                       PRZSETPOINT(9),NPRZSRVs
c.
      Common/PressurizerSprayLine/SprayPumpDeltaP,DSPRAY,LSPRAY,
     %                            AxBypass,AxSCV,KSPRAY,KBYPASS,KSCV,
     %                            SCVposition
      Common/SprayControl/SprayGain(3,3),RATESCV,SCVmin
c.*********************************************************************
      Common/PrimaryData/rholulp(26),rholp(26),ulp(26),ulp0(26),
     %                   Vp(26),Pp
      Common/CVCSData/mdotCHRG,mdotLD
      Common/SimulationControlData/Deltat
c.
c.*******************************************************************
      Common/ColebrookParameters/Re0,Roughness
c.*******************************************************************
      Common/RxTripSetPts/FlowVnom,QRXnom,RxTRIPS(10),ITRIPMode(10)
c.*******************************************************************     
      Data qin/26*0./      
      Data UAM/520*0./
      Data AA/676*0./
      Data SS/26*0./
      Data UA/26*0./
c.
      Data nodesSG/7*0,6*10,5*0,6*10,0,0/
      Data nvessel/16,1,2,3,4,5/
      Data nloop1/7,8,9,10,11,12,13,6,14,15/
      Data nloop2/25,24,23,22,21,20,19,26,18,17/
      Data iinlet/16,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,18,19,20,21,
     %            22,23,24,25,26,5/
      Data ioutlet/2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,1,16,17,18,19,
     %		  20,21,22,23,24,25/
c.
      Data ICALLTRIP/10*0/
c.********************************************************************
	QrxRate=0
	HeatupRate=50
	StartupRate=0.5
      ITRIPRCP1=0
      ITRIPRCP2=0
      TripClock=0.
      ITRIPFP=0
      ITRIPTurbine=0
      TESLEVEL=0.
c.**********************************************************************
c.
c     Turbine Bypass Valves (Nvalve = 3)
c.
      MODE(3)=1
      MODE(7)=1
c
c.    Turbine Control Valves (Nvalve = 4)
c.
      MODE(4)=1
      MODE(9)=0
c
      DeltaPREF=122.
c.
c.
c.    Feed Control Valves (Nvalve = 1)
c.
c.
      MODE(1)=1
      MODE(8)=0
      G1Feed(1)=1.
      G2Feed(1)=0.
c.
c.    Feed Bypass Valves (Nvalve =2)
c.
c.
      MODE(2)=0
      MODE(6)=1
c.
c.    Startup Feedwater System (Nvalve =5)
c.
      ISTARTSFWS=0
      FlowSFWS=0.
      SFWVPosition=0.    
c														   
c	mode 1: FCV
c	mode 2: FBV
c	mode 3: TBV
c	mode 4: TCV
c	mode 6: CLOSE FBV
c	mode 7: CLOSE TBV
c
c 	manual close FBV
c.	mode(6)=0+0
c.	mode(2)=1+0
c	manual close TBV
c.	mode(7)=0+0
c.	mode(3)=1+0
c.	mode(4)=0+0
c
	G1FeedByPass(1)=0.
      G2FeedByPass(1)=1.
c.
c.    Feed Line Loss Coefficients
c.
c      KFEED(1)=3.276			   !KHW
c      KFEED(2)=13.105            !KM1
c	 KFEED(3)=2.472             !KCP		
c      KFEED(4)=9.887             !KM3
c      KFEED(5)=22.73             !KFP
c      KFEED(6)=72.38               !K11
c      KFEED(7)=72.38               !KFD
c.
c.    Feed Line Flow Areas
c.
c      AxFEED(1)=0.474             !AxHW
c      AxFEED(2)=0.842             !AxM1
c      AxFEED(3)=0.561             !AxCP
c      AxFEED(4)=1.261             !AxM3
c      AxFEED(5)=0.298             !AxFP
c      AxFEED(6)=0.2398             !A11
c      AxFEED(7)=0.2398             !AxFD  
c.
c.	end of Feed Model
c.
      Kappa=3.4137e6
      pi=3.1415926
c.************************************************************
c.
c.    Simulation Control Data
c.
      IDEBUG=0
      Tmax=1.
      Dtmin=1.e-5
      Dtmax=0.0001
c.
c.************************************************************
c.
c.    Pressurizer Data
c.
c.
      KPRZ(1)=1.
      KPRZ(2)=1.
      KPRZ(3)=1.
      KPRZ(4)=1.
c.
c.
c.************************************************************
c.
c.    Read Input Data Information
c.
      Write(*,1200)
      Read(*,*)CaseFile
c.
      Open(unit=8,file=CaseFile)
      Open(unit=10,file="Summary.dat")
c.
      Read(8,*)GeometryFile
      Read(8,*)RxDataFile
      Read(8,*)ComponentFile
      Read(8,*)ControllerGains
      Read(8,*)SensorDataFile
      Read(8,*)ValveDataFile
      Read(8,*)BOPGeometryFile
      Read(8,*)TripSTPTFile
      Read(8,*)InitFile
      Read(8,*)TESDataFile
      Read(8,*)InitMode
      Read(8,*)IDEMAND,StartTime           
        if(IDEMAND.eq.0)then
        Read(8,*)PowerFraction
        endif
        if(IDEMAND.eq.1)then
        Read(8,*)RampRate,RampDuration				   
        endif
        if(IDEMAND.eq.2)then
        Read(8,*)LoadFile
        endif
      Read(8,*)ITYPEUpset,UPSETPARM(1),UPSETPARM(2),UPSETPARM(3),
     %                    UPSETPARM(4)
      Read(8,*)ModeRODS
      Read(8,*)Tmax,WriteInterval,RestartInterval
c.
      Close(unit=8)
c.
      write(10,2000)CaseFile
      write(10,2001)GeometryFile
      write(10,2002)RxDataFile
      write(10,2003)ComponentFile
      write(10,2008)ControllerGains
      write(10,2009)SensorDataFile
      write(10,2010)ValveDataFile
      write(10,2014)BOPGeometryFile
      write(10,2012)TripSTPTFile
      write(10,2004)InitFile,TESDataFile,InitMode
c.
      write(10,*)' '
c.
      if(IDEMAND.eq.0)then
      write(10,2005)PowerFraction,StartTime            
	QrxFinal=PowerFraction*RefRxPwr/100.					 
      endif
c.
      if(IDEMAND.eq.1)then
      write(10,2006)RampRate,RampDuration,StartTime    			           
      endif
c.
      if(IDEMAND.eq.2)then
      write(10,2013)LoadFile
      endif
c.
        If(ITYPEUpset.eq.213)then
        UpsetType='RCP Overspeed'
        elseif(ITYPEUpset.eq.212131)then
        UpsetType='Feed Pump Overspeed (active controller)'
        elseif(ITYPEUpset.eq.212132)then
        UpsetType='Feed Pump Overspeed (failed controller)'
        elseif(ITYPEUpset.eq.2141)then
        UpsetType='TCV Failed Open'
        elseif(ITYPEUpset.eq.211)then
        UpsetType='Decrease in feed temperature'
        elseif(ITYPEUpset.eq.21211)then
        UpsetType='Hotwell Pump Overspeed'
        elseif(ITYPEUpset.eq.21212)then
        UpsetType='Condensate Pump Overspeed'
        elseif(ITYPEUpset.eq.2123)then
        UpsetType='FBV Failed Open'
        elseif(ITYPEUpset.eq.2122)then
        UpsetType='FCV Failed Open'
        elseif(ITYPEUpset.eq.220)then
        UpsetType='Loss of all Feed Pumps'
        ITRIPFP=1
        elseif(ITYPEUpset.eq.230)then
        UpsetType='Loss of all RCPs'
        ITRIPRCP1=1
        ITRIPRCP2=1
        elseif(ITYPEUpset.eq.240)then
        UpsetType='Uncontrolled Rod Bank Withdrawal'
        elseif(ITYPEUpset.eq.241)then
        UpsetType='Dropped RCCA'
        else
        UpsetType='No Upsets'
        endif
c.
      write(10,2011)UpsetType,(UPSETPARM(i),i=1,4)
        if(ModeRODS.eq.0)then
        write(10,*)'Control Rods in Manual'
        elseif(ModeRODS.eq.1)then
        write(10,*)'Control Rods in Automatic'
        endif
      write(10,2007)Tmax,WriteInterval,RestartInterval
c.
 2000 Format(1x,'Case File',16x,A24)
 2001 Format(1x,'Geometry File ',11x,A24)
 2002 Format(1x,'Core Data File',11x,A24)
 2003 Format(1x,'Component Data File    ',2x,A24)
 2004 Format(1x,'Initial Conditions File',2x,A24,/1x,
     %          'TES Data File          ',2x,A24,/1x,
     %          'Initialization mode',3x,I4)
 2005 Format(1x,'Step Change in Load to ',F7.2,' %',                
     %           F7.2,' seconds into the simulation')               			  
 2006 Format(1x,'Ramp Change in Load of ',F7.2,
     %          ' % per min for ',F7.2,' minutes',
     %           F7.2,' seconds into the simulation')               
 2007 Format(1x,'Simulation time ',f9.2,' seconds',/1x,						   !Konor
     %          'Output File Write Interval',I4,' seconds',/1x,
     %          'Restart File Write Interval ',I6,' seconds')
 2008 Format(1x,'Controller Gains File  ',2x,A24)
 2009 Format(1x,'Sensor Data File       ',2x,A24)
 2010 Format(1x,'Valve Data File        ',2x,A24)
 2011 Format(1x/,1x,A40,//1x,
     %       'Upset Parameter 1',1x,e11.4,/1x,
     %       'Upset Parameter 2',1x,e11.4,/1x,
     %       'Upset Parameter 3',1x,e11.4,/1x,
     %       'Upset Parameter 4',1x,e11.4,/1x)
 2012 Format(1x,'Trip Set Point File    ',2x,A24)
 2013 Format(1x,'Daily Load File',10x,A24)
 2014 Format(1x,'BOP Geometry File      ',2x,A24)
c.
c.*************************************************************
c.
c.    Geometry Data
c.
      Open(unit=14,file=GeometryFile)
       do j=1,26
       read(14,*)Length(j),Area(j),V(j),Pheated(j),GenFraction(j),
     %           DeltaH(j),Equiv_Diam(j),lloss(j)
       Vp(j)=V(j)
       enddo
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*   Primary Side Geometry Data   *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
      write(10,4000)
      write(10,*)' '
c.
        do j=1,26
        write(10,4001)j,Length(j),Area(j),V(j),Pheated(j),
     %                  GenFraction(j),DeltaH(j),Equiv_Diam(j),lloss(j)
        enddo
c.
 4000 Format(3x,'Node',4x,'Length',8x,'Area',8x,'Volume',
     %       6x,'Pheated',4x,'GenFraction',4x,'Delta H',
     %       8x,'De',4x,'Loss Coefficient',/1x,11x,'(ft)',
     %       7x,'(ft**2)',6x,'(ft**3)',7x,'(ft)',22x,'(ft)',9x,'(ft)')
 4001 Format(1x,i4,8(2x,e11.4))     
      Close(unit=14)
      DeCore=Equiv_Diam(1)
      AxCore=Area(1)
c.
c.*************************************************************
c.
c.    Reactor Core Data
c.
      Open(unit=4,file=RxDataFile)
c.
c.    Input Reactor Physics Data
c.
      Read(4,*)RefRxPwr
      Read(4,*)prompt,Srx
      Read(4,*)(beta06(j),j=1,6)
      Read(4,*)(lamda06(j),j=1,6)
      Read(4,*)alphamod,alphaTrx,alphaBoron
      Read(4,*)Tref,TrxREF,Cref
      Read(4,*)GammaX,lamdaX,sigmaX,SigmaF,EquilibriumXenonWorth
      Read(4,*)GammaI,lamdaI
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*        Reactor Core Data       *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
      write(10,3000)RefRxPwr,
     %              prompt,SRX,
     %              alphamod,alphaTrx,alphaBoron,
     %              Tref,TrxREF,Cref,
     %              GammaX,lamdaX,sigmaX,SigmaF,EquilibriumXenonWorth,
     %              GammaI,lamdaI              
c.
 3000 Format(1x,'Nominal Full Power (Mwt)',16x,e11.4,/1x,
     %          'Prompt Neutron Lifetime (sec)',11x,e11.4,/1x,										      
     %          'External Neutron Source (Mw/hr)',9x,e11.4,/1x,
     %          'Moderator Temperature Coefficient (1/F)',1x,e11.4,/1x,
     %          'Fuel Temperature Coefficient (1/F)',6x,e11.4,/1x,
     %          'Soluable Boron Coefficient (1/ppm)',6x,e11.4,/1x,
     %          'Reference Moderator Temperature (F)',5x,e11.4,/1x,
     %          'Reference Fuel Temperature (F)',10x,e11.4,/1x,
     %          'Reference Boron Concentration (ppm)',5x,e11.4,//12x,
     %          'Xenon 135 Data',//1x,
     %          'Xenon 135 Fission Yield',17x,e11.4,/1x,
     %          'Xenon 135 Decay Constant (1/sec)',8x,e11.4,/1x,
     %          'Xenon 135 Absorption X-section (barns)',2x,e11.4,/1x,
     %          'Macroscopic Fission X-section (1/cm)',4x,e11.4,/1x,
     %          'Equilibrium Xenon Worth (pcm)',11x,e11.4,//1x,
     %          'I 135 Fission Yield',21x,e11.4,/1x,
     %          'I-135 Decay Constant (1/sec)',12x,e11.4)
c.
      psiX=1.16e12
      sigmaX=sigmaX*1.e-24
      EquilibriumXenonWorth=EquilibriumXenonWorth*1.e-5               
c.
      write(10,3100)
       do j=1,6
       write(10,3101)j,beta06(j),lamda06(j)
       enddo
 3100 Format(//12x,'Delayed Neutron Data',//1x,
     %       1x,'Group',2x,'Delayed Neutron Fraction',
     %       2x,'Decay Constant (1/sec)',/)
 3101 Format(1x,i4,8x,e11.4,14x,e11.4)
c.      
      Cb=0.
      Rho0=0.
c.
c.    Input Fuel Rod Thermal Data
c.
      Read(4,*)rhoUO2,Gammaf
      Read(4,*)rhoc,Cpc,kc
      Read(4,*)HGAP
c.
c.    Input Fuel Rod Geometric Data
c.
      Read(4,*)nrods,FuelHeight,Diameter,Dpellet,P_D,tc
c.
c.    Input Hot Channel Data
c.
      Read(4,*)alamda,Fq,Fz,nodesHC,ICHF
c.
      if(ICHF.eq.1)then
      CHFCorrelation='W3'
      elseif(ICHF.eq.2)then
      CHFCorrelation='Bowring'
      elseif(ICHF.eq.3)then
      CHFCorrelation='EPRI-1'
      endif
c.      
      write(10,*)' '
      write(10,3001)rhoUO2,Gammaf*100.,
     %              rhoc,Cpc,kc,
     %              HGAP,
     %              nrods,FuelHeight,Diameter,Dpellet,P_D,tc,
     %              alamda,Fq,Fz,nodesHC,CHFCorrelation
c.
 3001 Format(1x,'Fuel Density (lbm/ft**3)',16x,e11.4,/1x,
     %          'Heat Generated in Fuel (%)',14x,e11.4,/1x,
     %          'Clad Density (lbm/ft**3)',16x,e11.4,/1x,
     %          'Clad Specific Heat (Btu/lbm-F)',10x,e11.4,/1x,
     %          'Clad Thermal Conductivity (Btu/hr-ft-F)',1x,e11.4,/1x,
     %          'Gap Conductance (Btu/hr-ft**2-F)',8x,e11.4,/1x,
     %          'Number of Fuel Rods',21x,I8,/1x,
     %          'Active Fuel Height (ft)',17x,e11.4,/1x,
     %          'Outer Clad Diameter (inches)',12x,e11.4,/1x,
     %          'Fuel Pellet Diameter (inches)',11x,e11.4,/1x,
     %          'Pitch to Diameter Ratio',17x,e11.4,/1x,
     %          'Clad Thickness (inches)',17x,e11.4,//1x,
     %          'Hot Channel Extrapolation Distance (ft)',1x,e11.4,/1x,
     %          'Total Power Peaking Factor',14x,e11.4,/1x,
     %          'Axial Peaking Factor',20x,e11.4,/1x,
     %          'Number of Axial nodes for computing DNBR',2x,I4,/1x,
     %          'Critical Heat Flux Correlation',13x,A6)
      Diameter=Diameter/12.
      Dpellet=Dpellet/12.
      tc=tc/12.
      Di=Diameter-2.*tc
      Vfuel=float(nrods)*(Pi*Dpellet**2/4.)*FuelHeight
c.
c.    Input Control Rod Data
c.
      Read(4,*)aref,bref      
      Read(4,*)ShutDownWorth,
     %         RodLength,RodspeedMin,RodspeedMax
      Read(4,*)BankWorthParameters(1,1),BankWorthParameters(1,2),
     %         BankWorthParameters(1,3)
      Read(4,*)BankWorthParameters(2,1),BankWorthParameters(2,2),
     %         BankWorthParameters(2,3)
      Read(4,*)BankWorthParameters(3,1),BankWorthParameters(3,2),
     %         BankWorthParameters(3,3)
      Read(4,*)BankWorthParameters(4,1),BankWorthParameters(4,2),
     %         BankWorthParameters(4,3)
      Read(4,*)BankLength,Overlap
c.
      CummWorth=ControlBankWorth(1,0.)+ControlBankWorth(2,0.)+
     %          ControlBankWorth(3,0.)+ControlBankWorth(4,0.)
c.
      write(10,*)' '
      write(10,3002)CummWorth*100.,ShutDownWorth,
     %              RodLength,RodspeedMin,RodspeedMax,
     %              BankWorthParameters(1,1),BankWorthParameters(1,2),
     %              BankWorthParameters(1,3),
     %              BankWorthParameters(2,1),BankWorthParameters(2,2),
     %              BankWorthParameters(2,3),
     %              BankWorthParameters(3,1),BankWorthParameters(3,2),
     %              BankWorthParameters(3,3),
     %              BankWorthParameters(4,1),BankWorthParameters(4,2),
     %              BankWorthParameters(4,3),
     %              BankLength,Overlap,
     %              aref,bref
c.
 3002 Format(1x,'Cummulative Control Bank Worth (%)',7x,e11.4,/1x,
     %          'Shut Down Bank Worth (%)          ',7x,e11.4,/1x,
     %          'Control Bank Length (ft)          ',7x,e11.4,/1x,
     %          'Minimum Rod Speed (inches/min)    ',7x,e11.4,/1x,
     %          'Maximum Rod Speed (inches/min)    ',7x,e11.4,///1x,
     %		  'Control Bank Parameters           ',///1x,
     %          'Control Bank A                    ',//1x,
     %          'Parameter 1                       ',7x,e11.4,/1x,
     %          'Parameter 2                       ',7x,e11.4,/1x,
     %          'Parameter 3                       ',7x,e11.4,///1x,
     %          'Control Bank B                    ',//1x,
     %          'Parameter 1                       ',7x,e11.4,/1x,
     %          'Parameter 2                       ',7x,e11.4,/1x,
     %          'Parameter 3                       ',7x,e11.4,///1x,
     %          'Control Bank C                    ',//1x,
     %          'Parameter 1                       ',7x,e11.4,/1x,
     %          'Parameter 2                       ',7x,e11.4,/1x,
     %          'Parameter 3                       ',7x,e11.4,///1x,
     %          'Control Bank D                    ',//1x,
     %          'Parameter 1                       ',7x,e11.4,/1x,
     %          'Parameter 2                       ',7x,e11.4,/1x,
     %          'Parameter 3                       ',7x,e11.4,///1x,
     %          'Control Bank Length (Steps)       ',7x,e11.4,/1x,
     %          'Overlap (Steps)                   ',7x,e11.4,///1x,
     %          'Rod Control Program               ',///1x,
     %          'TaveREF = ',e11.4,1x,'+',e11.4,' x Wturb/RefLoad')
      ShutDownWorth=ShutDownWorth/100.
      RodspeedMin=RodspeedMin*5.
      RodspeedMax=RodspeedMax*5.
      InchesPerStep=RodLength*12./BankLength
c.
      RodGain=.005
c      ModeRODS=1
c.
      Close(unit=4)
c.
      if(ITYPEUpset.eq.241)then
c.
c.    Dropped RCCA
c.
      Rho0=UPSETPARM(1)*1.e-5
      Fq=UPSETPARM(2)
      IBANK=UPSETPARM(3)
        if(IBANK.lt.5)then
        CummWorth=CummWorth-Rho0
        BankWorthParameters(IBANK,1)=BankWorthParameters(IBANK,1)-
     %                               UPSETPARM(1)
        else
        ShutDownWorth=ShutDownWorth*1.e-3-Rho0
        endif      
      endif
c.
c.************************************************************
      Open(unit=4,file=TripSTPTFile)
c.
c.    Input Reactor Trip Set Points
c.
      Read(4,*)FlowVnom,QRXnom,TripDelay
      NTRIPS=8
       do i=1,NTRIPS
       Read(4,*)RxTRIPS(i),ITRIPMode(i)
       enddo
c.
      write(10,*)' '
      write(10,*)'***********************'
      write(10,*)'*                     *'
      write(10,*)'*  Reactor Trip Data  *'
      write(10,*)'*                     *'
      write(10,*)'***********************'
      write(10,*)' '
c.
      write(10,3102)FlowVnom,QRXnom,TripDelay
       do i=1,NTRIPS
         if(ITRIPMode(i).eq.1)then
         TripStatus(i)='Active'
         else
         TripStatus(i)='Inactive'
         endif
       enddo
      write(10,3202)(RxTRIPS(i),TripStatus(i),i=1,NTRIPS)
c.
 3102 Format(1x,'Nominal Reactor Coolant Flow (lbm/hr)',5x,e11.4,/1x,
     %          'Nominal Neutron Power (Mw)           ',5x,e11.4,/1x,
     %          'TripDelay (sec)                      ',5x,e11.4,//)
 3202 Format(1x,'High Neutron Flux Trip (% Nominal)   ',2x,e11.4,1x,
     %          'Status = ',A8,/1x,
     %          'Low Coolant Flow (% Nominal)         ',2x,e11.4,1x,
     %          'Status = ',A8,/1x,
     %          'High Pressurizer Pressure (psia)     ',2x,e11.4,1x,
     %          'Status = ',A8,/1x,
     %          'High Feedwater Flow (% Nominal)      ',2x,e11.4,1x,
     %          'Status = ',A8,/1x,
     %          'Low Feedwater Flow (% Nominal)       ',2x,e11.4,1x,
     %          'Status = ',A8,/1x,
     %          'Low Pressurizer Pressure (psia)      ',2x,e11.4,1x,
     %          'Status = ',A8,/1x,
     %          'High Pressurizer Level (%)           ',2x,e11.4,1x,
     %          'Status = ',A8,/1x,
     %          'Low Steam Temperature (F)            ',2x,e11.4,1x,
     %          'Status = ',A8)
c.
      Close(unit=4)
c.
c.************************************************************
c.
      Open(unit=3,file=ComponentFile)
c.
c.    Input Pressurizer Data
c.
      Read(3,*)RSRG,HSRG,RDOME,HHEAD,DORIFICE,KPRZ(3),nORIFICE
c.
      Read(3,*)Qprop,Qbackup,TauHeater
      Read(3,*)PRZSETPOINT(5),PRZSETPOINT(6),
     %         PRZSETPOINT(7),PRZSETPOINT(8)
c.
      Read(3,*)PRZSETPOINT(9)
c.
      Read(3,*)NPRZSRVs
        do n=1,NPRZSRVs
        read(3,*)KPRZSRV(n),AxSRV(n),PRZSETPOINT(n)
        enddo      
c.
      Read(3,*)SprayPumpDeltaP,DSPRAY,DBYPASS,DSCV,LSPRAY
      Read(3,*)KSPRAY,KBYPASS
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*        Pressurizer Data        *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
      write(10,3012)RSRG,HSRG,RDOME,HHEAD,nORIFICE,
     %              DORIFICE,KPRZ(3),Qprop,Qbackup,TauHeater,
     %              PRZSETPOINT(5),PRZSETPOINT(6),PRZSETPOINT(7),
     %              PRZSETPOINT(8),PRZSETPOINT(9),
     %              NPRZSRVs,KPRZSRV(1),KPRZSRV(2),
     %              KPRZSRV(3),KPRZSRV(4),AxSRV(1),AxSRV(2),AxSRV(3),
     %              AxSRV(4),PRZSETPOINT(1),PRZSETPOINT(2),
     %              PRZSETPOINT(3),PRZSETPOINT(4),SprayPumpDeltaP,
     %              DSPRAY,DBYPASS,DSCV,LSPRAY,KSPRAY,KBYPASS
c.
 3012 Format(1x,'Radius of Surge Region (ft)          ',1x,e11.4,/1x,
     %          'Height of Surge Region (ft)          ',1x,e11.4,/1x,
     %          'Upper Head Radius (ft)               ',1x,e11.4,/1x,
     %          'Upper Head Height (ft)               ',1x,e11.4,/1x,
     %          'Number of Surge Orifices             ',1x,I4,/1x,
     %          'Surge Orifice Diameter (ft)          ',1x,e11.4,/1x,
     %          'Surge Orifice Loss Coefficient       ',1x,e11.4,//1x,
     %          'Proportional Heater Capacity (kW)    ',1x,e11.4,/1x,
     %          'Backup Heater Capacity (kW)          ',1x,e11.4,/1x,
     %          'Heater Time Constant (sec)           ',1x,e11.4,//1x,
     %		  'Pressurizer Heater Set Points        ',//1x,
     %          'Pressurizer Reference Pressure (psia)',1x,e11.4,/1x,
     %          'Backup Heaters on (psia)             ',1x,e11.4,/1x,
     %          'Proportional Heaters Full on (psia)  ',1x,e11.4,/1x,
     %          'All Heaters Off (psia)               ',1x,e11.4,//1x,
     %          'Pressurizer Spray Set Points         ',//1x,
     %          'Pressurizer Spray Full On (psia)     ',1x,e11.4,//1x,
     %          'Number of Pressurizer SRVs (4 max)   ',1x,I4,/1x,
     %          'SRV 1 Loss Coefficient               ',1x,e11.4,/1x,              
     %          'SRV 2 Loss Coefficient               ',1x,e11.4,/1x,              
     %          'SRV 3 Loss Coefficient               ',1x,e11.4,/1x,              
     %          'SRV 4 Loss Coefficient               ',1x,e11.4,/1x,
     %          'SRV 1 Flow Area (ft**2)              ',1x,e11.4,/1x,              
     %          'SRV 2 Flow Area (ft**2)              ',1x,e11.4,/1x,              
     %          'SRV 3 Flow Area (ft**2)              ',1x,e11.4,/1x,              
     %          'SRV 4 Flow Area (ft**2)              ',1x,e11.4,//1x,
     %          'Pressurizer SRV Set Points           ',//1x,
     %          'Pressurizer SRV 1 Set Point (psia)   ',1x,e11.4,/1x,
     %          'Pressurizer SRV 2 Set Point (psia)   ',1x,e11.4,/1x,
     %          'Pressurizer SRV 3 Set Point (psia)   ',1x,e11.4,/1x,
     %          'Pressurizer SRV 4 Set Point (psia)   ',1x,e11.4,//1x,
     %          'Spray Line Parameters                ',//1x,
     %          'Spray Pump Delta P (psi)             ',1x,e11.4,/1x,
     %          'Spray Line Diameter (inches)         ',1x,e11.4,/1x,
     %          'Bypass Line Diameter (inches)        ',1x,e11.4,/1x,
     %          'Spray Control Valve Diameter (inches)',1x,e11.4,/1x,
     %          'Spray Line Length (ft)               ',1x,e11.4,/1x,
     %          'Spray Line Loss Coefficient          ',1x,e11.4,/1x,
     %          'Bypass Line Loss Coefficient         ',1x,e11.4)
      write(10,*)' '              
c.
      TauHeater=TauHeater/3600.
      Qprop=Qprop*3412.14
      Qbackup=Qbackup*3412.14
      DSPRAY=DSPRAY/12.
      DBYPASS=DBYPASS/12.
      DSCV=DSCV/12.
c.
c.    Geometry Calculations
c.
      RVESSEL=RDOME
      HCYL=HHEAD-RDOME-HSRG
c.
c.    Fixed Areas
c.
        Ax3=float(nORIFICE)*Pi*DORIFICE**2/4.
        Ax4=Pi*RSRG**2
        AxVESSEL=Pi*RVESSEL**2
c.
        AxSPRAY=pi*DSPRAY**2/4.
        AxBypass=pi*DBYPASS**2/4.
        AxSCV=pi*DSCV**2/4.
c.
c.    Fixed Volumes
c.
        VOL(1)=0.
        VSRG=Ax4*HSRG
        VCYL=AxVESSEL*HCYL
        VDOME=(2./3.)*Pi*RDOME**3
        VHEAD=VDOME+VCYL
        VPRZ=VHEAD+VSRG
c.
c.************************************************************
c.
c.    Input Steam Generator Data
c.
      Read(3,*)PSG_Ref,FlowSG0,RefLoad,TurbineEFF,k_turb,SGRefLVL,
     %         SGRefLVL0,Pcond					
      Read(3,*)ITYPESG,ntubes,LengthSG,Ro,Ri,Pitch,kw,AxSG,Fouling
      Read(3,*)Tfeed0,afeed,bfeed,cfeed
c.
        if(ITYPESG.eq.1)then
        SteamGeneratorType='Helical Coil'
        elseif(ITYPESG.eq.2)then
        SteamGeneratorType='Conventional OTSG'
        endif
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*      Steam Generator Data      *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
      write(10,3003)SteamGeneratorType,PSG_Ref,Pcond,FlowSG0,AxSG,											
     %              RefLoad,TurbineEFF,k_turb,SGRefLVL,SGRefLVL0,
     %              ntubes,LengthSG,Ro,Ri,Pitch,kw,Fouling,
     %              Tfeed0,afeed,bfeed,cfeed									
c.
 3003 Format(1x,'Steam Generator Type                   ',1x,A24,//1x,
     %          'Nominal Steam Pressure (psia)          ',1x,e11.4,/1x,
     %          'Condenser Pressure (psia)              ',1x,e11.4,/1x,
     %          'Nominal Steam Flow Rate (lbm/hr)       ',1x,e11.4,/1x,
     %          'Steam Generator Flow Area (ft**2)      ',1x,e11.4,/1x,
     %          'Reference Turbine Load (Mw)            ',1x,e11.4,/1x,
     %          'Effective Turbine Efficiency (%)       ',1x,e11.4,/1x,
     %          'Effective Turbine Loss Coefficient     ',1x,e11.4,/1x,
     %          'Reference Level (ft)                   ',1x,e11.4,/1x,
     %          'Full Scale Reference Level (ft)        ',1x,e11.4,/1x,				
     %          'Number of Steam Generator Tubes        ',1x,I8,/1x,
     %          'Steam Generator Tube Length (ft)       ',1x,e11.4,/1x,
     %          'Outer Tube Radius (inches)             ',1x,e11.4,/1x,
     %          'Inner Tube Radius (inches)             ',1x,e11.4,/1x,
     %          'Tube Pitch (inches)                    ',1x,e11.4,/1x,
     %          'Tube Thermal Conductivity (Btu/hr-ft-F)',1x,e11.4,/1x,
     %          'Fouling Parameter (%)                  ',1x,e11.4,//1x,
     %          'Feed Temperature Program               ',//1x,
     %          'Tfeed=',e11.4,' x (',e11.4,' + ',e11.4,
     %          ' x Prelative + ',e11.4,' x Prelative**2)')
      write(10,*)' '
      FlowDemand0=FlowSG0      
      DeltazSG=LengthSG/60.
      Ro=Ro/12.
      Ri=Ri/12.
      Pitch=Pitch/12.
      Fouling=Fouling/100.
      Roughness=0.000001+0.0006*Fouling/0.3
      TurbineEFF=TurbineEFF/100.
c.
        if(ITYPESG.eq.1)then
        DeSG=2.*Ri
        else
        DeSG=4.*(Pitch**2*sqrt(3.)/4.-Pi*(2.*Ro)**2/8.)/
     %          (Pi*Ro)
        endif
c.
c.************************************************************
c.
c.    Input Reactor Coolant Pump Data
c.
      Read(3,*)nRCPs,QR,HeadR,OmegaR,Inertia
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*   Reactor Coolant Pump Data    *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
      write(10,3004)nRCPs,QR,HeadR,OmegaR,Inertia
c.
 3004 Format(1x,'Number of Reactor Coolant Pump/SG pairs ',1x,I4,/1x,
     %          'Rated Volumetric Flow Rate (gpm)        ',1x,e11.4,/1x,
     %          'Rated Head (ft)                         ',1x,e11.4,/1x,
     %          'Rated Speed (rpm)                       ',1x,e11.4,/1x,
     %          'Flywheel Inertia (ft-lbf)               ',1x,e11.4,/1x)
      QR=QR*0.13368*60.
      npumps2=INT(float(nRCPs)/2.+0.51)
      npumps1=nRCPs-npumps2
c.
      nSGs2=npumps2
      nSGs1=npumps1
      nSG=nRCPs
c.
      nodePp1=7
      nodePp2=25

      PumpDegradation=1.
c.************************************************************
c.
c.    Input Feed Pump Data
c.
      Read(3,*)nFP,QR1(1),HR(1),OmegaR1(1)
      Read(3,*)a0P(1),b0P(1),c0P(1),d0P(1)
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*        Feed Pump Data          *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
      write(10,3005)nFP,QR1(1),HR(1),OmegaR1(1),
     %              a0P(1),b0P(1),c0P(1),d0P(1)
c.
 3005 Format(1x,'Number of Feed Pumps                   ',1x,I4,/1x,
     %          'Rated Volumetric Flow Rate (gpm)       ',1x,e11.4,/1x,
     %          'Rated Head (ft)                        ',1x,e11.4,/1x,
     %          'Rated Speed (rpm)                      ',1x,e11.4,//1x,
     %          '    Coefficients in Characteristic Pump Curve   ',//1x,
     %          'a0                                     ',1x,e11.4,/1x,
     %          'b0                                     ',1x,e11.4,/1x,
     %          'c0                                     ',1x,e11.4,/1x,
     %          'd0                                     ',1x,e11.4,/1x)
      QR1(1)=QR1(1)*0.13368*60.
c.************************************************************
c.
c.    Input Condensate Pump Data
c.
      Read(3,*)nCP,QR1(2),HR(2),OmegaR1(2)
      Read(3,*)a0P(2),b0P(2),c0P(2),d0P(2)
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*     Condensate Pump Data       *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
      write(10,3006)nCP,QR1(2),HR(2),OmegaR1(2),
     %              a0P(2),b0P(2),c0P(2),d0P(2)
c.
 3006 Format(1x,'Number of Condendsate Pumps            ',1x,I4,/1x,
     %          'Rated Volumetric Flow Rate (gpm)       ',1x,e11.4,/1x,
     %          'Rated Head (ft)                        ',1x,e11.4,/1x,
     %          'Rated Speed (rpm)                      ',1x,e11.4,//1x,
     %          '    Coefficients in Characteristic Pump Curve   ',//1x,
     %          'a0                                     ',1x,e11.4,/1x,
     %          'b0                                     ',1x,e11.4,/1x,
     %          'c0                                     ',1x,e11.4,/1x,
     %          'd0                                     ',1x,e11.4,/1x)
      QR1(2)=QR1(2)*0.13368*60.
c.************************************************************
c.
c.    Input Hotwell Pump Data
c.
      Read(3,*)nHWP,QR1(3),HR(3),OmegaR1(3)
      Read(3,*)a0P(3),b0P(3),c0P(3),d0P(3)
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*      Hotwell Pump Data         *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
      write(10,3007)nHWP,QR1(3),HR(3),OmegaR1(3),
     %              a0P(3),b0P(3),c0P(3),d0P(3)
c.
 3007 Format(1x,'Number of Hotwell Pumps                ',1x,I4,/1x,
     %          'Rated Volumetric Flow Rate (gpm)       ',1x,e11.4,/1x,
     %          'Rated Head (ft)                        ',1x,e11.4,/1x,
     %          'Rated Speed (rpm)                      ',1x,e11.4,//1x,
     %          '    Coefficients in Characteristic Pump Curve   ',//1x,
     %          'a0                                     ',1x,e11.4,/1x,
     %          'b0                                     ',1x,e11.4,/1x,
     %          'c0                                     ',1x,e11.4,/1x,
     %          'd0                                     ',1x,e11.4,/1x)
      QR1(3)=QR1(3)*0.13368*60.
c.*************************************************************
c.
c.    Input Startup Feedwater Pump Data
c.
      Read(3,*)DeltaPSFWPump
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*  Startup Feedwater Pump Data   *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
	write(10,*)' '
c.
      write(10,3018)DeltaPSFWPump
c.
 3018 Format(1x,'Startup Feedwater Pump Delta P (psi)   ',1x,e11.4)
c.
      Close(unit=3)
c.************************************************************
c.
      Open(unit=16,file=ControllerGains)
c.
c.    Input Controller Gains
c.
      Read(16,*)OmegaGAIN
c.
      write(10,*)' '
      write(10,*)'*************************************'
      write(10,*)'*                                   *'
      write(10,*)'*  Feedpump Speed Controller Gains  *'
      write(10,*)'*                                   *'
      write(10,*)'*************************************'
      write(10,*)' '
c.
      write(10,3016)OmegaGAIN

 3016 Format(1x,'Proportional Gain                     ',1x,e11.4,/1x)
c.
      Read(16,*)PRZHTRGain0,PRZHTRGain1,PRZHTRGain2
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*    Pressurizer Heater Gains    *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
      write(10,3015)PRZHTRGain0,PRZHTRGain1,PRZHTRGain2

 3015 Format(1x,'Controller Offset                     ',1x,e11.4,/1x,
     %          'Proportional Gain                     ',1x,e11.4,/1x,
     %          'Integral Gain                         ',1x,e11.4,/1x)        

c.
      Read(16,*)nTCV
       do j=1,nTCV
       Read(16,*)TCVGain(1,1,j),TCVGain(1,2,j),TCVGain(1,3,j)
       enddo
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*  Turbine Control Valve Gains   *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
        do j=1,nTCV
        write(10,*)' '
        write(10,3008)j,TCVGain(1,1,j),TCVGain(1,2,j),TCVGain(1,3,j)
        enddo
 3008 Format(1x,'Turbine Control Valve Nunber          ',1x,i4,/1x,
     %          'Controller Offset                     ',1x,e11.4,/1x,
     %          'Proportional Gain                     ',1x,e11.4,/1x,
     %          'Integral Gain                         ',1x,e11.4,/1x)        
c.
      Read(16,*)nTBV
       do j=1,nTBV
       Read(16,*)TBVGain(1,1,j),TBVGain(1,2,j),TBVGain(1,3,j)
       enddo
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*  Turbine Bypass Valve Gains    *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
        do j=1,nTBV
        write(10,*)' '
        write(10,3009)j,TBVGain(1,1,j),TBVGain(1,2,j),TBVGain(1,3,j)
        enddo
 3009 Format(1x,'Turbine Bypass Valve Nunber           ',1x,i4,/1x,
     %          'Controller Offset                     ',1x,e11.4,/1x,
     %          'Proportional Gain                     ',1x,e11.4,/1x,
     %          'Integral Gain                         ',1x,e11.4,/1x)        
c.
      Read(16,*)FeedGain(1,1),FeedGain(1,2),FeedGain(1,3),KSHIM
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*    Feed Control Valve Gains    *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
      write(10,3010)FeedGain(1,1),FeedGain(1,2),FeedGain(1,3),KSHIM
c.
 3010 Format(1x,'Feed Controller Offset                 ',1x,e11.4,/1x,
     %          'Feed Controller Proportional Gain      ',1x,e11.4,/1x,
     %          'Feed Controller Integral Gain          ',1x,e11.4,//1x,
     %          'Feed Shim Gain                         ',1x,e11.4,/1x)
c.        
      Read(16,*)FeedByPassGain(1,1),FeedByPassGain(1,2),
     %          FeedByPassGain(1,3)
c.
      write(10,*)' '
      write(10,*)'**********************************'
      write(10,*)'*                                *'
      write(10,*)'*    Feed ByPass Valve Gains     *'
      write(10,*)'*                                *'
      write(10,*)'**********************************'
      write(10,*)' '
c.
      write(10,3011)FeedByPassGain(1,1),FeedByPassGain(1,2),
     %              FeedByPassGain(1,3)
c.
 3011 Format(1x,'Feed ByPass Offset                 ',1x,e11.4,/1x,
     %          'Feed ByPass Proportional Gain      ',1x,e11.4,/1x,
     %          'Feed ByPass Integral Gain          ',1x,e11.4,/1x)        
c.
      Read(16,*)SFWSGain(1),SFWSGain(2),
     %          SFWSGain(3)
c.
      write(10,*)' '
      write(10,*)'**********************************************'
      write(10,*)'*                                            *'
      write(10,*)'*    Starup Feedwater System Valve Gains     *'
      write(10,*)'*                                            *'
      write(10,*)'**********************************************'
      write(10,*)' '
c.
      write(10,3017)SFWSGain(1),SFWSGain(2),
     %              SFWSGain(3)
c.
 3017 Format(1x,'Startup Feedwater Offset                ',1x,e11.4,/1x,
     %          'Startup Feedweter Proportional Gain     ',1x,e11.4,/1x,
     %          'Startup Feedwater Integral Gain         ',1x,e11.4,/1x)        
c.
      Read(16,*)SprayGain(1,1),SprayGain(1,2),
     %          SprayGain(1,3)
c.
      write(10,*)' '
      write(10,*)'**********************************************'
      write(10,*)'*                                            *'
      write(10,*)'*    Spray Control Valve Gains               *'
      write(10,*)'*                                            *'
      write(10,*)'**********************************************'
      write(10,*)' '
c.
      write(10,3020)SprayGain(1,1),SprayGain(1,2),
     %              SprayGain(1,3)
c.
 3020 Format(1x,'Spray Control Valve Offset              ',1x,e11.4,/1x,
     %          'Spray Control Valve Proportional Gain   ',1x,e11.4,/1x,
     %          'Spray Control Valve Integral Gain       ',1x,e11.4,/1x)        
c.
c.
c.
      Close(unit=16)
c.************************************************************
c.
      Open(unit=17,file=SensorDataFile)
c.
c.    Read Sensor Data
c.
      NSensors=10
        do j=1,NSensors
        Read(17,*)SensorNode(j),SensorSpan(j),SensorBias(j),
     %            SensorDriftRate(j),SensorDriftDuration(j),
     %            SensorNoiseData(j,1),SensorNoiseData(j,2)
        enddo
c.
      write(10,*)' '
      write(10,*)'*************************************'
      write(10,*)'*                                   *'
      write(10,*)'*       Hot Leg Sensor Data         *'
      write(10,*)'*                                   *'
      write(10,*)'*************************************'
      write(10,*)' '
c.
      write(10,3013)SensorNode(1),SensorSpan(1),SensorBias(1),
     %              SensorDriftRate(1),SensorDriftDuration(1),
     %              SensorNoiseData(1,1),SensorNoiseData(1,2)
c.
      write(10,*)' '
      write(10,*)'*************************************'
      write(10,*)'*                                   *'
      write(10,*)'*       Cold Leg Sensor Data        *'
      write(10,*)'*                                   *'
      write(10,*)'*************************************'
      write(10,*)' '
c.
      write(10,3013)SensorNode(2),SensorSpan(2),SensorBias(2),
     %              SensorDriftRate(2),SensorDriftDuration(2),
     %              SensorNoiseData(2,1),SensorNoiseData(2,2)
c.
      write(10,*)' '
      write(10,*)'*************************************'
      write(10,*)'*                                   *'
      write(10,*)'*    Steam Pressure Sensor Data     *'
      write(10,*)'*                                   *'
      write(10,*)'*************************************'
      write(10,*)' '
c.
      write(10,3013)SensorNode(3),SensorSpan(3),SensorBias(3),
     %              SensorDriftRate(3),SensorDriftDuration(3),
     %              SensorNoiseData(3,1),SensorNoiseData(3,2)
c.
      write(10,*)' '
      write(10,*)'*************************************'
      write(10,*)'*                                   *'
      write(10,*)'*       Feed Flow Sensor Data       *'
      write(10,*)'*                                   *'
      write(10,*)'*************************************'
      write(10,*)' '
c.
      write(10,3013)SensorNode(4),SensorSpan(4),SensorBias(4),
     %              SensorDriftRate(4),SensorDriftDuration(4),
     %              SensorNoiseData(4,1),SensorNoiseData(4,2)
c.
      write(10,*)' '
      write(10,*)'*************************************'
      write(10,*)'*                                   *'
      write(10,*)'*      Steam Flow Sensor Data       *'
      write(10,*)'*                                   *'
      write(10,*)'*************************************'
      write(10,*)' '
c.
      write(10,3013)SensorNode(5),SensorSpan(5),SensorBias(5),
     %              SensorDriftRate(5),SensorDriftDuration(5),
     %              SensorNoiseData(5,1),SensorNoiseData(5,2)
c.
      write(10,*)' '
      write(10,*)'*************************************'
      write(10,*)'*                                   *'
      write(10,*)'*  Pressurizer Pressure Sensor Data *'
      write(10,*)'*                                   *'
      write(10,*)'*************************************'
      write(10,*)' '
c.
      write(10,3013)SensorNode(6),SensorSpan(6),SensorBias(6),
     %              SensorDriftRate(6),SensorDriftDuration(6),
     %              SensorNoiseData(6,1),SensorNoiseData(6,2)
c.
      write(10,*)' '
      write(10,*)'*************************************'
      write(10,*)'*                                   *'
      write(10,*)'*   Pressurizer Level Sensor Data   *'
      write(10,*)'*                                   *'
      write(10,*)'*************************************'
      write(10,*)' '
c.
      write(10,3013)SensorNode(7),SensorSpan(7),SensorBias(7),
     %              SensorDriftRate(7),SensorDriftDuration(7),
     %              SensorNoiseData(7,1),SensorNoiseData(7,2)
c.
      write(10,*)' '
      write(10,*)'*************************************'
      write(10,*)'*                                   *'
      write(10,*)'*    SG Exit Temp. Sensor Data      *'
      write(10,*)'*                                   *'
      write(10,*)'*************************************'
      write(10,*)' '
c.
      write(10,3013)SensorNode(8),SensorSpan(8),SensorBias(8),
     %              SensorDriftRate(8),SensorDriftDuration(8),
     %              SensorNoiseData(8,1),SensorNoiseData(8,2)
c.
      write(10,*)' '
      write(10,*)'*************************************'
      write(10,*)'*                                   *'
      write(10,*)'*      Feed Temp. Sensor Data       *'
      write(10,*)'*                                   *'
      write(10,*)'*************************************'
      write(10,*)' '
c.
      write(10,3013)SensorNode(9),SensorSpan(9),SensorBias(9),
     %              SensorDriftRate(9),SensorDriftDuration(9),
     %              SensorNoiseData(9,1),SensorNoiseData(9,2)
c.
      write(10,*)' '
      write(10,*)'*************************************'
      write(10,*)'*                                   *'
      write(10,*)'*      SG Delta P Sensor Data       *'
      write(10,*)'*                                   *'
      write(10,*)'*************************************'
      write(10,*)' '
c.
      write(10,3013)SensorNode(10),SensorSpan(10),SensorBias(10),
     %              SensorDriftRate(10),SensorDriftDuration(10),
     %              SensorNoiseData(10,1),SensorNoiseData(10,2)
c.
      NodeHL=SensorNode(1)
      NodeCL=SensorNode(2)
c.
        do j=1,NSensors
        SensorBias(j)=SensorBias(j)*SensorSpan(j)/100.
        SensorDriftRate(j)=SensorDriftRate(j)*SensorSpan(j)/100.
        SensorNoiseData(j,1)=SensorNoiseData(j,1)*SensorSpan(j)/100.
        SensorNoiseData(j,2)=SensorNoiseData(j,2)*SensorSpan(j)/100.
        enddo
c.
 3013 Format(1x,'Sensor Location (node)                 ',2x,I4,/1x,
     %          'Sensor Span                            ',1x,e11.4,/1x,
     %          'Sensor Bias (% of Span)                ',1x,e11.4,/1x,
     %          'Sensor Drift Rate (% of Span per hour) ',1x,e11.4,/1x,
     %          'Drift Duration (hrs)                   ',1x,e11.4,/1x,
     %          'Sensor Noise Mean (% of Span)          ',1x,e11.4,/1x,
     %          'Sensor Noise Std. Dev. (% of Span)     ',1x,e11.4,/1x)
c.         
      Close(unit=17)
c.************************************************************
c.
      Open(unit=18,file=ValveDataFile)
c.
c.    Read Control Valve Data
c.
c.    ****  Feed Control Valve Data  *****
c.
      Read(18,*)DeadBand(1),Tau(1),Avalve(1),Kvalve(1),bvalve(1),
     %          RATEFCV,FCVmin
c.
      write(10,*)' '
      write(10,*)'*********************************'
      write(10,*)'*                               *'
      write(10,*)'*    Feed Control Valve Data    *'
      write(10,*)'*                               *'
      write(10,*)'*********************************'
      write(10,*)' '
c.
      write(10,3014)DeadBand(1),Tau(1),Avalve(1),Kvalve(1),bvalve(1),
     %              RATEFCV,FCVmin
c.
      DeadBand(1)=DeadBand(1)/100.
      Tau(1)=Tau(1)/3600.
      RATEFCV=3600./RATEFCV
      FCVmin=FCVmin/100.
c.
c.    **** Feed Bypass Valve Data  ****
c.
      Read(18,*)DeadBand(2),Tau(2),Avalve(2),Kvalve(2),bvalve(2),
     %          RATEFBV,FBVmin
c.
      write(10,*)' '
      write(10,*)'*********************************'
      write(10,*)'*                               *'
      write(10,*)'*    Feed Bypass Valve Data     *'
      write(10,*)'*                               *'
      write(10,*)'*********************************'
      write(10,*)' '
c.
      write(10,3014)DeadBand(2),Tau(2),Avalve(2),Kvalve(2),bvalve(2),
     %              RATEFBV,FBVmin
c.
      DeadBand(2)=DeadBand(2)/100.
      Tau(2)=Tau(2)/3600.
      RATEFBV=3600./RATEFBV
      FBVmin=FBVmin/100.
c.
c.    **** Turbine Bypass Valve Data  ****
c.
      Read(18,*)DeadBand(3),Tau(3),Avalve(3),Kvalve(3),bvalve(3),
     %          RATETBV,TBVmin
c.
      write(10,*)' '
      write(10,*)'*********************************'
      write(10,*)'*                               *'
      write(10,*)'*   Turbine Bypass Valve Data   *'
      write(10,*)'*                               *'
      write(10,*)'*********************************'
      write(10,*)' '
c.
      write(10,3014)DeadBand(3),Tau(3),Avalve(3),Kvalve(3),bvalve(3),
     %              RATETBV,TBVmin
c.
      DeadBand(3)=DeadBand(3)/100.
      Tau(3)=Tau(3)/3600.
      RATETBV=3600./RATETBV
      TBVmin=TBVmin/100.
c.
c.    **** Turbine Control Valve Data  ****
c.
      Read(18,*)DeadBand(4),Tau(4),Avalve(4),Kvalve(4),bvalve(4),
     %          RATETCV,TCVmin
c.
      write(10,*)' '
      write(10,*)'*********************************'
      write(10,*)'*                               *'
      write(10,*)'*  Turbine Control Valve Data   *'
      write(10,*)'*                               *'
      write(10,*)'*********************************'
      write(10,*)' '
c.
      write(10,3014)DeadBand(4),Tau(4),Avalve(4),Kvalve(4),bvalve(4),
     %              RATETCV,TCVmin
c.
      DeadBand(4)=DeadBand(4)/100.
      Tau(4)=Tau(4)/3600.
      RATETCV=3600./RATETCV
      TCVmin=TCVmin/100.
c.
c.    **** Startup Feedwater System Control Valve Data  ****
c.
      Read(18,*)DeadBand(5),Tau(5),Avalve(5),Kvalve(5),bvalve(5),
     %          RATESFWV,SFWVmin
c.
      write(10,*)' '
      write(10,*)'***************************************************'
      write(10,*)'*                                                 *'
      write(10,*)'*  Startup Feedwater Systems Control Valve Data   *'
      write(10,*)'*                                                 *'
      write(10,*)'***************************************************'
      write(10,*)' '
c.
      write(10,3014)DeadBand(5),Tau(5),Avalve(5),Kvalve(5),bvalve(5),
     %              RATESFWV,SFWVmin
c.
      DeadBand(5)=DeadBand(5)/100.
      Tau(5)=Tau(5)/3600.
      RATESFWV=3600./RATESFWV
      SFWVmin=SFWVmin/100.
c.
c.
c.    **** Spray Control Valve Data  ****
c.
      Read(18,*)DeadBand(6),Tau(6),Avalve(6),Kvalve(6),bvalve(6),
     %          RATESCV,SCVmin
c.
      Avalve(6)=AxSCV
      write(10,*)' '
      write(10,*)'*******************************'
      write(10,*)'*                             *'
      write(10,*)'*  Spray Control Valve Data   *'
      write(10,*)'*                             *'
      write(10,*)'*******************************'
      write(10,*)' '
c.
      write(10,3014)DeadBand(6),Tau(6),Avalve(6),Kvalve(6),bvalve(6),
     %              RATESCV,SCVmin
c.
      RATESCV=3600./RATESCV
      DeadBand(6)=DeadBand(6)/100.
      Tau(6)=Tau(6)/3600.
      SCVmin=SCVmin/100.
c.
c.    **** TES TBV Data  ****
c.
      Read(18,*)DeadBand(7),Tau(7),Avalve(7),Kvalve(7),bvalve(7),
     %          RATETES_TBV,TES_TBVmin
c.
      write(10,*)' '
      write(10,*)'*************************'
      write(10,*)'*                       *'
      write(10,*)'*  TES TBV Valve Data   *'
      write(10,*)'*                       *'
      write(10,*)'*************************'
      write(10,*)' '
c.
      write(10,3014)DeadBand(7),Tau(7),Avalve(7),Kvalve(7),bvalve(7),
     %              RATETES_TBV,TES_TBVmin
c.
      RATETES_TBV=3600./RATETES_TBV
      DeadBand(7)=DeadBand(7)/100.
      Tau(7)=Tau(7)/3600.
      TES_TBVmin=TES_TBVmin/100.
c.
 3014 Format(1x,'Valve Dead Band (% of full open)    ',1x,e11.4,/1x,
     %          'Valve Time Constant (seconds)       ',1x,e11.4,/1x,
     %          'Valve Area (ft**2)                  ',1x,e11.4,/1x,
     %          'Valve Full Open Loss Coefficient    ',1x,e11.4,/1x,
     %          'Valve Constant                      ',1x,e11.4,/1x,
     %          'Valve Closing Time (seconds)        ',1x,e11.4,/1x,
     %          'Minimum Closed Position (% )        ',1x,e11.4)
c.
      Close(unit=18)
c.************************************************************
      Open(unit=19,file = BOPGeometryFile)
c.
      Read(19,*)nMSL,AreaMSL,AreaSL
      Read(19,*)AxFEED(1),AxFEED(2),AxFEED(3),AxFEED(4),AxFEED(5),
     %          AxFEED(6),AxFEED(7)
      Read(19,*)KFEED(1),KFEED(2),KFEED(3),KFEED(4),KFEED(5),
     %          KFEED(6),KFEED(7)
c.
      write(10,*)' '
      write(10,*)'***********************'
      write(10,*)'*                     *'
      write(10,*)'*  BOP Geometry Data  *'
      write(10,*)'*                     *'
      write(10,*)'***********************'
      write(10,*)' '
c.
      write(10,3019)nMSL,AreaMSL,AreaSL,
     %              AxFEED(1),AxFEED(2),AxFEED(3),AxFEED(4),
     %              AxFEED(5),AxFEED(6),AxFEED(7),
     %              KFEED(1),KFEED(2),KFEED(3),KFEED(4),
     %              KFEED(5),KFEED(6),KFEED(7)
c.													  
 3019 Format(1x,'Number of Main Steam Lines              ',3x,I2,/1x,
     %          'Main Steam Line Flow Area (ft**2)       ',1x,e11.4,/1x,
     %          'Steam Line to Turbine Flow Area (ft**2) ',1x,e11.4,//1x,
     %          'Hotwell Pump Line Flow Area (ft**2)     ',1x,e11.4,/1x,
     %          'Connecting Line 1 Flow Area (ft**2)     ',1x,e11.4,/1x,
     %          'Condensate Pump Line Flow Area (ft**2)  ',1x,e11.4,/1x,
     %          'Connecting Line 2 Flow Area (ft**2)     ',1x,e11.4,/1x,
     %          'Feed Pump Line Flow Area (ft**2)        ',1x,e11.4,/1x,
     %          'FCV Line Flow Area (ft**2)              ',1x,e11.4,/1x,
     %          'Feed Line Flow Area (ft**2)             ',1x,e11.4,//1x,
     %          'Hotwell Pump Line Loss Coefficient      ',1x,e11.4,/1x,
     %          'Connecting Line 1 Loss Coefficient      ',1x,e11.4,/1x,
     %          'Condensate Pump Line Loss Coefficient   ',1x,e11.4,/1x,
     %          'Connecting Line 2 Loss Coefficient      ',1x,e11.4,/1x,
     %          'Feed Pump Line Loss Coefficient         ',1x,e11.4,/1x,
     %          'FCV Line Loss Coefficient               ',1x,e11.4,/1x,
     %          'Feed Line Loss Coefficient              ',1x,e11.4)
c.
      Close(unit=19)                                         
c.************************************************************
      Open(unit=20,file=TESDataFile)
      Read(20,*)ModeTES
      Read(20,*)nTESByPass
      Read(20,*)TESFlowDEMAND0
      Read(20,*)KEXH
      Read(20,*)KTAP
      Read(20,*)KSHIMTES
      Read(20,*)(TESSetPoint(j),j=1,4)
      Read(20,*)(TES_TBVGain(j),j=1,3)
c.
      write(10,*)' '
      write(10,*)'**************'
      write(10,*)'*            *'
      write(10,*)'*  TES Data  *'
      write(10,*)'*            *'
      write(10,*)'**************'
      write(10,*)' '
c.
      write(10,*)'TES Mode                             ',ModeTES
      write(10,*)'Number of TES ByPass Valves          ',nTESByPass
      write(10,*)'Reference TES Flow                   ',TESFlowDEMAND0
      write(10,*)'TES Turbine Exhaust Loss Coefficient ',KEXH
      write(10,*)'TES Shim Gain                        ',KSHIMTES
      write(10,*)' '
      write(10,*)'TESSetPoint(1)                       ',TESSetPoint(1)
      write(10,*)'TESSetPoint(2)                       ',TESSetPoint(2)
      write(10,*)'TESSetPoint(3)                       ',TESSetPoint(3)
      write(10,*)'TESSetPoint(4)                       ',TESSetPoint(4)
      write(10,*)' '
      write(10,*)'TES_TBVGain(1)                       ',TES_TBVGain(1)
      write(10,*)'TES_TBVGain(2)                       ',TES_TBVGain(2)
      write(10,*)'TES_TBVGain(3)                       ',TES_TBVGain(3)
c.
      Close(unit=20)
c.************************************************************
c.
      close(unit=10)
c.
c.    Read Initial Conditions
c.
      Open(unit=2,file = InitFile)
c.
      Read(2,*)Time
      Read(2,*)Qrx,Qth,Qtrans,Trx,Tclad
      Read(2,*)NI,NX
      Read(2,*)(Precursor(j),j=1,6)
      Read(2,*)(gammaDH(j),j=1,11)
      Read(2,*)Flowv,Flow1,Flow2
	Read(2,*)(Told(i),i=1,26)
      Read(2,*)THLIND,TCLIND
      Read(2,*)Pp,Px
      Read(2,*)VOL(1),VOL(2),VOL(3),VOL(4),Ax5,PRZLVL
      Read(2,*)alphagPx(1),alphagPx(2),alphagPx(3),alphagPx(4)
      Read(2,*)rholPx(1),rholPx(2),rholPx(3),rholPx(4)
      Read(2,*)ulPx(1),ulPx(2),ulPx(3),ulPx(4)
      Read(2,*)rhogPx(1),rhogPx(2),rhogPx(3),rhogPx(4)
      Read(2,*)ugPx(1),ugPx(2),ugPx(3),ugPx(4)
      Read(2,*)rhoPx(1),rhoPx(2),rhoPx(3),rhoPx(4)
      Read(2,*)rhouPx(1),rhouPx(2),rhouPx(3),rhouPx(4)
      Read(2,*)VelPx(1),VelPx(2),VelPx(3),VelPx(4),VelPx(5)
      Read(2,*)VSRVPx(1),VSRVPx(2),VSRVPx(3),VSRVPx(4)
      Read(2,*)PRZMass(1),PRZMass(2),PRZMass(3),PRZMass(4)
      Read(2,*)PRZE(1),PRZE(2),PRZE(3),PRZE(4)
      Read(2,*)QHTRP,QHTRB,SCVPosition,Vspray
      Read(2,*)mdotCHRG,mdotLD
       do j=1,26
        do i=1,nodesSG(j)
        read(2,*)TSG(i,j),hSG(i,j)
        enddo
       enddo
       Read(2,*)CriticalLength1,CriticalLength2
       Read(2,*)SGMass1,SGMass2
         do i=1,4
         Read(2,*)BANKPOSITION(i)
         enddo
       Read(2,*)DeltaPFHSG1,DeltaPEHSG1,DeltaPHSG1
       Read(2,*)DeltaPFHSG2,DeltaPEHSG2,DeltaPHSG2
       Read(2,*)Qsteam,Wload,Wturb,PSGIND,Pimpulse,p_hdr						   
	  do i=1,60
        read(2,*) velocity_kk(i),pressure_kk(i),ie_kk(i),
     %	kafa_kk(i),aj_kk(i),density_kk(i)
        enddo
c
		Read(2,*) FlowSG,FlowFDInd,FlowDEMAND,FlowSteamInd,FeedSHIM			   
		Read(2,*) OmegaFP, FCV, FBV
		Read(2,*) TBVposition
          Read(2,*) Tfeed
		Read(2,*)TCVposition
          Read(2,*)TfuelAVE
          Read(2,*)TfuelHOT
          Read(2,*)uHOT
          Read(2,*)MDNBR
c.
      Read(2,*)TESLoad,TESFlowDemand,TESSHIM,FlowAUX1,FlowAUX2,
     %         FlowAUX3,PTAP,rhoTAP,hTAP,PTES											   !Konor
      Read(2,*)IOPENTES(1),IOPENTES(2),IOPENTES(3),IOPENTES(4)
      Read(2,*)TES_TBV(1),TES_TBV(2),TES_TBV(3),TES_TBV(4)
      Read(2,*)ICLOSETBV,LockTBV
c
	close(unit=2)
c.																					   !Konor
      do n=1,nTESByPass																   !Konor
      TES_TBVnew(n)=TES_TBV(n)														   !Konor
      enddo																			   !Konor
c.																					   !Konor
      iwrite=int(time)
      PxIND=Px
      PRZLVLIND=PRZLVL
      TSGEXITIND=TSG(10,8)
      TfeedIND=Tfeed
      DeltaPSGIND=DeltaPHSG1/144.
      SprayGPM=Vspray*AxSPRAY/(0.1556*60.)
c.
            if(IDEMAND.eq.0)then                     
            RampDuration=0.                          
		  aload=RefLoad*PowerFraction/100.         
            bload=0.                                 
            elseif(IDEMAND.eq.1)then                 
            RampDuration=RampDuration*60.            
            aload=Wload                              
            bload=RefLoad*RampRate/(100.*60.)
            elseif(IDEMAND.eq.2)then
              open(unit=2,file=LoadFile)
              read(2,*)ntimes
               do j=1,ntimes
               read(2,*)Hour(j),TurbineLoad(j)
               enddo
              close(unit=2)
            endif                                    
c.
	OmegaCP=OmegaR1(2)								 
      OmegaHWP=OmegaR1(3)
        if(ITYPEUpset.eq.21212)then
        OmegaCP=OmegaCP*(1.+UPSETPARM(1)/100.)
        elseif(ITYPEUpset.eq.21211)then
        OmegaHWP=OmegaHWP*(1.+UPSETPARM(1)/100.)
        endif

        if((ITYPEUpset.eq.212131).or.(ITYPEUpset.eq.212132))then
        OmegaFP=OmegaFP*(1.+UPSETPARM(1)/100.)
        endif 

      FlowSteam=density_kk(60)*velocity_kk(60)*AxSG
      FlowSteam=FlowSteam*3600.
		
	PSG=pressure_kk(1)
      SGLVL=DeltaPHSG1/rhof(PSG)
c.
      do j=1,4
      alphalPx(j)=1.-alphagPx(j)
      enddo
c.******************************************************
c
c.    Compute Initial Internal Energy Distribution
c.
      do,i=1,26
      uold(i)=uliq(Told(i))
      end do
c.
      Tave=(Told(NodeHL)+Told(NodeCL))/2.
      TaveIND=(THLIND+TCLIND)/2.
      Tave0=TaveIND
      Tmod=(Told(4)+Told(16))/2.
      TaveREF=aref+bref*Wturb/RefLoad
c.

        if(IDEBUG.eq.1)then
        write(6,*)' '
        Write(6,*)'Time=',Time
        write(6,*)'Flow1=',Flow1,'Flow2=',Flow2,'Flowv=',Flowv
        write(6,*)' '
        write(6,*)('Internal Energy Distribution')
        write(6,*)' '
        Write(6,*)(uold(i), i=1,26)
        write(6,*)' '
        write(6,*)('Temperature Distribution')
        write(6,*)' '
        Write(6,*)(Told(i), i=1,26)
        write(6,*)' '
        endif
	Open(unit=7,file = 'System.dat')

c
c.    Fluid Properties
c.
      rhol=density(Tmod)
      grav=32.17*3600.**2
      gc=32.17*3600.**2
c.
      TorqueR=QR*density(Told(nodePp1))*HeadR/(2.*pi*omegaR*60.)
      omega1=omegaR
      omega2=omegaR

        if(ITYPEUpset.eq.213)then
        omega1=omega1*(1.+UPSETPARM(1)/100.)
        omega2=omega2*(1.+UPSETPARM(1)/100.)
        endif

c.    Pump loss Coefficients
c.
      Fp1plus=0.
      Fp1minus=1000.
      Fp2plus=0.
      Fp2minus=1000.
c.    Heat Transfer Areas and Volumes
c.
      Do 5 i=1,26
      Aheated(i)=Pheated(i)*Length(i)
 5    Continue
c.
      do i=1,4
      As(i)=Pi*Dpellet*Length(i)*float(nrods)
      enddo
c.
c.    Begin Time Advancement Loop                  ***********************************
c	    
	Deltat=0.3/3600.
c      time=0.
c.
      Flux=QrxNom*psiX/(SigmaF*Vfuel)
      NIref=GammaI*SigmaF*Flux/lamdaI
      NXref=(lamdaI*NIref+GammaX*SigmaF*Flux)/(lamdaX+sigmaX*Flux)
      alphaXe=EquilibriumXenonWorth/NXref
c.
c.*************************************************************************
c.
        if(InitMode.eq.1)then
          do j=1,6
          Precursor(j)=beta06(j)*Qrx/(lamda06(j)*Prompt)
          enddo
c.
        Call Decay_Heat(0.,Qrx/0.93,DecayHeat)
        Qth=Qrx+DecayHeat
c.    
      Flux=Qrx*psiX/(SigmaF*Vfuel)
      NI=GammaI*SigmaF*Flux/lamdaI
      NX=(lamdaI*NI+GammaX*SigmaF*Flux)/(lamdaX+sigmaX*Flux)
c.
        endif
c.
c.*************************************************************************
c.
      DeltaRhoFuel=alphaTrx*(Trx-Trxref)									
      DeltaRhoMod=alphamod*(Tmod-Tref)									
      DeltaRhoB=alphaBoron*(Cb-Cref)
c.										
       RhoCBA=ControlBankWorth(1,BANKPOSITION(1))
       RhoCBB=ControlBankWorth(2,BANKPOSITION(2))
       RhoCBC=ControlBankWorth(3,BANKPOSITION(3))
       RhoCBD=ControlBankWorth(4,BANKPOSITION(4))
       RhoCR=RhoCBA+RhoCBB+RhoCBC+RhoCBD
c.
      rhoX=alphaXe*(NX-NXref)
      Rho=Rho0+Rhocr+DeltaRhoFuel+DeltaRhoMod+DeltaRhoB+rhoX					
c.
c.    Output Initial Conditions
c.
      write(7,1000)
	Write(7,1001)time,Qrx,Qth,Qtrans/Kappa,flowv,
     %             Pp,Px,PxIND,PRZLVL*100./HHEAD,PRZLVLIND*100./HHEAD,
     %             VelPx(3)/3600.,
     %             QHTRP/3412.14,QHTRB/3412.14,SCVPosition,SprayGPM,
     %             Told(NodeHL),THLIND,Told(NodeCL),TCLIND,TaveREF,
     %             Tave,TaveIND,Tmod,FlowSFWS,FlowSG,FlowFDIND,
     %             FlowDEMAND,FlowSteam,FlowSteamIND,Wload,Wturb,				  
     %             OmegaFP,TSG(10,8),TSGEXITIND,aj_kk(60),
     %             CriticalLength1*100./LengthSG,SGLVL,					  
     %             Trx,TfuelHOT(1),MDNBR,Tfeed,TfeedIND,Qsteam,      
     %             psg,PSGIND,Pimpulse,DeltaPHSG1/144.,DeltaPSGIND,
     %             DeltaPEHSG1/144.,
     %			 deltaT*3600.,rho,rhoX,
     %             FCV,FBV,SFWVPosition,
     %  TCVposition(1), TCVposition(2), TCVposition(3), TCVposition(4),
     %  TBVposition(1), TBVposition(2), TBVposition(3), TBVposition(4),
     %  BANKPOSITION(1),BANKPOSITION(2),BANKPOSITION(3),BANKPOSITION(4),
     %  RhoCBA,RhoCBB,RhoCBC,RhoCBD,TESLoad,TESFlowDemand,FlowAUX1,
     %  FlowAUX2,FlowAUX3,PTAP,Tsat(PTAP),PTES,											 !Konor
     %  TES_TBV(1),TES_TBV(2),TES_TBV(3),TES_TBV(4)										 !Konor
c.
      ITRIPRX=0
      Open(unit=10,file='TripLog')
c.
      Tmax=Tmax+time
      Do while (time.lt.Tmax)
c.      if(qrx.gt.70)then
c	mode(6)=0+1
c	mode(1)=0+1
c.	mode(2)=1+0
c.	endif
c.	if(qrx.gt.150)then
c	manual close TBV
c.	mode(7)=0+1
c.	mode(3)=1+0
c.	mode(4)=0+1
c.      endif
c      if(qrx.gt.199)then
c	ModeRODS=1
c      G1Feed(1)=1.
c      G2Feed(1)=0.
c	endif
c	if(qrx.gt.100)then
c	if(qrx.gt.200)then
c.**********************************************
      Prelative=100.*Wturb/RefLoad
        if(Prelative.gt.0.)then
        Tfeed=Tfeed0*(afeed+bfeed*Prelative+cfeed*Prelative**2)
          if(ITYPEUpset.eq.211)then
          Tfeed=Tfeed*(1.-UPSETPARM(1)/100.)
          endif
        else
        Tfeed=100.
	  endif
c.
      SensorID=9
      Call SensorResponse(SensorID,Deltat,Tfeed,TfeedIND)
c.
c.*************************************************
c.
c.    Check for Reactor Trip
c.
c.      High Neutron Flux Trip
c.
      if(ITRIPMode(1).eq.1)then
       if(Qrx.gt.QrxNOM*RxTRIPS(1)/100.)then
       ITRIPRX=1
       ITRIPFP=1
       ISTARTSFWS=1
       ITRIPMode(4)=0
         if(ICALLTRIP(1).eq.0)then
         ICALLTRIP(1)=1
         write(10,*)'High Neutron Flux Signal at',time,' seconds'
         endif
       endif
      endif
c.
c.    Low RCS Flow Trip
c.
      if(ITRIPMode(2).eq.1)then
       if(Flowv.lt.FlowVNOM*RxTRIPS(2)/100.)then
       ITRIPRX=1
       ITRIPFP=1
       ISTARTSFWS=1
       ITRIPMode(4)=0
         if(ICALLTRIP(2).eq.0)then
         ICALLTRIP(2)=1
         write(10,*)'Low RCS Flow Signal at',time,' seconds'
         endif
       endif
      endif
c.
c.    High Pressurizer Pressure Trip
c.
      if(ITRIPMode(3).eq.1)then
       if(Px.gt.RxTRIPS(3))then
       ITRIPRX=1
       ITRIPFP=1
       ISTARTSFWS=1
       ITRIPMode(4)=0
        if(ICALLTRIP(3).eq.0)then
        ICALLTRIP(3)=1
        write(10,*)'High Pressurizer Pressure Signal at',time,' seconds'
        endif
       endif
      endif
c.
c.    High Feedwater Flow Trip
c.
      if(ITRIPMode(4).eq.1)then
       if(FlowSG.gt.FlowDEMAND*RxTRIPS(4)/100.)then
       ITRIPRX=1
       ITRIPFP=1
       ISTARTSFWS=1
         if(ICALLTRIP(4).eq.0)then
         ICALLTRIP(4)=1
         write(10,*)'High Feedwater Flow Signal at',time,' seconds'
         endif
       endif
      endif
c.
c.    Low Feedwater Flow Trip
c.
      if(ITRIPMode(5).eq.1)then
       if(FlowSG.le.FlowDEMAND*RxTRIPS(5)/100.)then
       ITRIPRX=1
       ITRIPFP=1
       ISTARTSFWS=1
       ITRIPMode(4)=0
         if(ICALLTRIP(5).eq.0)then
         ICALLTRIP(5)=1
         write(10,*)'Low Feedwater Flow Signal at',time,' seconds'
         endif
       endif
      endif
c.
c.    Low Pressurizer Pressure Trip
c.
      if(ITRIPMode(6).eq.1)then
       If(Px.lt.RxTRIPS(6))then
       ITRIPRX=1
       ITRIPFP=1
       ISTARTSFWS=1
       ITRIPMode(4)=0
         if(ICALLTRIP(6).eq.0)then
         ICALLTRIP(6)=1
         write(10,*)'Low Pressurizer Pressure Signal at',time,' seconds'
         endif
       endif
      endif 
c.
c.    High Pressurizer Level Trip
c.
      if(ITRIPMode(7).eq.1)then
       if(PRZLVLIND*100./HHEAD.gt.RxTRIPS(7))then
       ITRIPRX=1
       ITRIPFP=1
       ISTARTSFWS=1
       ITRIPMode(4)=0
         if(ICALLTRIP(7).eq.0)then
         ICALLTRIP(7)=1
         write(10,*)'High Pressurizer Level Signal at',time,' seconds'
         endif
       endif
      endif
c.
c.    Low Steam Temperature Trip
c.
      if(ITRIPMode(8).eq.1)then
       if(TSGEXITIND.lt.RxTRIPS(8))then
       ITRIPRX=1
       ITRIPFP=1
       ISTARTSFWS=1
       ITRIPMode(4)=0
         if(ICALLTRIP(8).eq.0)then
         ICALLTRIP(8)=1
         write(10,*)'Low Steam Temperature Signal at',time,' seconds'
         endif
       endif
      endif
c.
      if(ITRIPRX.eq.1)then
      TripClock=TripClock+Deltat*3600.
      endif
c.
c.*************************************************
c.
c.    Buoyancy term for the Reactor Vessel
c.
      buoyv=0.
      Do 15 kk=1,6
      index=nvessel(kk)
      buoyv=buoyv+density(Told(index))*(grav/gc)*DeltaH(index)
 15   Continue
c.
c.    Buoyancy term for Loop 1
c.
      buoy1=0.
      Do 20 kk=1,10
      index=nloop1(kk)
      buoy1=buoy1+density(Told(index))*(grav/gc)*DeltaH(index)
 20   Continue
c.
c.    Buoyancy term for Loop 2
c.
      buoy2=0.
      Do 25 kk=1,10
      index=nloop2(kk)
      buoy2=buoy2+density(Told(index))*(grav/gc)*DeltaH(index)
 25   Continue
c.
c.    Friction Losses and Inertial Terms For The Reactor Core
c.
      inertiac=0.
      frictionc=0.
      formsc=0.
      Do i=1,4
	L=Length(i)
      Ax=Area(i)
      De=Equiv_Diam(i)
      rhol=density(Told(i))
      Cp=Cpl(Told(i),Pp)
      k=kl(Told(i),Pp)
      mu=Viscosity(Told(i),Pp)
	inertiac=inertiac+L/Ax
	  G=Flowv/Ax
        ffactor=F(G,De)
	  frictionc=frictionc+ffactor*(L/De)*(1./Ax**2)
	  formsc=formsc+lloss(i)*(1./Ax**2)
      enddo      
c.
c.    Friction Losses and Inertial Terms For The Lower Plenum
c.
      inertiav=inertiac
      frictionv=frictionc
      formsv=formsc
c.
      L=Length(16)
      Ax=Area(16)
      De=Equiv_Diam(16)
      rhol=density(Told(16))
      Cp=Cpl(Told(16),Pp)
      k=kl(Told(16),Pp)
      mu=Viscosity(Told(16),Pp)
	inertiav=inertiav+L/Ax
	  G=Flowv/Ax
        ffactor=F(G,De)
	  frictionv=frictionv+ffactor*(L/De)*(1./Ax**2)
	  formsv=formsv+lloss(16)*(1./Ax**2)
c.
c.    Friction Losses and Inertial Terms For The Upper Plenum
c.
      L=Length(5)
      Ax=Area(5)
      De=Equiv_Diam(5)
      rhol=density(Told(5))
      Cp=Cpl(Told(5),Pp)
      k=kl(Told(5),Pp)
      mu=Viscosity(Told(5),Pp)
	inertiav=inertiav+L/Ax
	  G=Flowv/Ax
        ffactor=F(G,De)
	  frictionv=frictionv+ffactor*(L/De)*(1./Ax**2)
	  formsv=formsv+lloss(5)*(1./Ax**2)
c.
c.    Friction Losses and Inertial Terms For Steam Generator 1
c.
      inertia1=0.
      frictionSG1=0.
      formsSG1=0.
      Do i=1,7
      index=nloop1(i)
      L=Length(index)
      Ax=Area(index)
      De=Equiv_Diam(index)
      rhol=density(Told(index))
      Cp=Cpl(Told(index),Pp)
      k=kl(Told(index),Pp)
      mu=Viscosity(Told(index),Pp)
	inertia1=inertia1+L/Ax
	  G=Flow1/Ax
        ffactor=F(G,De)
	  frictionSG1=frictionSG1+ffactor*(L/De)*(1./Ax**2)
	  formsSG1=formsSG1+lloss(index)*(1./Ax**2)
      enddo
c.
c.    Friction Losses and Inertial Terms For Loop 1
c.
      friction1=frictionSG1
      forms1=formsSG1
      lloss(14)=0.5*(Fp1plus+Fp1minus)+
     %          0.5*abs(Flow1)/Flow1*(Fp1plus-Fp1minus)
      Do 40 i=8,10
      index=nloop1(i)
      L=Length(index)
      Ax=Area(index)
      De=Equiv_Diam(index)
      rhol=density(Told(index))
      Cp=Cpl(Told(index),Pp)
      k=kl(Told(index),Pp)
      mu=Viscosity(Told(index),Pp)
	inertia1=inertia1+L/Ax
	  G=Flow1/Ax
        ffactor=F(G,De)
	  friction1=friction1+ffactor*(L/De)*(1./Ax**2)
	  forms1=forms1+lloss(index)*(1./Ax**2)
 40   Continue
c.
c.    Friction Losses and Inertial Terms For Steam Generator 2
c.
      inertia2=0.
      frictionSG2=0.
      formsSG2=0.
      Do i=1,7
      index=nloop2(i)
      L=Length(index)
      Ax=Area(index)
      De=Equiv_Diam(index)
      rhol=density(Told(index))
      Cp=Cpl(Told(index),Pp)
      k=kl(Told(index),Pp)
      mu=Viscosity(Told(index),Pp)
	inertia2=inertia2+L/Ax
	  G=Flow2/Ax
        ffactor=F(G,De)
	  frictionSG2=frictionSG2+ffactor*(L/De)*(1./Ax**2)
	  formsSG2=formsSG2+lloss(index)*(1./Ax**2)
      enddo
c.
c.    Friction Losses and Inertial Terms For Loop 2
c.
      friction2=frictionSG2
      forms2=formsSG2
      lloss(18)=0.5*(Fp2plus+Fp2minus)+
     %          0.5*abs(Flow2)/Flow2*(Fp2plus-Fp2minus)
      Do 50 i=8,10
      index=nloop2(i)
      L=Length(index)
      Ax=Area(index)
      De=Equiv_Diam(index)
      rhol=density(Told(index))
      Cp=Cpl(Told(index),Pp)
      k=kl(Told(index),Pp)
      mu=Viscosity(Told(index),Pp)
	inertia2=inertia2+L/Ax
        G=Flow2/Ax
        ffactor=F(G,De)
	  friction2=friction2+ffactor*(L/De)*(1/Ax**2)
	  forms2=forms2+lloss(index)*(1/Ax**2)
 50   Continue
c.
c.    Coefficients for Time Advancement of Flow Rate
c.
      a1=(1./gc)*inertia1*(1./Deltat)+2.*(friction1+forms1)*
     %	 abs(Flow1)/(2.*rhol*gc)
c.
      b1=(Flow1/gc)*inertia1*(1./Deltat)+(friction1+forms1)*
     %   Flow1*abs(Flow1)/(2.*rhol*gc)-buoy1+
     %   DeltaPp1(Flow1/PumpDegradation,Deltat,rhol)
c.
c.
      a2=(1./gc)*inertia2*(1./Deltat)+2.*(friction2+forms2)*
     %	 abs(Flow2)/(2.*rhol*gc)
c.
      b2=(Flow2/gc)*inertia2*(1./Deltat)+(friction2+forms2)*
     %   Flow2*abs(Flow2)/(2.*rhol*gc)-buoy2+
     %   DeltaPp2(Flow2/PumpDegradation,Deltat,rhol)
c.
c.
      ac=(1./gc)*inertiav*(1./Deltat)+2.*(frictionv+formsv)*
     %	 abs(Flowv)/(2.*rhol*gc)
c.
      bc=(Flowv/gc)*inertiav*(1./Deltat)+(frictionv+formsv)*
     %   Flowv*abs(Flowv)/(2.*rhol*gc)-buoyv
c.
c.
c.    Advance Mass Flow Rates
c.
      Denom=a1*a2+a1*ac+a2*ac
c.
      Flow1=(b1*a2+b1*ac-ac*b2+a2*bc)/Denom
      Flow2=(-b1*ac+b2*a1+ac*b2+a1*bc)/Denom
      Flowv=Flow1+Flow2
c.
c.    Vessel Pressure Drop
c.
      DeltaPv=b1/a1+b2/a2-bc/ac
      DeltaPv=DeltaPv/(1./a1+1./a2+1./ac)/144.
c.
c.    Core Pressure Drop
c.
	DeltaPcore=(frictionc+formsc)*Flowv**2/(2.*rhol*gc)/144.
c.
c.    Steam Generator Pressure Drops
c.
      DeltaPSG1=(frictionSG1+formsSG1)*Flow1**2/(2.*rhol*gc)/144.
      DeltaPSG2=(frictionSG2+formsSG2)*Flow2**2/(2.*rhol*gc)/144.
c.******************************************************************
c.
c.    Compute Overall Heat Transfer Coefficients for the Core
c.
      do kk=1,6
      index=nvessel(kk)
      G=abs(Flowv/Area(index))
      De=Equiv_Diam(index)
        if(Aheated(index).gt.0.)then
        hcrx=hcW(G,De,P_D)
!        write(*,*)'G=',G,'De=',De,'P_D=',P_D
!        write(*,*)'hcrx=',hcrx
        UA(index)=hcrx*Aheated(index)
        else
        UA(index)=0.
        endif
      enddo
c.
c.    Compute Overall Heat Transfer coefficients for the steam generators
c.          Loop 1
c
          ICRIT=0
	    Do j=15,6,-1
          nodes=nodesSG(j)
            if(nodes.gt.0)then
			Do i=1,nodes
   			ii1=i+(13-j)*10

              Call UASG(Flow1,FlowSG,Area(j),DeltazSG,Told(j),Pp,
     %                  TSG(i,j),PSG,hSG(i,j),ntubes,UAM(i,j)
     %					,aj_kk(ii1),ii1)  
		      
              enddo
            endif
          enddo
c.
	iminus=0
      do j=19,24
	iminus=iminus+2
		Do i=1,10
		UAM(i,j)=UAM(i,j-iminus-4)
		enddo
	enddo
c	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c
c.    Advance Internal Energy Distribution 
c.    Reactor Vessel
c.
      Do 59 i=1,26
      Do 59 j=1,26
 59   AA(i,j)=0.
c.
      Qtrans=0.
      Do 60 kk=1,4
c.
      qin(kk)=Qth*Kappa*(1.-Gammaf)*GenFraction(kk)
c.
      rhol=density(Told(kk))
      Constant1=abs(Flowv)+V(kk)*rhol/Deltat
      AA(kk,kk)=Constant1
      AA(kk,ioutlet(kk))=(Flowv-abs(Flowv))/2.
      AA(kk,iinlet(kk))=-(Flowv+abs(Flowv))/2.
      SS(kk)=V(kk)*rhol*uold(kk)/Deltat+qin(kk)
     %       +UA(kk)*(Tclad-Tmod)
      Qtrans=Qtrans+UA(kk)*(Tclad-Tmod)
c.
 60   Continue
c.
c.    Upper Plenum
c.
      rhol=density(Told(5))
      AA(5,4)=-(Flowv+abs(Flowv))/2.
      AA(5,5)=V(5)*rhol/Deltat+
     %        (abs(Flow1)+abs(Flow2)+abs(Flowv))/2.
      AA(5,6)=(Flow1-abs(Flow1))/2.
      AA(5,26)=(Flow2-abs(Flow2))/2.
      SS(5)=V(5)*rhol*uold(5)/Deltat
c.
c.    Lower Plenum
c.
      rhol=density(Told(16))
      AA(16,1)=(Flowv-abs(Flowv))/2.
      AA(16,15)=-(Flow1+abs(Flow1))/2.
      AA(16,16)=V(16)*rhol/Deltat+
     %          (abs(Flow1)+abs(Flow2)+abs(Flowv))/2.
      AA(16,17)=-(Flow2+abs(Flow2))/2.
      SS(16)=V(16)*rhol*uold(16)/Deltat
c.
c.    Loop 1
c.
      Do 70 kk=6,15
        UA(kk)=0.
        UADeltaT=0.
        nodes=nodesSG(kk)
          if(nodes.gt.0)then
            do i=1,nodes
            UA(kk)=UA(kk)+UAM(i,kk)*float(nSGs1)
            UADeltaT=UADeltaT+
     %               UAM(i,kk)*(Told(kk)-TSG(i,kk))*float(nSGs1)
            enddo
          endif
      rhol=density(Told(kk))
      Constant1=abs(Flow1)+V(kk)*rhol/Deltat
      AA(kk,kk)=Constant1+UA(kk)*dTdu(uold(kk))
      AA(kk,ioutlet(kk))=(Flow1-abs(Flow1))/2.
      AA(kk,iinlet(kk))=-(Flow1+abs(Flow1))/2.
      SS(kk)=V(kk)*rhol*uold(kk)/Deltat+qin(kk)-UADeltaT+
     %       UA(kk)*dTdu(uold(kk))*uold(kk)
 70   Continue
c.
c.    Loop 2
c.
      Do 80 kk=17,26
        UA(kk)=0.
        UADeltaT=0.
        nodes=nodesSG(kk)
          if(nodes.gt.0)then
            do i=1,nodes
            UA(kk)=UA(kk)+UAM(i,kk)*float(nSGs2)
            UADeltaT=UADeltaT+
     %               UAM(i,kk)*(Told(kk)-TSG(i,kk))*float(nSGs2)
            enddo
          endif
      rhol=density(Told(kk))
      Constant1=abs(Flow2)+V(kk)*rhol/Deltat									 
      AA(kk,kk)=Constant1+UA(kk)*dTdu(uold(kk))
      AA(kk,ioutlet(kk))=(Flow2-abs(Flow2))/2.
      AA(kk,iinlet(kk))=-(Flow2+abs(Flow2))/2.
      SS(kk)=V(kk)*rhol*uold(kk)/Deltat+qin(kk)-UADeltaT+
     %       UA(kk)*dTdu(uold(kk))*uold(kk)
 80   Continue
c.****************************************************************
c.
c.    Pump Heat
c.
      rhol=density(Told(nodePp1))
      SS(nodePp1)=SS(nodePp1)+
     %            Flow1*DeltaPp1(Flow1/PumpDegradation,Deltat,rhol)/
     %            (778.*rhol)
!      write(*,*)'Flow1=',Flow1
!      write(*,*)'DeltaP=',DeltaPp1(Flow1,Deltat,rhol)
!      write(*,*)'Pump Q =',Flow1*DeltaPp1(Flow1,Deltat,rhol)/(778.*rhol)
c.
      rhol=density(Told(nodePp2))
      SS(nodePp2)=SS(nodePp2)+
     %            Flow2*DeltaPp2(Flow2/PumpDegradation,Deltat,rhol)/
     %            (778.*rhol)
c.
c.****************************************************************
c.
      Call Gauss(AA,SS,unew,26)
c.
c.    Advance Pressurizer Pressure
c.
      do j=1,26
      ulp(j)=unew(j)
      ulp0(j)=uold(j)
      rholp(j)=rhop(ulp(j),Pp)
      rholulp(j)=rholp(j)*ulp(j)
      enddo
c.
      Tspray=Told(NodeCL)
      uSPRAY=uliq(Tspray)
      rhoSPRAY=rhop(uSPRAY,Pp)
      rhouSPRAY=rhoSPRAY*uSPRAY
      Call Pressurizer(PRZLVL,Px)
c.
      Nvalve=6
      Call SprayControlValvePosition(SCVposition,1,Px,Deltat)
      Call Valve(SCVposition,Nvalve,KSCV)
c.
      Call PressurizerSpray
      SprayGPM=Vspray*AxSPRAY/(0.1556*60.)
c.
      SensorID=6
      Call SensorResponse(SensorID,Deltat,Px,PXIND)
c.
      SensorID=7
      Call SensorResponse(SensorID,Deltat,PRZLVL,PRZLVLIND)
c.
c.    Update Temperatures
c.
      SumU=0.
      Do 90 i=1,26
      SumU=SumU+((unew(i)-uold(i))/uold(i))**2
      uold(i)=unew(i)
      Tnew(i)=Temp(unew(i))
      Told(i)=Tnew(i)
 90   Continue
      SumU=sqrt(SumU)

c	if(time.gt.2126.14)then
c	write(*,*)''
c	endif

c.
      Tave=(Told(NodeHL)+Told(NodeCL))/2.
c.
      SensorID=1
      Call SensorResponse(SensorID,Deltat,Told(NodeHL),THLIND)
c.
      SensorID=2
      Call SensorResponse(SensorID,Deltat,Told(NodeCL),TCLIND)
c.
      TaveIND=(THLIND+TCLIND)/2.
      TmodNEW=(Told(4)+Told(16))/2.
********************************************************************
c.
c.    Compute Rod Worth
c.
      if((ITRIPRX.eq.0).or.(TripClock.lt.TripDelay))then    
       If(ModeRODS.eq.1)then
c       Call Rods(TaveIND,Wturb,Qth,Deltat,RodDepth,Rhocr)
c.
       Call ControlRodSpeed(TaveIND,Wturb,Qth,RodSpeed,IWITHDRAW)
       Call ControlBankPositions(RodSpeed,Deltat,IWITHDRAW,BANKPOSITION)
       RhoCBA=ControlBankWorth(1,BANKPOSITION(1))
       RhoCBB=ControlBankWorth(2,BANKPOSITION(2))
       RhoCBC=ControlBankWorth(3,BANKPOSITION(3))
       RhoCBD=ControlBankWorth(4,BANKPOSITION(4))
       RhoCR=RhoCBA+RhoCBB+RhoCBC+RhoCBD
c.
	 else If(ModeRODS.eq.2)then
       Call RodsLP(TaveIND,TAVE0,Qrx,time,Deltat,RodDepth,Rhocr)
       endif
c.
      else
      Rho0=0.
      Rhocr=CummWorth+ShutDownWorth
      BANKPOSITION(1)=0.
      BANKPOSITION(2)=0.
      BANKPOSITION(3)=0.
      BankPOSITION(4)=0.
      RhoCBA=ControlBankWorth(1,BANKPOSITION(1))
      RhoCBB=ControlBankWorth(2,BANKPOSITION(2))
      RhoCBC=ControlBankWorth(3,BANKPOSITION(3))
      RhoCBD=ControlBankWorth(4,BANKPOSITION(4))
      endif
c.
c.    Advance Reactor Power
c.
      Call Xenon(Qrx,Deltat,NX,NI,rhoX)
      Call Kinetics06(Qrxnew,Qrx,QrxRate,Trx,TmodNEW,Cb,Deltat)
      Call Decay_Heat(Deltat,Qrxnew,DecayHeat)
c.
      Qthnew=Qrxnew+DecayHeat
c
        if((ITRIPRX.eq.0).or.(TripClock.lt.TripDelay))then
        Tstart=Time-StartTime										  
          if(Tstart.ge.0.)then                                      
          Wload=Load(Tstart)                                        
          endif													  
        else
        ITRIPTurbine=1
        Wload=0.
        Mode(9)=1
        Mode(6)=0
        Mode(2)=1
        endif
c.
c.*******************************************************
c.
      if(ModeTES.eq.0)then
      TESLoad=0.
      TESFlowDemand=0.
      FlowAUX1=0.
      FlowAUX2=0.
	FlowAUX3=0.
      else
c.
      TESLoad=RefLoad-Wload
        if(TESLoad.lt.0.)TESLoad=0.
      Call TESDemand(Qth,RefRxPwr,TESFlowDemand,Deltat)
c.
        if(ModeTES.eq.1)then
        Call TESByPassControlValvePosition(TES_TBVnew,TES_TBV,
     %                                     FlowAUX1,TESFlowDemand,
     %                                     Deltat)
c.
        Nvalve=7
          do j=1,4
          Call Valve(TES_TBVnew(j),Nvalve,KTESTBV(j))
          enddo
c.***********************************************************************
c.
        PIHX=750.
c.
            if(TES_TBVnew(1).gt.0.)then
            TotalK=KTAP+KTESTBV(1)
            GAUX1(1)=2.*density_kk(60)*gc*(p_hdr-PIHX)*144./TotalK
            GAUX1(1)=sqrt(GAUX1(1))
            else
            GAUX1(1)=0.
            endif
c.
            if(TES_TBVnew(2).gt.0.)then
            TotalK=KTAP+KTESTBV(2)
            GAUX1(2)=2.*density_kk(60)*gc*(p_hdr-PIHX)*144./TotalK      !Konor's stuff goes in here
            GAUX1(2)=sqrt(GAUX1(2))
            else
            GAUX1(2)=0.
            endif
c.
            if(TES_TBVnew(3).gt.0.)then
            TotalK=KTAP+KTESTBV(3)
            GAUX1(3)=2.*density_kk(60)*gc*(p_hdr-PIHX)*144./TotalK
            GAUX1(3)=sqrt(GAUX1(3))
            else
            GAUX1(3)=0.
            endif
c.
c.
            if(TES_TBVnew(4).gt.0.)then
            TotalK=KTAP+KTESTBV(4)
            GAUX1(4)=2.*density_kk(60)*gc*(p_hdr-PIHX)*144./TotalK
            GAUX1(4)=sqrt(GAUX1(4))
            else
            GAUX1(4)=0.
            endif
c.
        FlowAUX1=(GAUX1(1)+GAUX1(2)+GAUX1(3)+GAUX1(4))*Avalve(7)
c.
c.******************************************************************************
        endif
c.
        if(ModeTES.eq.2)then
        Call TESByPassControlValvePosition(TES_TBVnew,TES_TBV,
     %                                     FlowAUX2*float(nTCV),
     %                                     TESFlowDemand,Deltat)

        FlowAUX2=TES_TBVnew(1)*TESFlowDemand0/float(nTCV)
        endif
c.
c.******************************************************************************	 !Konor
c.       																			 !Konor
        if(ModeTES.eq.3)then														 !Konor
          if(TESLevel.gt.TESSetPoint(3))then										 !Konor
          ICLOSETBV=1																 !Konor
          endif																	 !Konor
            if(TESLevel.lt.TESSetPoint(2))then									 !Konor
            LockTBV=0																 !Konor
            ICLOSETBV=0															 !Konor
            endif																	 !Konor
        Call TESByPassControlValvePosition(TES_TBVnew,TES_TBV,					 !Konor
     %                                     FlowAUX3,TESFlowDemand,				 !Konor
     %                                     Deltat)								 !Konor
c.																				 !Konor
        Nvalve=7																	 !Konor
        Call Valve(TES_TBVnew(1),Nvalve,KTESTBV(1))								 !Konor
          if(TES_TBVnew(1).gt.0.)then												 !Konor
          TotalK=KTAP+KTESTBV(1)													 !Konor
          GAUX3=2.*rhoTAP*gc*(PTAP-Pcond)*144./TotalK								 !Konor
          GAUX3=sqrt(GAUX3)														 !Konor
          PTES=PTAP-(KTESTBV(1)/TotalK)*(PTAP-Pcond)								 !Konor
          else																	 !Konor
          GAUX3=0.																 !Konor
          PTES=Pcond																 !Konor
          endif																	 !Konor
        FlowAUX3=GAUX3*Avalve(7)													 !Konor
c.																				 !Konor
        endif																		 !Konor
      endif																		 !Konor
c.																				 !Konor
      do n=1,nTESByPass
      TES_TBV(n)=TES_TBVnew(n)
      enddo

c.
c.*******************************************************
      Call FeedDemand(Wload,Wturb,FlowDEMAND,Deltat)                    	 
      Call FeedFlow(PSG,SGLVL,FlowDEMAND,FlowSG,FlowFDIND,
     %              Deltat)
        if(ISTARTSFWS.eq.1)then
        Call SFWS(PSG,SGLVL,FlowSFWS,SFWVPosition,Deltat)
        FlowSG=FlowSG+FlowSFWS
        endif
c.
      SensorID=4
      Call SensorResponse(SensorID,Deltat,FlowSG,FlowFDIND)
c.
c.    Advance Reactor Fuel Temperature
c.
      Call PeakPin(Qthnew,Qth,TmodNEW,Tmod,Pp,Pp,Deltat,hcrx,0.,
     %             TfuelAVE,TrxBAR,TcladBAR,0)
c.
      Qrx=Qrxnew
      Qth=Qthnew
      Tmod=TmodNEW
      Trx=TrxBAR
      Tclad=TcladBAR
c.
c.    Compute Critical Heat Flux Ratio and Peak Pin Temperature
c.
      uin=uold(16)
      Call HotChannel(TfuelHot,uin,uHOT,Flowv,Qtrans,
     %                Qth,Deltat,Pp,MDNBR)
c.
c.
c.    Advance Steam Generators
c.
      call SG(Tnew,FlowSG,PSG,PSGIND,UAM,Deltat,DeltazSG,DeltaH,
     %        DeltaPFHSG1,DeltaPEHSG1,DeltaPHSG1,
     %        DeltaPFHSG2,DeltaPEHSG2,DeltaPHSG2,nodesSG,
     %		ntubes,Qsteam,time,tmax,Pimpulse,p_hdr,k_turb)
c.
      SGLVL=DeltaPHSG1/rhof(PSG)
      SensorID=3
      Call SensorResponse(SensorID,Deltat,PSG,PSGIND)
c.
      SensorID=8
      Call SensorResponse(SensorID,Deltat,TSG(10,8),TSGEXITIND)
c.
      SensorID=10
      Call SensorResponse(SensorID,Deltat,DeltaPHSG1/144.,DeltaPSGIND)
c.
c.    Output Flow and Temperature
c
      FlowSteam=density_kk(60)*velocity_kk(60)*AxSG
      FlowSteam=FlowSteam*3600.
c.
      SensorID=5
      Call SensorResponse(SensorID,Deltat,FlowSteam,FlowSteamIND)
c.																	!Mod05
c.    Compute Turbine Output											!Mod05
c.																	!Mod05
      FlowTurbine=FlowSteam*float(nSG)							    !Mod05
c.*********************************************
c.
      FlowTurbine=FlowTurbine-FlowAUX1-FlowAUX2*float(nTCV)           !TES Mod
c.
c.*********************************************
      hsteam=(ie_kk(60)+(144./778.)*PSG)/density_kk(60)			    !Mod05
c.
        if(ITRIPTurbine.eq.0)then
c        call Turbine(hsteam,FlowTurbine,Phdr,Pcond,TurbineEFF,Wturb)
        call TurbineMod01(hsteam,FlowTurbine,Pimpulse,Pcond,TurbineEFF,
     %                    Wturb)
        else
        Wturb=0.
        endif               
c.  
	if(int(time).ge.iwrite) then       
	Write(7,1001)time,Qrx,Qth,Qtrans/Kappa,flowv,
     %             Pp,Px,PxIND,PRZLVL*100./HHEAD,PRZLVLIND*100./HHEAD,
     %             VelPx(3)/3600.,
     %             QHTRP/3412.14,QHTRB/3412.14,SCVPosition,SprayGPM,
     %             Told(NodeHL),THLIND,Told(NodeCL),TCLIND,TaveREF,
     %             Tave,TaveIND,Tmod,FlowSFWS,FlowSG,FlowFDIND,
     %             FlowDEMAND,FlowSteam,FlowSteamIND,Wload,Wturb,			    
     %             OmegaFP,TSG(10,8),TSGEXITIND,aj_kk(60),
     %             CriticalLength1*100./LengthSG,SGLVL,				
     %             Trx,TfuelHOT(1),MDNBR,Tfeed,TfeedIND,Qsteam,      
     %             psg,PSGIND,Pimpulse,DeltaPHSG1/144.,DeltaPSGIND,
     %             DeltaPEHSG1/144.,
     %			 deltaT*3600.,rho,rhoX,
     %             FCV,FBV,SFWVPosition,
     %  TCVposition(1), TCVposition(2), TCVposition(3), TCVposition(4),
     %  TBVposition(1), TBVposition(2), TBVposition(3), TBVposition(4),
     %  BANKPOSITION(1),BANKPOSITION(2),BANKPOSITION(3),BANKPOSITION(4),
     %  RhoCBA,RhoCBB,RhoCBC,RhoCBD,TESLoad,TESFlowDemand,FlowAUX1,
     %  FlowAUX2,FlowAUX3,PTAP,Tsat(PTAP),PTES,								 !Konor
     %  TES_TBV(1),TES_TBV(2),TES_TBV(3),TES_TBV(4)							 !Konor
c      write(*,*)aj_kk(57),aj_kk(58),aj_kk(59),aj_kk(60)
	iwrite=iwrite+WriteInterval
	endif
c
c
	if(int(time).gt.iwrite0) then 
      open(unit=12,file='Restart.dat')
      write(12,*)Time
      write(12,*)Qrx,Qth,Qtrans,Trx,Tclad
      write(12,*)NI,NX
      write(12,*)(Precursor(j),j=1,6)
      write(12,*)(gammaDH(j),j=1,11)
      write(12,*)Flowv,Flow1,Flow2
	write(12,*)(Told(i),i=1,26)
      write(12,*)THLIND,TCLIND
      write(12,*)Pp,Px
      write(12,*)VOL(1),VOL(2),VOL(3),VOL(4),Ax5,PRZLVL
      write(12,*)alphagPx(1),alphagPx(2),alphagPx(3),alphagPx(4)
      write(12,*)rholPx(1),rholPx(2),rholPx(3),rholPx(4)
      write(12,*)ulPx(1),ulPx(2),ulPx(3),ulPx(4)
      write(12,*)rhogPx(1),rhogPx(2),rhogPx(3),rhogPx(4)
      write(12,*)ugPx(1),ugPx(2),ugPx(3),ugPx(4)
      write(12,*)rhoPx(1),rhoPx(2),rhoPx(3),rhoPx(4)
      write(12,*)rhouPx(1),rhouPx(2),rhouPx(3),rhouPx(4)
      write(12,*)VelPx(1),VelPx(2),VelPx(3),VelPx(4),VelPx(5)
      write(12,*)VSRVPx(1),VSRVPx(2),VSRVPx(3),VSRVPx(4)
      write(12,*)PRZMass(1),PRZMass(2),PRZMass(3),PRZMass(4)
      write(12,*)PRZE(1),PRZE(2),PRZE(3),PRZE(4)
      write(12,*)QHTRP,QHTRB,SCVPosition,Vspray
      write(12,*)mdotCHRG,mdotLD
      do j=1,26
      do i=1,nodesSG(j)
      write(12,*)TSG(i,j),hSG(i,j)
      enddo
      enddo
      write(12,*)CriticalLength1,CriticalLength2
      write(12,*)SGMass1,SGMass2
c      Write(12,*)RodDepth
       do i=1,4
       write(12,*)BANKPOSITION(i)
       enddo
      write(12,*)DeltaPFHSG1,DeltaPEHSG1,DeltaPHSG1
      write(12,*)DeltaPFHSG2,DeltaPEHSG2,DeltaPHSG2
      write(12,*)Qsteam,Wload,Wturb,PSGIND,Pimpulse,p_hdr							  
c	creat SG restart files by shen	
	do i=1,60
	write(12,4444)velocity_kk(i),pressure_kk(i),ie_kk(i),
     %	kafa_kk(i),aj_kk(i),density_kk(i)
	enddo
c	creat Feed Flow by shen	
	write(12,*)FlowSG,FlowFDInd,FlowDEMAND,FlowSteamInd,FeedSHIM					  
	write(12,*)OmegaFP,FCV,FBV
	write(12,*)TBVposition
      write(12,*)Tfeed
	write(12,*)TCVposition
c.
      write(12,*)TfuelAVE
      write(12,*)TfuelHOT
      write(12,*)uHOT
      write(12,*)MDNBR
      write(12,*)TESLoad,TESFlowDemand,TESSHIM,FlowAUX1,FlowAUX2,
     %           FlowAUX3,PTAP,rhoTAP,hTAP,PTES								   !Konor
      write(12,*)IOPENTES(1),IOPENTES(2),IOPENTES(3),IOPENTES(4)
      write(12,*)TES_TBV(1),TES_TBV(2),TES_TBV(3),TES_TBV(4)
      write(12,*)ICLOSETBV,LockTBV
c.**************************************************
      Close(unit=12)
	iwrite0=iwrite0+RestartInterval
	endif
c
c
        if(IDEBUG.eq.1)then
        write(6,*)' '
        Write(6,*)'Time=',Time
        write(6,*)'Flow1=',Flow1,' Flow2=',Flow2,' Flowv=',Flowv
        write(6,*)' '
        Write(6,*)'DeltaP Vessel=',DeltaPv,' DeltaP Core=',DeltaPcore
        write(6,*)'DeltaP SG 1=',DeltaPSG1,' DeltaP SG 2 = ',DeltaPSG2
        write(6,*)' '
        write(6,*)('Internal Energy Distribution')
        write(6,*)' '
        Write(6,*)(uold(i), i=1,26)
        write(6,*)' '
        write(6,*)('Temperature Distribution')
        write(6,*)' '
        Write(6,*)(Told(i), i=1,26)
        write(6,*)' '
        endif
c.
      end do										   !end time loop
c.
      if(IDEBUG.eq.1)then
c.
c.    Output SG Temperatures and Enthalpies
c.
        do j=1,26
          write(6,*)' '
          write(6,*)'Loop node j = ',j,' Primary Temp = ',Told(j)
          write(6,*)' '
          do i=1,nodesSG(j)
          write(6,*)'i=',i,' TSG(i,j)=',TSG(i,j),' hSG(i,j)=',hsg(i,j)
          enddo
        enddo
      write(6,*)' '
      write(6,*)'ICRIT1j=',ICRIT1j,' ICRIT1i=',ICRIT1i
      write(6,*)'ICRIT2j=',ICRIT2j,' ICRIT2i=',ICRIT2i
      write(6,*)' '
      Write(6,*)'Critical Length 1=',CriticalLength1
      Write(6,*)'Critical Length 2=',CriticalLength2
      endif
c.**************************************************
c.
c.    Create Restart File
c.
      open(unit=12,file='Restart.dat')
      write(12,*)Time
      write(12,*)Qrx,Qth,Qtrans,Trx,Tclad
      write(12,*)NI,NX
      write(12,*)(Precursor(j),j=1,6)
      write(12,*)(gammaDH(j),j=1,11)
      write(12,*)Flowv,Flow1,Flow2
	write(12,*)(Told(i),i=1,26)
      write(12,*)THLIND,TCLIND
      write(12,*)Pp,Px
      write(12,*)VOL(1),VOL(2),VOL(3),VOL(4),Ax5,PRZLVL
      write(12,*)alphagPx(1),alphagPx(2),alphagPx(3),alphagPx(4)
      write(12,*)rholPx(1),rholPx(2),rholPx(3),rholPx(4)
      write(12,*)ulPx(1),ulPx(2),ulPx(3),ulPx(4)
      write(12,*)rhogPx(1),rhogPx(2),rhogPx(3),rhogPx(4)
      write(12,*)ugPx(1),ugPx(2),ugPx(3),ugPx(4)
      write(12,*)rhoPx(1),rhoPx(2),rhoPx(3),rhoPx(4)
      write(12,*)rhouPx(1),rhouPx(2),rhouPx(3),rhouPx(4)
      write(12,*)VelPx(1),VelPx(2),VelPx(3),VelPx(4),VelPx(5)
      write(12,*)VSRVPx(1),VSRVPx(2),VSRVPx(3),VSRVPx(4)
      write(12,*)PRZMass(1),PRZMass(2),PRZMass(3),PRZMass(4)
      write(12,*)PRZE(1),PRZE(2),PRZE(3),PRZE(4)
      write(12,*)QHTRP,QHTRB,SCVPosition,Vspray
      write(12,*)mdotCHRG,mdotLD
      do j=1,26
      do i=1,nodesSG(j)
      write(12,*)TSG(i,j),hSG(i,j)
      enddo
      enddo
      write(12,*)CriticalLength1,CriticalLength2
      write(12,*)SGMass1,SGMass2
c      Write(12,*)RodDepth
       do i=1,4
       write(12,*)BANKPOSITION(i)
       enddo
      write(12,*)DeltaPFHSG1,DeltaPEHSG1,DeltaPHSG1
      write(12,*)DeltaPFHSG2,DeltaPEHSG2,DeltaPHSG2
      write(12,*)Qsteam,Wload,Wturb,PSGIND,Pimpulse,p_hdr							
c	creat SG restart files by shen	
	do i=1,60
	write(12,4444)velocity_kk(i),pressure_kk(i),ie_kk(i),
     %	kafa_kk(i),aj_kk(i),density_kk(i)
	enddo
c	creat Feed Flow by shen	
	write(12,*)FlowSG,FlowFDInd,FlowDEMAND,FlowSteamInd,FeedSHIM						!Mod05
	write(12,*)OmegaFP,FCV,FBV
	write(12,*)TBVposition
      write(12,*)Tfeed
	write(12,*)TCVposition
c.
      write(12,*)TfuelAVE
      write(12,*)TfuelHOT
      write(12,*)uHOT
      write(12,*)MDNBR
      write(12,*)TESLoad,TESFlowDemand,TESSHIM,FlowAUX1,FlowAUX2,
     %           FlowAUX3,PTAP,rhoTAP,hTAP,PTES										   !Konor
      write(12,*)IOPENTES(1),IOPENTES(2),IOPENTES(3),IOPENTES(4)
      write(12,*)TES_TBV(1),TES_TBV(2),TES_TBV(3),TES_TBV(4)
      write(12,*)ICLOSETBV,LockTBV
c.**************************************************
      Close(unit=7)
      close(unit=10)
      close(unit=12)
 4444 Format(E20.8,5(8x,E20.8)) 
 1000 Format(6x,'Time',16x,'Qrx',13x,'Qth',13x,'Qtrans',11x,'Flowv',
     %       14x,'Pp',15x,'Px',13x,'PxIND',12x,'PRZLVL',9x,'PRZLVLIND',
     %       9x'VelSRG',12x,'QHTRP',12x,'QHTRB',9x,'SCV Position',
     %       6x,'Spray GPM',11x,'THL',12x,'THL Ind',12x,'TCL',
     %       12x,'TCL Ind',10x,'TaveREF',
     %       11x,'Tave',12x,'Tave Ind',10x,'Tmod',
     %       11x,'Flow SFWS',9x,'Flow FD',8x,'Flow FD Ind',9x,'Demand',	         
     %       9x,'Steam Flow',5x,'Steam Flow Ind',7x,'Wload',
     %       12x,'Wturb',11x,'Omega FP',8x,'Texit SG 1',
     %       6x,'Texit SG IND',5x,'SG Exit Void',				  
     %       7x,'Dryout 1',8x,'SGLVL Ind',11x,'Trx',12x,'TCL Hot',		  
     %       11x,'MDNBR',12x,'Tfeed',11x,'TfeedIND',10x,'Qsteam',
     %       12x,'PSG',13x,'PSG Ind',11x,'Pimp',
     %       10x,'DeltaP SG',6x,'DeltaP SG IND',
     %       5x,'DP elev SG',9x,'Deltat',
     %       13x,'rho',13x,'rhoX',
     %       14x,'FCV',14x,'FBV',13x,'SFWV',
     %       13x,'TCV 1',12x,'TCV 2',12x,'TCV 3',12x,'TCV 4',
     %       12x,'TBV 1',12x,'TBV 2',12x,'TBV 3',12x,'TBV 4',
     %       12x,'BANK A',11x,'BANK B',11x,'BANK C',11x,'BANK D',
     %       11x,'RhoCBA',11x,'RhoCBB',11x,'RhoCBC',11x,'RhoCBD',
     %       10x,'TESLoad',7x,'TESFlowDemand',7x,'FlowAUX1',
     %        9x,'FlowAUX2',9x,'FlowAUX3',11x,'PTAP',11x,'Tsat Tap',
     %       10x,'PTES',11x,'TES_TBV(1)',7x,'TES_TBV(2)',	                           !Konor
     %        7x,'TES_TBV(3)',7x,'TES_TBV(4)')									   !Konor
 1001 Format(1x,e15.8,83(2x,e15.8))									  			   !Konor
 1100 Format(1x,'Reactor Data File = ',$)
 1200 Format(1x,'Case File = ',$)
c.
	TTIM = DTIME(TA)
c	write(*,*) 'Program has been running for', TTIM, 'seconds.'
      Stop
      End
c.
      Subroutine Pause
*********************************************************************
*  This subroutine prompts the user to enter <ret> to continue.     *
*********************************************************************
      WRITE(*,10)'Type <ret> to continue. '
 10   FORMAT(17X,A)
      READ(*,*)
      RETURN 
      END
c.************************************************************************
c.
c.    Subroutine to Compute Reactor Power Using
c.    the Six Group Point Kinetics Equations
c.
      Subroutine Kinetics06(Qrxnew,Qrx,QrxRate,Trx,Tinf,Cb,Deltat)
      Real lamda,NXref
      Common /Reactivity/alphaTrx,alphamod,alphaBoron,alphaXe,
     %                   Trxref,Tref,Cref,NXref,
     %                   Rho0,Prompt,Rhocr,Rho,
     %                   DeltaRhoFuel,DeltaRhoMod,DeltaRhoB,Srx
      Common/XenonWorth/rhoX
      Common/DelayedNeutronData/Precursor(6),lamda(6),beta(6)
c.

      DeltaTs=Deltat*3600.
      BetaEFF=0.
      Delayed=0.
       do j=1,6
       BetaEFF=BetaEFF+beta(j)
       Delayed=Delayed+lamda(j)*Precursor(j)
       enddo
      Delayed=Delayed+Srx      
c.
c.    Compute Reactivity
c.
      DeltaRhoFuel=alphaTrx*(Trx-Trxref)
      DeltaRhoMod=alphamod*(Tinf-Tref)
      DeltaRhoB=alphaBoron*(Cb-Cref)
      Rho=Rho0+Rhocr+DeltaRhoFuel+DeltaRhoMod+DeltaRhoB
      Rho=Rho+rhoX
c.
      CapLamda=Prompt*(1.-Rho)
      TauP=CapLamda/(Rho-BetaEFF)
c.
c.    New Reactor Power
c.
      Qrxnew=Qrx*exp(DeltaTs/TauP)-TauP*Delayed*(1.-exp(DeltaTs/TauP))
c.
c.    New Delayed Neutron Precursor Concentrations
c.
       do j=1,6
       Precursor(j)=Precursor(j)*exp(-lamda(j)*DeltaTs)+
     %              (Qrxnew/CapLamda)*(beta(j)/lamda(j))*
     %              (1.-exp(-lamda(j)*DeltaTs))
       enddo
c.
      QrxRate=(100./Qrx)*((Rho-BetaEFF)*Qrx/((1.-Rho)*Prompt)+     
     &                    Delayed)*60.                         
      Return
      End
c.********************************************************************
c.
c.    Subroutine to compute decay heat rate
c.
      Subroutine Decay_Heat(Deltat,Qrx,DecayHeat)
      Real lamda
      Dimension E(11),lamda(11)
      Data E/0.00299,0.00825,0.01550,0.01935,0.01165,0.00645,0.00231,
     %       0.00164,0.00085,0.00043,0.00057/
      Data lamda/1.772e+0,5.774e-1,6.743e-2,6.214e-3,4.739e-4,4.810e-5,
     %           5.344e-6,5.726e-7,1.036e-7,2.959e-8,7.585e-10/
      Common/DecayHeatData/gamma(11)
c.
      time=Deltat*3600.
	if(Deltat.eq.0.)then
       do j=1,11
       gamma(j)=Qrx*E(j)/lamda(j)
       enddo
      else
       do j=1,11
       gamma(j)=gamma(j)*exp(-lamda(j)*time)+
     %          Qrx*E(j)/lamda(j)*(1.-exp(-lamda(j)*time))
       enddo
      endif
c.      
      DecayHeat=0.
      do j=1,11
      DecayHeat=DecayHeat+gamma(j)*lamda(j)
      enddo
c.
      Return      
      End
c.********************************************************************
c.
c.    Subroutine to compute control rod speed
c.
      Subroutine ControlRodSpeed(Tave,Wturb,Qth,RodSpeed,IWITHDRAW)
	Common/ControlRods/aref,bref,RodspeedMin,RodspeedMax,RefRxPwr,
     %                   TaveREF,RodGain					           
      Common/TurbineLoadData/aload,bload,RefLoad,RampDuration
c.*********************************************************
c.
      Common/TESParameters/FlowAUX1,FlowAUX2,FlowAUX3,TESLoad
c.
      TotalLoad=Wturb+TESLoad
c.
c.********************************************************* 		 
      G1=5.
      IDEBUG=0
c.
c.*********************************************************
c.            
c      TaveREF=aref+bref*Wturb/RefLoad
c      E1=Wturb/RefLoad-Qth/RefRxPwr
c.															 !TES Mod
      TaveREF=aref+bref*TotalLoad/RefLoad
      E1=TotalLoad/RefLoad-Qth/RefRxPwr
c.
c.*********************************************************
      E2=TaveREF-Tave									
c.
      ERROR=G1*E1+E2
c.
        If(Abs(ERROR).gt.0.5)then
        RodSpeed=RodGain*abs(ERROR)*RodSpeedMax
         if(RodSpeed.gt.RodSpeedMax)RodSpeed=RodSpeedMax
         if(RodSpeed.lt.RodSpeedMin)RodSpeed=RodSpeedMin
        else
        RodSpeed=0.
        endif
c.
      If(ERROR.gt.0)then
      IWITHDRAW=1
      else
      IWITHDRAW=0
      endif
c.	 
        if(IDEBUG.eq.1)then
        open(unit=14,file='Debug.dat')
        write(14,*)' '
        write(14,*)'E1 = ',E1
        write(14,*)'E2 = ',E2
        write(14,*)'ERROR=',ERROR
        write(14,*)'RodSpeedMax= ',RodSpeedMax
        write(14,*)'RodSpeedMin= ',RodSpeedMin
        write(14,*)'RodSpeed= ',RodSpeed
        write(14,*)'IWITHDRAW=',IWITHDRAW
        endif
c.                   
      Return
      End
c.********************************************************************
c.
c.    Subroutine to compute control bank positions
c.
      Subroutine ControlBankPositions(RodSpeed,Deltat,IWITHDRAW,
     %                                BANKPOSITION)
c.
      Common/ControlBankData/BankWorthParameters(4,3),BankLength,
     %                       Overlap,InchesPerStep
      Common/UpsetParameters/ITYPEUpset,UPSETPARM(4)
      Dimension BANKPOSITION(4)
      Real InchesPerStep
c.
      IDEBUG=0
c.
      if(ITYPEUpset.eq.240)then
c.
c.    Uncontrolled Rod Bank Withdrawal
c.
      IWITHDRAW=1
      IPULL=INT(UPSETPARM(1))
      NBANKS=INT(UPSETPARM(2))
      RodSpeed0=UPSETPARM(3)
c.      
      DeltaPosition=RodSpeed0*Deltat*60.
	DeltaPosition=DeltaPosition/InchesPerStep
c.
      ISTART=IPULL
      ISTOP=IPULL+NBANKS-1
      else
      ISTART=1
      ISTOP=4
      DeltaPosition=RodSpeed*Deltat
c.
c.     Convert Rod Position From Feet to Steps
c.
      DeltaPosition=DeltaPosition*12./InchesPerStep
      endif
c.
       If(IWITHDRAW.eq.1)then
c.
c.*******************************************************************
c.
c.     Rods Withdrawing
c.
         do i=ISTART,ISTOP
c.
c.        Control Bank A
c.
          if(i.eq.1)then
            if(BANKPOSITION(1).lt.BankLength)then
            BANKPOSITION(1)=AMIN1(BANKPOSITION(1)+DeltaPosition,
     %                            BankLength)
            endif
          endif
c.
c.        Control Bank B
c.
          if(i.eq.2)then
            if((BANKPOSITION(1).gt.BankLength-Overlap).and.
     %         (BANKPOSITION(2).lt.BankLength))then
                BANKPOSITION(2)=AMIN1(BANKPOSITION(2)+DeltaPosition,
     %                                BankLength)
            endif
          endif
c.
c.        Control Bank C
c.       
          if(i.eq.3)then
             if((BANKPOSITION(2).gt.BankLength-Overlap).and.
     %          (BANKPOSITION(3).lt.BankLength))then
                 BANKPOSITION(3)=AMIN1(BANKPOSITION(3)+DeltaPosition,
     %                                 BankLength)
             endif
          endif
c.
c.        Control Bank D
c.       
          if(i.eq.4)then
             if((BANKPOSITION(3).gt.BankLength-Overlap).and.
     %          (BANKPOSITION(4).lt.BankLength))then
                 BANKPOSITION(4)=AMIN1(BANKPOSITION(4)+DeltaPosition,
     %                                 BankLength)
             endif
          endif
         enddo
c.******************************************************************
       else
c.*******************************************************************
c.
c.     Rods Inserting
c.
         do i=4,1,-1
c.
c.        Control Bank D
c.
          if(i.eq.4)then
            if(BANKPOSITION(4).gt.0.)then
            BANKPOSITION(4)=AMAX1(BANKPOSITION(4)-DeltaPosition,
     %                            0.)
            endif
          endif
c.
c.        Control Bank C
c.
          if(i.eq.3)then
            if((BANKPOSITION(4).lt.Overlap).and.
     %         (BANKPOSITION(3).gt.0.))then
                BANKPOSITION(3)=AMAX1(BANKPOSITION(3)-DeltaPosition,
     %                                0.)
            endif
          endif
c.
c.        Control Bank B
c.       
          if(i.eq.2)then
            if((BANKPOSITION(3).lt.Overlap).and.
     %         (BANKPOSITION(2).gt.0.))then
                BANKPOSITION(2)=AMAX1(BANKPOSITION(2)-DeltaPosition,
     %                                 0.)
             endif
          endif
c.
c.        Control Bank D
c.       
          if(i.eq.1)then
             if((BANKPOSITION(2).lt.Overlap).and.
     %          (BANKPOSITION(1).gt.0.))then
                 BANKPOSITION(1)=AMAX1(BANKPOSITION(1)-DeltaPosition,
     %                                 0.)
             endif
          endif
         enddo
c.******************************************************************
       endif
      Return
      End
c.
c.    Function to Compute Integral Control Bank Worth
c.
      Function ControlBankWorth(ID,Position)
c.
      Common/ControlBankData/BankWorthParameters(4,3),BankLength,
     %                       Overlap,InchesPerStep
      REAL InchesPerStep
c.
      a=BankWorthParameters(ID,1)
      b=BankWorthParameters(ID,2)
      x0=BankWorthParameters(ID,3)
c.
      ARG=(Position-x0)/b
      ARG0=(BankLength-x0)/b
c.
      ControlBankWorth=a/(1.+exp(-ARG))-a/(1.+exp(-ARG0))
      ControlBankWorth=ControlBankWorth*1.e-5
c.
      Return
      End
c.*****************************************************************************    
c.
c.    Subroutine to model Helical Steam Generators
c.
      Subroutine SG(Tp,FlowSG,PSG,PSGIND,UAM,DeltaT,DeltaZ,DeltaH,
     %            DeltaPFSG1,DeltaPESG1,DeltaPSG1,
     %            DeltaPFSG2,DeltaPESG2,DeltaPSG2,nodesSG,
     %			ntubes,Qsteam,time,tmax,Pimpulse,p_hdr,k_turb0)
c      Real kw,Mass
      Real kw
      Real mug
c.
      Dimension UAM(20,26),nodesSG(26)
      Dimension Tp(26)
      Dimension DeltaH(26)
c.	add SGdata common by shen
	common /SGdata/ velocity_kk,pressure_kk,ie_kk,
     %	kafa_kk,aj_kk,density_kk

c      Common/SGUA/Ri,Ro,kw,S,Fouling,ITYPESG
      Common/SGUA/Ri,Ro,kw,S,Fouling,DeSG,AxSG,ITYPESG
      Common/SGTemps/TSG(20,26),hSG(20,26),Tfeed,FlowSteam
      Common/CriticalLocation/ICRIT1j,ICRIT1i,ICRIT2j,ICRIT2i,
     %      CriticalLength1,CriticalLength2,fraction1,fraction2
      Common/SteamGeneratorMass/SGMass1,SGMass2
c	trubine bypass 
      Common/TCVControl/TCVGain(3,3,4),RATETCV,nTCV
      Common/TBVControl/TBVGain(3,3,4),RATETBV,nTBV
      Common/PressureControlSetPoints/PSG_Ref
      Common/SteamFlowInit/TBVposition(4),TCVposition(4)
	Common/ValveProperties/DeadBand(10),Tau(10),
     %                       Avalve(10),Kvalve(10),bvalve(10)
      Common/ControlMODES/MODE(10)
      Common/DEGUG/IRESTART,IDEBUG
      Common/FeedPARAMETERS/nHWP,nCP,nFP,nSG,Pcond		  !Mod05
      Common/UpsetParameters/ITYPEUpset,UPSETPARM(4)
c.
      Common/BOPGeometry/AreaMSL,nMSL,AreaSL
c.
c.*************************************************
c.
      Real KEXH
      Common/TESParameters/FlowAUX1,FlowAUX2,FlowAUX3,TESLoad                 !TES Mod
      Common/TESTapParameters/KEXH,PTAP,rhoTAP,hTAP
      Common/TESByPassControlSetPoints/TESFlowDEMAND0,TESSetPoint(4),
     %                                 IOPENTES(4),nTESByPass,ModeTES,
     %                                 ICLOSETBV,LockTBV
c.
c.*************************************************
	real Kvalve, KTBV(4),KTCV(4)
	Dimension ATBV(4), velocity_tbv_kk(4),a_tbv(4),b_tbv(4)
	Dimension ATCV(4), velocity_tcv_kk(4)
	Dimension old_velocity_tbv_tt(4),old_velocity_tbv_kk(4)
	Dimension old_velocity_tcv_tt(4),old_velocity_tcv_kk(4)
c
c.	add more declarations by shen
	real th_a(60),th_b(60),th_c(60),th_s(60)
	real alp(61), th_g(61),th_a_sg,th_b_sg,th_s_sg
	real old_pressure_tt(60),old_pressure_kk(61)
	real old_velocity_tt(60),old_velocity_kk(60)
	real old_density_tt(60),old_density_kk(60)
	real old_ie_tt(60),old_ie_kk(60)
	real old_kafa_tt(60),old_kafa_kk(60)
	real old_aj_tt(60),old_aj_kk(61)
	real old_temperature_kk(60),old_temperature_tt(60)
	real pressure_kk(60),velocity_KK(60),density_kk(60)
	real kafa_kk(60),ie_kk(60),aj_kk(60)
	real aj_do(60),density_do(60),densityf_do(60)
	real densityg_do(60),uf_do(60),ug_do(60),ie_do(60)
	real density_ave(60),factor(60)		 
	real drift_a1(60),drift_a2(60),drift_b1(60),drift_b2(60)
	real drift_mo(61),v_g(60),v_l(60)
	real t_temp(60),qt(60),dvdz(60),density_ave_kk(60)
	real ie_in,ie_temp
	real k_adv,k_hdr,k_tbv1,k_turb,k_turb0
	integer count

c	test
	real pha22_(60),pha33_(60),pha44_(60)
	real error_2(60),error_3(60),error_4(60)
c.*************************************************
      Dimension IMOVETCV(4),IOPENTCV(4),TCVnew(4)
      Data IMOVETCV/4*0/
      Data IOPENTCV/4*0/
c.*************************************************
c
c	Open(unit=1,file ='shen.txt')
c	Open(unit=3,file ='stop.txt')
c	Open(unit=4,file ='output.txt')
      Pi=3.1415926
      Ts=Tsat(PSG)
c      V=DeltaZ*Pi*Ri**2*float(ntubes)
c      Mass=density(Tfeed)*V
      gc=4.17e8
c.    ******* Steam Generator 1 *********
caaa	New SG Model added by shen~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	delta_t=deltaT*3600
	N=60
	p_atm=14.696
      p_cond=Pcond								!Mod05
	gc1=32.17*144
	converter=144/778.
c.
c	area_sg=Ntubes*pi*Ri**2
      area_sg=AxSG
      area_sl=AreaMSL*float(nMSL)/float(nSG)
      k_turb=k_turb0*(Avalve(4)/AreaSL)**2
c      k_turb=k_turb0
c.
	area_adv=0.5*area_sg*2.9
c.
	u_in=uliq(Tfeed)
	density_in=rhop(u_in,PSG)			  
	ie_in=density_in*u_in
	velocity_in=FlowSG/density_in/area_sg/3600.

c	TCV open	
	k_adv=10000.
	k_tbv1=10000.
	k_hdr=2.
c	k_turb=220.													 !Mod05
c	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Qsteam=0.
	do j=13,8,-1
	do i=1,10
	ii=i+(13-j)*10
	qt(ii)=UAM(i,j)*(Tp(j)-TSG(i,j))
	Qsteam=Qsteam+qt(ii)
	enddo
	enddo
      Qsteam=Qsteam*float(nSG)/3.4137e6
c
c.************************************************************************
c.
	if(MODE(7).eq.1) then	
	data iishen /0/
		if(iishen.eq.0)then
		TBVPosition_ini=TBVPosition(1)
		iishen=iishen+1
		endif
	TBVPosition=TBVPosition-TBVPosition_ini*DeltaT*60./1.
	    if(TBVPosition(1).le.0.) then
		TBVPosition=0.
		ATBV=0.
		else if(TBVPosition(1).gt.1) then
		TBVPosition=1.
		ATBV=Avalve(3)
		else
		ATBV=Avalve(3)
		endif
	else if(MODE(3).eq.1 .and. MODE(9).eq.0) then	
      call TurbineByPassValvePosition(PSGIND,MODE(3),ATBV,Deltat)
	endif
c.
c.***********************************************************************
c.
	if(MODE(4).eq.1 .and. MODE(9).eq.0) then	
      call TurbineControlValvePosition(TCVNew,PSGIND,MODE(4),Deltat)
	endif
c.
	if(MODE(9).eq.1) then	
	data iishen1 /0/
		if(iishen1.eq.0)then
            do j=1,nTCV
            TCVNew(j)=TCVPosition(j)
            enddo
		iishen1=iishen1+1
		endif
      do j=1,nTCV
	TCVNew(j)=TCVNew(j)-Deltat*RATETCV
      if(TCVNew(j).lt.0.)TCVNew(j)=0.
      if(TCVNew(j).gt.1.)TCVNew(j)=1.
      enddo
c.
	if(MODE(3).eq.1) then	
      call TurbineByPassValvePosition(PSGIND,MODE(3),ATBV,Deltat)
	endif
c.
	ENDIF
c.
c.**********************************************************************
c.

	Nvalve=3
       do j=1,nTBV
       Call Valve(TBVPosition(j),Nvalve,KTBV(j))
       enddo
	Nvalve=4
       do j=1,nTCV
       Call ValvePosition(TCVPosition(j),TCVNew(j),Deltat,IMOVETCV(j),
     %                    IOPENTCV(j),Nvalve)
        if(ITYPEUpset.eq.2141)then
        TCVPosition(j)=UPSETPARM(1)/100.
        endif
          if(TCVposition(j).le.0.)then
          TCVposition(j)=0.
          ATCV(j)=0.
          elseif(TCVposition(j).ge.1.)then
          TCVposition(j)=1.
          ATCV(j)=Avalve(4)
          else
          ATCV(j)=Avalve(4)
          endif
       Call Valve(TCVPosition(j),Nvalve,KTCV(j))
       enddo
c
	istart=istart+1	
	if(istart.eq.1)then
	velocity_adv_kk=0
	velocity_sl_kk=(area_sg*velocity_kk(N)-
     %			   area_adv*velocity_adv_kk)/area_sl
		velocity_tbv1_kk=0
		p_hdr=psg-k_hdr*density_kk(N)*velocity_sl_kk**2/2/gc1
		do i=1, nTBV
		velocity_tbv_kk(i)=(p_hdr-p_cond)*2*gc1/density_kk(N)
     %		/KTBV(i)
		velocity_tbv_kk(i)=velocity_tbv_kk(i)**0.5
		enddo
		do i=1, nTCV
		velocity_tcv_kk(i)=(p_hdr-p_cond)*2*gc1/density_kk(N)
     %		/(KTCV(i)+k_turb)
		velocity_tcv_kk(i)=velocity_tcv_kk(i)**0.5
		enddo
	endif		
	
c	change unit of heat source to btu/(ft^2*s)
	qt=qt/area_sg/3600.
c		
	do i=1,N
	old_pressure_tt(i)=pressure_kk(i)
	old_velocity_tt(i)=velocity_kk(i)
	old_density_tt(i)=density_kk(i)
	old_ie_tt(i)=ie_kk(i)
	old_aj_tt(i)=aj_kk(i)
	old_kafa_tt(i)=kafa_kk(i)
	enddo
	old_velocity_adv_tt=velocity_adv_kk
	old_velocity_sl_tt=velocity_sl_kk
	old_velocity_tbv1_tt=velocity_tbv1_kk
	old_velocity_tbv_tt=velocity_tbv_kk
	old_velocity_tcv_tt=velocity_tcv_kk

	do i=1,N-1
	density_ave(i)=(old_density_tt(i)+old_density_tt(i+1))/2
	enddo
	density_ave(N)=old_density_tt(N)

1	count=0
	do i=1,N	
	pressure_kk(i)=old_pressure_tt(i)
	velocity_kk(i)=old_velocity_tt(i)
	density_kk(i)=old_density_tt(i)
	ie_kk(i)=old_ie_tt(i)
	kafa_kk(i)=old_kafa_tt(i)
	aj_kk(i)=old_aj_tt(i)
	enddo
	velocity_adv_kk=old_velocity_adv_tt
	velocity_sl_kk=old_velocity_sl_tt
	velocity_tbv1_kk=old_velocity_tbv1_tt
	velocity_tcv_kk=old_velocity_tcv_tt	

c.	newton iteration***************************************************************	
2	count=count+1
	do i=1,N
	old_pressure_kk(i)=pressure_kk(i)
	old_velocity_kk(i)=velocity_kk(i)
	old_density_kk(i)=density_kk(i)
	old_ie_kk(i)=ie_kk(i)
	old_kafa_kk(i)=kafa_kk(i)
	old_aj_kk(i)=aj_kk(i)
	enddo
	old_velocity_adv_kk=velocity_adv_kk
	old_velocity_sl_kk=velocity_sl_kk
	old_velocity_tbv1_kk=velocity_tbv1_kk
	old_velocity_tbv_kk=velocity_tbv_kk
	old_velocity_tcv_kk=velocity_tcv_kk
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	do i=1,N-1
	density_ave_kk(i)=(old_density_kk(i)+old_density_kk(i+1))/2
	enddo
	density_ave_kk(N)=old_density_kk(N)
c	donor ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	do i=1,N-1	
	g=density_ave_kk(i)*old_velocity_kk(i)*3600

c	case 0 (single liquid or single vapour)
	if(old_aj_kk(i+1).eq.0 .and.old_aj_kk(i).eq.0 .or.
     %	old_aj_kk(i+1).ge.0.99 .and.old_aj_kk(i).ge.0.99 ) then
		if(old_velocity_kk(i).gt.0) then
		density_do(i)=old_density_tt(i)
		ie_do(i)=old_ie_tt(i)
		else
		density_do(i)=old_density_tt(i+1)
		ie_do(i)=old_ie_tt(i+1)
		endif
	aj_do(i)=0	
	v_g(i)=0
	v_l(i)=old_velocity_kk(i)
	if(old_aj_kk(i+1).ge.0.99 .and.old_aj_kk(i).ge.0.99 ) then
	aj_do(i)=1
	v_g(i)=old_velocity_kk(i)
	v_l(i)=0
	endif

c	case 5
	else if(i.le.98 .and. old_aj_kk(i).eq.0 .and.
     % old_aj_kk(i+1).lt.0.99 .and. old_aj_kk(i+1).gt.0
     % .and. old_aj_kk(i+2).ge.0.99) then
			if(old_velocity_kk(i).gt.0) then
			densityf_do(i)=old_density_tt(i)
			uf_do(i)=old_ie_tt(i)/old_density_tt(i)
c			densityf_do(i)=rhof(old_pressure_tt(i))
c			uf_do(i)=uf(old_pressure_tt(i))
			else
			densityf_do(i)=old_density_tt(i+1)
			uf_do(i)=old_ie_tt(i+1)/old_density_tt(i+1)
c			densityf_do(i)=rhof(old_pressure_tt(i+1))
c			uf_do(i)=uf(old_pressure_tt(i+1))
			endif	
			aj_do(i)=0
			density_do(i)=densityf_do(i)
			ie_do(i)=densityf_do(i)*uf_do(i)	

c	case 1	
	else if(old_aj_kk(i).lt.0.99 .and. old_aj_kk(i).gt.0. .and.
     %    	old_aj_kk(i+1).lt.0.99 .and.old_aj_kk(i+1).gt.0) then
	aj_head=max(old_aj_kk(i),old_aj_kk(i+1))
	p=old_pressure_kk(i)
	v=old_velocity_kk(i)	
	v_g(i)=v+(1-aj_head)*rhof(p)/((1-aj_head)*rhof(p)+aj_head*rhog(p))
     %    *rv(aj_head,v,p,ri,g)		
	v_l(i)=v-aj_head*rhog(p)/((1-aj_head)*rhof(p)+aj_head*rhog(p))
     %	*rv(aj_head,v,p,ri,g)

		if(old_velocity_kk(i).gt.0) then
		aj_do(i)=old_aj_kk(i)
		densityg_do(i)=rhog(old_pressure_tt(i))
		ug_do(i)=ug(old_pressure_tt(i))
			if(v_l(i).gt.0) then
			densityf_do(i)=rhof(old_pressure_tt(i))
			uf_do(i)=uf(old_pressure_tt(i))
			else
			densityf_do(i)=rhof(old_pressure_tt(i+1))
			uf_do(i)=uf(old_pressure_tt(i+1))
			endif
		else
			densityf_do(i)=rhof(old_pressure_tt(i+1))
			uf_do(i)=uf(old_pressure_tt(i+1))
			if(v_g(i).gt.0) then
			aj_do(i)=old_aj_kk(i)
			densityg_do(i)=rhog(old_pressure_tt(i))
			ug_do(i)=ug(old_pressure_tt(i))
			else
			aj_do(i)=old_aj_kk(i+1)
			densityg_do(i)=rhog(old_pressure_tt(i+1))
			ug_do(i)=ug(old_pressure_tt(i+1))
			endif				
		endif
		density_do(i)=aj_do(i)*densityg_do(i)+(1-aj_do(i))*densityf_do(i)
		ie_do(i)=aj_do(i)*densityg_do(i)*ug_do(i)
     %		+(1-aj_do(i))*densityf_do(i)*uf_do(i)			

c	case 2
	else if( old_aj_kk(i).gt.0 .and. old_aj_kk(i+1).eq.0) then
	aj_head=old_aj_kk(i)
	p=old_pressure_kk(i)
	v=old_velocity_kk(i)	
	v_g(i)=v+(1-aj_head)*rhof(p)/((1-aj_head)*rhof(p)+aj_head*rhog(p))
     %    *rv(aj_head,v,p,ri,g)		
	v_l(i)=v-aj_head*rhog(p)/((1-aj_head)*rhof(p)+aj_head*rhog(p))
     %	*rv(aj_head,v,p,ri,g)

		if(old_velocity_kk(i).gt.0) then
		aj_do(i)=old_aj_kk(i)
		densityg_do(i)=rhog(old_pressure_tt(i))
		ug_do(i)=ug(old_pressure_tt(i))
			if(v_l(i).gt.0) then
			densityf_do(i)=rhof(old_pressure_tt(i))
			uf_do(i)=uf(old_pressure_tt(i))
			else
c			densityf_do(i)=old_density_tt(i+1)
c			uf_do(i)=old_ie_tt(i+1)/old_density_tt(i+1)
c	shen
			densityf_do(i)=rhof(old_pressure_tt(i+1))
			uf_do(i)=uf(old_pressure_tt(i+1))
			endif
		density_do(i)=aj_do(i)*densityg_do(i)+(1-aj_do(i))*densityf_do(i)
		ie_do(i)=aj_do(i)*densityg_do(i)*ug_do(i)
     %		+(1-aj_do(i))*densityf_do(i)*uf_do(i)
		else
c			densityf_do(i)=old_density_tt(i+1)
c			uf_do(i)=old_ie_tt(i+1)/old_density_tt(i+1)
			densityf_do(i)=rhof(old_pressure_tt(i+1))
			uf_do(i)=uf(old_pressure_tt(i+1))
			if(v_g(i).gt.0) then
			aj_do(i)=old_aj_kk(i)
			densityg_do(i)=rhog(old_pressure_tt(i))
			ug_do(i)=ug(old_pressure_tt(i))
	
			density_do(i)=aj_do(i)*densityg_do(i)+
     %			(1-aj_do(i))*densityf_do(i)
			ie_do(i)=aj_do(i)*densityg_do(i)*ug_do(i)
     %		+(1-aj_do(i))*densityf_do(i)*uf_do(i)
			else
			aj_do(i)=0
			density_do(i)=old_density_tt(i+1)
			ie_do(i)=old_ie_tt(i+1)
c			density_do(i)=rhof(old_pressure_tt(i))
c			ie_do(i)=rhof(old_pressure_tt(i))*uf(old_pressure_tt(i))
			endif				
		endif
		
c	case 3
	else if(old_aj_kk(i+1).lt.0.99 .and. old_aj_kk(i+1).gt.0 .and.
     %	old_aj_kk(i).eq.0) then
	aj_head=old_aj_kk(i+1)
	p=old_pressure_kk(i)
	v=old_velocity_kk(i)	
	v_g(i)=v+(1-aj_head)*rhof(p)/((1-aj_head)*rhof(p)+aj_head*rhog(p))
     %    *rv(aj_head,v,p,ri,g)		
	v_l(i)=v-aj_head*rhog(p)/((1-aj_head)*rhof(p)+aj_head*rhog(p))
     %	*rv(aj_head,v,p,ri,g)

		if(old_velocity_kk(i).gt.0) then
		aj_do(i)=0
		density_do(i)=old_density_tt(i)
		ie_do(i)=old_ie_tt(i)
		else
			densityf_do(i)=rhof(old_pressure_tt(i+1))
			uf_do(i)=uf(old_pressure_tt(i+1))
			if(v_g(i).gt.0) then
			aj_do(i)=0
			density_do(i)=rhof(old_pressure_tt(i+1))
			ie_do(i)=rhof(old_pressure_tt(i+1))
     %			*uf(old_pressure_tt(i+1))
			else
			aj_do(i)=old_aj_kk(i+1)
c 			density_do(i)=old_density_tt(i+1)
c			ie_do(i)=old_ie_tt(i+1)
			densityg_do(i)=rhog(old_pressure_tt(i+1))
			ug_do(i)=ug(old_pressure_tt(i+1))
			density_do(i)=aj_do(i)*densityg_do(i)+(1-aj_do(i))
     %			*densityf_do(i)
			ie_do(i)=aj_do(i)*densityg_do(i)*ug_do(i)
     %		+(1-aj_do(i))*densityf_do(i)*uf_do(i)
			endif					
		endif

c	case 4
	else if(old_aj_kk(i).lt.0.99 .and. old_aj_kk(i+1).ge.0.99
     %.or. old_aj_kk(i).ge.0.99 .and.  old_aj_kk(i+1).lt.0.99) then
			if(old_velocity_kk(i).gt.0) then
c			densityg_do(i)=rhog(old_pressure_tt(i))
c			ug_do(i)=ug(old_pressure_tt(i))
			densityg_do(i)=old_density_tt(i)
			ug_do(i)=old_ie_tt(i)/old_density_tt(i)
		else
			densityg_do(i)=old_density_tt(i+1)
			ug_do(i)=old_ie_tt(i+1)/old_density_tt(i+1)
c			densityg_do(i)=rhog(old_pressure_tt(i+1))
c			ug_do(i)=ug(old_pressure_tt(i+1))
		endif
			density_do(i)=densityg_do(i)
			ie_do(i)=densityg_do(i)*ug_do(i)
	aj_do(i)=1
	v_g(i)=(old_velocity_kk(i)+old_velocity_kk(i+1))/2
	v_l(i)=0													
	endif	
	enddo
c	right boundary for donor scheme
	if(old_aj_kk(N).ge.0.99 .or. old_aj_kk(N).eq.0) then	
		if(old_aj_kk(N).eq.0) then	
		aj_do(N)=0
		v_g(N)=0
		v_l(N)=old_velocity_kk(N)
		else if(old_aj_kk(N).ge.0.99) then	
		aj_do(N)=1
		v_g(N)=old_velocity_kk(N)
		v_l(N)=0
		endif
	else
	g=density_ave_kk(N)*old_velocity_kk(N)*3600
	p=old_pressure_kk(N)
	v=old_velocity_kk(N)	
	aj_head=old_aj_kk(N)
	v_g(N)=v+(1-aj_head)*rhof(p)/((1-aj_head)*rhof(p)+aj_head*rhog(p))
     %    *rv(aj_head,v,p,ri,g)		
	v_l(N)=v-aj_head*rhog(p)/((1-aj_head)*rhof(p)+aj_head*rhog(p))
     %	*rv(aj_head,v,p,ri,g)
	
		aj_do(N)=old_aj_kk(N)
		densityg_do(N)=rhog(old_pressure_tt(N))
		ug_do(N)=ug(old_pressure_tt(N))
		densityf_do(N)=rhof(old_pressure_tt(N))
		uf_do(N)=uf(old_pressure_tt(N))
	endif	
		density_do(N)=old_density_tt(N)
		ie_do(N)=old_ie_tt(N)

c	compute drift term in i.e. ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	do i=1,N
		if(aj_do(i).eq.0 .or. aj_do(i).ge.0.99 .or. 
     %	densityf_do(i).eq.0 .or.densityg_do(i).eq.0 )then
		drift_a1(i)=0
		drift_a2(i)=0
		drift_b1(i)=0
		drift_b2(i)=0
		else 
		den=aj_do(i)*densityg_do(i)+(1-aj_do(i))*densityf_do(i)
	drift1=aj_do(i)*(1-aj_do(i))*densityf_do(i)*densityg_do(i)/den
     %	*(1./densityg_do(i)-1./densityf_do(i))
	drift2=aj_do(i)*(1-aj_do(i))*densityf_do(i)*densityg_do(i)/den
     %	*(ug_do(i)-uf_do(i))
		g=density_ave_kk(i)*old_velocity_kk(i)*3600

		call rv1(old_velocity_kk(i), 
     %		aj_do(i),old_pressure_tt(i),ri,G,rv_a,rv_b)
		drift_a1(i)=drift1*rv_a
		drift_a2(i)=drift1*rv_b
		drift_b1(i)=drift2*rv_a
		drift_b2(i)=drift2*rv_b
		endif
	enddo

c	coefficient matrix ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	do i=1,N
	call derivative(old_aj_kk(i),old_kafa_kk(i),old_pressure_kk(i),
     %	dpdx1,dpdp1,density_temp,dpudx1,dpudp1,ie_temp)
	if(i.eq.1)then
	th_s(i)=(density_temp-old_density_tt(i)-dpdp1*old_pressure_kk(i))
     %	/delta_t+dpdx1/dpudx1*((old_ie_tt(i)-ie_temp+dpudp1*
     %	old_pressure_kk(i))/delta_t-(converter*old_pressure_tt(i)
     %	*drift_a1(i)+drift_b1(i)-qt(i))/deltaz)
     %	-velocity_in*(density_in-dpdx1/dpudx1*(ie_in+
     %   converter*old_pressure_tt(i)))/deltaz
	else			
	th_b(i)=(density_do(i-1)-dpdx1/dpudx1*(ie_do(i-1)+ converter*
     %  old_pressure_tt(i)*(1+drift_a2(i-1))+drift_b2(i-1)))/deltaz

	th_s(i)=(density_temp-old_density_tt(i)-dpdp1*old_pressure_kk(i))
     %	/delta_t+dpdx1/dpudx1*
     %	((old_ie_tt(i)-ie_temp+dpudp1*old_pressure_kk(i))/delta_t-
     %	(converter*old_pressure_tt(i)*(drift_a1(i)-drift_a1(i-1))+
     %	drift_b1(i)-drift_b1(i-1)-qt(i))/deltaz)	
	endif
	th_a(i)=-(density_do(i)-dpdx1/dpudx1*(ie_do(i)+converter*
     %   old_pressure_tt(i)*(1+drift_a2(i))+drift_b2(i)))/deltaz
	th_c(i)=(dpdx1*dpudp1/dpudx1-dpdp1)/delta_t
	enddo

c	right boundary~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	a_hdr=-k_hdr*old_density_tt(N)*old_velocity_sl_kk**2/2./gc1
	b_hdr=k_hdr*old_density_tt(N)*old_velocity_sl_kk/gc1
	term1=0
	term2=0
c	if only TBV open:
	if(mode(7).eq.0)then
	do i=1, nTBV
	a_tbv(i)=p_cond-
     %	KTBV(i)*old_density_tt(N)*old_velocity_tbv_kk(i)**2/2./gc1
	b_tbv(i)=KTBV(i)*old_density_tt(N)*old_velocity_tbv_kk(i)/gc1
	term1=term1+ATBV(i)/b_tbv(i)
	term2=term2+a_tbv(i)*ATBV(i)/b_tbv(i)
	enddo
	th_a_sg=1-area_sl/(area_sl+b_hdr*term1)
	th_b_sg=-b_hdr*area_sg/area_sl
	th_s_sg=a_hdr+(b_hdr*term2-a_hdr*area_sl)/(area_sl+b_hdr*term1)
c	if both tbv and tcv open
	else if(mode(7).eq.1 .or. mode(9).eq.1)then
	do i=1, nTBV
	a_tbv(i)=p_cond-
     %	KTBV(i)*old_density_tt(N)*old_velocity_tbv_kk(i)**2/2./gc1
	b_tbv(i)=KTBV(i)*old_density_tt(N)*old_velocity_tbv_kk(i)/gc1
	enddo
c	a_tcv=p_cond-(KTCV(1)+kturb)*
c     %	old_density_tt(N)*old_velocity_tcv_kk(1)**2/2./gc1
c	b_tcv=(KTCV(1)+kturb)*old_density_tt(N)*old_velocity_tcv_kk(1)/gc1
	a_tcv=p_cond-(KTCV(1)+k_turb)*
     %	  old_density_tt(N)*old_velocity_tcv_kk(1)**2/2./gc1
	b_tcv=(KTCV(1)+k_turb)*
     %       old_density_tt(N)*old_velocity_tcv_kk(1)/gc1
c.***********************************************************************
c.
      if(ModeTES.eq.1)then
      a_tcv=a_tcv-
     %      b_tcv*(FlowAUX1/3600.)/
     %      (old_density_tt(N)*ATCV(1)*float(nTCV))	 !TES Mod
      elseif(ModeTES.eq.2)then
      VAUX2=(FlowAUX2/3600.)/(old_density_tt(N)*AreaSL)
      a_tcv=a_tcv+
     %      k_turb*old_density_tt(N)*VAUX2**2*(AreaSL/ATCV(1))**2/
     %      (2.*gc1)
      b_tcv=b_tcv-k_turb*old_density_tt(N)*VAUX2*(AreaSL/ATCV(1))/gc1
      elseif(ModeTES.eq.3)then
      VAUX3=(FlowAUX3/3600.)/(old_density_tt(N)*AreaSL*float(nTCV))
      a_tcv=a_tcv+
     %      KEXH*old_density_tt(N)*VAUX3**2/(2.*gc1)
      b_tcv=b_tcv-KEXH*old_density_tt(N)*VAUX3*(ATCV(1)/AreaSL)/gc1
      endif
c.
c.***********************************************************************
	do i=1, nTBV
	term1=term1+ATBV(i)/b_tbv(i)
	term2=term2+ATBV(i)*a_tbv(i)/b_tbv(i)
	enddo
c	ATCV_tot=ATCV(1)*nTCV
      ATCV_tot=ATCV(1)*float(nTCV)/float(nSG)
	th_a_sg=1-area_sl*
     %	b_tcv/b_hdr/(area_sl*b_tcv/b_hdr+b_tcv*term1+ATCV_tot)
	th_b_sg=-b_hdr*area_sg/area_sl
	th_s_sg=a_hdr+
     %(a_tcv*ATCV_tot-a_hdr*area_sl*b_tcv/b_hdr+b_tcv*term2)/
     %(area_sl*b_tcv/b_hdr+b_tcv*term1+ATCV_tot)
	endif

c	atm dump valves open
c	a_adv=p_atm-k_adv*old_density_tt(N)*old_velocity_adv_kk**2/2./gc1
c	b_adv=k_adv*old_density_tt(N)*old_velocity_adv_kk/gc1
c	turbine bypass valves open	
c	a_tbv1=p_cond-k_tbv1*old_density_tt(N)*old_velocity_tbv1_kk**2/2./gc1
c	b_tbv1=k_tbv1*old_density_tt(N)*old_velocity_tbv1_kk/gc1
c	turbine flow open, only pipe 1 open
c	a_tcv=p_cond-(k_tcv+k_tur)*old_density_tt(N)
c     %	*old_velocity_tcv_kk**2/2./gc1
c	b_tcv=(k_tcv+k_tur)*old_density_tt(N)*old_velocity_tcv_kk/gc1
c
c	case 4: ADV's open, MSIV's open, TBV 1 is open
c	th_a_sg=area_sl/b_hdr+area_adv/b_adv-area_sl**2/b_hdr/
c    %	(area_sl+b_hdr*area_tbv1/b_tbv1)
c	th_b_sg=-area_sg
c	th_s_sg=area_adv*a_adv/b_adv+area_sl/(area_sl+b_hdr*area_tbv1/b_tbv1)
c     %	*(a_hdr*area_tbv1/b_tbv1+area_tbv1*a_tbv1/b_tbv1)	
c	case 3: MSIV's open, TCV 1 is open
c	th_a_sg=1
c	th_b_sg=-(b_hdr+b_tcv*area_sl/area_tcv)*area_sg/area_sl
c	th_s_sg=a_hdr+a_tcv
c	case 2
c
c	Solution of the matrix ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	alp(1)=th_c(1)
	th_g(1)=th_s(1)
	do i=2,N
	alp(i)=th_c(i)-alp(i-1)*th_b(i)/th_a(i-1)
	th_g(i)=th_s(i)-th_g(i-1)*th_b(i)/th_a(i-1)
	enddo
	alp(N+1)=th_a_sg-alp(N)*th_b_sg/th_a(N)
	th_g(N+1)=th_s_sg-th_g(N)*th_b_sg/th_a(N)	

	psg=th_g(N+1)/alp(N+1)
	pressure_kk=psg
	do i=N,1,-1	
	velocity_kk(i)=(th_g(i)-alp(i)*psg)/th_a(i)
	enddo

C	solve V_sl,V_adv, etc for case 3 using true value~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	vsg=velocity_kk(N)
	velocity_adv_kk=0
	velocity_sl_kk=(vsg*area_sg-velocity_adv_kk*area_adv)/area_sl
	do i=1,nTBV
	velocity_tbv_kk(i)=(PSG-a_hdr-b_hdr*velocity_sl_kk-a_tbv(i))
     %	/b_tbv(i)
	enddo
	do i=1,nTCV
	velocity_tcv_kk(i)=(PSG-a_hdr-b_hdr*velocity_sl_kk-a_tcv)
     %	/b_tcv
	enddo
c	velocity_tbv1_kk=0
c	velocity_tcv_kk=velocity_sl_kk*area_sl/area_tcv
c	velocity_tcv_kk=0
c	p_hdr=a_tbv1+b_tbv1*velocity_tbv1_kk
c	p_hdr=a_tcv+b_tcv*velocity_tcv_kk
	if(mode(4).eq.1)then
	p_hdr=a_tcv+b_tcv*velocity_tcv_kk(nTCV)
	else
	p_hdr=a_tbv(nTBV)+b_tbv(nTBV)*velocity_tbv_kk(nTBV)
	endif
c	modify right boundary when vapour velocity drops below 0.001 ft/s
c	if(vsg.le.0.001.or. mm.gt.0)then
	if(vsg.le.0.)then
	mm=mm+1
	density_do(N)=0
	ie_do(N)=0
	th_a_sg=th_c(N)
	th_b_sg=th_b(N)
	th_s_sg=th_s(N )
	alp(1)=th_c(1)
	th_g(1)=th_s(1)
	do i=2,N-1
	alp(i)=th_c(i)-alp(i-1)*th_b(i)/th_a(i-1)
	th_g(i)=th_s(i)-th_g(i-1)*th_b(i)/th_a(i-1)
	enddo
	alp(N)=th_a_sg-alp(N-1)*th_b_sg/th_a(N-1)
	th_g(N)=th_s_sg-th_g(N-1)*th_b_sg/th_a(N-1)	

	psg=th_g(N)/alp(N)
	pressure_kk=psg
	do i=N-1,1,-1	
	velocity_kk(i)=(th_g(i)-alp(i)*psg)/th_a(i)
	enddo
	velocity_kk(N)=0
	vsg=0
	endif

C	solve density, ie and X ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	do i=1,N
	call derivative(old_aj_kk(i),old_kafa_kk(i),old_pressure_kk(i),
     %	dpdx1,dpdp1,density_temp,dpudx1,dpudp1,ie_temp)
	if(i.eq.1) then
		density_kk(i)=old_density_tt(i)+delta_t/deltaz*
     %	(density_in*velocity_in-density_do(i)*velocity_kk(i))
	else
	density_kk(i)=old_density_tt(i)+delta_t/deltaz*
     %	(density_do(i-1)*velocity_kk(i-1)-density_do(i)*velocity_kk(i))
	endif
	kafa_kk(i)=old_kafa_kk(i)+(density_kk(i)-density_temp-
     %	dpdp1*(pressure_kk(i)-old_pressure_kk(i)))/dpdx1
	
	ie_kk(i)=ie_temp+(kafa_kk(i)-old_kafa_kk(i))*dpudx1+
     %	(pressure_kk(i)-old_pressure_kk(i))*dpudp1	
	enddo

c	tell the phase of flow ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	do i=1,N	
	if(density_kk(i).ge.rhof(pressure_kk(i))) then
	aj_kk(i)=0
			if(old_aj_kk(i).gt.0) then
			kafa_kk(i)=ie_kk(i)/density_kk(i)
			endif
	else if(density_kk(i).le.rhog(pressure_kk(i))) then
	aj_kk(i)=1
			if(old_aj_kk(i).lt.1)then
			kafa_kk(i)=ie_kk(i)/density_kk(i)
			endif
	else
	aj_kk(i)=kafa_kk(i)
			if(kafa_kk(i).le.0)then
			kafa_kk(i)=ie_kk(i)/density_kk(i)
			aj_kk(i)=0
			endif
			if(old_aj_kk(i).eq.0 .or.old_aj_kk(i).eq.1)then
			p=pressure_kk(i)
			aj_kk(i)=(rhof(p)-density_kk(i))/(rhof(p)-rhog(p))
			kafa_kk(i)=aj_kk(i)
			endif
			if(kafa_kk(i).ge.1 .and.aj_kk(i).ge.1) then
			aj_kk(i)=1
			kafa_kk(i)=ie_kk(i)/density_kk(i)
			endif		
	endif
	enddo

c	check convergence of newton iteration ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	error=abs((old_pressure_kk(1)-pressure_kk(1))/old_pressure_kk(1))
	do i=1,N
	error2=abs((old_density_kk(i)-density_kk(i))/old_density_kk(i))
	error3=abs((old_IE_kk(i)-IE_kk(i))/old_IE_kk(i))
	error=max(error,error2,error3)
	enddo

c	do i=1,N
c	zzz=abs((old_density_kk(i)-density_kk(i))/old_density_kk(i))
c	if(error.eq. zzz)then
c	itemp=i
c	endif
c	enddo
c			
	doi=1,N
	error_2(i)=
     %	abs((old_density_kk(i)-density_kk(i))/old_density_kk(i))
	error_3(i)=
     %	abs((old_pressure_kk(i)-pressure_kk(i))/old_pressure_kk(i))	  
	error_4(i)=abs((old_IE_kk(i)-IE_kk(i))/old_IE_kk(i))
	enddo
c
 	if (error.gt.0.005 .and. count.lt.5) then
	goto 2
	else if (error.gt.0.005 .and. count.ge.5) then
	delta_t=delta_t/2.
c
	if(delta_t.lt.1.e-4) write(*,*)'delt_t < e-4 for newton iteration'
c
c		if(delta_t.lt.1.e-2 .and. i_n1.lt.1)  then
c			i_n1=i_n1+1
c			delta_t=0.1
c		endif
		if(delta_t.lt.1.e-3 .and. i_n2.lt.1)  then
			i_n2=i_n2+1
			delta_t=0.1
		endif
	goto 1
	endif
c	i_n1=0
	i_n2=0
c	compute the relative difference bwtween new time value and past time value~~~~~~~~~~~~~~~~~~
	pha=abs((old_pressure_tt(1)-pressure_kk(1))/old_pressure_tt(1))
	do i=1,N
	pha2=abs((old_density_tt(i)-density_kk(i))/old_density_tt(i))
	pha3=abs((old_IE_tt(i)-IE_kk(i))/old_IE_tt(i))
	pha=max(pha,pha2,pha3)
	enddo
c
 	do i=1,N
      pha22_(i)=abs((old_density_tt(i)-density_kk(i))/
     %	old_density_tt(i))
      pha33_(i)=abs
     %	((old_pressure_tt(i)-pressure_kk(i))/old_pressure_tt(i))
      pha44_(i)=abs((old_ie_tt(i)-IE_kk(i))/old_IE_tt(i))
 	enddo
	if(pha.gt.0.05)then
	delta_t=delta_t/2.
c
	if(delta_t.lt.1.e-4) write(*,*)'delt_t < e-4 for pha iteration'
c			if(delta_t.lt.1.e-2 .and. i_p1.lt.1)  then
c			i_p1=i_p1+1
c			delta_t=0.1
c			endif
			if(delta_t.lt.1.e-3 .and. i_p2.lt.1)  then
			i_p2=i_p2+1
			delta_t=0.1
			endif
	goto 1
	endif
c	i_p1=0
	i_p2=0
c.
      time=time+Delta_t
	if(time.gt.Tmax)then
	old_t=delta_t
	Delta_t=delta_t-(time-Tmax)
      time=time-old_t 
	goto 1
      endif

	if(pha.lt.0.001) then
	delta_t=1.2*delta_t
	end if

c
c	modify for chur flow~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	ttt=3000*737.3257
	do i=1,N
	g=density_ave_kk(i)*velocity_kk(i)*3600
		if (g.gt.ttt.and.aj_kk(i).gt.0.and.aj_kk(i).lt.1)then
		x=kafa_kk(i)
		p=pressure_kk(i)
		s_temp=(1-x)*rvc(x,p)
		delta_t_c1=1+(rhof(p)-density_kk(i))/density_kk(i)*s_temp
		delta_t_c2=delta_t_c1+(rhof(p)/density_kk(i)
     %	-x/(1-x))*s_temp
		delta_t_c=delta_t_c1/delta_t_c2
		else
		delta_t_c=1
		endif
	t_temp(i)=abs(deltaz/velocity_kk(i)*delta_t_c)
	enddo
c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	delta_t_temp=t_temp(1)
	do i=2,N
	delta_t_temp=min(delta_t_temp,t_temp(i))
	enddo
	delta_t=min(delta_t,delta_t_temp)
c	delta_t=min(delta_t,delta_t_temp,0.01)
	deltaT=delta_t/3600.

c	do while(int(time*0.1).gt. pp)
c	pp=pp+1
c	write(*,*) time,delta_t,CriticalLength1,psg,flowsg
c	enddo
c
c	write(3,2222) time,psg,delta_t,vsg,kafa_kk(N),velocity_in,
c     %	aj_kk(N)
c	do i=1,N
c	write(1,2222) velocity_kk(i),PRESSURE_kk(I),
c     %	ie_kk(i),kafa_kk(i),aj_kk(i),density_kk(i),qt(i)
c	enddo
c
c	write(4,3333) time,k_adv, k_hdr,k_tcv, p_hdr,
c     %	velocity_in,velocity_sl_kk,velocity_tcv_kk,delta_t
 2222 Format(E14.5E4,6(8x,E14.5E4))	
 3333 Format(2x,e11.4,8(5x,e11.4))
c	close(unit=1)
c	close(unit=3)
c	close(unit=4)
cccc	Temperature, Enthalpy and Mass Distribution added by shen~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
      ICRIT=0
      ICRIT1j=0
      ICRIT1i=0
      SGMass1=0.
      V=DeltaZ*Pi*Ri**2*float(ntubes)
      do j=15,6,-1
      nodes=nodesSG(j)
       if(nodes.gt.0)then  
       i=0
        do while (i.lt.nodes)
        i=i+1
	ii=(13-j)*10+i
	if(aj_kk(ii).eq.0)then
	TSG(i,j)=Temp(ie_kk(ii)/density_kk(ii))
	HSG(i,j)=(ie_kk(ii)+PSG*144./778)/density_kk(ii)
      SGMass1=SGMass1+density_kk(ii)*V

	if(ii .lt. N .and. aj_kk(ii+1) .gt.0.99)then
      ICRIT1j=j
      ICRIT1i=i
	Fraction1=1.
	endif

	else if(aj_kk(ii).eq.1)then
	TSG(i,j)=Tsup(ie_kk(ii)/density_kk(ii),PSG)
	HSG(i,j)=(ie_kk(ii)+PSG*144./778)/density_kk(ii)
	else
	G=density_kk(ii)*velocity_kk(ii)*3600
	rv_3=rv(aj_kk(ii),velocity_kk(ii),PSG,ri,G)
	velocity_g=velocity_kk(ii)+(1-aj_kk(ii))*rhof(PSG)/density_kk(ii)
     %	*rv_3
	velocity_l=velocity_kk(ii)-aj_kk(ii)*rhog(PSG)/density_kk(ii)
     %	*rv_3
	x=abs(aj_kk(ii)*rhog(PSG)*velocity_g)/
     %	(abs(aj_kk(ii)*rhog(PSG)*velocity_g)
     %   +abs((1-aj_kk(ii))*rhof(PSG)*velocity_l))
	TSG(i,j)=Tsat(PSG)
	HSG(i,j)=hf(PSG)+x*hfg(PSG)
c	if (aj_kk(ii).lt.0.99) SGMass1=SGMass1+density_kk(ii)*V
	SGMass1=SGMass1+rhof(PSG)*V*(1-aj_kk(ii))
		if(ii.lt.N) then	
		  if(aj_kk(ii+1).ge.0.99 .and.aj_kk(ii).lt.0.99)then
            ICRIT=1
            ICRIT1j=j
            ICRIT1i=i
		  Fraction1=(0.99-aj_kk(ii))/(aj_kk(ii+1)-aj_kk(ii))
            endif
		 endif
	endif
       enddo
	endif
      end do
c
c	modify for no vapor exists by shen
c	if(aj_kk(N).lt.1)then
	if(aj_kk(N).lt.0.99)then
      ICRIT1j=8
      ICRIT1i=10
	Fraction1=1.
	endif
	if(aj_kk(1).ge.0.99)then
      ICRIT1j=13
      ICRIT1i=1
	Fraction1=0.
	endif	
cddd	end of upgrade ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c.********************************************************						   !Konor
c.																				   !Konor
c.    Turbine Impulse Pressure													   !Konor
c.																				   !Konor
c      Pimpulse=p_hdr-															   !Konor
c     %         KTCV(1)*density_kk(N)*velocity_tcv_kk(1)**2/(2.*gc1)				   !Konor
c.********************************************************						   !Konor
c.																				   !Konor
c.    TES Tap Pressure															   !Konor
c.																				   !Konor
      FlowSteam=density_kk(N)*velocity_kk(N)*AxSG*3600.							   !Konor
      FlowTurbine=FlowSteam*float(nSG)							    		       !Konor
      FlowTurbine=FlowTurbine-FlowAUX1-FlowAUX2*float(nTCV)						   !Konor
c.           																		   !Konor
      VTURB=(FlowTurbine/3600.)/(density_kk(N)*AreaSL*float(nTCV))				   !Konor
      VAUX3=(FlowAUX3/3600.)/(density_kk(N)*AreaSL*float(nTCV))					   !Konor
      VEXH=VTURB-VAUX3															   !Konor
      PTAP=Pcond+KEXH*density_kk(N)*VEXH**2/(2.*gc1)								   !Konor
      Pimpulse=Pcond+																   !Konor
     %         (k_turb0)*density_kk(N)*VTURB**2/(2.*gc1)							   !Konor
c.																				   !Konor
c.********************************************************						   !Konor
c.
c.    Dryout Location
c.
      CriticalLength1=0.
      do j=15,ICRIT1j,-1
      nodes=nodesSG(j)
       if(j.ne.ICRIT1j)then
       CriticalLength1=CriticalLength1+float(nodes)*DeltaZ
       else
         if(ICRIT1i.gt.1)then
         CriticalLength1=CriticalLength1+
     %                   float(ICRIT1i-1)*DeltaZ+
     %                   Fraction1*DeltaZ
         else
         CriticalLength1=CriticalLength1+
     %                   Fraction1*DeltaZ
         endif
       endif
      enddo
c.*********************************************************
c.
c.    Pressure Drop Calculation
c.
      DeltaPFSG1=0.
      DeltaPESG1=0.
      G=FlowSG/(Pi*Ri**2*float(ntubes))
      De=2.*Ri
      do j=15,6,-1
      nodes=nodesSG(j)
       if(nodes.gt.0)then
       i=0
       do while (i.lt.nodes)
       i=i+1
	ii=(13-j)*10+i
	if(aj_kk(ii).eq.0)then
c.
c.       Subcooled Liquid
c.
         Re=G*De/Viscosity(TSG(i,j),PSG)
      Call Colebrook(Re,ffactor)               !Mod7a
c
         DeltaPFSG1=DeltaPFSG1+
     %             (ffactor*DeltaZ/De)*G**2/(2.*density_kk(ii)*gc)
         DeltaPESG1=DeltaPESG1-
     %              density_kk(ii)*DeltaH(j)/float(nodes)
c.
		else if(aj_kk(ii).lt.1)then
c.
c.       Two Phase Mixture
c.
 	rv_3=rv(aj_kk(ii),velocity_kk(ii),PSG,ri,G)
	velocity_g=velocity_kk(ii)+(1-aj_kk(ii))*rhof(PSG)/density_kk(ii)
     %	*rv_3
	velocity_l=velocity_kk(ii)-aj_kk(ii)*rhog(PSG)/density_kk(ii)
     %	*rv_3
	x=abs(aj_kk(ii)*rhog(PSG)*velocity_g)/
     %	(abs(aj_kk(ii)*rhog(PSG)*velocity_g)
     %   +abs((1-aj_kk(ii))*rhof(PSG)*velocity_l))
c
           if(x.le.0.)then
           philosqr=1.
           else 
           philosqr=TPmult(x,G,PSG)
           endif
c.
         Re=G*De/Viscosity(TSG(i,j),PSG)
c
      Call Colebrook(Re,ffactor)            !Mod7a
c
         DeltaPFSG1=DeltaPFSG1+
     %              philosqr*(ffactor*DeltaZ/De)*
     %                       G**2/(2.*rhof(PSG)*gc)
         DeltaPESG1=DeltaPESG1-
     %              density_kk(ii)*DeltaH(j)/float(nodes)
           else
c.                     
c.       Superheated Vapor
c.
           Re=G*De/mug(PSG)
      Call Colebrook(Re,ffactor)            !Mod7a
c
           DeltaPFSG1=DeltaPFSG1+
     %                (ffactor*DeltaZ/De)*G**2/(2.*density_kk(ii)*gc)
           DeltaPESG1=DeltaPESG1-
     %                density_kk(ii)*DeltaH(j)/float(nodes)
c           endif                     
         endif
       enddo
       endif
      enddo
!      write(*,*)'DeltaP Friction SG1=',DeltaPFSG1/144.
!      write(*,*)'DeltaP Elevation SG1=',DeltaPESG1/144.
      DeltaPSG1=DeltaPFSG1+DeltaPESG1
c.
c.**********************************************************     
c.
c.    ******* Steam Generator 2 *********
c
c	SG2 is assummed to behave identical with SG1 by shen
c
      ICRIT2i=ICRIT1i
      SGMass2=SGMass1
	Fraction2=Fraction1
	CriticalLength2=CriticalLength1
      DeltaPFSG2=DeltaPFSG1
      DeltaPESG2=DeltaPESG1
	DeltaPSG2=DeltaPSG1
c
	iminus=0
      do j=19,24
	iminus=iminus+2

		if(j-4-iminus.eq.ICRIT1j)then
	    ICRIT2j=j
		endif

      nodes=nodesSG(j)
       if(nodes.gt.0)then
       i=0
	    do while (i.lt.nodes)
		i=i+1
		TSG(i,j)=TSG(i,j-4-iminus)
		HSG(i,j)=HSG(i,j-4-iminus)	
  		enddo
	 endif
	enddo
c
      Return
      end
c.
c.    Function Subprogram to calculate Pump Force in Loop 1
c.
      Function DeltaPp1(Flow1,Deltat,rho)
      Real Inertia
      common/RCPs/QR,HeadR,TorqueR,omegaR,Inertia,npumps1,npumps2,
     %            omega1,omega2
      Common/Trips/ITRIPRCP1,ITRIPRCP2,ITRIPRX,ITRIPFP
      pi=3.1415926
      gc=4.17e8
      alpha=omega1/omegaR
      Q=Flow1/(rho*npumps1)
      v=Q/QR
      Head=0.
!      write(*,*)'alpha=',alpha,'v=',v,'rho=',rho
      If(ITRIPRCP1.eq.1)then
      beta=alpha**2*(1.37-1.28*(v/alpha)+1.61*(v/alpha**2)
     %               -0.7*(v/alpha**3))
      if(beta.lt.0.)beta=0.
      Torque=TorqueR*beta
      omega1=omega1-Torque*(Deltat)*gc/(2.*pi*Inertia*60.)
      alpha=omega1/omegaR
c. 	write(14,*)'Torque=',Torque
      endif
      if(alpha.gt.0.)then
      h=alpha**2*(1.8-0.3*(v/alpha)+0.35*(v/alpha**2)
     %            -0.85*(v/alpha**3))
      if(h.gt.0.)Head=HeadR*h
      DeltaPp1=rho*Head
      else
      DeltaPp1=0.
      endif
      Return
      End
c.
c.    Function Subprogram to calculate Pump Force in Loop 2
c.
      Function DeltaPp2(Flow2,Deltat,rho)
      Real Inertia
      common/RCPs/QR,HeadR,TorqueR,omegaR,Inertia,npumps1,npumps2,
     %            omega1,omega2
      Common/Trips/ITRIPRCP1,ITRIPRCP2,ITRIPRX,ITRIPFP
      pi=3.1415926
      gc=4.17e8
      alpha=omega2/omegaR
      Q=Flow2/(rho*npumps2)
      v=Q/QR
      Head=0.
      If(ITRIPRCP2.eq.1)then
      beta=alpha**2*(1.37-1.28*(v/alpha)+1.61*(v/alpha**2)
     %               -0.7*(v/alpha**3))
      if(beta.lt.0.)beta=0.
      Torque=TorqueR*beta
      omega2=omega2-Torque*Deltat*gc/(2.*pi*Inertia*60.)
      alpha=omega2/omegaR
      endif
      if(alpha.gt.0.)then
      h=alpha**2*(1.8-0.3*(v/alpha)+0.35*(v/alpha**2)
     %            -0.85*(v/alpha**3))
      if(h.gt.0.)Head=HeadR*h
      DeltaPp2=rho*Head
      else
      DeltaPp2=0.
      endif
      Return
      End
c.
c.    Function Subprogram to calculate fluid density as a function of
c.    temperature
c.
      Function density(T)
c.
c.    Density of subcooled liquid
c.
      a0=226.4619456276
      a1=-.9178760497
      a2=.0016639435
      a3=-1.076e-6
      if(T.le.653.)then
      density=a0+a1*T+a2*T**2+a3*T**3
      else
      density=37.06
      endif
      Return
      End
c.
c.    Function Subprogram to calculate convective heat transfer coefficient
c.    using the Dittus-Boelter Correlation
c.
      Function hcDB(G,De)
      Real mu,k
      Common/FluidProperties/rho,Cp,mu,k
      Re=abs(G*De/mu)
      Pr=Cp*mu/k
        if(Re.gt.0.)then
        hcDB=(k/De)*0.023*Re**.8*Pr**.4
        else
        hcDB=0.
        endif
      Return
      End
c.
c.    Function Subprogram to calculate convective heat transfer coefficient
c.    using the Weisman Correlation
c.
      Function hcW(G,De,P_D)
      Real mu,k
      Common/FluidProperties/rho,Cp,mu,k
      Pi=3.1415926
      C=0.042*P_D-0.024
      Re=abs(G*De/mu)
      Pr=Cp*mu/k
        if(Re.gt.0.)then
        hcW=(k/De)*C*Re**.8*Pr**(1./3.)
        else
        hcW=0.
        endif
      Return
      End
c.
c.    Function Subprogram to calculate convective heat transfer coefficient
c.    normal to tube banks
c.
      Function hc(G)
      Real mu,k,n,kw
      Common/FluidProperties/rho,Cp,mu,k
      Common/SGUA/Ri,Ro,kw,S,Fouling,DeSG,AxSG,ITYPESG
      D=2.*Ro
      C=0.57
      n=0.555
      Gmax=G*S/(S-D)
      Re=abs(Gmax*D/mu)
      Pr=Cp*mu/k
        if(Re.gt.0.)then
        hc=(k/D)*C*Re**n*Pr**.33
        else
        hc=0.
        endif
      Return
      End
c.
c.    Function Subprogram to calculate friction factor by the Blasius
c.    Equation
c.
      Function F(G,De)
      Real mu,k
      Common/FluidProperties/rho,Cp,mu,k
      Re=abs(G*De/mu)
      if(Re.gt.100.)then
        if(Re.lt.2300.)then
        F=64./Re
        elseif(Re.lt.3000.)then
        fl0=64./2300.
        ft0=0.3164/(3000.)**0.25
        F=fl0+(Re-2300.)*(ft0-fl0)/700.
        elseif(Re.lt.51090.)then
        F=0.3164/Re**0.25
        else
        F=0.184/Re**.2
        end if
      else
      F=0.64
      end if
      Return
      End
C.      SUBROUTINE TO SOLVE LINEAR SVSTEMS OF EQUATIONS By
C.	GAUSSIAN ELIMINATION WITH BACK SUBSTITUTION AND
C	PARTIAL PIVOTING
	SUBROUTINE GAUSS(A,B,X,N)
	DIMENSION A(26,26),B(26),X(26)
C.	BEGIN LOOP ON PIVOT ELEMENT
C.
        DO 10 K=1,N
C	SEARCH COLUMN K FOR MAXIMUM PIVOT ELEMENT
        TEST=0.
	DO 20 I=K,N
	IF (ABS(A(I,K)).GT.TEST)THEN
	TEST=ABS(A(I,K))
	ISTORE=I
	END IF
 20	CONTINUE
C	INTERCHANGE ROW K AND ROW ISTORE
	IF(ISTORE.NE.K)THEN
	DO 30 J=K,N
        ASTORE=A(K,J)
        A(K,J)=A(ISTORE,J)
        A(ISTORE,J)=ASTORE
 30	CONTINUE
	BSTORE=B(K)
	B(K)=B(ISTORE)
	B(ISTORE)=BSTORE
	END IF
	PIVOT=A(K,K)
        A(K,K)=1.
C       DIVIDE ROW K By THE PIVOT ELEMENT
	B(K)=B(K)/PIVOT
        DO 40 J=K+1,N
 40	A(K,J)=A(K,J)/PIVOT
C	ZERO COLUMN K
        DO 50 I=K+1,N
	AMULT=A(I,K)
        A(I,K)=0.
        IF(AMULT.Eq.0.)GO TO 50
        B(I)=B(I)-AMULT*B(K)
        DO 55 J=K+1,N
 55	A(I,J)=A(I,J)-AMULT*A(K,J)
 50	CONTINUE
 10	CONTINUE
C	BACK SUBSTITUTION STEP
	X(N)=B(N)
        DO 60 I=N-1,1,-1
        SUM=0.
        DO 70 J=I+1,N
 70	SUM=SUM+X(J)*A(I,J)
	X(I)=B(I)-SUM
 60	CONTINUE
	RETURN
        END
c.
c.    Function Subprogram to Calculate Enthalpy
c.
      Function Enthalpy(T,P)
      Enthalpy=uliq(T)+(P/density(T))*144./778.
      End
c.
c.    Function to compute Specific Heat
c.
      Function Cpl(T,P)
      Dimension a(3),b(3),aa(3),bb(4)
      Data a/0.98850267,3.11434479e-4,9.79793383e-27/
      Data b/1.00787645e-4,0.01223534,0.08836906/
      Data aa/0.03500856,7.40539427e-4,-1.30297916e-6/
      Data bb/0.41844219,-7.71336906e-3,3.23610762e-5,-3.94022105e-8/
      DeltaT=Tsat(P)-T
      Cpsat=0.
      Do i=1,3
         Cpsat=Cpsat+a(i)*exp(b(i)*T)
      enddo
      R=(aa(1)+aa(2)*DeltaT+aa(3)*DeltaT**2)*
     %  (bb(1)+bb(2)*T+bb(3)*T**2+bb(4)*T**3)
      Cpl=Cpsat+R
      Return
      End
c.
c.    Function Subprogram to Calculate Liquid Internal Energy
c.
      Function uliq(T)
      Dimension a(6)
      Data a /-42.1658015,1.3305375,-3.0673856e-3,1.1675009e-5,
     %        -1.9395597e-8,1.2214095e-11/
      F(u)=T-Temp(u)
c.
      u0=0.
      do k=1,6
      u0=u0+a(k)*T**(k-1)
      enddo
      epsilon=1.
       dowhile(epsilon.gt.1.e-4)
       Deltau=abs(0.001*u0)
       dFdu=(F(u0+Deltau)-F(u0-Deltau))/(2.*Deltau)
       Delu=F(u0)/dFdu
       u=u0-Delu
       epsilon=abs(Delu/u0)
       u0=u
       enddo
       uliq=u
c.
      Return
      End
c.
c.    Function Subprogram to Calculate Temperature from
c.    Liquid Internal Energy
c.
      Function Temp(u)
      Dimension a(6)
      Data a /32.180814,.9858671,1.8576575e-4,-8.0930376e-7,
     %        1.0831764e-9,-8.1894562e-13/
c.
      Temp=0.
      do, k=1,6
      Temp=Temp+a(k)*u**(k-1)
      end do
c.
      Return
      End
c.
c.    Function Subprogram to Calculate the derivative of
c.    Temperature with respect to Liquid Internal Energy
c.
      Function dTdu(u)
      Dimension a(6)
      Data a /32.180814,.9858671,1.8576575e-4,-8.0930376e-7,
     %        1.0831764e-9,-8.1894562e-13/
c.
      dTdu=0.
      do, k=2,6
      dTdu=dTdu+(k-1)*a(k)*u**(k-2)
      end do
c.
      Return
      End
c.
c.    Function to compute Liquid Viscosity
c.
      Function Viscosity(T,P)
      Dimension a(3),b(3),aa(4),bb(4)
      Data a/3.69971196,4.27115194,0.75003508/
      Data b/-0.01342834,-0.03890983,-2.19455284e-3/
      Data aa/8.52917235e-4,-4.17979848e-5,2.6043459e-7,-2.20531928e-11/
      Data bb/-1.13658775,0.01495184,-2.86548888e-5,2.17440064e-9/
      DeltaT=Tsat(P)-T
      Vsat=0.
      Do i=1,3
         Vsat=Vsat+a(i)*exp(b(i)*T)
      enddo
      R=(aa(1)+aa(2)*DeltaT+aa(3)*DeltaT**2+aa(4)*DeltaT**3)*
     %  (bb(1)+bb(2)*T+bb(3)*T**2+bb(4)*T**3)
      Viscosity=Vsat+R
      Return
      End
c.
c.    Function to compute saturated vapor viscosity
c.
      Function Mug(P)
      Real Mug
      Dimension a(4)
      Data a/0.01790175,5.22632124e-5,4.52957731e-19,0.05532552/
      T=Tsat(P)
      Mug=a(1)+a(2)*T+a(3)*exp(a(4)*T)
      Return
      End
c.
c.    Function to compute saturated vapor Specific Heat
c.
      Function Cpg(P)
      Dimension a(8)
      Data a/-0.93789913,6.21497845e-3,-9.96950004e-5,7.66745404e-7,
     %       -3.04253809e-9,6.60113915e-12,-7.35804327e-15,
     %        3.29909649e-18/
      T=Tsat(P)
      sum=0.
      do i=1,8
         sum=sum+a(i)*T**(i-1)
      enddo
      Cpg=exp(sum)
      Return
      end
c.
c.    Function to compute saturated vapor thermal conductivity
c.
      Function kg(P)
      real kg
      Dimension a(8)
      Data a/7.44183990e-3,1.25392582e-4,-1.82051645e-6,1.46805191e-8,
     %      -6.13654527e-11,1.38802910e-13,-1.60219619e-16,
     %       7.44710160e-20/
      T=Tsat(P)
      sum=0.
      do i=1,8
         sum=sum+a(i)*T**(i-1)
      enddo
      kg=sum
      Return
      end

c.
c.	Function to compute saturated vapor specific volume
c.
      Function vg(P)
      Dimension a(7),b(7)
      data a/5931.557,1142.2341,171.5671,41.76546,
     %11.64542,3.264609,.8898603/
      data b/11.60044,1.990131,.3299698,.0806798,
     %.0200894,4.596498e-3,7.761257e-4/
       sum=0.
        do i=1,7
           sum=sum+a(i)*exp(-b(i)*P)
        enddo
       vg=sum
      Return
      End
c.
c.    Function to compute the density of a saturated vapor
c.
      Function rhog(P)
      rhog=1./vg(P)
      Return
      End
c.
c.	Function to compute saturated liquid specific volume
c.
      Function vf(P)

      Dimension a(8)
      data a/.0158605,1.436698e-6,-6.546245e-10,1.2621567e-12,
     %-6.106028e-16,1.17416e-19,3.004294e-4,.3809203/
      vf=a(1)+a(2)*P+a(3)*P**2+a(4)*P**3+a(5)*P**4+a(6)*P**5
     %  +a(7)*P**a(8)
      Return
      End
c.
c.    Function to compute the density of a saturated liquid
c.
      Function rhof(P)
      rhof=1./vf(P)
      Return
      End
c.
c.    Function to compute the difference between saturated vapor and
c.    saturated liquid specific volume
c.
      Function vfg(P)
      vfg=vg(P)-vf(P)
      Return
      end
c.
c.	Function to compute Thermal Conductivity of Water
c.
      Function kl(T,P)
      Real Ksat,kl
      Dimension a(6),aa(6),bb(6)
      Data a/0.28956598,9.98373531e-4,-2.76514034e-6,1.31610616e-9,
     %       3.99581573e-12,-5.18550975e-15/
      Data aa/-3.51256646e-3,6.04273366e-5,2.48976537e-7,3.85754267e-11,
     %        -1.59857317e-13,2.20172921e-16/
      Data bb/-0.01305876,9.88477177e-4,-5.52334508e-6,6.66724984e-9,
     %         3.03459927e-11,-3.78351489e-14/
      DeltaT=Tsat(P)-T
      Ksat=0.
      Do i=1,6
         Ksat=Ksat+a(i)*T**(i-1)
      enddo
      R=(aa(1)+aa(2)*DeltaT+aa(3)*DeltaT**2+aa(4)*DeltaT**3+
     %   aa(5)*DeltaT**4+aa(6)*DeltaT**5)*
     %  (bb(1)+bb(2)*T+bb(3)*T**2+bb(4)*T**3+bb(5)*T**4+bb(6)*T**5)
      kl=Ksat+R
      Return
      End
c.
c.	Function to compute saturated liquid enthalpy
c.
      Function hf(P)
      Dimension a(8)
      data a/-158.951133,.1064128,-5.990278e-5,3.9394998e-8,
     %-1.3013275e-11,1.7895135e-15,227.89663,.1464544/
      hf=a(1)+a(2)*P+a(3)*P**2+a(4)*P**3+a(5)*P**4+a(6)*P**5
     %  +a(7)*P**a(8)
      Return
      End
c.
c.	Function to compute saturated vapor enthalpy
c.
      Function hg(P)
      Dimension a(8)
      data a/982.80863,-.0693143,1.042881e-5,-1.091194e-8,
     %4.079445e-12,-8.0123869e-16,123.10181,.1172116/
      hg=a(1)+a(2)*P+a(3)*P**2+a(4)*P**3+a(5)*P**4+a(6)*P**5
     %  +a(7)*P**a(8)
      Return
      End
c.
c.	Function to compute latent heat of vaporization
c.
      Function hfg(P)
      hfg=hg(P)-hf(P)
      Return
      End
c.
c.    Function to compute saturated liquid entropy		    !Mod05
c.
      Function sf(P)
      Dimension a(8)
      data a/-.5864158,8.7429585e-5,-6.0398601e-8,4.022512e-11,
     %-1.3327989e-14,1.8065282e-18,.71821152,.08297097/
      sf=a(1)+a(2)*P+a(3)*P**2+a(4)*P**3+a(5)*P**4+a(6)*P**5
     %  +a(7)*P**a(8)
      Return
      End
c.
c.    Function to compute saturated vapor entropy             !Mod05
c.
      Function sgs(P)
      Dimension a(8)
      data a/4.9191672,1.58394e-4,-2.7692662e-7,2.001747e-10,
     %-6.8316294e-14,8.5122981e-18,-2.934533,.02760756/
      sgs=a(1)+a(2)*P+a(3)*P**2+a(4)*P**3+a(5)*P**4+a(6)*P**5
     %  +a(7)*P**a(8)
      Return
      End
c.
      Function sfg(P)
      sfg=sgs(P)-sf(P)
      return
      end
c.
c.    Function to compute superheated vapor entropy           !Mod05
c.
      Function sv(h,P)
      Dimension a(7)
      data a/9.8995e-3,-3.2439e-5,1.203e-3,2.6076e-8,
     %      -2.9559e-6,-8.6226e-12,9.5261e-9/
      dh=h-hg(P)
      ds=a(1)+a(2)*P+a(3)*dh+a(4)*P**2+a(5)*dh**2+a(6)*P**3+a(7)*dh**3
      sv=sgs(P)+ds
      Return
      End
c.
c.	Function to compute saturation temperature
c.
      Function Tsat(P)
      Dimension a(8)
      data a/-127.45099,.0736883,-5.127918e-5,2.941807e-8,
     %-8.968781e-12,1.066619e-15,228.4795,.1463839/
      Tsat=a(1)+a(2)*P+a(3)*P**2+a(4)*P**3+a(5)*P**4+a(6)*P**5
     %  +a(7)*P**a(8)
      Return
      End
c.
c.    Function to compute surface tension
c.
      Function sigma(P)
      Dimension a(6)
      data a/5.244774e-3,1.409364e-6,-3.573894e-8,1.087337e-10,
     %       -1.700704e-13,1.000511e-16/
      T=Tsat(P)
      sigma=0.
       do i=1,6
        sigma=sigma+a(i)*T**(i-1)
       enddo
      Return
      End
c.
c.    Function to calculate the specific heat of superheated steam
c.
      Function Cpv(T)
      av=25.516998
	bv=-.1332852
      cv=2.5092745e-4
      dv=-2.1222402e-7
      ev=6.780595e-11
      Cpv=av+bv*T+cv*T**2+dv*T**3+ev*T**4
      Return
      end
c.
c.    Subroutine to compute critical heat flux in a uniformly
c.    heated channel using the Bowring Correlation
c.
      Subroutine CHFB(De,G,P,x,qcrit)
      real n
      D=De*0.3048
      Gsi=G*4.8824/3600.
      Psi=P*6.8946e-3
      hfgs=hfg(P)
	hfgsi=hfgs*2.3255e3
      pr=0.145*Psi
      n=2.0-.5*pr
c.
      if(pr.lt.1.)then
      F1=(pr**18.942*exp(20.89*(1.-pr))+0.917)/1.917
      F2=F1/((pr**1.316*exp(2.444*(1.-pr))+0.309)/1.309)
      F3=(pr**17.023*exp(16.658*(1.-pr))+0.667)/1.667
      F4=F3*pr**1.649
      else
      F1=pr**(-0.368)*exp(0.648*(1.-pr))
      F2=F1/(pr**(-0.448)*exp(0.245*(1.-pr)))
      F3=pr**0.219
      F4=F3*pr**1.649
      endif
c.
      B=D*Gsi/4.
      A=(2.317*hfgsi*B*F1)/(1.+0.0143*F2*sqrt(D)*Gsi)
      C=0.077*F3*D*Gsi/(1.+0.347*F4*(Gsi/1356.)**n)
      qcrit=(A-B*hfgsi*x)/C
      qcrit=qcrit*3171.2e-4
      Return
      End
c.
c.    Subroutine to compute boiling heat transfer coefficients 
c.    using the Chen Correlation
c.
      Subroutine Chen(P,x,G,De,Tw,Hlo,H2p)
      Real muf,mug,kf,kl
      Common/FluidProperties/rho,Cpf,muf,kf
c.
      gc=4.17e8
      CapJ=778.
c.
c.    Fluid Properties
c.
      T=Tsat(P)
      rho=rhof(P)
      muf=Viscosity(T,P)
      Cpf=Cpl(T,P)
      kf=kl(T,P)
c.
c.    Single Phase Heat Transfer Coefficient
c.
      if(x.gt.0. .and. x .lt.1.)then
c.
c.    Turbulent Martinelli Parameter
c.
      Xtt=((1.-x)/x)**0.9*(rhog(P)/rhof(P))**0.5*(muf/mug(P))**0.1
c.
c.     Reynolds Number Factor
c.
         if(1./Xtt.le.0.1)then
         F=1.
         else
         F=2.35*(0.213+1./Xtt)**0.736
         endif
      Re=G*(1.-x)*De*F**1.25/muf
      Hlo=hcDB(G*(1.-x),De)*F
      else
      F=1.
      Re=G*De/muf
      Hlo=hcDB(G,De)
      endif
c.
c.    Nucleate Boiling Heat Transfer Coefficient
c.
        If(Tw.gt.T)then
c.
c.      Suppression Factor
c.
        S=1./(1.+2.53e-6*Re**1.17)
c.
        Top=kf**0.79*Cpf**0.45*rhof(P)**0.49*gc**0.25
        Bottom=sigma(P)**0.5*muf**0.29*hfg(P)**0.24*rhog(P)**0.24
        Term=(hfg(P)*CapJ/((T+460.)*vfg(P)))**0.75
c.
        H2p=0.00122*(Top/Bottom)*Term*(Tw-T)**0.99*S
        else
        H2p=0.
        endif
c.
      Return
      End
c.
c.	Subroutine to calculate overall heat transfer coefficients 
c.	for the steam generators
c.
      Subroutine UASG(FlowP,FlowSG,AxP,L,Tp,Pp,Tsec,Ps,
     %                hSG,ntubes,UA,aj,ii)
      Real L																			
      Real mu,mug
      Real kw,k,kg,kl
c
	real pressure_kk(60),velocity_KK(60),density_kk(60)
	real kafa_kk(60),ie_kk(60),aj_kk(60)
c
      Common/SGUA/Ri,Ro,kw,S,Fouling,DeSG,AxSG,ITYPESG
      Common/FluidProperties/rho,Cp,mu,k
	common /SGdata/ velocity_kk,pressure_kk,ie_kk,
     %	kafa_kk,aj_kk,density_kk
c	
	ICRIT=0
      Pi=3.1415926
      Effntubes=float(ntubes)
      Ai=2.*Pi*Ri*L*Effntubes
      Ao=2.*Pi*Ro*L*Effntubes
      Ts=Tsat(Ps)
c
	G2=density_kk(ii)*velocity_kk(ii)*3600.
	rv_sg=rv(aj_kk(ii),velocity_kk(ii),ps,ri,G2)
	velocity_g=velocity_kk(ii)+(1-aj_kk(ii))*rhof(ps)/density_kk(ii)
     %	*rv_sg
	velocity_l=velocity_kk(ii)-aj_kk(ii)*rhog(Ps)/density_kk(ii)
     %	*rv_sg
	x=abs(aj_kk(ii)*rhog(Ps)*velocity_g)/
     %	(abs(aj_kk(ii)*rhog(Ps)*velocity_g)
     %   +abs((1-aj_kk(ii))*rhof(PSG)*velocity_l))
c
c.    *******************************************************
c.
c.    Primary Side Heat Transfer Coefficient
c.
      G=abs(Flowp/Axp)
      if(G.gt.0.)then
      rho=density(Tp)
      Cp=Cpl(Tp,Pp)
      k=kl(Tp,Pp)
      mu=Viscosity(Tp,Pp)
c.
        if(ITYPESG.eq.1)then
         hprim=hc(G)
         Aprim=Ao
         Asec=Ai
        elseif(ITYPESG.eq.2)then
         hprim=hcDB(G,2.*Ri)
         Aprim=Ai
         Asec=Ao
        endif
c.
      UA1=1./(1./(hprim*Aprim)+1./(2.*Pi*Kw*L*Effntubes)*alog(Ro/Ri))
  
c.
c.    *******************************************************
c.
c.    Secondary Side Heat Transfer Coefficient
c.
      G=FlowSG/AxSG
	if(aj.gt.0.99)then
c.
c.    Single Phase Vapor Heat Transfer Coefficient
c.
      rho=rhog(Ps)
      Cp=Cpg(Ps)
      k=kg(Ps)
      mu=Mug(Ps)
      hsec=hcDB(G,DeSG)
c
      old_hci2=hsec
	endif
c
	if(aj.lt.1)then
c.
      rho=density(Tsec)
      Cp=Cpl(Tsec,Ps)
      k=kl(Tsec,Ps)
      mu=Viscosity(Tsec,Ps)
      hsec=hcDB(G,DeSG)
      Tw=(Tsec+UA1/(hsec*Asec)*Tp)/(1.+UA1/(hsec*Asec))
c
        if(Tw.gt.Ts)then
c.
c.      Heat Transfer Coefficient by Chen Correlation
c.
c.      Iterate on Wall Temperature
c.
        Tw=Ts+3.
        DeltaTw=Tw
        Icount=0
          Do While((Icount.le.10).and.(abs(DeltaTw/Tw).gt.1.e-4))
          Tw0=Tw
          Call Chen(Ps,x,G,DeSG,Tw0,Hlo,H2p)
          FTw0=Tw0-(UA1*Tp+Hlo*Asec*Tsec+H2p*Asec*Ts)/
     %             (UA1+Hlo*Asec+H2p*Asec)
          DTw=0.001*Tw0
          Call Chen(Ps,x,G,DeSG,Tw0+DTw,Hlo,H2p)
          FTw=Tw0+DTw-(UA1*Tp+Hlo*Asec*Tsec+H2p*Asec*Ts)/
     %                (UA1+Hlo*Asec+H2p*Asec)
          DFTwDTw=(FTw-FTw0)/DTw
          DeltaTw=-FTw0/DFTwDTw
          Tw=Tw0+DeltaTW
          Icount=Icount+1
          enddo
c.
        if(Icount.gt.10)then
        write(*,*)'Iterations exceeded in Chen'
        endif
c.
        Call Chen(Ps,x,G,DeSG,Tw,Hlo,H2p)
c.
c.	  Effective Boiling Heat Transfer Coefficient
c.
        hsec=(Hlo*(Tw-Tsec)+H2p*(Tw-Ts))/(Tw-Tsec)
        endif
	old_hci1=hsec
      endif
c.
	if(aj.gt.0.99 .and. aj.lt.1)then
	hsec=old_hci1+(old_hci2-old_hci1)*(aj-0.99)/0.01
	endif
c.***********************************************************
c.
c.    Overall Heat Transfer Coefficient
c.
      UA=(1.-Fouling)/(1./UA1+1./(hsec*Asec))
c.
      else
      UA=0.
      endif
c.
      Return
      End
c.
c.    Subroutine to find the internal energy of a superheated vapor
c.
      Subroutine uv(h,P,u1,IFLAGU)
      F1(u1)=u1+(P/rhovsup(u1,P))*144./778.-h
      icount=0
      err=1.
      a=ug(P)
      delu=150.
      b=a+delu
      u1=a
      IFLAGU=1
      if(F1(a)*F1(b).lt.0.)then
      u1=a
      do while(err.gt.1.e-5.and.icount.lt.20)
      icount=icount+1
c.
      dF1du1=1.-(P/rhovsup(u1,P)**2)*(144./778.)*drhovsupdu(u1,P)
c.
c.
      delu=-F1(u1)/dF1du1
      err=abs(delu/u1)
      u=u1+delu
      if(u.gt.b.or.u.lt.a)u=(a+b)/2.     
        if(F1(a)*F1(u).gt.0.)then
        a=u
        else
        b=u
        endif
      u1=u
      enddo
      if(icount.lt.20)IFLAGU=0
      endif
      Return
      end
c.
c.    Subroutine to find the Temperature of a subcooled liquid
c.
      Function Tliq(h,P)
      F1(T1)=Enthalpy(T1,P)-h
      icount=0
      err=1.
      a=35.
      b=Tsat(P)
      T1=a
      if(F1(a)*F1(b).lt.0.)then
      T1=a
      do while(err.gt.1.e-5.and.icount.lt.20)
      icount=icount+1
c.
      DeltaT1=0.001*T1
      dF1dT1=(F1(T1+DeltaT1)-F1(T1-DeltaT1))/(2.*DeltaT1)
c.
c.
      delT=-F1(T1)/dF1dT1
      err=abs(delT/T1)
      T=T1+delT
      if(T.gt.b.or.T.lt.a)T=(a+b)/2.     
        if(F1(a)*F1(T).gt.0.)then
        a=T
        else
        b=T
        endif
      T1=T
      enddo
      Tliq=T1
      else
      Tliq=Tsat(P)
      endif
      Return
      end
c.
c.	Function Subprogram to calculate Temperature of a Superheated Vapor
c.	from Internal Energy and Pressure
c.
      Function Tsup(u,P)
      Dimension a(5),b(5),c(5)
      Data a/-8.07262872,-2.13858162e-3,7.15709133e-7,11.04088274,
     %       -7.31047017e-3/
      Data b/0.49992610,9.31975007e-6,-4.39884878e-9,-0.50042049,
     %       -3.12926214e-4/
      Data c/-1.99999631,-1.43082818e-8,7.77451433e-12,1.99999571,
     %       -4.60121270e-8/
c.
      a0=a(1)+a(2)*P+a(3)*P**2+a(4)*P**a(5)
      b0=b(1)+b(2)*P+b(3)*P**2+b(4)*P**b(5)
      c0=c(1)+c(2)*P+c(3)*P**2+c(4)*P**c(5)
c.
      Delu=u-ug(P)
c.
      Tsup=Tsat(P)+a0*Delu+b0*Delu**2+c0*Delu**3
      Return
      End
c.
c.	Function to compute saturated vapor internal energy
c.
      Function ug(P)
      Dimension a(8)
      data a/961.57632930,-0.06346313,2.69645643e-5,-2.46758641e-8,
     %       9.45803668e-12,-1.53574346e-15,82.19290877,0.13028136/
      ug=a(1)+a(2)*P+a(3)*P**2+a(4)*P**3+a(5)*P**4+a(6)*P**5
     %  +a(7)*P**a(8)
      Return
      End
c.
c.	Function to compute density of a superheated vapor
c.
      Function rhovsup(u,P)
      Dimension a(3),b(4)
      Data a/-1.29244509e-4,1.660071081,0.118866194/
      Data b/3.03597094e-7,1.909267903e-5,-0.026492255,0.0260077262/
      delu=u-ug(P)
      a0=a(1)+a(2)/P+a(3)/P**2
      b0=b(1)+b(2)/P+b(3)/P**2+b(4)/P**3
      v=vg(P)+a0*delu+b0*delu**2
      rhovsup=1/v
      Return
      End
c.
c.    Function to compute the derivative of superheated vapor density 
c.    with respect to internal energy
c.
      Function drhovsupdu(u,P)
      Dimension a(3),b(4)
      Data a/-1.29244509e-4,1.660071081,0.118866194/
      Data b/3.03597094e-7,1.909267903e-5,-0.026492255,0.0260077262/
      delu=u-ug(P)
      a0=a(1)+a(2)/P+a(3)/P**2
      b0=b(1)+b(2)/P+b(3)/P**2+b(4)/P**3
      v=vg(P)+a0*delu+b0*delu**2
c.
      dvdu=a0+2.*b0*delu
      drhovsupdu=(-1./v**2)*dvdu
      Return
      End
c.   
c.	Function to compute the two phase multiplier using Jones flow
c.	correction
c.     	
      Function TPmult(x,G,P)
      if(x.le.0.)then
         Tpmult=1.
      else
         if(G/1.e6.le.0.7)then
            term=1.36+0.0005*P+0.1*(G/1.e6)-0.000714*P*(G/1.e6)
         else
            term=1.26-0.0004*P+0.119*(1.e6/G)+0.00028*P*(1.e6/G)
         end if
         TPmult=term*(1.2*(rhof(P)/rhog(P)-1.)*x**0.824)+1.0
      endif
      Return
      End
c.
c.    Subroutine to compute void fraction using the Zuber-Findlay Correlation
c.
      Subroutine Zuber_Findlay(x,P,G,alpha)
c.
      Co=1.13
      rhol=rhof(P)
      rhov=rhog(P)
      gc=4.17e8
      Vgj=1.41*(sigma(P)*gc*gc*(rhol-rhov)/rhol**2)**.25
c.
      alpha=Co*(1.+(rhov/rhol)*(1.-x)/x)+rhov*Vgj/(G*x)
      alpha=1./alpha
c.
      Return
      End

c	functions added by shen
c.	Function to compute saturated liquid internal energy

      Function uf(P)
      Dimension a(8)
      data a/-158.61531184,0.10213234,-5.88930771e-5,3.77381711e-8,
     %-1.22429068e-11,1.65122388e-15,227.55166589,0.14666680/
      uf=a(1)+a(2)*P+a(3)*P**2+a(4)*P**3+a(5)*P**4+a(6)*P**5
     %  +a(7)*P**a(8)
      Return
      End
c.
c.	Function to compute the derivative of saturated liquid
c.	internal energy with respect to pressure
c.
      Function dufdP(P)
      Dimension a(8)
      data a/-158.61531184,0.10213234,-5.88930771e-5,3.77381711e-8,
     %-1.22429068e-11,1.65122388e-15,227.55166589,0.14666680/
      dufdP=a(2)+2.*a(3)*P+3.*a(4)*P**2+4.*a(5)*P**3+5.*a(6)*P**4
     %  +a(8)*a(7)*P**(a(8)-1.)
      Return
      End


c.	Function to compute the derivative of saturated vapor 
c.	internal energy with respect to pressure
c.
      Function dugdP(P)
      Dimension a(8)
      data a/961.57632930,-0.06346313,2.69645643e-5,-2.46758641e-8,
     %       9.45803668e-12,-1.53574346e-15,82.19290877,0.13028136/
      dugdP=a(2)+2.*a(3)*P+3.*a(4)*P**2+4.*a(5)*P**3+5.*a(6)*P**4
     %  +a(8)*a(7)*P**(a(8)-1.)
      Return
      End
c.
c.    Function to compute difference between saturated liquid and 
c.    saturated vapor internal energies    
c.
      Function ufg(P)
      ufg=ug(P)-uf(P)
      Return
      End
c.
c.	Function to compute derivative of latent heat of vaporization
c.	with respect to pressure
c.
      Function dufgdP(P)
      dufgdP=dugdP(P)-dufdP(P)
      Return
      End

c.    Function to compute saturation pressure from temperature
c.
      Function Psat(T)
c.
c.    Spline coefficients
c.
      a0=-4.2783969
      b0=0.1700619
      c0=-1.8445571e-3
      d0=6.8826857e-6
      d1=2.1727190e-5
      d2=3.5465308e-5
      d3=8.4908055e-5
      T1=262.9033023
      T2=441.5206305
      T3=602.5002447
c.
      a1=a0+b0*T1+c0*T1**2+d0*T1**3
      b1=b0+2.*c0*T1+3.*d0*T1**2
      c1=c0+3.*d0*T1
c.
      a2=a1+b1*(T2-T1)+c1*(T2-T1)**2+d1*(T2-T1)**3
      b2=b1+2.*c1*(T2-T1)+3.*d1*(T2-T1)**2
      c2=c1+3.*d1*(T2-T1)
c.
      a3=a2+b2*(T3-T2)+c2*(T3-T2)**2+d2*(T3-T2)**3
      b3=b2+2.*c2*(T3-T2)+3.*d2*(T3-T2)**2
      c3=c2+3.*d2*(T3-T2)
c.
      if(T.lt.T1)then
      Psat=a0+b0*T+c0*T**2+d0*T**3
      elseif(T.lt.T2)then
      Psat=a1+b1*(T-T1)+c1*(T-T1)**2+d1*(T-T1)**3
      elseif(T.lt.T3)then
      Psat=a2+b2*(T-T2)+c2*(T-T2)**2+d2*(T-T2)**3
      else
      Psat=a3+b3*(T-T3)+c3*(T-T3)**2+d3*(T-T3)**3
      endif      
c.
      Return
      end

c.	Function to compute derivative of saturated liquid specific 
c.	volume with respect to pressure
c.
      Function dvfdP(P)
      Dimension a(8)
      data a/.0158605,1.436698e-6,-6.546245e-10,1.2621567e-12,
     %-6.106028e-16,1.17416e-19,3.004294e-4,.3809203/
      dvfdP=a(2)+2.*a(3)*P+3.*a(4)*P**2+4.*a(5)*P**3+5.*a(6)*P**4
     %  +a(8)*a(7)*P**(a(8)-1.)
      Return
      End

c.	Function to compute derivative of saturated vapor specific 
c.	volume with respect to pressure
c.
      Function dvgdP(P)
      Dimension a(7),b(7)
      data a/5931.557,1142.2341,171.5671,41.76546,
     %11.64542,3.264609,.8898603/
      data b/11.60044,1.990131,.3299698,.0806798,
     %.0200894,4.596498e-3,7.761257e-4/
       sum=0.
        do i=1,7
        sum=sum-a(i)*b(i)*exp(-b(i)*P)
        enddo
       dvgdP=sum
      Return
      End

c.
c.    Function to compute the derivative of superheated vapor density 
c.    with respect to pressure
c.
      Function drhovsupdP(u,P)
      Dimension a(3),b(4)
      Data a/-1.29244509e-4,1.660071081,0.118866194/
      Data b/3.03597094e-7,1.909267903e-5,-0.026492255,0.0260077262/
      delu=u-ug(P)
      a0=a(1)+a(2)/P+a(3)/P**2
      b0=b(1)+b(2)/P+b(3)/P**2+b(4)/P**3
      v=vg(P)+a0*delu+b0*delu**2
c.
      dadP=-a(2)/P**2-2.*a(3)/P**3
      dbdP=-b(2)/P**2-2.*b(3)/P**3-3.*b(4)/P**4
c.
      dvdP=dvgdP(P)-dugdP(P)*(a0+2.*delu*b0)+
     %     delu*dadP+delu**2*dbdP
      drhovsupdP=(-1./v**2)*dvdP
      Return
      End

c.    Function to compute the derivative of saturated liquid density  
c.    with respect to pressure
c.
      Function drhofdP(P)
      drhofdP=-(1./vf(P)**2)*dvfdP(P)
      Return
      End

c.    Function to compute the derivative of saturated vapor density  
c.    with respect to pressure
c.
      Function drhogdP(P)
      drhogdP=-(1./vg(P)**2)*dvgdP(P)
      Return
      End

c.    Function to compute the derivative of the difference between 
c.    saturated vapor and saturated liquid specific volume
c.
      Function dvfgdP(P)
      dvfgdP=dvgdP(P)-dvfdP(P)
      Return
      end
c.
c.	Function to compute density as a function of Internal Energy
c.	and pressure
c.
      Function rhop(u,P)
      Dimension a(5),b(5),c(5)
      Data a/-16.6292550e-3,-88.8920769e-6,80.7871571e-9,-33.8804030e-12
     %      ,4.68248456e-15/
      Data b/42.3254971e-6,-269.512210e-9,289.924067e-12,-126.247514e-15
     %      ,18.2130057e-18/
      Data c/100.115638e-9,-297.848894e-12,302.240803e-15,
     %      -127.204073e-18,18.1566424e-21/
      au(P)=a(1)+a(2)*P+a(3)*P**2+a(4)*P**3+a(5)*P**4
      bu(P)=b(1)+b(2)*P+b(3)*P**2+b(4)*P**3+b(5)*P**4
      cu(P)=c(1)+c(2)*P+c(3)*P**2+c(4)*P**3+c(5)*P**4
      delu=u-uf(P)
      rhop=rhof(P)+au(P)*delu+bu(P)*delu**2+cu(P)*delu**3
      Return
      end
c.
c.	Function to compute the derivative of density with respect to 
c.	Internal energy
c.
      Function drhopdu(u,P)
      Dimension a(5),b(5),c(5)
      Data a/-16.6292550e-3,-88.8920769e-6,80.7871571e-9,-33.8804030e-12
     %      ,4.68248456e-15/
      Data b/42.3254971e-6,-269.512210e-9,289.924067e-12,-126.247514e-15
     %      ,18.2130057e-18/
      Data c/100.115638e-9,-297.848894e-12,302.240803e-15,
     %      -127.204073e-18,18.1566424e-21/
      au(P)=a(1)+a(2)*P+a(3)*P**2+a(4)*P**3+a(5)*P**4
      bu(P)=b(1)+b(2)*P+b(3)*P**2+b(4)*P**3+b(5)*P**4
      cu(P)=c(1)+c(2)*P+c(3)*P**2+c(4)*P**3+c(5)*P**4
      delu=u-uf(P)
      drhopdu=au(P)+2.*bu(P)*delu+3.*cu(P)*delu**2
      Return
      End
c.
c.	Function to compute the derivative of density with respect to 
c.	pressure
c.
      Function drhopdP(u,P)
      Dimension a(5),b(5),c(5)
      Data a/-16.6292550e-3,-88.8920769e-6,80.7871571e-9,-33.8804030e-12
     %      ,4.68248456e-15/
      Data b/42.3254971e-6,-269.512210e-9,289.924067e-12,-126.247514e-15
     %      ,18.2130057e-18/
      Data c/100.115638e-9,-297.848894e-12,302.240803e-15,
     %      -127.204073e-18,18.1566424e-21/
      au(P)=a(1)+a(2)*P+a(3)*P**2+a(4)*P**3+a(5)*P**4
      bu(P)=b(1)+b(2)*P+b(3)*P**2+b(4)*P**3+b(5)*P**4
      cu(P)=c(1)+c(2)*P+c(3)*P**2+c(4)*P**3+c(5)*P**4
      delu=u-uf(P)
      drhopdu=au(P)+2.*bu(P)*delu+3.*cu(P)*delu**2
      daudP=a(2)+2.*a(3)*P+3.*a(4)*P**2+4.*a(5)*P**3
      dbudP=b(2)+2.*b(3)*P+3.*b(4)*P**2+4.*b(5)*P**3
      dcudP=c(2)+2.*c(3)*P+3.*c(4)*P**2+4.*c(5)*P**3
      drhopdP=drhofdP(P)-dufdP(P)*drhopdu+
     %        delu*daudP+delu**2*dbudP+delu**3*dcudP
c	shen
	if(drhopdP.lt.0) drhopdP=0.0
c	drhopdP = 0.0003
      Return
      End

c	subroutine to compute dp/dp,dpu/dp,dp/dx.dpu/dx	
	subroutine derivative(old_aj_kk,old_kafa_kk,old_pressure_kk,
     %	dpdx1,dpdp1,density_temp,dpudx1,dpudp1,ie_temp)
	real ie_temp
	if(old_aj_kk.eq.1) then
	dpdx1=drhovsupdu(old_kafa_kk,old_pressure_kk)
	dpdp1=drhovsupdp(old_kafa_kk,old_pressure_kk)

	density_temp=rhovsup(old_kafa_kk,old_pressure_kk)	
	dpudx1=density_temp+
     %       old_kafa_kk*drhovsupdu(old_kafa_kk,old_pressure_kk)
	dpudp1=old_kafa_kk*drhovsupdp(old_kafa_kk,old_pressure_kk)
	ie_temp=old_kafa_kk*density_temp	
	else if(old_aj_kk.eq.0) then
	dpdx1=drhopdu(old_kafa_kk,old_pressure_kk)
	dpdp1=drhopdp(old_kafa_kk,old_pressure_kk)	
	density_temp=rhop(old_kafa_kk,old_pressure_kk)	
	dpudx1=density_temp+
     %       old_kafa_kk*drhopdu(old_kafa_kk,old_pressure_kk)
	dpudp1=old_kafa_kk*drhopdp(old_kafa_kk,old_pressure_kk)		
	ie_temp=old_kafa_kk*density_temp	
	else if(old_aj_kk.lt.1.and.old_aj_kk.gt.0) then
	p=old_pressure_kk
	x=old_aj_kk
	dpdx1=rhog(p)-rhof(p)
	dpdp1=(1-x)*drhofdp(p)+x*drhogdp(p)
	dpudx1=rhog(p)*ug(p)-rhof(p)*uf(p)
	dpudp1=(1-x)*(rhof(p)*dufdp(p)+uf(p)*drhofdp(p))
     %	+x*(rhog(p)*dugdp(p)+ug(p)*drhogdp(p))
	density_temp=(1-x)*rhof(p)+x*rhog(p)
	ie_temp=(1-x)*rhof(p)*uf(p)+x*rhog(p)*ug(p)
	endif
	return 
	end

c	subroutine to compute coefficients of relative velocity 
	subroutine rv1(V,aj,p,ri,G,rv_a,rv_b)
	ttt=2000*737.3257
	if(G.le.ttt) then
		if(aj.gt.0.and.aj.lt.0.1) then
		rv_a=rvb(aj,p)
		rv_b=0
		else if(aj.gt. 0.2 .and. aj.lt.0.65) then
		rv_a=rvs(aj,p,ri)
		rv_b=0
		else if(aj.gt.0.85.and. aj.lt.0.9) then
		rv_a=0
		rv_b=rva(aj,p)
		else if(aj.gt.0.1 .and. aj.lt.0.2) then
		rv_a=rvb(aj,p)+(aj-0.1)/0.1*(rvs(aj,p,ri)-rvb(aj,p))
		rv_b=0
		else if(aj.gt.0.65.and. aj.lt.0.85) then
		rv_a=rvs(aj,p,ri)+(aj-0.65)/0.2*(-rvs(aj,p,ri))
		rv_b=(aj-0.65)/0.2*rva(aj,p)
		else if(aj.gt.0.9 .and. aj.lt.1) then
		rv_a=0
		rv_b=rva(aj,p)+(aj-0.9)/0.09*(-rva(aj,p))
		endif
	ttt=3000*737.3257
	else if (G.gt.ttt) then
	rv_a=0
	rv_b=rvc(aj,p)
	else
	tmp=(G-2000*737.3257)/(1000*737.3257)		
		if(aj.gt.0.and.aj.lt.0.1) then
		rv_a=rvb(aj,p)+tmp*(-rvb(aj,p))
		rv_b=tmp*rvc(aj,p)
		else if(aj.gt. 0.2 .and. aj.lt.0.65) then
		rv_a=rvs(aj,p,ri)+tmp*(-rvs(aj,p,ri))
		rv_b=tmp*rvc(aj,p)
		else if(aj.gt.0.85.and. aj.lt.0.9) then
		rv_a=0
		rv_b=rva(aj,p)+tmp*(rvc(aj,p)-rva(aj,p))
		else if(aj.gt.0.1 .and. aj.lt.0.2) then
		rv_tmp=rvb(aj,p)+(aj-0.1)/0.1*(rvs(aj,p,ri)-rvb(aj,p))
		rv_a=rv_tmp+tmp*(-rv_tmp)
		rv_b=tmp*rvc(aj,p)
		else if(aj.gt.0.65.and. aj.lt.0.85) then
		rv_tmp1=rvs(aj,p,ri)+(aj-0.65)/0.2*(-rvs(aj,p,ri))
		rv_tmp2=(aj-0.65)/0.2*rva(aj,p)
		rv_a=rv_tmp1+tmp*(-rv_tmp1)
		rv_b=rv_tmp2+tmp*(rvc(aj,p)-rv_tmp2)
		else if(aj.gt.0.9 .and. aj.lt.1) then
		rv_a=0
		rv_tmp=rva(aj,p)+(aj-0.9)/0.09*(-rva(aj,p))
		rv_b=rv_tmp+tmp*(rvc(aj,p)-rv_tmp)
		endif
	endif
	RV_A=RV_A/3600.
	RV_B=RV_B

c	switch from annular to slug when liquid velocity is negative
		if(aj.gt.0.65)then
		den=aj*rhog(p)+(1-aj)*rhof(p)
		rv=rv_a+rv_b*v
		v_l=v-aj*rhog(p)/den*rv
			if (v_l.lt.0)then
			rv_a=rvs(aj,p,ri)/3600
			rv_b=0
			endif
		endif
	return
	end

c	function to compute relatively velocity at past time.
	function rv(aj,v,p,ri,G)
	ttt=2000*737.3257
	if(G.le.ttt) then
		if(aj.gt.0.and.aj.lt.0.1) then
		rv_a=rvb(aj,p)
		rv_b=0
		else if(aj.gt. 0.2 .and. aj.lt.0.65) then
		rv_a=rvs(aj,p,ri)
		rv_b=0
		else if(aj.gt.0.85.and. aj.lt.0.9) then
		rv_a=0
		rv_b=rva(aj,p)
		else if(aj.gt.0.1 .and. aj.lt.0.2) then
		rv_a=rvb(aj,p)+(aj-0.1)/0.1*(rvs(aj,p,ri)-rvb(aj,p))
		rv_b=0
		else if(aj.gt.0.65.and. aj.lt.0.85) then
		rv_a=rvs(aj,p,ri)+(aj-0.65)/0.2*(-rvs(aj,p,ri))
		rv_b=(aj-0.65)/0.2*rva(aj,p)
		else if(aj.gt.0.9 .and. aj.lt.1) then
		rv_a=0
		rv_b=rva(aj,p)+(aj-0.9)/0.09*(-rva(aj,p))
		endif
	ttt=3000*737.3257
	else if (G.gt.ttt) then
	rv_a=0
	rv_b=rvc(aj,p)
	else
	tmp=(G-2000*737.3257)/(1000*737.3257)		
		if(aj.gt.0.and.aj.lt.0.1) then
		rv_a=rvb(aj,p)+tmp*(-rvb(aj,p))
		rv_b=tmp*rvc(aj,p)
		else if(aj.gt. 0.2 .and. aj.lt.0.65) then
		rv_a=rvs(aj,p,ri)+tmp*(-rvs(aj,p,ri))
		rv_b=tmp*rvc(aj,p)
		else if(aj.gt.0.85.and. aj.lt.0.9) then
		rv_a=0
		rv_b=rva(aj,p)+tmp*(rvc(aj,p)-rva(aj,p))
		else if(aj.gt.0.1 .and. aj.lt.0.2) then
		rv_tmp=rvb(aj,p)+(aj-0.1)/0.1*(rvs(aj,p,ri)-rvb(aj,p))
		rv_a=rv_tmp+tmp*(-rv_tmp)
		rv_b=tmp*rvc(aj,p)
		else if(aj.gt.0.65.and. aj.lt.0.85) then

		rv_tmp1=rvs(aj,p,ri)+(aj-0.65)/0.2*(-rvs(aj,p,ri))
		rv_tmp2=(aj-0.65)/0.2*rva(aj,p)
		rv_a=rv_tmp1+tmp*(-rv_tmp1)
		rv_b=rv_tmp2+tmp*(rvc(aj,p)-rv_tmp2)
		else if(aj.gt.0.9 .and. aj.lt.1) then
		rv_a=0
		rv_tmp=rva(aj,p)+(aj-0.9)/0.09*(-rva(aj,p))
		rv_b=rv_tmp+tmp*(rvc(aj,p)-rv_tmp)
		endif
	endif
	rv=rv_a/3600.+rv_b*v

c	switch from annular to slug when liquid velocity is negative
		if(aj.gt.0.65)then
			den=aj*rhog(p)+(1-aj)*rhof(p)
			v_l=v-aj*rhog(p)/den*rv
			if(v_l.lt.0) then
			rv=rvs(aj,p,ri)/3600
			v_l=v-aj*rhog(p)/den*rv
			endif
		endif
	return
	end

C	UNITS FOR ALL THE FLOW REGIMES ARE FT/HOUR
	function rvb(aj,p)
	gc=32.17*3600**2
	rvb=1.41/(1-aj)*(sigma(p)*gc**2*(rhof(p)-rhog(p))/rhof(p)**2)**0.25
	return 
	end

	function rvs(aj,p,ri)
      gc=32.17*3600**2
		rvs=0.345/(1-aj)*(2*ri*gc*(rhof(p)-rhog(p))/rhof(p))**0.5
	return 
	end

	function rva(aj,p)
		den=aj*rhog(p)+(1-aj)*rhof(p)
		rv_tmp=(rhog(p)*(76-75*aj)/rhof(p)*aj**0.5)**0.5+aj*rhog(p)/den
		rva=1./rv_tmp
	return
	end

	function rvc(aj,p)
	den=aj*rhog(p)+(1-aj)*rhof(p)
	if(aj.lt. 0.8) then
		rvc=1./((10-11*aj)+aj*rhog(p)/den)
	else
		aj=0.8
		rvc=1./((10-11*aj)+aj*rhog(p)/den)
	endif
	return
	end

c
c.    Subroutine to compute Feed Flow
c.
      Subroutine FeedFlow(PSG,SGLvL,FlowDEMAND,FlowFD,FlowFDIND,
     %                    Deltat_FD)
c.**************************************************************************
      Real KFEED,Kvalve
      Real KHW,KM1,KCP,KM3,KFP,K11,KFD
      Real KFBV,KFCV
c.**************************************************************************
      Integer PumpID
c.**************************************************************************
      External FFC1,FFC3
c.************************************************************************** 
      Common/FeedFlowinit/OmegaHWP,OmegaCP,OmegaFP,FCV,FBV,Qrx
      Common/FeedFlowConstants/PSG0,Psi,Phi,Gamma,Chi,rho
      Common/ValveProperties/DeadBand(10),Tau(10),
     %                       Avalve(10),Kvalve(10),bvalve(10)
      Common/FeedGEOM/AxFEED(10),KFEED(10),KFCV,KFBV
      Common/FeedPARAMETERS/nHWP,nCP,nFP,nSG,Pcond
      Common/ControlMODES/MODE(10)
      Common/FeedControl/FeedGain(3,3),G1Feed(3),G2Feed(3),RATEFCV
      Common/UpsetParameters/ITYPEUpset,UPSETPARM(4)
      Common/DEGUG/IRESTART,IDEBUG
      Common/Trips/ITRIPRCP1,ITRIPRCP2,ITRIPRX,ITRIPFP							
	Common/SteamGeneratorMass/SGMass1,SGMass2
c.**************************************************************************
      Data IMOVEFCV,IOPENFCV/2*0/
      Data IMOVEFBV,IOPENFBV/2*0/
c.**************************************************************************
      gc=4.17e8
      rho=51.45					 
      PSG0=PSG
      Pcd=Pcond
c.
      AFCV=Avalve(1)
      AFBV=Avalve(2)
c.
c.    Feed Line Loss Coefficients
c.
      KHW=KFEED(1)
      KM1=KFEED(2)
	KCP=KFEED(3)
      KM3=KFEED(4)
      KFP=KFEED(5)
      K11=KFEED(6)
      KFD=KFEED(7)
c.
c.    Feed Line Flow Areas
c.
      AxHW=AxFEED(1)
      AxM1=AxFEED(2)
      AxCP=AxFEED(3)
      AxM3=AxFEED(4)
      AxFP=AxFEED(5)
      A11=AxFEED(6)
      AxFD=AxFEED(7)     
c.
      if(IDEBUG.eq.1)then
      write(14,*)' '
      write(14,*)'In Subroutine FeedFLow'
      write(14,*)' '
      write(14,*)'OmegaHWP=',OmegaHWP                 
      write(14,*)'OmegaCP=',OmegaCP
      write(14,*)'OmegaFP=',OmegaFP                                  
      write(14,*)'nHWP=',nHWP
      write(14,*)'nCP=',nCP
      write(14,*)'nFP=',nFP
      end if
c.*************************************************************************
c.
c.    Compute New Feed Pump Speed
c.
        Flow0=FlowFD*float(nSG)
        FlowFP=Flow0/float(nFP)
        FlowCP=Flow0/float(nCP)
        FlowHWP=Flow0/float(nHWP)
c.
        Call Pump(OmegaHWP,rho,FlowHWP,DeltaPHWP,3)
        Call Pump(OmegaCP,rho,FlowCP,DeltaPCP,2)
        Call Pump(OmegaFP,rho,FlowFP,DeltaPFP,1)
c.
        Pm1=Pcd+DeltaPHWP-(KHW/AxHW**2)*FlowHWP**2/(2.*rho*gc*144.)
        Pm2=Pm1-(KM1/AxM1**2)*Flow0**2/(2.*rho*gc*144.)
        Pm3=Pm2+DeltaPCP-(KCP/AxCP**2)*FlowCP**2/(2.*rho*gc*144.)
        Pm4=Pm3-(KM3/AxM3**2)*Flow0**2/(2.*rho*gc*144.)
c.
        Pdischarge=Pm4+DeltaPFP-(KFP/AxFP**2)*FlowFP**2/(2.*rho*gc*144.)
c.
          if(ITYPEUpset.ne.212132)then
          Call FeedPumpSpeedController(OmegaFP,Pdischarge)
          endif
c.
      if(ITRIPFP.eq.1)then
      OmegaFP=0.
        if(ITYPEUpset.ne.2122)then
        FCV=FCV-RATEFCV*Deltat_FD
        endif
          if(FCV.lt.0.)then
          FCV=0.
          endif
      endif
c.
c.*************************************************************************
	 if((OmegaFP.eq.0.).or.(nFP.eq.0))then                   
	 FlowFD=0.001
         if(IDEBUG.eq.1)then
         write(14,*)'FlowFD=',FlowFD
         write(14,*)' '
         endif
       Return
       endif
c.
      Call Pump(OmegaHWP,rho,0.,DeltaPHWP,3)
      Call Pump(OmegaCP,rho,0.,DeltaPCP,2)
      Call Pump(OmegaFP,rho,0.,DeltaPFP,1)
c.
      PmMAX=Pcond+DeltaPHWP+DeltaPCP+DeltaPFP
c.
        if(IDEBUG.eq.1)then
        write(14,*)'Max DeltaPHWP=',DeltaPHWP                   
        write(14,*)'Max DeltaPCP=',DeltaPCP                   
        write(14,*)'Max DeltaPFP=',DeltaPFP
        endif
c.                   
      PmMAX=1.2*PmMAX
c.*************************************************************************
c.
c.    Compute New Valve Positions
c.
       Call FeedControlValvePosition(FCVnew,MODE(1),FCV,
     %                               FlowFDIND,FlowDEMAND,SGLVL,
     %                               Deltat_FD)
       Call FeedByPassValvePosition (FBVnew,MODE(2),FBV,
     %                               SGLVL,Qrx,Deltat_FD)
c.      
      if(FCVnew.lt.0.)FCVnew=0.
      if(FCVnew.gt.1.)FCVnew=1.
c.
      if(FBVnew.lt.0.)FBVnew=0.
      if(FBVnew.gt.1.)FBVnew=1.
c
c	shen
	if(MODE(6).eq.0 .and. MODE(8).eq.0) then
		Call ValvePosition(FBV,FBVnew,Deltat_FD,IMOVEFBV,IOPENFBV,2)
	else if(MODE(6).eq.1) then
		data ii /0/
		if(ii.eq.0)then
		FBV_ini=FBV
		ii=ii+1
		endif
		FBV=FBV-FBV_ini*Deltat_FD*60./1.
	    if(FBV.lt.0.)FBV=0.
		if(FBV.gt.1.)FBV=1.
	endif
c
	if(MODE(8).eq.0) then
		Call ValvePosition(FCV,FCVnew,Deltat_FD,IMOVEFCV,IOPENFCV,1)	
	else if(MODE(8).eq.1) then
		data iih /0/
		if(iih.eq.0)then
		FCV_ini=FCV
		iih=iih+1
		endif
		FCV=FCV-FCV_ini*Deltat_FD*60./1.
	    if(FCV.lt.0.)FCV=0.
		if(FCV.gt.1.)FCV=1.
		Call ValvePosition(FBV,FBVnew,Deltat_FD,IMOVEFBV,IOPENFBV,2)
	endif
c
c	end shen
c.
      if(ITYPEUpset.eq.2122)then
      FCV=UPSETPARM(1)/100.
      endif
c.
      if(ITYPEUpset.eq.2123)then
      FBV=UPSETPARM(1)/100.
      endif
c.
       if(IDEBUG.eq.1)then
       write(14,*)'FCVnew= ',FCVnew
       write(14,*)'FCV= ',FCV
       write(14,*)' '
       write(14,*)'FBVnew= ',FBVnew
       write(14,*)'FBV= ',FBV
       write(14,*)' '
   	 endif
c.*******************************************************************************
c.
c.    Compute Valve Loss Coefficients
c.
      Nvalve=1
      Call Valve(FCV,Nvalve,KFCV)
c.
      Nvalve=2
      Call Valve(FBV,Nvalve,KFBV)
c.
       if(IDEBUG.eq.1)then
       write(14,*)'KHW=',KHW
       write(14,*)'AxHW=',AxHW
       write(14,*)' '
       write(14,*)'KM1=',KM1
       write(14,*)'AxM1=',AxM1
       write(14,*)' '
       write(14,*)'KCP=',KCP
       write(14,*)'AxCP=',AxCP
       write(14,*)' '
       write(14,*)'KM3=',KM3
       write(14,*)'AxM3=',AxM3
       write(14,*)' '
       write(14,*)'KFP=',KFP
       write(14,*)'AxFP=',AxFP
       write(14,*)' '
       write(14,*)'K11=',K11
       write(14,*)'A11=',A11
c.
       write(14,*)' '
       write(14,*)'KFCV ',KFCV
       write(14,*)'AFCV= ',AFCV
c.
       write(14,*)'KFBV= ',KFBV
       write(14,*)'AFBV= ',AFBV
c.
       write(14,*)' '
       write(14,*)'KFD=',KFD
       write(14,*)'AxFD=',AxFD
       endif
c.
      AxHWn=AxHW*float(nHWP)
      AxCPn=AxCP*float(nCP)
      AxFPn=AxFP*float(nFP)
c.
      Gamma=KHW/AxHWn**2+KM1/AxM1**2+
     %      KCP/AxCPn**2+KM3/AxM3**2+KFP/AxFPn**2
c.
c.*******************************************************************************
c.
c.    Determine flow configuration and solve for flow rates
c.
         if(FBV.eq.0.)then				! Start Feed Bypass Valve Closed
c.
c.       Feed Bypass Valve Closed
c.
         FlowFBV=0.
           if(FCV.eq.0.)then
c.**************************************************************
c.
c.         Feed Control Valve Closed
c.
           FlowFCV=0.
           FlowFD=0.
           else
c.****************************************************************
c.
c.         Feed Control Valve Open  -> Case 3
c.
           Chi=KFCV/AFCV**2+KFD/AxFD**2+K11/A11**2
           FlowMAX=sqrt(2.*rho*gc*144.*(PmMAX-PSG)/Chi)
           FlowMIN=0.
           call Brent(FFC3,FlowMIN,FlowMAX,FlowFCV,Icount)
           FlowFD=FlowFCV
           endif
c.****************************************************************
         else                           !End Feed Bypass Valve Closed
c.
c.       Feed Bypass Valve Open         !Start Feed Bypass Valve Open
c.
           if(FCV.eq.0.)then
c.
c.         Feed Control Valve Closed	  -> Case 2 
c.
           Phi=1.
           else
c.
c.         Feed Control Valve 1 Open	  -> Case 1
c.
           Phi=1.+sqrt(KFBV/KFCV)*AFCV/AFBV
           endif
c.
         Psi=KFBV/AFBV**2+(Phi**2)*(KFD/AxFD**2+K11/A11**2)
         FlowMAX=sqrt(2.*rho*gc*144.*(PmMAX-PSG)/Psi)
         FlowMIN=0.
         call Brent(FFC1,FlowMIN,FlowMAX,FlowFBV,Icount)
         FlowFD=Phi*FlowFBV
           if(FCV.gt.0.)then
           FlowFCV=FlowFBV*sqrt(KFBV/KFCV)*(AFCV/AFBV)
           else
           FlowFCV=0.
           endif
         endif                          !End Feed Bypass Valve Open
c.
       if(IDEBUG.eq.1)then
c.
      Flow0=FlowFD*float(nSG)
       PumpID=3
       FlowHWP=Flow0/float(nHWP)
       Call Pump(OmegaHWP,rho,FlowHWP,DeltaPHWP,PumpID)
         PumpID=2
         FlowCP=Flow0/float(nCP)
         Call Pump(OmegaCP,rho,FlowCP,DeltaPCP,PumpID)
           PumpID=1
           FlowFP=Flow0/float(nFP)
           Call Pump(OmegaFP,rho,FlowFP,DeltaPFP,PumpID)
c.
      Pm1=Pcd+DeltaPHWP-(KHW/AxHW**2)*FlowHWP**2/(2.*rho*gc*144.)
      Pm2=Pm1-(KM1/AxM1**2)*Flow0**2/(2.*rho*gc*144.)
      Pm3=Pm2+DeltaPCP-(KCP/AxCP**2)*FlowCP**2/(2.*rho*gc*144.)
      Pm4=Pm3-(KM3/AxM3**2)*Flow0**2/(2.*rho*gc*144.)
      Pm=Pm4+DeltaPFP-(KFP/AxFP**2)*FlowFP**2/(2.*rho*gc*144.)
c.
       write(14,*)' '
       write(14,*)'Phi=',Phi
       write(14,*)'Psi=',Psi
       write(14,*)'Chi=',Chi
       write(14,*)'Gamma=',Gamma
       write(14,*)' '
       write(14,*)'DeltaPHWP=',DeltaPHWP
       write(14,*)'DeltaPCP=',DeltaPCP
       write(14,*)'DeltaPFP=',DeltaPFP
       write(14,*)' '
       write(14,*)'Pm1=',Pm1
       write(14,*)'Pm2=',Pm2
       write(14,*)'Pm3=',Pm3
       write(14,*)'Pm4=',Pm4
       write(14,*)'Pm=',Pm
       write(14,*)' '
       write(14,*)'FlowFBV=',FlowFBV
       write(14,*)'FlowFCV=',FlowFCV
       write(14,*)'FlowFD=',FlowFD
       write(14,*)'Flow0=',Flow0
       endif
c.           
      Return
      End

c.*********************************************************************
c.
c.    Function Subprogram to compute feed flow for Case 1 and 2 Equations
c.
      Function FFC1(x)
      Integer PumpID
      Common/FeedFlowinit/OmegaHWP,OmegaCP,OmegaFP,FCV,FBV,Qrx
      Common/FeedFlowConstants/PSG,Psi,Phi,Gamma,Chi,rho
      Common/FeedPARAMETERS/nHWP,nCP,nFP,nSG,Pcond
      gc=4.17e8
c.
      Pm=PSG+Psi*x**2/(2.*rho*gc*144.)
      Flow0=Phi*x*float(nSG)
c.
      PumpID=3
      FlowHWP=Flow0/float(nHWP)
      Call Pump(OmegaHWP,rho,FlowHWP,DeltaPHWP,PumpID)
c.
      PumpID=2
      FlowCP=Flow0/float(nCP)
      Call Pump(OmegaCP,rho,FlowCP,DeltaPCP,PumpID)
c.
      PumpID=1
      FlowFP=Flow0/float(nFP)
      Call Pump(OmegaFP,rho,FlowFP,DeltaPFP,PumpID)
c.  
      Psource=Pcond+DeltaPHWP+DeltaPCP+DeltaPFP
c.
      FFC1=Psource-Pm-(Gamma)*Flow0**2/(2.*rho*gc*144.)
c.
      Return
      End
c.*********************************************************************
c.
c.    Function Subprogram to compute feed flow for Case 3 Equations
c.
      Function FFC3(x)
      Integer PumpID
      Common/FeedFlowinit/OmegaHWP,OmegaCP,OmegaFP,FCV,FBV,Qrx
      Common/FeedFlowConstants/PSG,Psi,Phi,Gamma,Chi,rho
      Common/FeedPARAMETERS/nHWP,nCP,nFP,nSG,Pcond
      gc=4.17e8
c.
      Pm=PSG+Chi*x**2/(2.*rho*gc*144.)
      Flow0=x*float(nSG)
c.
      PumpID=3
      FlowHWP=Flow0/float(nHWP)
      Call Pump(OmegaHWP,rho,FlowHWP,DeltaPHWP,PumpID)
c.
      PumpID=2
      FlowCP=Flow0/float(nCP)
      Call Pump(OmegaCP,rho,FlowCP,DeltaPCP,PumpID)
c.
      PumpID=1
      FlowFP=Flow0/float(nFP)
      Call Pump(OmegaFP,rho,FlowFP,DeltaPFP,PumpID)
c.  
      Psource=Pcond+DeltaPHWP+DeltaPCP+DeltaPFP
c.
      FFC3=Psource-Pm-(Gamma)*Flow0**2/(2.*rho*gc*144.)
c.
c.
      Return
      End
c.*********************************************************************
c.
c.    Subroutine to Determine Roots of Equations by Brents Algoritm
c.
      Subroutine Brent(F,a,b,x0,icount)
      icount=0
	err=1.
      if(F(a)*F(b).lt.0.)then
      x0=(a+b)/2.
	do while(err.gt.1.e-4.and.icount.lt.50)
      itest=0
	icount=icount+1
c      write(*,*)' '
c      write(*,*)'a=',a,' F(a)=',F(a)
c      write(*,*)'b=',b,' F(b)=',F(b)
c.
      Deltax=0.001*abs(x0)
        if(Deltax.gt.0.)then                             
	  dFdx=(F(x0+Deltax)-F(x0-Deltax))/(2.*Deltax)
c.
          if(dFdx.ne.0.)then
	    delx=-F(x0)/dFdx
	    err=abs(delx/x0)
	    x=x0+delx
          else
          itest=1
          endif
        else
        itest=1
        endif
      if((itest.eq.0).and.(x.ge.b.or.x.le.a))then
      itest=1
      endif
c.
      xTEST=(a+b)/2.
        if(F(a)*F(xTEST).gt.0.)then
        a=xTEST
        else
        b=xTEST
        endif
c.
      if(itest.eq.1)then
          if(b.eq.0.)then
	    err=abs(a)
          else
          err=abs((b-a)/b)
          endif     
      x0=xTEST
      else
      x0=x
      endif
c.           
c      write(*,*)'x=',x0,' F(x)=',F(x0)
c      write(*,*)'err=',err
c      write(*,*)'itest=',itest
c.
	enddo
        if(icount.ge.50)then
	  write(*,*)'maximum number of iterations exceeded'
        write(*,*)'a=',a
        write(*,*)'b=',b
        endif
      else
	write(*,*)'root not in interval in BRENT1'
      write(*,*)'a=',a,' F(a)=',F(a)
      write(*,*)'b=',b,' F(b)=',F(b)
      endif
      Return
	end
c.*********************************************************************
c.
c.    Subroutine to determine Valve Position as a function of time
c.
      Subroutine ValvePosition(P,Pnew,Deltat_FD,IMOVE,IOPEN,Nvalve)
      Real Kvalve
      Common/ValveProperties/DeadBand(10),Tau(10),
     %                       Avalve(10),Kvalve(10),bvalve(10)
c.
      TauV=Tau(Nvalve)
      if(IOPEN.eq.0)then
       if(Pnew.gt.P)then
       Pstar=Pnew+DeadBand(Nvalve)
       IOPEN=1
       IMOVE=0
       else
       Pstar=Pnew-DeadBand(Nvalve)
       endif
      else
       if(Pnew.lt.P)then
       Pstar=Pnew-DeadBand(Nvalve)
       IOPEN=0
       IMOVE=0
       else
       Pstar=Pnew+DeadBand(Nvalve)
       endif
      endif
c.
      if(IMOVE.eq.0)then
c.
c.    Valve Not Moving
c.
        if(abs(Pnew-P).gt.DeadBand(Nvalve))then
     	  P=P*exp(-Deltat_FD/TauV)+Pstar*(1.-exp(-Deltat_FD/TauV))
        IMOVE=1
        endif
      else
        if(IOPEN.eq.1)then
c.
c.      Valve Opening
c.
     	  P=P*exp(-Deltat_FD/TauV)+Pstar*(1.-exp(-Deltat_FD/TauV))
        if(P.gt.Pnew)IMOVE=0
c.
        elseif(IOPEN.eq.0)then
c.
c.      Valve Closing
c.
     	  P=P*exp(-Deltat_FD/TauV)+Pstar*(1.-exp(-Deltat_FD/TauV))
        if(P.lt.Pnew)IMOVE=0
        endif
      endif
c.
      if(P.lt.0.)P=0.
      if(P.gt.1.)P=1.
c.
      Return
      End
c.
c.    Subroutine to compute the loss coefficient across a valve
c.
      Subroutine Valve(Position,Nvalve,K)
      Real Kvalve,K
      Common/ValveProperties/DeadBand(10),Tau(10),
     %                       Avalve(10),Kvalve(10),bvalve(10)
c.
      b=bValve(Nvalve)
      TauV=Position*(1.-b*(1.-Position))
        if(TauV**2.lt.1.e-20)then
        K=Kvalve(Nvalve)/1.e-20
        else
        K=Kvalve(Nvalve)/TauV**2
        endif
      Return
      End
c.
c.    Subroutine to compute the performance of a centrugal pump
c.
      Subroutine Pump(Omega,Rho,Flow,DeltaP,PumpID)
      Integer PumpID
      Common/PumpData/OmegaR1(10),QR1(10),HR(10),
     %                a0P(10),b0P(10),c0P(10),d0P(10)
      Q=Flow/Rho
      a=Omega/OmegaR1(PumpID)
      v=Q/QR1(PumpID)
c.
      if(a.gt.0.)then
      h=a0P(PumpID)+
     %  b0P(PumpID)*(v/a)+
     %  c0P(PumpID)*(v/a)**2+
     %  d0P(PumpID)*(v/a)**3
      else
      h=0.
      endif
c.
      h=h*a**2
      Head=h*HR(PumpID)
      if(Head.lt.0.)Head=0.
c.
      DeltaP=Head*Rho/144.
      Return
      End
c.
c.*********************************************************************
c.
c.    Control Routine for Feed Pump Speed
c.
      Subroutine FeedPumpSpeedController(Omega,Pdischarge)
c.
      Common/FeedPumpControl/DeltaPREF,OmegaGAIN
      Common/FeedFlowConstants/PSG0,Psi,Phi,Gamma,Chi,rho
      Common/DEGUG/IRESTART,IDEBUG
c.
c.    Feed Pump Speed Controller
c.
        Pmanifold=PSG0
        DeltaP=Pdischarge-Pmanifold
        ERROR=DeltaPREF-DeltaP
        DeltaOmega=OmegaGain*ERROR
        Omega=Omega+DeltaOmega
          if(IDEBUG.eq.1)then
          write(14,*)' '
          write(14,*)'**** In Pump Speed Controller ****'
          write(14,*)' '
          write(14,*)'Omega=',Omega
          write(14,*)'Pmanifold=',Pmanifold
          write(14,*)'Pdischarge=',Pdischarge
          write(14,*)' '
          endif
      Return
      End
c.
c.*********************************************************************
c.
c.    Control Routine for Feed Control Valve Position
c.
      Subroutine FeedControlValvePosition(FCVnew,MODE,FCV,
     %                                    FlowFD,FlowDEMAND,SGLVL,
     %                                    Deltat_FD)
c.********************************************************************
      Common/FeedControl/FeedGain(3,3),G1Feed(3),G2Feed(3),RATEFCV
      Common/FeedControlSetPoints/FlowDEMAND0,SGRefLVL0,SGRefLVL
c.********************************************************************
      Data SumERROR/0./
c.********************************************************************
c.
       IDEBUG=0
c.
       if(IDEBUG.eq.1)then
       open(unit=14,file='Debug.dat')
       endif
c.
       if(IDEBUG.eq.1)then
       write(14,*)' '
       write(14,*)'In Subroutine FeedControlValvePosition'
       write(14,*)' '
       write(14,*)'MODE=',MODE
       write(14,*)'Reference Steam Generator Level= ',SGRefLVL
       write(14,*)'SG Level= ',SGLVL
       write(14,*)'FlowFD=',FlowFD
       write(14,*)'FlowDEMAND=',FlowDEMAND
       endif
c.**************************************************************
c.
      if(MODE.eq.0)then
c.
c.    Manual Control
c.
      DeltaFCV=0.
      else
c.
c.    Automatic Control
c.
      FlowERR=-(FlowFD-FlowDEMAND)/FlowDEMAND0
        if(FlowERR.gt.1.)FlowERR=1.
        if(FlowERR.lt.-1.)FlowERR=-1.
      ERROR=G1Feed(MODE)*FlowERR
      SumERROR=SumERROR+ERROR*Deltat_FD
      DeltaFCV=FeedGain(MODE,1)+
     %         FeedGain(MODE,2)*ERROR+
     %         FeedGain(MODE,3)*SumERROR
      endif
c.
        if(DeltaFCV.ge.0.)then
        DeltaFCVM=RATEFCV*Deltat_FD
        DeltaFCV=Amin1(DeltaFCV,DeltaFCVM)
        else
        DeltaFCVM=-RATEFCV*Deltat_FD
        DeltaFCV=Amax1(DeltaFCV,DeltaFCVM)
        endif
c.
        if(IDEBUG.eq.1)then
        write(14,*)' '
        write(14,*)'FlowERR=',FlowERR
        write(14,*)'ERROR=',ERROR
        write(14,*)'DeltaFCV=',DeltaFCV
        write(14,*)' '
        endif
c.**************************************************************
c.
      FCVnew=FCV+DeltaFCV
c.
      if(FCVnew.gt.1.)FCVnew=1.
      if(FCVnew.lt.0.)FCVnew=0.
c.
      Return
      end
c.
c.
c.    Control Routine for Feed ByPass Valve Position
c.
      Subroutine FeedByPassValvePosition (FBVnew,MODE,FBV,
     %                                    SGLVL,Qrx,
     %                                    Deltat_FD)
c.********************************************************************
      Real LevelERR
c.********************************************************************
      Common/FeedByPassControl/FeedByPassGain(3,3),
     %                         G1FeedByPass(3),G2FeedByPass(3)
      Common/FeedControlSetPoints/FlowDEMAND0,SGRefLVL0,SGRefLVL
	Common/ControlRods/aref,bref,RodspeedMin,RodspeedMax,RefRxPwr,
     %                   TaveREF,RodGain								  !Mod05
c.********************************************************************
      Data SumERROR/0./
c.********************************************************************
c.
      IDEBUG=0
c.
       if(IDEBUG.eq.1)then
       open(unit=14,file='Debug.dat')
       write(14,*)' '
       write(14,*)'In Subroutine FeedByPassValvePosition'
       write(14,*)' '
       write(14,*)'MODE=',MODE
       write(14,*)'Reference Steam Generator Level= ',SGRefLVL
       write(14,*)'SG Level= ',SGLVL
       write(14,*)'Qrx=',Qrx
       write(14,*)'Reference Rx Power=',RefRxPwr
       endif
c.**************************************************************
c.
      if(MODE.eq.0)then
c.
c.    Manual Control
c.
      DeltaFBV=0.
      else
c.
      LevelERR=-(SGLVL-SGRefLVL)/SGRefLVL0
      SumERROR=SumERROR+LevelERR*Deltat_FD

      DeltaFBV=FeedByPassGain(MODE,1)+
     %         FeedByPassGain(MODE,2)*LevelERR+
     %         FeedByPassGain(MODE,3)*SumERROR
      endif
c.
        if(IDEBUG.eq.1)then
        write(14,*)' '
        write(14,*)'LevelERR=',LevelERR
        write(14,*)'DeltaFBV=',DeltaFBV
        write(14,*)' '
        endif
c.**************************************************************
c.
        FBVnew=FBV+DeltaFBV
c.
      if(FBVnew.gt.1.)FBVnew=1.
      if(FBVnew.lt.0.)FBVnew=0.
c.
      Return
      end
c.
c.    Control Routine for Turbine Bypass Valve Position
c.
      Subroutine TurbineByPassValvePosition(PSG,MODE,ATBV,Deltat)
c.********************************************************************
      Real Kvalve
c.********************************************************************
      Common/ValveProperties/DeadBand(10),Tau(10),
     %                       Avalve(10),Kvalve(10),bvalve(10)
      Common/TBVControl/TBVGain(3,3,4),RATETBV,nTBV
      Common/PressureControlSetPoints/PSG_Ref
      Common/SteamFlowInit/TBVposition(4),TCVposition(4)
c.********************************************************************
      Dimension ATBV(4)
c.********************************************************************
      Data SumERROR/0./
c.********************************************************************
c.
      IDEBUG=0
       if(IDEBUG.eq.1)then
       open(unit=14,file='Debug.dat')
       write(14,*)' '
       write(14,*)'In Subroutine TurbineByPassValvePosition'
       write(14,*)' '
       write(14,*)'MODE=',MODE
       write(14,*)'Reference Steam Generator Pressure = ',PSG_Ref
       endif
c.**************************************************************
c.
      if(MODE.eq.0)then
c.
c.    Manual Control
c.
      DeltaTBV=0.
      else
c.
c.    Automatic Control
c.
      ERRTBV=(PSG-PSG_Ref)
c.
      SumERROR=SumERROR+ERRTBV*Deltat
        do j=1,nTBV
        DeltaTBV1=TBVGain(MODE,1,j)+
     %            TBVGain(MODE,2,j)*ErrTBV+
     %            TBVGain(MODE,3,j)*SumERROR
          if(DeltaTBV1.ge.0.)then
          DeltaTBV2=RateTBV*Deltat
          DeltaTBV=Amin1(DeltaTBV1,DeltaTBV2)
          else
          DeltaTBV2=-RateTBV*Deltat
          DeltaTBV=Amax1(DeltaTBV1,DeltaTBV2)
          endif
        TBVposition(j)=TBVposition(j)+DeltaTBV
          if(TBVposition(j).le.0.)then
          TBVposition(j)=0.
          ATBV(j)=0.
          elseif(TBVposition(j).ge.1.)then
          TBVposition(j)=1.
          ATBV(j)=Avalve(3)
          else
          ATBV(j)=Avalve(3)
          endif
        enddo
      endif
c.
        if(IDEBUG.eq.1)then
        write(14,*)' '
        write(14,*)'ERRTBV=',ERRTBV
        write(14,*)'SumERROR=',SumERROR
        write(14,*)'DeltaTBV1=',DeltaTBV1
        write(14,*)'DeltaTBV2=',DeltaTBV2
        write(14,*)'DeltaTBV=',DeltaTBV
        write(14,*)' '
        endif
c.**************************************************************
      Return
      end
c.
      Subroutine TurbineControlValvePosition(TCVNew,PSG,MODE,Deltat)
c.********************************************************************
      Real Kvalve
c.********************************************************************
      Common/ValveProperties/DeadBand(10),Tau(10),
     %                       Avalve(10),Kvalve(10),bvalve(10)
      Common/TCVControl/TCVGain(3,3,4),RATETCV,nTCV
      Common/PressureControlSetPoints/PSG_Ref
      Common/SteamFlowInit/TBVposition(4),TCVposition(4)
      Common/DEGUG/IRESTART,IDEBUG
c.********************************************************************
      Dimension TCVNew(4)
c.********************************************************************
      Data SumERROR/0./
c.********************************************************************
c.
       if(IDEBUG.eq.1)then
       write(14,*)' '
       write(14,*)'In Subroutine TurbineControlValvePosition'
       write(14,*)' '
       write(14,*)'MODE=',MODE
       write(14,*)'Reference Steam Generator Pressure = ',PSG_Ref
       endif
c.**************************************************************
c.
      if(MODE.eq.0)then
c.
c.    Manual Control
c.
      DeltaTCV=0.
      else
c.
c.    Automatic Control
c.
      ERRTCV=(PSG-PSG_Ref)
c.
      SumERROR=SumERROR+ERRTCV*Deltat
        do j=1,nTCV
        DeltaTCV1=TCVGain(MODE,1,j)+
     %            TCVGain(MODE,2,j)*ErrTCV+
     %            TCVGain(MODE,3,j)*SumERROR
          if(DeltaTCV1.ge.0.)then
          DeltaTCV2=RateTCV*Deltat
          DeltaTCV=Amin1(DeltaTCV1,DeltaTCV2)
          else
          DeltaTCV2=-RateTCV*Deltat
          DeltaTCV=Amax1(DeltaTCV1,DeltaTCV2)
          endif
c        TCVposition(j)=TCVposition(j)+DeltaTCV
        TCVNew(j)=TCVposition(j)+DeltaTCV
c          if(TCVposition(j).le.0.)then
c          TCVposition(j)=0.
c          ATCV(j)=0.
c          elseif(TCVposition(j).ge.1.)then
c          TCVposition(j)=1.
c          ATCV(j)=Avalve(4)
c          else
c          ATCV(j)=Avalve(4)
c          endif
          if(TCVnew(j).le.0.)TCVnew(j)=0.
          if(TCVnew(j).ge.1.)TCVnew(j)=1.
        enddo
      endif

        if(IDEBUG.eq.1)then
        write(14,*)' '
        write(14,*)'ERRTCV=',ERRTCV
        write(14,*)'SumERROR=',SumERROR
        write(14,*)'DeltaTCV1=',DeltaTCV1
        write(14,*)'DeltaTCV2=',DeltaTCV2
        write(14,*)'DeltaTCV=',DeltaTCV
        write(14,*)' '
        endif
c.**************************************************************
      Return
      end
c.*********************************************************************
c.
c.    Control Routine for TES ByPass Control Valve Position
c.
      Subroutine TESByPassControlValvePosition(TES_TBVnew,TES_TBV,
     %                                         FlowAUX,TESFlowDEMAND,
     %                                         Deltat)
c.********************************************************************
      Common/TESByPassControl/TES_TBVGain(3),RATETES_TBV
      Common/TESByPassControlSetPoints/TESFlowDEMAND0,TESSetPoint(4),
     %                                 IOPENTES(4),nTESByPass,ModeTES,
     %                                 ICLOSETBV,LockTBV
      Dimension TES_TBVnew(4),TES_TBV(4)
c.********************************************************************
      Data SumERROR/0./
c.********************************************************************
c.
       IDEBUG=0
c.
       if(IDEBUG.eq.1)then
       open(unit=14,file='Debug.dat')
       endif
c.
       if(IDEBUG.eq.1)then
       write(14,*)' '
       write(14,*)'In Subroutine TESByPassControlValvePosition'
       write(14,*)' '
       write(14,*)'TES_TBV=',TES_TBV
       write(14,*)'FlowAUX=',FlowAUX
       write(14,*)'TESFlowDEMAND=',TESFlowDEMAND
       write(14,*)' '
       write(14,*)'TESSetPoint(1)=',TESSetPoint(1)
       write(14,*)'TESSetPoint(2)=',TESSetPoint(2)
       write(14,*)'TESSetPoint(3)=',TESSetPoint(3)
       write(14,*)'TESSetPoint(4)=',TESSetPoint(4)
       write(14,*)' '
       write(14,*)'IOPENTES(1)=',IOPENTES(1)
       write(14,*)'IOPENTES(2)=',IOPENTES(2)
       write(14,*)'IOPENTES(3)=',IOPENTES(3)
       write(14,*)'IOPENTES(4)=',IOPENTES(4)
       write(14,*)' '
       write(14,*)'nTESByPass=',nTESByPass
       write(14,*)'ICLOSETBV=',ICLOSETBV
       write(14,*)'LockTBV=',LockTBV
       endif
c.
c.**************************************************************
c.
      if(LockTBV.eq.1)then
      DeltaTBV=0.
      elseif(ICLOSETBV.eq.1)then
      DeltaTBV=-RATETES_TBV*Deltat
      else
      RelativeDemand=TESFlowDEMAND/TESFlowDEMAND0
      ERROR=RelativeDemand-FlowAUX/TESFlowDEMAND0
        if(ERROR.gt.1.)ERROR=1.
        if(ERROR.lt.-1.)ERROR=-1.
      SumERROR=SumERROR+ERROR*Deltat
      DeltaTBV=TES_TBVGain(1)+
     %         TES_TBVGain(2)*ERROR+
     %         TES_TBVGain(3)*SumERROR
      endif
c.
        if(DeltaTBV.ge.0.)then
        DeltaTBVM=RATETES_TBV*Deltat
        DeltaTBV=Amin1(DeltaTBV,DeltaTBVM)
        else
        DeltaTBVM=-RATETES_TBV*Deltat
        DeltaTBV=Amax1(DeltaTBV,DeltaTBVM)
        endif
c.
        if(IDEBUG.eq.1)then
        write(14,*)' '
        write(14,*)'ERROR=',ERROR
        write(14,*)'SumERROR=',SumERROR
        write(14,*)'DeltaTBV=',DeltaTBV
        endif
c.
c.**************************************************************
c.
      do n=1,nTESByPass
        if(IOPENTES(n).eq.1)then
          if(DeltaTBV.gt.0.)then
          TES_TBVnew(n)=TES_TBV(n)+DeltaTBV
          else
            if(n.eq.nTESByPass)TES_TBVnew(n)=TES_TBV(n)+DeltaTBV
              if((n.lt.nTESByPass).and.
     %           (IOPENTES(n+1).eq.0))then
              TES_TBVnew(n)=TES_TBV(n)+DeltaTBV
              endif
           if(IDEBUG.eq.1)then
           write(14,*)' '
           write(14,*)'n=',n
           write(14,*)'TES_TBV(n)=',TES_TBV(n)
           write(14,*)'DeltaTBV=',DeltaTBV
           write(14,*)'TES_TBVnew(n)=',TES_TBVnew(n)
           endif
          endif
c.	 
          if(TES_TBVnew(n).gt.1.)TES_TBVnew(n)=1.
          if(TES_TBVnew(n).lt.0.)then
          TES_TBVnew(n)=0.
          IOPENTES(n)=0
            if(ICLOSETBV.eq.1)then
            LOCKTBV=1
            ICLOSETBV=0
            endif
          endif
        else
          if((RelativeDemand.gt.TESSetPoint(n)).and.
     %       (DeltaTBV.gt.0.))then
          IOPENTES(n)=1
          TES_TBVnew(n)=AMIN1(1.,DeltaTBV)
          endif
        endif
      enddo
c.
        if(IDEBUG.eq.1)then
        write(14,*)' '
        write(14,*)'TES_TBVnew(1)=',TES_TBVnew(1)
        write(14,*)'TES_TBVnew(2)=',TES_TBVnew(2)
        write(14,*)'TES_TBVnew(3)=',TES_TBVnew(3)
        write(14,*)'TES_TBVnew(4)=',TES_TBVnew(4)
        write(14,*)' '
        endif
c.
c.***************************************************************
c.
      Return
      end
c.
c.    Subroutine to compute Feed demand								    !Mod05
c.																		!Mod05
      Subroutine FeedDemand(Wload,Wturb,FlowDemand,Deltat)				!Mod05
      Real KSHIM          				                                !Mod05
      Common/TurbineLoadData/aload,bload,RefLoad,RampDuration				!Mod05
      Common/FeedDemandParameters/FlowSG0,FeedSHIM,KSHIM					!Mod05
c.*************************************
      Common/TESParameters/FlowAUX1,FlowAUX2,FlowAUX3,TESLoad             !TES Mod
      Common/FeedPARAMETERS/nHWP,nCP,nFP,nSG,Pcond                        !TES Mod
c.*************************************
      FlowDemand=FlowSG0*Wload/RefLoad+FeedSHIM                           !Mod05
      FeedSHIM=FeedSHIM+KSHIM*FlowSG0*(Wload-Wturb)*Deltat/RefLoad
c.*************************************
c.
      FlowDemand=FlowDemand+FlowAUX1/float(nSG)                           !TES Mod
      FlowDemand=FlowDemand+FlowAUX2*float(nTCV)/float(nSG)
c      FlowDemand=FlowDemand+FlowAUX3/float(nSG)
c.
c.*************************************

      Return																!Mod05
      End																	!Mod05
c.
c.    Subroutine to compute TES Bypass Flow demand					    !TES Mod
c.																	  	!TES Mod
      Subroutine TESDemand(Qth,RefRxPwr,TESFlowDemand,Deltat) 		    !TES Mod
      Real KSHIM,KSHIMTES													!TES Mod
c.*************************************	                                !TES Mod
      Common/TurbineLoadData/aload,bload,RefLoad,RampDuration				!TES Mod
      Common/FeedDemandParameters/FlowSG0,FeedSHIM,KSHIM					!TES Mod
      Common/FeedPARAMETERS/nHWP,nCP,nFP,nSG,Pcond                        !TES Mod
c.*************************************									!TES Mod
      Common/TESParameters/FlowAUX1,FlowAUX2,FlowAUX3,TESLoad             !TES Mod
      Common/TESDemandParameters/TESSHIM,KSHIMTES                         !TES Mod
c.*************************************									!TES Mod
c.
      TESFlowDemand=FlowSG0*float(nSG)*TESLoad/RefLoad+TESSHIM            !TES Mod
      TESSHIM=TESSHIM+KSHIMTES*FlowSG0*float(nSG)*
     %                (RefRxPwr-Qth)*Deltat/RefRxPwr     
	 if(TESFlowDemand.lt.0.)TESFlowDemand=0.
c.
c.*************************************									!TES Mod
c.																		!TES Mod
      Return																!TES Mod
      End																	!TES Mod
c.
c.    Function Subprogram to compute Turbine Load
c.
      Function Load(time)										   !Mod05
      Real Load
c.
      Common/TurbineLoadData/aload,bload,RefLoad,RampDuration
      Common/LoadData/Hour(300),TurbineLoad(300),IDEMAND,ntimes
      Data LASTINDEX/1/
      Data SHIFT/0./ 		  
c.    
        if(IDEMAND.eq.2)then
        Hours=time/3600.-SHIFT
c.
          if(Hours.gt.Hour(ntimes))then
          SHIFT=SHIFT+Hour(ntimes)
          Hours=Hours-SHIFT
          LASTINDEX=1
          endif
c.
        index=LASTINDEX
          do while ((Hours.gt.Hour(index+1)).and.
     %              (Hours.lt.Hour(ntimes)))
          index=index+1
          enddo
        LASTINDEX=index
c.        
        Slope=(TurbineLoad(index+1)-TurbineLoad(index))/
     %        (Hour(index+1)-Hour(index))
        Load=TurbineLoad(index)+(Hours-Hour(index))*Slope
        Load=(Load/100.)*RefLoad 
        else
          if(time.le.RampDuration)then
          Load=aload+bload*time
          else
          Load=aload+bload*RampDuration
          endif
        endif
      Return
      end
c.
c.    Subroutine to compute turbine output
c.
      Subroutine Turbine(hsteam,FlowTurbine,Phdr,Pcond,epsilon,Wturb)
      Real Kappa
c.
c.    Compute Turbine Work
c.
      Kappa=3.4137e6
c.
      if(Phdr.gt.0.)then    
        if(hsteam.gt.hg(Phdr))then
        shdr=sv(hsteam,Phdr)
        else        
        xhdr=(hsteam-hf(Phdr))/hfg(Phdr)
        shdr=sf(Phdr)+xhdr*sfg(Phdr)
        endif
c.
        xexh=(shdr-sf(Pcond))/sfg(Pcond)
        hexh=hf(Pcond)+xexh*hfg(Pcond)
c.
        Wturb=FlowTurbine*epsilon*(hsteam-hexh)/Kappa
      else
      Wturb=0.
      endif
c.
c.      write(*,*)'hsteam=',hsteam
c.      write(*,*)'Phdr=',Phdr
c.      write(*,*)'FlowTurbine=',FlowTurbine
c.      write(*,*)'Wturb=',Wturb
c.      write(*,*)'shdr=',shdr
c.      write(*,*)'xexh=',xexh
c.      write(*,*)'hexh=',hexh

      Return
      End
c.
c.*******************************************************************************
c.
      Subroutine TurbineMod01(hsteam,FlowTurbine,Pimpulse,Pcond,epsilon,
     %                        WturbMod01)
      Common/TESParameters/FlowAUX1,FlowAUX2,FlowAUX3,TESLoad
      Common/TESTapParameters/KEXH,PTAP,rhoTAP,hTAP
c.
      Real Kappa
      Real KEXH
c.
      Kappa=3.4137e6
      gc=4.17e8
c.
      if(Pimpulse.le.Pcond)then
      Wturb=0.
      else    
c.
c.    Compute Turbine Inlet Conditions
c.
        if(hsteam.gt.hg(Pimpulse))then
        shdr=sv(hsteam,Pimpulse)
        rhoHDR=rhog(Pimpulse)
        else        
        xhdr=(hsteam-hf(Pimpulse))/hfg(Pimpulse)
        shdr=sf(Pimpulse)+xhdr*sfg(Pimpulse)
        rhoHDR=1./(vf(Pimpulse)+xhdr*vfg(Pimpulse))
        endif
c.
c.    Compute Turbine Tap Conditions
c.
        xTAP=(shdr-sf(PTAP))/sfg(PTAP)
        hTAP=hf(PTAP)+xTAP*hfg(PTAP)
        rhoTAP=1./(vf(PTAP)+xTAP*vfg(PTAP))      
c.															
c.    Compute Turbine Exhaust Conditions
c.
        xexh=(shdr-sf(Pcond))/sfg(Pcond)
        hexh=hf(Pcond)+xexh*hfg(Pcond)
c.
      FlowEXH=FlowTurbine-FlowAUX3
c.
c.    Compute Turbine Work
c.
      WturbMod01=FlowTurbine*epsilon*(hsteam-hTAP)/Kappa+
     %           FlowEXH*epsilon*(hTAP-hexh)/Kappa
      endif
c.
c      write(*,*)'FlowTurbine=',FlowTurbine
c      write(*,*)'Pimpulse=',Pimpulse
c      write(*,*)'rhoHDR=',rhoHDR
c      write(*,*)'PTAP=',PTAP
c      write(*,*)'xTAP=',xTAP
c      write(*,*)'hTAP=',hTAP
c      write(*,*)'rhoTAP=',rhoTAP
c      write(*,*)'WturbMod01=',WturbMod01
c      write(*,*)' '     
      Return
      End
c.*******************************************************************************
c
c.    Subroutine to calculate the reactivity due to Control Rods in Heat up/Cool down mode
c.
      Subroutine RodsLP(Tave,TAVE0,Qrx,time,Deltat,RodDepth,Rhocr)
      Common/ControlRods/aref,bref,RodspeedMin,RodspeedMax,RefRxPwr,
     %                   TaveREF,RodGain								!Mod05
c.     %                   RefLoad,TaveREF,RodGain					!Mod05
      Common/RodWorthData/CummWorth,ShutDownWorth,RodLength
      Common/LowPower/QrxFINAL,HeatUpRate,StartupRATE,QrxRATE            
      TaveREF=TAVE0+HeatUpRate*Deltat               
      Tave0=Tave                                    
      TaveDB=0.
      PwrDB=0.1
      RateDB=0.05                                   
      ERROR=100.*(QrxFINAL-Qrx)/RefRxPwr
      DPM=QrxRATE/100./10.
c.
      if(HeatUpRate.gt.0.)then
      ERROR1=TaveREF-Tave
      else      
      ERROR1=Tave-TaveREF
      endif
      ITESTPWR=0
       If(HeatUpRate.gt.0.)then
         If(Qrx.lt.QrxFINAL-PwrDB)ITESTPWR=1
       else
         If(Qrx.gt.QrxFINAL+PwrDB)ITESTPWR=1
       endif
       MoveRods=0
         If(ITESTPWR.eq.1)then                                            
            if(DPM.lt.StartupRATE-RateDB)then                             
              if(ERROR1.gt.TaveDB)then                                    
              MoveRods=1                                                  
              RateERROR=StartupRATE-RateDB-DPM                            
              RodERROR=AMIN1(RateERROR,abs(ERROR)-PwrDB)                  
              endif                                                       
           endif                                                          
         endif                                                             
         if(MoveRods.eq.1)then
           If(abs(ERROR).gt.PwrDB)then
             RodSpeed=RodGain*RodERROR*RodSpeedMax                        
             if(RodSpeed.gt.RodSpeedMax)RodSpeed=RodSpeedMax
             if(RodSpeed.lt.RodSpeedMin)RodSpeed=RodSpeedMin
               If(RodERROR.lt.0.)then                                     
               RodDepth=RodDepth+RodSpeed*Deltat
               else
               RodDepth=RodDepth-RodSpeed*Deltat
               endif
           endif
         endif
      if(RodDepth.gt.RodLength)RodDepth=RodLength
      if(RodDepth.lt.0.)RodDepth=0.
c      Rhocr=RodWorth(RodDepth)
      Return
      end
c.
c.    Subroutine to compute the temperature distribution in a Fuel Rod
c.
      Subroutine PeakPin(Qthnew,Qth,Tinfnew,Tinf,Pp0,Pp,Deltat,
     %                   hlo,h2p,T,Tbar,Tclad,IFLAGHotRod)
      Real KUO2,Kappa,kc
      Dimension a(50),b(50),c(50),s(50),T(50)
      Common /FuelProperties/rhoUO2,Diameter,Dpellet,FuelHeight,P_D,
     %                       Gammaf,tc,rhoc,Cpc,kc,HG,nrods
      Common /HotRod/alamda,DeCore,AxCore,Fq,Fz,nodes,ICHF
c.
      Kappa=3.4137e6
      Pi=3.1415926
      Mesh=10
      Ro=Diameter/2.
      Ri=Ro-tc
      Rpellet=Dpellet/2.
      icnodes=2
      Deltarc=tc/(float(icnodes+1))
      Hcore=FuelHeight
c.
      Tsatnew=Tsat(Pp)
      Tsatold=Tsat(Pp0)
c.
c.    Volumetric Heat Generation Rate
c.
      FuelVolume=Pi*Dpellet**2/4.*Hcore*float(nrods)
c.
        if(IFLAGHotRod.eq.1)then
        Q=Deltat/2.*Kappa*(Qthnew+Qth)*Fq*Gammaf/FuelVolume
        else
        Q=Deltat/2.*Kappa*(Qthnew+Qth)*Gammaf/FuelVolume
        endif
c      if(IFLAGHotRod.eq.1)then
c      write(*,*)'Qth=',Qth,' Q=',Q
c      write(*,*)'hlo=',hlo,' h2p=',h2p
c      write(*,*)' '
c      endif

c.
c.    ***********************
c.    *                     *
c.    * Matrix Coefficients *
c.    *                     *
c.    ***********************
c.
c.    Center Node
c.
      Deltar=Rpellet/float(Mesh)
      Cpj=CpUO2(T(1))
      alphaplus=KUO2((T(1)+T(2))/2.)/(rhoUO2*Cpj)
      Foplus=alphaplus*Deltat/Deltar**2
      c(1)=2.*Foplus
      b(1)=0.
      a(1)=-(c(1)+1.)
      s(1)=-c(1)*T(2)+(c(1)-1.)*T(1)-Q/(rhoUO2*Cpj)
c.
c.    Fuel Interior Nodes
c.
      do i=1,Mesh-1
      j=i+1
      rj=Deltar*float(i)
      Cpj=CpUO2(T(j))
      alphaplus=KUO2((T(j+1)+T(j))/2.)/(rhoUO2*Cpj)
      alphaminus=KUO2((T(j)+T(j-1))/2.)/(rhoUO2*Cpj)
      Foplus=alphaplus*Deltat/Deltar**2
      Fominus=alphaminus*Deltat/Deltar**2
      c(j)=Foplus/2.*(1.+Deltar/(2.*rj))
      b(j)=Fominus/2.*(1.-Deltar/(2.*rj))
      a(j)=-(c(j)+b(j)+1.)
      s(j)=-c(j)*T(j+1)+(c(j)+b(j)-1.)*T(j)-b(j)*T(j-1)-Q/(rhoUO2*Cpj)
      enddo
c.
c.    Fuel Surface Node
c.
      j=Mesh+1
      Cpj=CpUO2(T(j))
      BiG=HG*Deltar/KUO2((T(j)+T(j-1))/2.)
      alphaminus=KUO2((T(j)+T(j-1))/2.)/(rhoUO2*Cpj)
      Fominus=alphaminus*Deltat/Deltar**2
     	c(j)=BiG*Fominus*Ri/Rpellet
      b(j)=Fominus*(1.-Deltar/(2.*Rpellet))
      a(j)=-(c(j)+b(j)+1.)
      s(j)=-c(j)*T(j+1)+(c(j)+b(j)-1.)*T(j)-b(j)*T(j-1)-Q/(rhoUO2*Cpj)
c.
c.    Inner Clad Node
c.
      j=Mesh+2
      Bic=HG*Deltarc/kc
      alphac=kc/(rhoc*Cpc)
      Foc=alphac*Deltat/Deltarc**2
      c(j)=Foc*(1.+Deltarc/(2.*Ri))
      b(j)=Bic*Foc
      a(j)=-(c(j)+b(j)+1.)
      s(j)=-c(j)*T(j+1)+(c(j)+b(j)-1.)*T(j)-b(j)*T(j-1)
c.
c.    Interior Clad Nodes
c.
      do i=1,icnodes
      j=Mesh+2+i
      rj=Ri+Deltarc*float(i)
      c(j)=Foc/2.*(1.+Deltarc/(2.*rj))
      b(j)=Foc/2.*(1.-Deltarc/(2.*rj))
      a(j)=-(c(j)+b(j)+1.)
      s(j)=-c(j)*T(j+1)+(c(j)+b(j)-1.)*T(j)-b(j)*T(j-1)
      enddo
c.
c.    Outer Clad Node
c.    
      Bilo=hlo*Deltarc/kc
      Bi2p=h2p*Deltarc/kc
      j=Mesh+2+icnodes+1
      c(j)=(Bilo+Bi2p)*Foc
      b(j)=Foc*(1.-Deltarc/(2.*Ro))
      a(j)=-(c(j)+b(j)+1.)
      s(j)=-b(j)*T(j-1)+(c(j)+b(j)-1.)*T(j)
     %     -Bilo*Foc*(Tinfnew+Tinf)-Bi2p*Foc*(Tsatnew+Tsatold)
c.
c.    Solve Matrix Equation
c.
      Call Thomas(a,b,c,s,T,j)
c.
c.    Compute Average Temperature
c.
      Tclad=T(j)      
      Tbar=T(1)*Deltar**2/4.
      Vbar=Deltar**2/4.
c.
        do i=1,Mesh-1
        j=i+1
        rj=Deltar*float(i)
        Tbar=Tbar+T(j)*2.*rj*Deltar
        Vbar=Vbar+2.*rj*Deltar
        enddo
c.
      j=Mesh+1
      Tbar=Tbar+T(j)*Rpellet*Deltar
      Vbar=Vbar+Rpellet*Deltar
c.
      Tbar=Tbar/Vbar
c.
      Return
      end
c.
c.    Subroutine to Solve Tridiagonal Systems of Equations 
c.
      Subroutine Thomas(a,b,c,s,x,n)
      Dimension a(50),b(50),c(50),s(50),x(50)
      Dimension alpha(50),g(50),store(50)
c.
      alpha(1)=a(1)
      do i=2,n
      store(i-1)=c(i-1)/alpha(i-1)
      alpha(i)=a(i)-b(i)*store(i-1)
      enddo
c.
      g(1)=s(1)/alpha(1)
      do i=2,n
      g(i)=(s(i)-b(i)*g(i-1))/alpha(i)
      enddo
c.
      x(n)=g(n)
      do i=n-1,1,-1
      x(i)=g(i)-store(i)*x(i+1)
      enddo
c.
      Return
      end           
c.
c.    Function Subprogram to Compute the Thermal Conductivity of UO2
c.      
      Function KUO2(T)
      Real KUO2
      KUO2=3978.1/(692.61+T)+6.02366e-12*(T+460.)**3
      Return
      End
c.
c.    Function Subprogram to Compute the Specific Heat of UO2
c.
      Function CpUO2(T)
      R=1.987
      Tkelvin=5.*T/9.+255.22
      X=exp(6.25-42659./(R*Tkelvin))
      CpUO2=0.07622+1.16e-6*Tkelvin+X/(1.+X)**2*(6.76e6/(R*Tkelvin**2))
      Return
      End
c.**************************************************
c.
c.    Subroutine to Compute Pressurizer Behavior
c.
      Subroutine Pressurizer(PRZLVL,Px)
c.
      Real NewMass(4),NewE(4),Mass
      Real KPRZSRV,KPRZ
      Real MpTILDA
      Real mdotCHRG,mdotLD,mdotLD0,mdotSPRAY
      
      Common/PressurizerGeometry/RSRG,RDOME,HSRG,HCYL,
     %                           Ax3,Ax4,Ax5,AxVESSEL,
     %                           VSRG,VDOME,VHEAD,VPRZ,
     %                           VOL(4)
      Common/PressurizerData/KPRZSRV(4),AxSRV(4),KPRZ(4),
     %                       PRZSETPOINT(9),NPRZSRVs
      Common/PressurizerSprayData/rhoSPRAY,rhouSPRAY,Vspray,AxSPRAY
c.
      Common/PressurizerProperties/alphag(4),alphal(4),rhol(4),ul(4),
     %                             rhov(4),uv(4),rho(4),rhou(4),
     %                             Vel(5),VelSRV(4),Mass(4),E(4)
c.
      Common/PrimaryData/rholulp(26),rholp(26),ulp(26),ulp0(26),
     %                   Vp(26),Pp
c.
      Common/CVCSData/mdotCHRG,mdotLD0
      Common/SimulationControlData/Deltat
c.
      Dimension alphagDonor(6),alphalDonor(6),rhodonor(6),
     %          rhoudonor(6),rholdonor(6),uldonor(6)
      Dimension aSRV(4),bSRV(4)
      Dimension rhoTILDA(4)
c.
      gc=4.17e8
      Pamb=14.7
      IDEBUG=0
      mdotSPRAY=rhoSPRAY*Vspray*AxSPRAY
      mdotLD=mdotLD0+mdotSPRAY
      if(IDEBUG.eq.1)then
      open(unit=14,file='debug.dat')
      endif
c.***********************************************************************
      if(IDEBUG.eq.1)then
      write(14,*)' '
      write(14,*)'Primary Side Data'
      write(14,*)' '
      write(14,*)'Pp=',Pp
      write(14,*)'mdotCHRG=',mdotCHRG,' mdotLD0=',mdotLD0
      write(14,*)'mdotSPRAY=',mdotSPRAY,' mdotLD=',mdotLD
      write(14,*)' '
c.
      do j=1,26
      write(14,*)'j=',j,' ulp=',ulp(j),' rholp=',rholp(j),' rholulp=',
     %               rholulp(j)
      enddo
c.
      write(14,*)'Pressurizer Data'
      write(14,*)' '
      write(14,*)'Px=',Px,' PRZLVL=',PRZLVL
      write(14,*)' '
      write(14,*)'rhof=',rhof(Px),' uf=',uf(Px)
      write(14,*)'rhog=',rhog(Px),' ug=',ug(Px)
c.
      write(14,*)' '
      do j=1,4
      write(14,*)'j=',j,' alphag=',alphag(j),' alphal=',alphal(j)
      enddo
c.
      write(14,*)' '
      do j=1,4
      write(14,*)'j=',j,' rhol=',rhol(j),' ul=',ul(j)
      enddo
c.
      write(14,*)' '
      do j=1,4
      write(14,*)'j=',j,' rhov=',rhov(j),' uv=',uv(j)
      enddo
c.
      write(14,*)' '
      do j=1,4
      write(14,*)'j=',j,' rho=',rho(j),' rhou=',rhou(j)
      enddo
c.
      write(14,*)' '
      do j=1,4
      write(14,*)'j=',j,' Mass=',Mass(j),' E=',E(j)
      enddo
c.
      write(14,*)' '
      do j=1,5
      write(14,*)'j=',j,' Vel=',Vel(j)
      enddo
c.
      write(14,*)' '
      do j=1,4
      write(14,*)'j=',j,' VelSRV=',VelSRV(j)
      enddo
c.
      write(14,*)' '
      do j=1,4
      write(14,*)'j=',j,' VOL=',VOL(j)
      enddo
      write(14,*)' '
c.
      endif
c.***********************************************************************
c.
c.    Saturation Properties
c.
      rhofs=rhof(Px)
      ufs=uf(Px)
      rhogs=rhog(Px)
      ugs=ug(Px)
      vgs=vg(Px)
      vfs=vf(Px)
      ufgs=ugs-ufs
      vfgs=vgs-vfs
c.
c.    Initial Guess at Donored Volume Fractions
c.
c.
      alphagDonor(3)=alphag(2)
      alphalDonor(3)=1.-alphagDonor(3)
      if(alphagDonor(3).gt.0.)then
      rhodonor(3)=alphalDonor(3)*rhofs+alphagDonor(3)*rhogs
      endif
c.
      alphagDonor(4)=Amax1(alphag(2),alphag(3))
      alphalDonor(4)=1.-alphagDonor(4)
      if(alphagDonor(4).gt.0.)then
      rhodonor(4)=alphalDonor(4)*rhofs+alphagDonor(4)*rhogs
      endif
c.*********************************************************
      if(IDEBUG.eq.1)then
      write(14,*)' '
      write(14,*)'Donor Decision Variables'
      write(14,*)' '     
      do j=2,4
      write(14,*)'j=',j,' alphagDonor=',alphagDonor(j),
     %          ' alphalDonor=',alphalDonor(j)
      enddo
      write(14,*)' '
      do j=2,4
      write(14,*)'j=',j,' rhodonor=',rhodonor(j)
      enddo
      write(14,*)' '
      endif
c.*********************************************************      
c.
c.    Compute Donored Values
c. 
c.*****************************************
      if(Vel(1).gt.0.)then
      rhodonor(1)=rho(1)
      rhoudonor(1)=rhou(1)
      else
      rhodonor(1)=rho(2)
      rhoudonor(1)=rhou(2)
      endif
c.******************************************
      Vrg3=0.
      Vrl3=0.
      Vrg4=0.
      Vrl4=0.
      Vrg5=0.
      Vrl5=0.
c.
      do j=1,5
      rholdonor(j)=rhofs
      enddo
c.
        if(alphagDonor(3).eq.0.)then
        vl3=0.
        vg3=0.
          if(Vel(3).gt.0.)then
          rholdonor(3)=rholp(6)
          uldonor(3)=ulp(6)
          rhodonor(3)=rholp(6)
          rhoudonor(3)=rholulp(6)
          else
          rholdonor(3)=rhol(2)
          uldonor(3)=ul(2)
          rhodonor(3)=rhol(2)
          rhoudonor(3)=rhol(2)*ul(2)
          endif
        else
        vl3=Vel(3)-alphagDonor(3)*rhogs*Vrg(alphalDonor(3),Px)/
     %             rhodonor(3)
        vg3=Vel(3)+alphalDonor(3)*rhofs*Vrg(alphalDonor(3),Px)/
     %             rhodonor(3)
          if(vg3.gt.0.)then
          alphagDonor(3)=0.
          alphalDonor(3)=1.
          else
          alphagDonor(3)=alphag(2)
          alphalDonor(3)=alphal(2)
          endif
            if(vl3.gt.0.)then
            rholdonor(3)=rholp(6)
            uldonor(3)=ulp(6)
            else
            rholdonor(3)=rhol(2)
            uldonor(3)=ul(2)
            endif
            rhodonor(3)=alphalDonor(3)*rholdonor(3)+
     %                  alphagDonor(3)*rhogs
            rhoudonor(3)=alphalDonor(3)*rholdonor(3)*uldonor(3)+
     %                   alphagDonor(3)*rhogs*ugs
            Vrg3=Vrg(alphalDonor(3),Px)
        endif
c.*****************************************
       alphalDonor(5)=0.
       alphagDonor(5)=0.
       rhodonor(5)=0.
       rhoudonor(5)=0.
       rholdonor(5)=rhofs
       uldonor(5)=ufs
       vl5=0.
       vg5=0.
c.
       rhoSRV=rho(3)
       rhouSRV=rhou(3)
c.
      if(PRZLVL.gt.HSRG)then
c.********************************************
        if(alphagDonor(4).eq.0.)then
        vl4=0.
        vg4=0.
          if(Vel(4).gt.0.)then
          rhodonor(4)=rhol(2)
          rhoudonor(4)=rhol(2)*ul(2)
          else
          rhodonor(4)=rhol(3)
          rhoudonor(4)=rhol(3)*ul(3)
          endif
        else
        vl4=Vel(4)-alphagDonor(4)*rhogs*Vrg(alphalDonor(4),Px)/
     %             rhodonor(4)
        vg4=Vel(4)+alphalDonor(4)*rhofs*Vrg(alphalDonor(4),Px)/
     %             rhodonor(4)
          if(vg4.gt.0.)then
          alphagDonor(4)=alphag(2)
          alphalDonor(4)=alphal(2)
          else
          alphagDonor(4)=alphag(3)
          alphalDonor(4)=1.-alphag(3)
          endif
            if(alphagDonor(4).eq.0.)then
              if(Vel(4).gt.0.)then
              rhodonor(4)=rhol(2)
              rhoudonor(4)=rhol(2)*ul(2)
              else
              rhodonor(4)=rhol(3)
              rhoudonor(4)=rhol(3)*ul(3)
              endif
            else
              if(vl4.gt.0.)then
              rholdonor(4)=rhol(2)
              uldonor(4)=ul(2)
              else
              rholdonor(4)=rhol(3)
              uldonor(4)=ul(3)
              endif
              rhodonor(4)=alphalDonor(4)*rholdonor(4)+
     %                    alphagDonor(4)*rhogs
              rhoudonor(4)=alphalDonor(4)*rholdonor(4)*uldonor(4)+
     %                     alphagDonor(4)*rhogs*ugs
              Vrg4=Vrg(alphalDonor(4),Px)
            endif
        endif
c.********************************************
c.       
      rhoSRV=rho(4)
      rhouSRV=rhou(4)
       if(rho(3).gt.rhofs)then
       alphagDonor(5)=0.
       alphalDonor(5)=alphal(4)
       Vrl5=Vrl(Px)
       else
       alphagDonor(5)=alphag(3)
       alphalDonor(5)=alphal(3)*alphal(4)
       Vrg5=Vrg(alphal(3),Px)
       Vrl5=Vrl(Px)
       endif
c.**********************************************************
      else
c.
      rhodonor(4)=0.
      rhoudonor(4)=0.
      rholdonor(4)=rhofs
      uldonor(4)=ufs
      alphagDonor(4)=alphag(2)
      alphalDonor(4)=alphal(2)*alphal(4)
      Vrg4=Vrg(alphal(2),Px)
      Vrl4=Vrl(Px)     
      endif
c.
      if(IDEBUG.eq.1)then
      write(14,*)' '
      write(14,*)'Donored Values'
      write(14,*)' '
      write(14,*)'vl3=',vl3,' vg3=',vg3
      write(14,*)'vl4=',vl4,' vg4=',vg4
      write(14,*)'vl5=',vl5,' vg5=',vg5
      write(14,*)' '
      write(14,*)'Vrl3=',Vrl3,' Vrg3=',Vrg3
      write(14,*)'Vrl4=',Vrl4,' Vrg4=',Vrg4
      write(14,*)'Vrl5=',Vrl5,' Vrg5=',Vrg5
      write(14,*)' '
      do j=1,5
      write(14,*)'j=',j,' alphagDonor=',alphagDonor(j),
     %                 ' alphalDonor=',alphalDonor(j)
      enddo
      write(14,*)' '
      do j=1,5
      write(14,*)'j=',j,' rholdonor=',rholdonor(j),
     %                 ' uldonor=',uldonor(j)
      enddo
      write(14,*)' '
      do j=1,5
      write(14,*)'j=',j,' rhodonor=',rhodonor(j),
     %                 ' rhoudonor=',rhoudonor(j)
      enddo
      write(14,*)' '
      endif
c.
c.***********************************
c.
c.    Compute Matrix Coefficients
c.
c.***********************************
c.
c.    Check for SRV opening
c.
      nSRVsOPEN=0
      do j=1,NPRZSRVs
      VelSRV(j)=0.
        if(Px.gt.PRZSETPOINT(j))then
        nSRVsOPEN=nSRVsOPEN+1
        endif
      enddo
c.
      if(nSRVsOPEN.gt.0)then
	  do j=1,nSRVsOPEN
        aSRV(j)=rhoSRV*AxSRV(j)*Deltat
        bSRV(j)=(rhouSRV+Px*144./778.)*AxSRV(j)*Deltat
        enddo
      endif
c.
c.    Node 2
c.
      call derivative(alphag(2),ul(2),Px,drhodPHI,drhodPx,rhoTILDA(2),
     %                drhoudPHI,drhoudPx,rhouTILDA)
      dM2dPx=Vol(2)*drhodPx
      dM2dPHI=Vol(2)*drhodPHI
      dM2u2dPx=Vol(2)*drhoudPx
      dM2u2dPHI=Vol(2)*drhoudPHI
c.
      a3=rhodonor(3)*Ax3*Deltat
      b3=(rhoudonor(3)+Px*144./778.)*Ax3*Deltat
c.
      a2P=dM2dPx/dM2dPHI-dM2u2dPx/dM2u2dPHI
      a23=-(a3/dM2dPHI-b3/dM2u2dPHI)
c.
      SM2=0.
      SE2=Qhtr(Px)*Deltat
        if(PRZLVL.lt.HSRG)then
        a4=0.
        b4=0.
        a24=0.
        dM2dV4=-rhoTILDA(2)
        dM2u2dV4=-rhouTILDA
c.
        SM2=(alphalDonor(4)*rhofs*Vrl4-
     %       alphagDonor(4)*rhogs*Vrg4)*Ax4*Deltat
        SE2=SE2+
     %      (alphalDonor(4)*Vrl4*(rhofs*ufs+Px*144./778.)-
     %       alphagDonor(4)*Vrg4*(rhogs*ugs+Px*144./778.))*Ax4*Deltat+
     %       alphalDonor(3)*rhofs*alphagDonor(3)*rhogs*Vrg3*
     %       (ufgs-Px*vfgs*144./778.)*Ax3*Deltat/rhodonor(3)
c.
        a2V=dM2dV4/dM2dPHI-dM2u2dV4/dM2u2dPHI
        else
        dM2dV4=0.
        dM2u2dV4=0.
        a2V=0.
c.
        a4=rhodonor(4)*Ax4*Deltat
        b4=(rhoudonor(4)+Px*144./778.)*Ax4*Deltat
        a24=(a4/dM2dPHI-b4/dM2u2dPHI)
c.
        SE2=SE2+
     %      (alphalDonor(3)*rhofs*alphagDonor(3)*rhogs*Vrg3*
     %      (ufgs+Px*vfgs*144./778.))*Ax3*Deltat/rhodonor(3)
          if(alphagDonor(4).gt.0.)then
          SE2=SE2-
     %        (alphalDonor(4)*rholDonor(4)*alphagDonor(4)*rhogs*Vrg4*
     %        (ugs-uldonor(4)+Px*(vgs-1./rholdonor(4))*144./778.))*
     %         Ax4*Deltat/rhodonor(4)
          endif
c.
        endif
c.
      S2=(Mass(2)-Vol(2)*rhoTILDA(2)+SM2)/dM2dPHI-
     %   (E(2)-Vol(2)*rhouTILDA+SE2)/dM2u2dPHI
c.
c.    Node 3
c.
      dM3dPx=0.
      dM3dPHI=0.
      dM3u3dPx=0.
      dM3u3dPHI=0.
c.
      if(PRZLVL.gt.HSRG)then
      call derivative(alphag(3),ul(3),Px,drhodPHI,drhodPx,rhoTILDA(3),
     %                drhoudPHI,drhoudPx,rhouTILDA)
      dM3dPx=Vol(3)*drhodPx
      dM3dPHI=Vol(3)*drhodPHI
      dM3u3dPx=Vol(3)*drhoudPx
      dM3u3dPHI=Vol(3)*drhoudPHI
      dM3dV4=-rhoTILDA(3)
      dM3u3dV4=-rhouTILDA
c.
      a3P=dM3dPx/dM3dPHI-dM3u3dPx/dM3u3dPHI
      a34=-(a4/dM3dPHI-b4/dM3u3dPHI)
      a3V=dM3dV4/dM3dPHI-dM3u3dV4/dM3u3dPHI
c.
      SM3=(alphalDonor(5)*rhofs*Vrl5-
     %     alphagDonor(5)*rhogs*Vrg5)*Ax5*Deltat
      SE3=(alphalDonor(5)*Vrl5*(rhofs*ufs+Px*144./778.)-
     %     alphagDonor(5)*Vrg5*(rhogs*ugs+Px*144./778.))*Ax5*Deltat+
     %    (alphalDonor(4)*rholDonor(4)*alphagDonor(4)*rhogs*Vrg4*
     %    (ugs-uldonor(4)+Px*(vgs-1./rholdonor(4))*144./778.))*
     %     Ax4*Deltat/rhodonor(4)
c.
      S3=(Mass(3)-Vol(3)*rhoTILDA(3)+SM3)/dM3dPHI-
     %   (E(3)-Vol(3)*rhouTILDA+SE3)/dM3u3dPHI
      endif
c.
c.    Node 4
c.
        if(alphag(4).lt.1.)then
        call derivative(alphag(4),ul(4),Px,drhodPHI,drhodPx,rhoTILDA(4),
     %                  drhoudPHI,drhoudPx,rhouTILDA)
        else
        call derivative(alphag(4),uv(4),Px,drhodPHI,drhodPx,rhoTILDA(4),
     %                  drhoudPHI,drhoudPx,rhouTILDA)
        endif
c.
      dM4dPx=Vol(4)*drhodPx
      dM4dPHI=Vol(4)*drhodPHI
      dM4u4dPx=Vol(4)*drhoudPx
      dM4u4dPHI=Vol(4)*drhoudPHI
      dM4dV4=rhoTILDA(4)
      dM4u4dV4=rhouTILDA
c.
      a4P=dM4dPx/dM4dPHI-dM4u4dPx/dM4u4dPHI
      a4V=dM4dV4/dM4dPHI-dM4u4dV4/dM4u4dPHI
c.
        if(PRZLVL.gt.HSRG)then
c.
        SM4=rhoSPRAY*Vspray*AxSPRAY*Deltat-
     %      (alphalDonor(5)*rhofs*Vrl5-
     %       alphagDonor(5)*rhogs*Vrg5)*Ax5*Deltat
        
        SE4=(rhouSPRAY+Px*144./778.)*Vspray*AxSPRAY*Deltat-
	%      (alphalDonor(5)*Vrl5*(rhofs*ufs+Px*144./778.)-
     %       alphagDonor(5)*Vrg5*(rhogs*ugs+Px*144./778.))*Ax5*Deltat
        else
        SM4=rhoSPRAY*Vspray*AxSPRAY*Deltat-
     %      (alphalDonor(4)*rhofs*Vrl4-
     %       alphagDonor(4)*rhogs*Vrg4)*Ax4*Deltat
        SE4=(rhouSPRAY+Px*144./778.)*Vspray*AxSPRAY*Deltat-
     %      (alphalDonor(4)*Vrl4*(rhofs*ufs+Px*144./778.)-
     %       alphagDonor(4)*Vrg4*(rhogs*ugs+Px*144./778.))*Ax4*Deltat
        endif
      S4=(Mass(4)-Vol(4)*rhoTILDA(4)+SM4)/dM4dPHI-
     %   (E(4)-Vol(4)*rhouTILDA+SE4)/dM4u4dPHI
c.		
c.    SRV Equations
c.
      if(nSRVsOPEN.gt.0)then
        do n=1,nSRVsOPEN
        VelSRV(n)=sqrt(2.*gc*(Px-Pamb)*144./(rhoSRV*KPRZSRV(n)))
        Gamma=KPRZSRV(n)*rhoSRV*VelSRV(n)/gc
        Psi=(Px-Pamb)*144.-KPRZSRV(n)*rhoSRV*VelSRV(n)**2/(2.*gc)
        Gamma=Gamma/144.
        Psi=Psi/144.
c.
        a4SRV=aSRV(n)/dM4dPHI-bSRV(n)/dM4u4dPHI
        a4P=a4P+a4SRV/Gamma
        S4=S4-a4SRV*Psi/Gamma
        enddo
      endif
c.
c.
c.    Orifice Momentum Equation
c.
      DeltaP=(Pp-Px)*144.-rho(2)*HSRG/2.
      Vel(3)=0.
        if(abs(DeltaP).gt.0.)then
        Vel(3)=sqrt(2.*gc*abs(DeltaP)/(KPRZ(3)*rhodonor(3)))*
     %         abs(DeltaP)/DeltaP
        endif
      Gamma3=KPRZ(3)*rhodonor(3)*abs(Vel(3))/gc
      SMB3=rho(2)*HSRG/2.+(Px-Pp)*144.-
     %     KPRZ(3)*rhodonor(3)*Vel(3)*abs(Vel(3))/(2.*gc)
      Gamma3=Gamma3/144.
      SMB3=SMB3/144.
c.
c.    Primary Mass Balance Equation
c.
      TermPp=0.
      MpTILDA=0.
       do j=1,26
       TermPp=TermPp+Vp(j)*drhopdP(ulp(j),Pp)
       MpTILDA=MpTILDA+Vp(j)*drhopdu(ulp(j),Pp)*(ulp(j)-ulp0(j))
       enddo
      SMp=-MpTILDA+(mdotCHRG-mdotLD)*Deltat
c.
      Gamma3=Gamma3+a3/TermPp
      SMB3=SMB3-SMp/TermPp
      if(IDEBUG.eq.1)then
      write(14,*)'QHTR=',QHTR(Px)
      write(14,*)'SM2=',SM2,' SE2=',SE2
      write(14,*)'SM3=',SM3,' SE3=',SE3
      write(14,*)'SM4=',SM4,' SE4=',SE4
      write(14,*)' '
      write(14,*)'S2=',S2,' S3=',S3,' S4=',S4
      write(14,*)'MpTILDA=',MpTILDA
      write(14,*)'SMB3=',SMB3,' SMp=',SMp
      write(14,*)'TermPp=',TermPp
      endif
c.
c.    Matrix Solution
c.
      if(PRZLVL.lt.HSRG)then
c.
      beta=a2p-a4p*(a2V/a4V)-a23/Gamma3
      dPx=(1./beta)*(S2+SMB3*a23/Gamma3-
     %               S4*a2V/a4V)
      dV4=(S4-a4p*dPx)/a4V
c.
      Vel(1)=0.
      Vel(2)=0.           
      Vel(3)=-(dPx+SMB3)/Gamma3
      Vel(4)=0.
c.
      Pxnew=Px+dPx
      V4new=Vol(4)+dV4
c.
      else
c.
      beta=-a2p*a34/a24+a3p-a4p*a3V/a4V+
     %     (a23/Gamma3)*(a34/a24)
      dPx=(1./beta)*(-S2*a34/a24+S3-S4*a3V/a4V-
     %                SMB3*(a23/Gamma3)*(a34/a24))
	dV4=(S4-a4p*dPx)/a4V
c.
      Vel(1)=0.
      Vel(2)=0.
      Vel(3)=-(dPx+SMB3)/Gamma3
      Vel(4)=(S2-a2p*dPx-Vel(3)*a23)/a24
c.
      Pxnew=Px+dPx
      V4new=Vol(4)+dV4
      endif
c.
c.    Update Primary Side Pressure
c.
      Pp=Pp+(SMp-a3*Vel(3))/TermPp
c.
      if(nSRVsOPEN.gt.0)then
        do n=1,nSRVsOPEN
        VelSRV(n)=sqrt(2.*gc*(Pxnew-Pamb)*144./(rhoSRV*KPRZSRV(n)))
        enddo
      endif
c.
      rhofs=rhof(Pxnew)
      rhogs=rhog(Pxnew)
      ufs=uf(Pxnew)
      ugs=ug(Pxnew)
      ufgs=ugs-ufs
      vfgs=(1./rhogs-1./rhofs)
c.
c.    Update Mass, Energy and Volumes
c.
      NewMass(2)=Mass(2)+a3*Vel(3)-a4*Vel(4)+SM2
      NewE(2)=E(2)+b3*Vel(3)-b4*Vel(4)+SE2
c.
      if(Vol(3).eq.0.)then
c.
      Vol(2)=(VPRZ-V4new)
c.
      rho(2)=NewMass(2)/Vol(2)
      rhou(2)=NewE(2)/Vol(2)
c.
      rhov(2)=rhogs
      uv(2)=ugs
c.
        if(rho(2).lt.rhofs)then
        alphag(2)=(rhofs-rho(2))/(rhofs-rhogs)
        alphal(2)=1.-alphag(2)
        rhol(2)=rhofs
        ul(2)=ufs
        else
        alphag(2)=0.
        alphal(2)=1.
        rhol(2)=rho(2)
        Call IEsearchl(rhol(2),Pxnew,uliq,IFLAGU)
        ul(2)=uliq
        endif
c.
      NewMass(3)=0.
      NewE(3)=0.
      rho(3)=rhogs
      rhou(3)=rhogs*ugs
      rhol(3)=rhofs
      ul(3)=ufs
      rhov(3)=rhogs
      uv(3)=ugs
c.
      NewMass(4)=Mass(4)+SM4
      NewE(4)=E(4)+SE4
        if(nSRVsOPEN.gt.0)then
          do n=1,nSRVsOPEN
          NewMass(4)=NewMass(4)-aSRV(n)*VelSRV(n)
          NewE(4)=NewE(4)-bSRV(n)*VelSRV(n)
          enddo
        endif
      rho(4)=NewMass(4)/V4new
      rhou(4)=NewE(4)/V4new
      Vol(4)=V4new
        if(rho(4).ge.rhogs)then
        alphag(4)=(rhofs-rho(4))/(rhofs-rhogs)
        alphal(4)=1.-alphag(4)
        rhol(4)=rhofs
        ul(4)=ufs
        else
        alphag(4)=1.
        alphal(4)=0.
        rhov(4)=rho(4)
        Call IEsearchv(rhov(4),Pxnew,uvap,IFLAGU)
          if(IFLAGU.eq.1)then
          write(*,*)'Root not in interval in IEsearchv'
          elseif(IFLAGU.eq.2)then
          write(*,*)'Max iterations exceeded in IEsearchv'
          endif
        uv(4)=uvap
        endif
c.
      Call PRZGEOM(PRZLVL)
c.
          if(V4new.lt.VHEAD)then
c.
          VOL2=Vol(2)
          Vol(3)=Vol(2)-VSRG
          Vol(2)=VSRG
c.
          NewMass(2)=NewMass(2)*Vol(2)/VOL2
          NewE(2)=NewE(2)*Vol(2)/VOL2
c.
          rho(3)=rho(2)
          rhou(3)=rhou(2)
          alphag(3)=alphag(2)
          alphal(3)=alphal(2)
          rhol(3)=rhol(2)
          ul(3)=ul(2)
          rhov(3)=rhov(2)
          uv(3)=uv(2)
          NewMass(3)=rho(3)*Vol(3)
          NewE(3)=rhou(3)*Vol(3)
c.
          Call PRZGEOM(PRZLVL)
c.
          endif
      else
	NewMass(3)=Mass(3)+a4*Vel(4)+SM3
      NewE(3)=E(3)+b4*Vel(4)+SE3
c.
      NewMass(4)=Mass(4)+SM4
      NewE(4)=E(4)+SE4
        if(nSRVsOPEN.gt.0)then
          do n=1,nSRVsOPEN
          NewMass(4)=NewMass(4)-aSRV(n)*VelSRV(n)
          NewE(4)=NewE(4)-bSRV(n)*VelSRV(n)
          enddo
        endif
c.
      rho(2)=NewMass(2)/Vol(2)
      rhou(2)=NewE(2)/Vol(2)
c.
      rhov(2)=rhogs
      uv(2)=ugs
c.
        if(rho(2).lt.rhofs)then
        alphag(2)=(rhofs-rho(2))/(rhofs-rhogs)
        alphal(2)=1.-alphag(2)
        rhol(2)=rhofs
        ul(2)=ufs
        else
        alphag(2)=0.
        alphal(2)=1.
        rhol(2)=rho(2)
        Call IEsearchl(rhol(2),Pxnew,uliq,IFLAGU)
        ul(2)=uliq
        endif
c.
          if((V4new.ge.0.975*VHEAD).and.(Vel(4).lt.0.))then
c.
          Mtot=NewMass(3)+NewMass(4)
          Etot=NewE(3)+NewE(4)
c.
          Vol(3)=0.
          NewMass(3)=0.
          NewE(3)=0.
c.
          Vol(4)=VHEAD
          NewMass(4)=Mtot
          NewE(4)=Etot
c.
          rho(4)=NewMass(4)/Vol(4)
          rhou(4)=NewE(4)/Vol(4)
c.
          u4=rhou(4)/rho(4)
c.
          alphag(4)=rhofs*(u4-ufs)/(rhofs*(u4-ufs)+rhogs*(ugs-u4))
          alphal(4)=1.-alphag(4)
          rhol(4)=rhofs
          ul(4)=ufs
c.
          PRZLVL=HSRG-0.01
          else
c.																
          Vol(3)=VHEAD-V4new
          Vol(4)=V4new
c.
          rho(3)=NewMass(3)/Vol(3)
          rhou(3)=NewE(3)/Vol(3)
c.
          rhov(3)=rhogs
          uv(3)=ugs
c.
            if(rho(3).lt.rhofs)then
            alphag(3)=(rhofs-rho(3))/(rhofs-rhogs)
            alphal(3)=1.-alphag(3)
            rhol(3)=rhofs
            ul(3)=ufs																		 
            else
            alphag(3)=0.
            alphal(3)=1.
            rhol(3)=rho(3)
            Call IEsearchl(rhol(3),Pxnew,uliq,IFLAGU)
            ul(3)=uliq
            endif
c.
          rho(4)=NewMass(4)/Vol(4)
          rhou(4)=NewE(4)/Vol(4)
c.
          rhol(4)=rhofs
          ul(4)=ufs
c.
          rhov(4)=rhogs
          uv(4)=ugs
c.
            if(rho(4).ge.rhogs)then
            alphag(4)=(rhofs-rho(4))/(rhofs-rhogs)
            alphal(4)=1.-alphag(4)
            else
            alphag(4)=1.
            alphal(4)=0.
            rhov(4)=rho(4)
            Call IEsearchv(rhov(4),Pxnew,uvap,IFLAGU)
          if(IFLAGU.eq.1)then
          write(*,*)'Root not in interval in IEsearchv'
          elseif(IFLAGU.eq.2)then
          write(*,*)'Max iterations exceeded in IEsearchv'
          endif
            uv(4)=uvap
            endif
          call PRZGEOM(PRZLVL)
          endif
      endif	
c.
      do j=1,4
      Mass(j)=NewMass(j)
      E(j)=NewE(j)
      enddo
c.
      Px=Pxnew
c.
      if(IDEBUG.eq.1)then
      close(unit=14)
      endif
      Return
	End
c.
c.**************************************************
c.
c.    Function Subprogram to Compute Pressurizer Heater Output
c.
      Function QHTR(Px)
c.
      Common/PressurizerHeaterData/Qprop,Qbackup,TauHEATER,
     %                             PRZHTRGain0,PRZHTRGain1,PRZHTRGain2
      Common/SimulationControlData/Deltat
      Common/PRZHTRINIT/QHTRP,QHTRB
c.
      Call HeaterDemand(Px,DemandP,DemandB)
c.
c.    Proportional Banks
c.
      QHTRP=QHTRP*exp(-Deltat/TauHEATER)+
     %      DemandP*(1.-exp(-Deltat/TauHEATER))
c.
c.    Backup Banks
c.
      QHTRB=QHTRB*exp(-Deltat/TauHEATER)+
     %      DemandB*(1.-exp(-Deltat/TauHEATER))
c.
      QHTR=QHTRP+QHTRB
      Return
      End
c.
c.**************************************************
c.
c.    Subroutine to Compute Pressurizer Heater Demand
c.
      Subroutine HeaterDemand(Px,DemandP,DemandB)
      Real KPRZSRV,KPRZ
      Common/SimulationControlData/Deltat
      Common/PressurizerHeaterData/Qprop,Qbackup,TauHEATER,
     %                             PRZHTRGain0,PRZHTRGain1,PRZHTRGain2
      Common/PressurizerData/KPRZSRV(4),AxSRV(4),KPRZ(4),
     %                       PRZSETPOINT(9),NPRZSRVs
      Common/PRZHTRINIT/QHTRP,QHTRB
c.
      Data ICALL/0/
      Data MODE/1/
      Data SUMERROR/0./
c.
      ICALL=ICALL+1
      Pref=PRZSETPOINT(5)
        if(ICALL.eq.1)then
        Demand0=QHTRP/Qprop
        endif
c.
      if(Px.ge.PRZSETPOINT(8))then
      MODE=0
      elseif(Px.ge.PRZSETPOINT(7))then
      MODE=1
      elseif(Px.le.PRZSETPOINT(6))then
      MODE=3
      else
        if(MODE.eq.1)then
        MODE=2
        endif
      endif      
c.
      if(MODE.eq.0)then
      DemandP=0.
      DemandB=0.
c.
      elseif(MODE.eq.1)then
c.
      ERROR=(Pref-Px)
      SUMERROR=SUMERROR+ERROR*Deltat
c.
      Demand=Demand0+PRZHTRGain0+PRZHTRGain1*ERROR+PRZHTRGain2*SUMERROR
      DemandP=Demand*Qprop
        if(DemandP.gt.Qprop)then
        DemandP=Qprop
        elseif(DemandP.lt.0.)then
        DemandP=0.
        endif
      DemandB=0.
c.
      elseif(MODE.eq.2)then
      DemandP=Qprop
      DemandB=0.
c.
      elseif(MODE.eq.3)then
      DemandP=Qprop
      DemandB=Qbackup
      endif
c.
      Return
      End
c.**************************************************
c.
c.    Function Subprogram to Compute Vapor Phase Relative Velocity
c.
      Function Vrg(alphal,P)
      g=4.17e8
      gc=g
c.
      if(alphal.gt.0.)then
      Term=sigma(P)*g*gc*(rhof(P)-rhog(P))/rhof(P)**2
      Vrg=1.41*Term**0.25/alphal
      else
      Vrg=0.
      endif
c.
      Return
      End       
c.**************************************************
c.
c.    Function Subprogram to Compute Liquid Phase Relative Velocity
c.
      Function Vrl(P)
      g=4.17e8
      gc=g
c.
      Term=sigma(P)*g*gc*(rhof(P)-rhog(P))/rhog(P)**2
      Vrl=1.41*Term**0.25
c.
      Return
      End       
c.**************************************************
c.
c.    Subroutine to compute Pressurizer Geometry
c.
      Subroutine PRZGEOM(PRZLVL)
c.
      EXTERNAL ZLVL
c.
      Common/PressurizerGeometry/RSRG,RDOME,HSRG,HCYL,
     %                           Ax3,Ax4,Ax5,AxVESSEL,
     %                           VSRG,VDOME,VHEAD,VPRZ,
     %                           VOL(4)
c.
      Pi=3.1415926
      Ax5=AxVESSEL
c.
      If(VOL(4).le.VDOME)then
      zlow=0.
      zhigh=RDOME
      Call Brent(ZLVL,zlow,zhigh,z,icount)
      PRZLVL=HSRG+HCYL+z
      rsqrd=RDOME**2-z**2
      Ax5=Pi*rsqrd
      endif
c.
        if((VOL(4).gt.VDOME).and.(VOL(4).le.VHEAD))then
        PRZLVL=HSRG+(VHEAD-VOL(4))/AxVESSEL
        endif
          if(VOL(4).gt.VHEAD)then
          PRZLVL=(VPRZ-VOL(4))/Ax4
          endif
      Return
      End
c.
      Function ZLVL(z)
      Common/PressurizerGeometry/RSRG,RDOME,HSRG,HCYL,
     %                           Ax3,Ax4,Ax5,AxVESSEL,
     %                           VSRG,VDOME,VHEAD,VPRZ,
     %                           VOL(4)
      Pi=3.1415926
      VOLUME=VDOME-VOL(4)
      ZLVL=Pi*z**3/3.-Pi*RDOME**2*z+VOLUME
      Return
      End      
c.*********************************************************************
c.
c.    Subroutine to find the internal energy of a subcooled liquid
c.
      Subroutine IEsearchl(rho,P,u1,IFLAGU)
      F1(u1)=rhop(u1,P)-rho
      icount=0
      err=1.
      a=32.
      b=uf(P)
      u1=b
      IFLAGU=1
      if(F1(a)*F1(b).lt.0.)then
      u1=b
      do while(err.gt.1.e-5.and.icount.lt.20)
      icount=icount+1
c.
      dF1du1=drhopdu(u1,P)
c.
c.
      delu=-F1(u1)/dF1du1
      err=abs(delu/u1)
      u=u1+delu
      if(u.gt.b.or.u.lt.a)u=(a+b)/2.     
        if(F1(a)*F1(u).gt.0.)then
        a=u
        else
        b=u
        endif
      u1=u
      enddo
      if(icount.lt.20)IFLAGU=0
      endif
      Return
      end
c.
c.    Subroutine to find the internal energy of a superheated vapor
c.
      Subroutine IEsearchv(rho,P,u1,IFLAGU)
      F1(u1)=rhovsup(u1,P)-rho
      icount=0
      err=1.
      delu=150.
      a=ug(P)
      b=a+delu
      u1=a
      IFLAGU=1
      if(F1(a)*F1(b).lt.0.)then
      IFLAGU=2
      u1=a
      do while(err.gt.1.e-5.and.icount.lt.20)
      icount=icount+1
c.
      dF1du1=drhovsupdu(u1,P)
c.
c.
      delu=-F1(u1)/dF1du1
      err=abs(delu/u1)
      u=u1+delu
      if(u.gt.b.or.u.lt.a)u=(a+b)/2.     
        if(F1(a)*F1(u).gt.0.)then
        a=u
        else
        b=u
        endif
      u1=u
      enddo
      if(icount.lt.20)IFLAGU=0
      endif
      if(IFLAGU.eq.1)then
      write(*,*)'rho=',rho
      write(*,*)'P=',P
      write(*,*)'rho(a)=',rhovsup(a,P)
      write(*,*)'rho(b)=',rhovsup(b,P)
      write(*,*)'F1(a)=',F1(a)
      write(*,*)'F1(b)=',F1(b)
      endif
c.      write(*,*)'icount=',icount
      Return
      end
c.
c.    Subroutine to model critical heat flux in the hot channel
c.
      Subroutine HotChannel(TfuelHot,uin,uHOT,mdotcore,
     %                      Qtrans,Qth,Deltat,P,MDNBR)
      EXTERNAL FHOT
      Real ldnbn,ldnbeu,MDNBR,mdotcore,MdotChannel
      Real kc,k,kl,mu
      Common/FluidProperties/rhol,Cp,mu,k
      Common /HotRod/alamda,De,Ax,Fq,Fz,nodes,ICHF
      Common /FuelProperties/rhoUO2,D,Dpellet,FuelHeight,P_D,
     %                       Gammaf,tc,rhoc,Cpc,kc,HG,nrods
      Common/HotChannelParameters/Vstar,rhoHOT,G,MdotChannel,SOURCE,
     %                            Pchannel,IPHASE
      Dimension TfuelHot(50)
      Dimension qPhot(150),qDPhot(150)
c      Dimension rhouHOT(150),uHOT(150),hHOT(150)
      Dimension uHOT(150),hHOT(150)
      IDEBUG=0
      if(IDEBUG.ne.0)then
      open(unit=14,file='Debug.dat')
      endif
c.
      Hcore=FuelHeight
      He=Hcore+2.*alamda      
      Pi=3.1415926
      Deltaz=Hcore/float(nodes)
      G=mdotcore/Ax
      Pchannel=P*1.
      uMIN=18.
c.
      hfs=uf(P)+P/rhof(P)*(144./778.)
      hgs=ug(P)+P/rhog(P)*(144./778.)
      hfgs=hgs-hfs
c.
      gc=4.17e8
      C0=1.13
      Vgj=1.41*(sigma(P)*gc*gc*(rhof(P)-rhog(P))/rhof(P)**2)**.25
c.
      Gstar=G/(rhog(P)*Vgj)
      epsilon=rhog(P)/rhof(P)
c.
      AxChannel=D**2*(P_D**2-Pi/4.)
      Vstar=AxChannel*Deltaz/Deltat
      MdotChannel=G*AxChannel
      hin=uin+(P/rhop(uin,P))*(144./778.)
      xinlet=(hin-hfs)/hfgs
c.
c.    Determine Heat Added Per Unit Length in the Hot Channel
c.
      Q=Qtrans+(1.-Gammaf)*Qth*3.4137e6
      qPHOT0=qprime(0.,Q)*(Fq/Fz)/float(nrods)
      do i=1,nodes
      z=float(i)*Deltaz
      qPHOT(i)=qprime(z,Q)*(Fq/Fz)/float(nrods)
      enddo
c.
c.    Compute Maximum Heat Flux in the hot channel
c.
      qDPmax=Qtrans*Fq/(float(nrods)*Pi*D*Hcore)
c.
      if(IDEBUG.gt.0)then
      write(14,*)' '
      write(14,*)'Maximum Heat Flux'
      write(14,*)' '
      write(14,*)'qDPmax=',qDPmax
      write(14,*)'De=',De
      write(14,*)'hin=',hin,' uin=',uin
      write(14,*)'hf=',hfs,' hg=',hgs,' hfg=',hfgs
      write(14,*)'mdotcore=',mdotcore
      write(14,*)'mdotchannel=',MdotChannel
      endif
c.
c.    Compute the Heat Flux profile in the hot channel
c.
      qDPhot0=qprime(0.,Qtrans)*(Fq/Fz)/(float(nrods)*Pi*D)
      do i=1,nodes
      z=float(i)*Deltaz
      qDPhot(i)=qprime(z,Qtrans)*(Fq/Fz)/(float(nrods)*Pi*D)
      enddo
c.
c.****************************************************************************
c.
c.    Compute Internal Energy and Enthalpy Distribution in the Hot Channel
c.
      Do i=1,nodes
       if(i.eq.1)then
       Qin=(qPHOT(i)+qPHOT0)*Deltaz/2.
       else
       Qin=(qPHOT(i)+qPHOT(i-1))*Deltaz/2.
       endif
c.
       if(uHOT(i).lt.uf(P))then
       alphag=0.
       rhoHOT=rhop(uHOT(i),P)
       else
       alphag=rhof(P)*(uf(P)-uHOT(i))/
     %        (rhof(P)*(uf(P)-uHOT(i))-rhog(P)*(ug(P)-uHOT(i)))
       rhoHOT=rhof(P)-alphag*(rhof(P)-rhog(P))
       endif
c.     
       if(i.eq.1)then
       SOURCE=Vstar*rhoHOT*uHOT(i)+MdotChannel*hin+Qin
       else
       SOURCE=Vstar*rhoHOT*uHOT(i)+MdotChannel*hHOT(i-1)+Qin
       endif
c.
      if(IDEBUG.eq.1)then
      write(14,*)' '
      write(14,*)'i=',i,' Qin=',Qin,' alphag=',alphag,' rhoHOT=',rhoHOT
      write(14,*)'uHOT=',uHOT(i),' SOURCE=',SOURCE
      endif
c.
      TEST=Vstar*rhoHOT*uf(P)+MdotChannel*hfs-SOURCE
c.*********************************************************************
       if(TEST.gt.0.)then
       IPHASE=1
c.
         if(FHOT(uin).lt.0.)then
         uLOW=uin
         else
         uLOW=uMIN
         endif
c.
       uHIGH=uf(P)
       Call Brent(FHOT,uLOW,uHIGH,uHOT(i),icount)
c.         if(FHOT(uLOW)*FHOT(uHIGH).ge.0.)then
c.         write(*,*)'Root not in interval in FHOT'
c.         write(*,*)'uLOW=',uLOW,' uHIGH=',uHIGH
c.         write(*,*)'FLOW=',FHOT(uLOW),' FHIGH=',FHOT(uHIGH)
c.         write(*,*)'FMIN=',FHOT(uMIN)
c.         stop
c.         endif
       hHOT(i)=uHOT(i)+P/rhop(uHOT(i),P)*(144./778.)
c.
      if(IDEBUG.eq.1)then
      write(14,*)'FHOT Low=',FHOT(uin),' FHOT High=',FHOT(uf(P))
      write(14,*)'TEST=',TEST,' IPHASE=',IPHASE,' icount=',icount
      write(14,*)'uHOT=',uHOT(i),' uf=',uf(P)
      write(14,*)'hHOT=',hHOT(i),' hf=',hfs
      endif
c.
c.********************************************************************
       else
       IPHASE=2
       xLOW=0.
c.       xHIGH=0.1
       xHIGH=0.2
       Call Brent(FHOT,xLOW,xHIGH,x,icount)
       alphag=x/(C0*(x+epsilon*(1.-x))+1./Gstar)
       hHOT(i)=hfs+x*hfgs
       rhouHOT=rhof(P)*uf(P)-alphag*(rhof(P)*uf(P)-rhog(P)*ug(P))
       rhoHOT=rhof(P)-alphag*(rhof(P)-rhog(P))
       uHOT(i)=rhouHOT/rhoHOT
c.
      if(IDEBUG.eq.1)then
      write(14,*)'FHOT Low=',FHOT(0.),' FHOT High=',FHOT(0.1)
      write(14,*)'TEST=',TEST,' IPHASE=',IPHASE,' icount=',icount
      write(14,*)'alpha=',alphag,' x=',x
      write(14,*)'uHOT=',uHOT(i),' uf=',uf(P)
      write(14,*)'hHOT=',hHOT(i),' hf=',hfs
      endif
c.
       endif
c.
      enddo
c.
c.*****************************************************************************            
c.
c.    Compute Clad Temperature and convective heat transfer coefficient at position of maximum heat
c.
        if(hHOT(nodes/2).lt.hfs)then
        Tin=Temp(uin)
        Tinf=Temp(uhot(nodes/2))
        rhol=density(Tin)
        Cp=Cpl(Tin,P)
        k=kl(Tin,P)
        mu=Viscosity(Tin,P)
        hcrx=hcW(G,De,P_D)
        TcladMAX=Tinf+qDPmax/hcrx
        H1p=hcrx
        H2p=0.
          if(TcladMax.gt.Tsat(P))then
            Tw=Tsat(P)+0.072*exp(-P/1260.)*sqrt(qDPmax)
              if(TcladMAX.gt.Tw)then
              TcladMAX=Tw
              H1p=0.
              H2p=192.9*exp(2.*P/1260.)*(TcladMAX-Tsat(P))
              endif
          endif
        else
        TcladMAX=Tsat(P)+0.072*exp(-P/1260.)*sqrt(qDPmax)
        H1p=0.
        H2p=192.9*exp(2.*P/1260.)*(TcladMAX-Tsat(P))
        endif	               
c.
c.    Compute Fuel Temperature Distribution
c.
      Call PeakPin(Qth,Qth,Tinf,Tinf,P,P,Deltat,H1p,H2p,TfuelHot,
     %             TbarHOT,TcladHOT,1)
c.
      if(IDEBUG.eq.1)then
      write(14,*)' '
      write(14,*)'Peak Fuel Temperatures'
      write(14,*)' '
      write(14,*)'Tinf=',Tinf,' Tsat=',Tsat(P)
      write(14,*)'TcladMAX=',TcladMAX
      write(14,*)'h1p=',h1p
      write(14,*)'h2p=',h2p
      write(14,*)' '
      do i=1,15
      write(14,*)'i=',i,' TfuelHot(i)=',TfuelHot(i)
      enddo
      endif
c.
      MDNBR=1000.
      do i=nodes/2,nodes
      ldnbn=float(i)*Deltaz
c.
c.    Compute local quality
c.
      x=(hHOT(i)-hfs)/hfgs
c.
      if((ICHF.eq.1).or.(ICHF.eq.2))then
        if(ICHF.eq.1)then
c.******************************************************************************
c.
c.      Compute critical heat flux in a uniform channel using the W3 Correlation 
c.
        quniform=qcritEU(x,G,P,De,uin)
c.
        elseif(ICHF.eq.2)then
c.
c.      Compute critical heat flux in a uniform channel using the Bowring correlation
c.
        Call CHFB(De,G,P,x,qcritB)
c.
        quniform=qcritB
c.
        endif
c.
      if(IDEBUG.eq.2)then
      write(14,*)' '
      write(14,*)'Uniform critical heat flux calculation'
      write(14,*)' '
      write(14,*)'G=',G,' P=',P
      write(14,*)'hf=',hfs,' hg=',hgs,' hHOT=',hHOT(i)
      write(14,*)'ldnbn=',ldnbn,' x=',x
      write(14,*)'qcrit uniform=',quniform
      write(14,*)' '
      endif
c.
c.    Compute axial location of DNB in a uniform channel
c.
      ldnbeu=mdotcore*(hHOT(i)-hin)/(quniform*Pi*D*float(nrods))
c.
c.    Compute Tong F Factor
c.
      C=0.44*(1.-x)**7.9/((G/1.e6)**1.72)
      C=C*12.
      xn=Pi*(ldnbn+alamda)/He
      x0=Pi*alamda/He
      F1=(C*He/Pi)*sin(xn)-cos(xn)
      F2=exp(-C*ldnbn)*((C*He/Pi)*sin(x0)-cos(x0))
      Fstar=qDPmax*(He/Pi)*(F1-F2)/((C*He/Pi)**2+1.)
      Fstar=C*Fstar/(qDPhot(i)*(1.-exp(-C*ldnbeu)))
      F=Fstar
c.
      if(IDEBUG.eq.2)then
      write(14,*)' '
      write(14,*)'C=',C/12.
      write(14,*)'ldnbeu=',ldnbeu,' F=',F,' qcritn=',qcritn
      write(14,*)'qDPhot=',qDPhot(i),' DNBR=',DNBR
      write(14,*)'**********************************'
      endif
c.
c.    Compute nonuniform critical heat flux
c.
      qcritn=quniform/F
c.
c.*********************************************************************
c.
      elseif(ICHF.eq.3)then
c.
c.    Compute Critical Heat Flux using The EPRI-1 Correlation
c.
      Pcritical=3208.2
c.
c.    Constants in the EPRI-1 Correlation
c.
      P1=0.5328
      P2=0.1212
      P3=1.6151
      P4=1.4066
      P5=-0.3040
      P6=0.4843
      P7=-0.3285
      P8=-2.0749
c.
      Prel=P/Pcritical
      Gstar=G/1.e6
      qL=qDPhot(i)/1.e6
c.
      A=P1*(Prel**P2)*Gstar**(P5+P7*Prel)
      C=P3*(Prel**P4)*Gstar**(P6+P8*Prel)
c.
c.    Non Uniform Heat Flux Correction Factor
c.
      xn=Pi*(ldnbn+alamda)/He
      x0=Pi*alamda/He
      F1=(He/(Pi*ldnbn))*(cos(x0)-cos(xn))
      Y=F1/sin(xn)
      Cnu=1.+(Y-1.)/(1.+Gstar)            
c.
      qcr=(A-xinlet)/(C*Cnu+(x-xinlet)/qL)      
      qcritn=1.e6*qcr
      endif
c.*********************************************************************

c.    Compute DNB Ratio
c.
      DNBR=qcritn/qDPhot(i)
c.
c.    Compute minimum DNB Ratio
c.
      MDNBR=AMIN1(DNBR,MDNBR)
c.
      enddo
      if(IDEBUG.eq.2)then
      write(14,*)' '
      write(14,*)'MDNBR=',MDNBR
      endif
c      stop
      Return
      end
c.
c.    Function subprogram to compute core averaged linear heat rate
c.
      Function qprime(z,Q)
      Real kc
      Common /HotRod/alamda,De,Ax,Fq,Fz,nodes,ICHF
      Common /FuelProperties/rhoUO2,Diameter,Dpellet,FuelHeight,P_D,
     %                       Gammaf,tc,rhoc,Cpc,kc,HG,nrods
      Pi=3.1415926
      Hcore=FuelHeight
      He=Hcore+2.*alamda
      q0=Pi*Q/(cos(Pi*alamda/He)-cos(Pi*(Hcore+alamda)/He))/He
      qprime=q0*sin(Pi*(z+alamda)/He)
      Return
      End
c.
c.    Function Subprogram to compute critical heat flux in a uniformly heated channel
c.    by the W3 correlation
c.
      Function qcritEU(x,G,P,DeFt,uin)
      De=DeFt*12.
      hin=uin+P/rhop(uin,P)*144./778.
      Term1=((2.022-0.0004302*P)+(0.1722-0.0000984*P)*
     %       exp((18.177-0.004129*P)*x))
      Term2=(0.1484-1.596*x+0.1729*x*abs(x))*G/1.e6+1.037
      Term3=(1.157-0.869*x)*(0.2664+0.8357*exp(-3.151*De))
      Term4=0.8258+0.000794*(hf(P)-hin)
c.
      qcritEU=1.e6*Term1*Term2*Term3*Term4
      Return
      End
c.
c.    Subroutine to Calculate Sensor Response
c.
      Subroutine SensorResponse(SensorID,Deltat,TrueSignal,Signal)
      Integer SensorID
      Real Mean
      Common/SensorData/SensorSpan(10),SensorBias(10),
     %                  SensorDriftRate(10),SensorDriftDuration(10),
     %                  SensorNoiseData(10,2)
      Dimension Drift(10),DriftDuration(10)
c.
      Data ISEED/123456789/
      Data Drift/10*0./
      Data DriftDuration/10*0./
c.
c.    Compute Sensor Noise
c.
      Mean=SensorNoiseData(SensorID,1)
      Sigma=SensorNoiseData(SensorID,2)
      Call Gaussian(Mean,Sigma,ISEED,SensorNoise)
c.
c.    Compute Sensor Drift
c.
      DriftDuration(SensorID)=DriftDuration(SensorID)+Deltat
        if(DriftDuration(SensorID).lt.SensorDriftDuration(SensorID))then
        Drift(SensorID)=Drift(SensorID)+SensorDriftRate(SensorID)*Deltat
        else
        Drift(SensorID)=SensorDriftRate(SensorID)*
     %                  SensorDriftDuration(SensorID)
        endif      
c.
c.    Compute Sensor Output
c.
      Signal=TrueSignal+SensorNoise+SensorBias(SensorID)+Drift(SensorID)
      Return
      End
c.
c.    Subroutine to sample random numbers according to a gaussian distribution
c.
      Subroutine Gaussian(mu,sigma,iseed,z)
      Real mu
      y=2.
      z=0.
c.
      do while((y-1.)**2.gt.2.*z)
c.
      psi1=RAN(iseed)
      psi2=RAN(iseed)
      y=-ALOG(psi1)
      z=-ALOG(psi2)
      enddo
c.
	psi=2.*RAN(iseed)-1.
      if(psi.lt.0.)y=-y
c.
      z=y*sigma+mu
      Return
      end
c.
c.    Subroutine to compute Startup Feedwater Flow
c.
      Subroutine SFWS(PSG,SGLVL,FlowSFWS,SFWVPosition,Deltat)
c.**************************************************************************
      Real Kvalve
      Real KSFWV
c.**************************************************************************
      Common/ValveProperties/DeadBand(10),Tau(10),
     %                       Avalve(10),Kvalve(10),bvalve(10)
      Common/FeedPARAMETERS/nHWP,nCP,nFP,nSG,Pcond
      Common/SFWSPARAMETERS/DeltaPSFWPump
c.**************************************************************************
      Data IMOVESFWV,IOPENSFWV/2*0/
c.**************************************************************************
	gc=4.17e8
      rho=rhof(Pcond)
      ASFWS=Avalve(5)
c.
c.    Compute New Valve Position
c.
      Call StartupFeedwaterControlValvePosition(SFWVNew,SFWVPosition,
     %                                          SGLVL,Deltat)
      Call ValvePosition(SFWVPosition,SFWVNew,Deltat,
     %                   IMOVESFWV,IOPENSFWV,5)
c.
c.    Compute Valve Loss Coefficient
c.
      if(SFWVPosition.gt.0.)then
      Nvalve=5
      Call Valve(SFWVPosition,Nvalve,KSFWV)
c.
c.    Compute Startup Feedwater Flow Rate
c.
      DeltaP=Pcond+DeltaPSFWPump-PSG
        if(DeltaP.gt.0.)then
        FlowSFWS=ASFWS*sqrt(DeltaP*144.*2.*rho*gc/KSFWV)      
        else
        FlowSFWS=0.
        endif
      else
      FlowSFWS=0.
      endif
c.      write(*,*)'DeltaP=',DeltaP,'ASFWS=',ASFWS
c.      write(*,*)'rho=',rho,' KSFWV=',KSFWV
c.      write(*,*)' '
      Return
      End
c.
c.    Control Routine for Startup Feedwater Valve Position
c.
      Subroutine StartupFeedwaterControlValvePosition(SFWVNew,
     %                                                SFWVPosition,
     %                                                SGLVL,Deltat)
c.********************************************************************
      Real LevelERR
c.********************************************************************
      Common/SFWSControl/SFWSGain(3)
      Common/FeedControlSetPoints/FlowDEMAND0,SGRefLVL0,SGRefLVL
c.********************************************************************
      Data SumERROR/0./
c.********************************************************************
c.
      LevelERR=-(SGLVL-SGRefLVL)/SGRefLVL0
      SumERROR=SumERROR+LevelERR*Deltat
c.
      DeltaSFWV=SFWSGain(1)+
     %          SFWSGain(2)*LevelERR+
     %          SFWSGain(3)*SumERROR
c.
c.********************************************************************
c.
c.      write(*,*)'SGLVL=',SGLVL
c.      write(*,*)'SGRefLVL=',SGRefLVL,' SGRefLVL0=',SGRefLVL0
c.      write(*,*)'LevelERR=',LevelERR,' DeltaSFWV=',DeltaSFWV
c.      write(*,*)'DeltaSFWV=',DeltaSFWV
c.      write(*,*)' '
      SFWVNew=SFWVPosition+DeltaSFWV
c.
      if(SFWVNew.gt.1.)SFWVNew=1.
      if(SFWVNew.lt.0.)SFWVNew=0.
c.
      Return
      End
c.**************************************************************************
c.
c.    Subroutine to Compute Friction Factor by the Colebrook Relationship
c.
      Subroutine Colebrook(Re,f)
      External FCOL
      Common/ColebrookParameters/Re0,Roughness
c.
      if(Re.lt.2300.)then
         if(Re.eq.0.)then
         f=1.
         else
         f=64./Re
         endif
      elseif(Re.lt.4200.)then
c.
      Re0=4200.
      a=0.001
      b=0.1
c.
      f2300=64./2300.
      Call Brent(FCOL,a,b,f4200,icount)
      f=f2300+(Re-2300.)*(f4200-f2300)/(4200.-2300.)
      else
c.
      Re0=Re
      a=0.001
      b=0.1    
      Call Brent(FCOL,a,b,f,icount)
      endif
c.
      Return
      End
c.
      Function FCOL(f)
      Common/ColebrookParameters/Re0,Roughness
c.
      FCOL=1./sqrt(f)-1.14+2.*ALOG10(Roughness+9.35/(Re0*sqrt(f)))
c.
      Return
      End
c.*****************************************************************************    
c.
c.    Subroutine to compute Xenon Reactivity Worth
c.
      Subroutine Xenon(Qrx,Deltat,NX,NI,rhoX)
c.
      Common/XenonData/GammaX,lamdaX,sigmaX,
     %                 GammaI,lamdaI,SigmaF,psiX,Vfuel
      Common /Reactivity/alphaTrx,alphamod,alphaBoron,alphaXe,
     %                   Trxref,Tref,Cref,NXref,
     %                   Rho0,Prompt,Rhocr,Rho,
     %                   DeltaRhoFuel,DeltaRhoMod,DeltaRhoB,Srx

      Real lamdaX,lamdaI,NX,NI
      Real NI0,NX0,NXref
      Real lamdaXeff
c.
      DeltaTs=Deltat*3600.
      NI0=NI
      NX0=NX
c.
c.    Convert Power to Flux
c.
      phi=Qrx*psiX/(SigmaF*Vfuel)
      Term0=(GammaI*SigmaF*phi/lamdaI)
c.
c.    Iodine Concentration
c.
      NI=NI0*exp(-lamdaI*DeltaTs)+
     %   Term0*(1.-exp(-lamdaI*DeltaTs))
c.
c.    Xenon Concentration
c.
      lamdaXeff=lamdaX+sigmaX*phi
      Term1=(GammaX+GammaI)*SigmaF*phi/lamdaXeff
      Term2=(lamdaI*NI0-GammaI*SigmaF*phi)/(lamdaXeff-lamdaI)
c.
      NX=NX0*exp(-lamdaXeff*DeltaTs)+
     %   Term1*(1.-exp(-lamdaXeff*DeltaTs))+
     %   Term2*(exp(-lamdaI*DeltaTs)-exp(-lamdaXeff*DeltaTs))
c.
c.    Xenon Reactivity      
c.
      rhoX=alphaXe*(NX-NXref)
c.      
      Return
      end
c.********************************************************************************
c.                                                                               
c.    Subroutine to compute pressurizer spray rate                               
c.
      Subroutine PressurizerSpray
c.
      External FSPRAY
      Real KSPRAY,KBYPASS,KSCV,LSPRAY
      Common/PressurizerSprayData/rhoSPRAY,rhouSPRAY,Vspray,AxSPRAY
      Common/PressurizerSprayLine/SprayPumpDeltaP,DSPRAY,LSPRAY,
     %                            AxBypass,AxSCV,KSPRAY,KBYPASS,KSCV,
     %                            SCVposition
c.								 
      gc=4.17e8
c.
        if(SprayPumpDeltaP.gt.0.)then
        Gmax=2.*rhoSPRAY*gc*SprayPumpDeltaP*144./KSPRAY
        Gmax=sqrt(Gmax)
        a=100.
        b=Gmax
        call Brent(FSPRAY,a,b,Gspray,icount)
c.
        Vspray=Gspray/rhoSPRAY
        else
        Vspray=0.
        endif
      Return
      End
c.
      Function FSPRAY(Gsp)
      Real KSPRAY,KBYPASS,KSCV,LSPRAY
      Common/PressurizerSprayData/rhoSPRAY,rhouSPRAY,Vspray,AxSPRAY
      Common/PressurizerSprayLine/SprayPumpDeltaP,DSPRAY,LSPRAY,
     %                            AxBypass,AxSCV,KSPRAY,KBYPASS,KSCV,
     %                            SCVposition
      gc=4.17e8
      frictionfactor=F(Gsp,DSPRAY)
      Chi=frictionfactor*LSPRAY/DSPRAY+KSPRAY
c.
      if(SCVposition.eq.0.)then
c.
c.    Bypass Line only
c.
      Chi=Chi+KBYPASS*(AxSPRAY/AxBypass)**2
c.
      elseif(AxBypass.eq.0.)then
c.
c.    No Bypass Line
c.
      Chi=Chi+KSCV*(AxSPRAY/AxSCV)**2
c.
      else
c.
c.    Bypass and Spray Control Valve
c.
      Psi=AxSCV/AxSPRAY+(AxBypass/AxSPRAY)*sqrt(KSCV/KBYPASS)
      Psi=1./Psi
      Chi=Chi+KSCV*Psi**2
      endif
c.
      FSPRAY=SprayPumpDeltaP*144.-Chi*Gsp**2/(2.*rhoSPRAY*gc)
      Return
      End
c.*********************************************************************
c.
c.    Control Routine for Spray Control Valve Position
c.
      Subroutine SprayControlValvePosition(SCVposition,MODE,Px,Deltat)
c.********************************************************************
      Real KPRZSRV,KPRZ
      Common/SprayControl/SprayGain(3,3),RATESCV,SCVmin
      Common/PressurizerData/KPRZSRV(4),AxSRV(4),KPRZ(4),
     %                       PRZSETPOINT(9),NPRZSRVs

c.********************************************************************
c.
       IDEBUG=0
c.
       if(IDEBUG.eq.1)then
       open(unit=14,file='Debug.dat')
       write(14,*)' '
       write(14,*)'In Subroutine SprayControlValvePosition'
       write(14,*)' '
       write(14,*)'MODE=',MODE
       write(14,*)'Reference Pressurizer Pressure= ',PRZSETPOINT(5)
       write(14,*)'Backup Heaters On = ',PRZSETPOINT(6)
       write(14,*)'Sprays Full On =',PRZSETPOINT(9) 
       write(14,*)'Pressurizer Pressure= ',Px
       endif
c.**************************************************************
c.
      if(MODE.eq.0)then
c.
c.    Manual Control
c.
      DeltaSCV=0.
      else
c.
c.    Automatic Control
c.
      SetPoint=PRZSETPOINT(5)
      FullOpen=PRZSETPOINT(9)
      FullClose=PRZSETPOINT(6)
c.
        if(Px.lt.FullClose)then
        DeltaSCV=-SCVposition
        elseif(Px.Lt.FullOpen)then
        ERROR=(Px-SetPoint)/SetPoint
          if(ERROR.gt.1.)ERROR=1.
          if(ERROR.lt.-1.)ERROR=-1.
        DeltaSCV=SprayGain(MODE,1)+
     %           SprayGain(MODE,2)*ERROR
        else
        DeltaSCV=1.-SCVposition
        endif
      endif
c.
      DeltaSCVMAX=RATESCV*Deltat
c.
        if(IDEBUG.eq.1)then
        write(14,*)' '
        write(14,*)'ERROR= ',ERROR
        write(14,*)'SCVposition= ',SCVposition
        write(14,*)'DeltaSCV= ',DeltaSCV
        write(14,*)'DeltaSCVMAX= ',DeltaSCVMAX
        write(14,*)' '
        endif
c.
      if(DeltaSCV.lt.0.)then
      DeltaSCV=-AMIN1(abs(DeltaSCV),DeltaSCVMAX)
      else
      DeltaSCV=AMIN1(DeltaSCV,DeltaSCVMAX)
      endif
c.
c.**************************************************************
c.
      SCVposition=SCVposition+DeltaSCV
c.
      if(SCVposition.gt.1.)SCVposition=1.
      if(SCVposition.lt.SCVmin)SCVposition=SCVmin
c.
        if(IDEBUG.eq.1)then
        write(14,*)' '
        write(14,*)'DeltaSCV= ',DeltaSCV
        write(14,*)'SCVposition= ',SCVposition
        write(14,*)'SCVmin= ',SCVmin
        endif
c.
      Return
      end
c.
      Function FHOT(Phi)
      REAL MdotChannel
      Common/HotChannelParameters/Vstar,rhoHOT,G,MdotChannel,SOURCE,P,
     %                            IPHASE
c.
      if(IPHASE.eq.1)then
c.
c.    Single Phase
c.
      u=PHI
      h=u+P/rhop(u,P)*(144./778.)
c.
      elseif(IPHASE.eq.2)then
c.
c.    Two Phase
c.
      x=Phi
      hfs=uf(P)+P/rhof(P)*(144./778.)
      hgs=ug(P)+P/rhog(P)*(144./778.)
      hfgs=hgs-hfs
c.
      gc=4.17e8
      C0=1.13
      Vgj=1.41*(sigma(P)*gc*gc*(rhof(P)-rhog(P))/rhof(P)**2)**.25
c.
      Gstar=G/(rhog(P)*Vgj)
      epsilon=rhog(P)/rhof(P)
      alphag=x/(C0*(x+epsilon*(1.-x))+1./Gstar)
c.
      rhou=rhof(P)*uf(P)-alphag*(rhof(P)*uf(P)-rhog(P)*ug(P))
      rho=rhof(P)-alphag*(rhof(P)-rhog(P))
      u=rhou/rho
      h=hfs+x*hfgs
c.
      endif
c.
      FHOT=Vstar*rhoHOT*u+MdotChannel*h-SOURCE
c.
      Return
      End                                                                      
