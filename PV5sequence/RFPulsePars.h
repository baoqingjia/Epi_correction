double parameter
{
  display_name "Bandwidth Scaling Factor";
  relations BwScaleRel;
  units "%";
  format "%f";
}BwScale;

/*
 *  Excitation pulse parameter
 */


PV_PULSE_LIST parameter
{
  display_name "Excitation Pulse Shape";
  relations    ExcPulseEnumRel;
}ExcPulseEnum;


PVM_RF_PULSE_TYPE parameter
{
  display_name "Excitation Pulse";
  relations    ExcPulseRel;
}ExcPulse;








