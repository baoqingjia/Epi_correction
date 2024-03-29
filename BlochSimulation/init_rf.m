 function varargout=init_rf(p1pat)

rfstruct.head.bandwidth     =0;
rfstruct.head.integral      =0;
rfstruct.head.inversionBw   =0;  
rfstruct.head.modulation    ='';
rfstruct.head.rfFraction    =0;
rfstruct.head.type          ='';
rfstruct.head.version       =1.0;
rfstruct.head.EXCITEWIDTH       =0;
rfstruct.head.INVERTWIDTH       =0;
rfstruct.head.maxamp             =0;
rfstruct.head.B1max             =0;
rfstruct.head.B1rms             =0;
rfstruct.head.nptot             =0;
rfstruct.head.stepsize           =0;

rfstruct.channelphase       =0;
rfstruct.tof                =0;
rfstruct.duration           =0;
rfstruct.res                =0;
rfstruct.flip               =0;
rfstruct.flipmult           =0;
rfstruct.bandwidth          =0;
rfstruct.pulseBase          ='';
rfstruct.pulseName          =p1pat;
rfstruct.shapeName          ='';
rfstruct.rfcoil             ='x';
rfstruct.powerCoarse        =0;
rfstruct.powerFine          =0;
rfstruct.param1             ='tpwr';
rfstruct.param2             ='tpwr1';
rfstruct.rof1               =0;
rfstruct.rof2               =0;
rfstruct.sar                =0;
rfstruct.pts                =0;
rfstruct.npars              =0;
rfstruct.lobes              =0;
rfstruct.cutoff             =0;
rfstruct.mu                 =0;
rfstruct.beta               =0;
rfstruct.display            =0;
rfstruct.error              ='';
rfstruct.amp                =0;
rfstruct.freq               =0;
rfstruct.phase              =0;



varargout{1}=rfstruct;
