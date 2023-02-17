/*
 *  Slice Excitation parameter
 */

double parameter
{
  display_name "Exc. Slice Gradient";
  format "%f";
  units  "%";
  relations ExcSliceGradRel;
}ExcSliceGrad;


double parameter
{
  display_name "Max. Exc. Slice Gradient";
  format "%f";
  units  "%";
  relations ExcSliceGradLimRel;
}ExcSliceGradLim;


double parameter
{
  display_name "Exc. Slice Reph. Gradient";
  format "%f";
  units  "%";
  relations ExcSliceRephGradRel;
}ExcSliceRephGrad;

double parameter
{
  display_name "Max. Exc. Slice Reph. Gradient";
  format "%f";
  units  "%";
  relations ExcSliceRephGradLimRel;
}ExcSliceRephGradLim;


double parameter
{
  display_name "Exc. Slice Reph. Time";
  format "%f";
  units "ms";
  relations ExcSliceRephTimeRel;
}ExcSliceRephTime;



double parameter
{
  display_name "Slice Gradient Stabilization Time";
  relations SliceGradStabTimeRel;
  units "ms";
  format "%f";
}SliceGradStabTime;
