//maps the wavelength of the spectrum to pixels
int nmForPixel(int pixel)
{
  float fraction = float(pixel) / SpectrumSize;
  float inverted = 1 - fraction;
  int nm = (int)(400 + (inverted * 500));
  return nm;
}

//map wavelength to rgb color
float[] rgbForNm(int wavelength)
{
  float Gamma = 0.80;
  int IntensityMax = 255;
  float factor, red, green, blue;
  
  if((wavelength >= 520) && (wavelength<650)){
      red = 0.0;
      green = 0.0;
      blue = 1.0;
  }else if((wavelength >= 450) && (wavelength<520)){
      red = 0.0;
      green = 1.0;
      blue = 0.0;
  }else if((wavelength >= 650) && (wavelength<740)){
      red = 1.0;
      green = 0.0;
      blue = 0.0;
  }else{
      red = 0.0;
      green = 0.0;
      blue = 0.0;
  };

  // Let the intensity fall off near the vision limits
  if((wavelength >= 380) && (wavelength<420)){
      factor = 0.3 + 0.7*(wavelength - 380) / (420 - 380);
  }else if((wavelength >= 420) && (wavelength<701)){
      factor = 1.0;
  }else if((wavelength >= 701) && (wavelength<781)){
      factor = 0.3 + 0.7*(780 - wavelength) / (780 - 700);
  }else{
      factor = 0.0;
  };

  if (red != 0){
      red = Math.round(IntensityMax * Math.pow(red * factor, Gamma));
  }
  if (green != 0){
      green = Math.round(IntensityMax * Math.pow(green * factor, Gamma));
  }
  if (blue != 0){
      blue = Math.round(IntensityMax * Math.pow(blue * factor, Gamma));
  }
  float[] rgb = {red,blue,green};
  return rgb;
}
