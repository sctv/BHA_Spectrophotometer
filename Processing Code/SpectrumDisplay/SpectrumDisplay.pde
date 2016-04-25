
import processing.serial.*;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Calendar;

Serial port;      // The serial port
int exposureTime = 1; // 1 ms
float updateSpeed = 2000; // 1000 ms

int lastSpectrumUpdate=0;

boolean ledState=true;
boolean rledState=false;
boolean gledState=false;
boolean bledState=false;
PFont defaultFont;
PFont titleFont;

String buffer;

//Mathematically the spectrometer should operate in the 400-900 nm wavelength range
//For this specific box, pixel one corresponds with 900 nm, pixel 768 corresponds with 400nm
//But should be calibrated..
int SpectrumSize = 768;
float[] rawSpectrumData, correctedSpectrumData;
float[] darkReadout, whiteReadout;
int spectrumValueIndex=0;
int spectraCount=0;

void setup() {
  size(800, 400);
  // create a font with the third font available to the system:
  defaultFont = createFont(PFont.list()[0], 14);
  titleFont = createFont(PFont.list()[4], 20);
  textFont(defaultFont);

  // List all the available serial ports:
  printArray(Serial.list());

  String portName = Serial.list()[2];
  port = new Serial(this, portName, 57600);

  correctedSpectrumData = new float[SpectrumSize];
  rawSpectrumData = new float[SpectrumSize];
  darkReadout = new float[SpectrumSize];
  whiteReadout = new float[SpectrumSize];
  for(int i=0;i<SpectrumSize;i++)
    whiteReadout[i]=1.0f;
  
  lastSpectrumUpdate=millis();

  ledState=true;
  port.write("led 1\n");
}


void readSpectrum() {
  println("Updating spectrum");
  port.write("read\n");
}

void drawSpectrum() {
  int xstart=10, ystart=height-30;
  
  float maxVal=0.0f;
  for (int i=0;i<correctedSpectrumData.length;i++)
    maxVal = max(correctedSpectrumData[i],maxVal);
    
  float yscale = (height - 160)/maxVal;
  for (int i=1;i<correctedSpectrumData.length;i++) {
    
    float[] c = rgbForNm(nmForPixel(i));
    stroke(c[0],c[1],c[2]);
    
    line(i+xstart, ystart - correctedSpectrumData[i-1] * yscale, 
        i+xstart+1, ystart - correctedSpectrumData[i] * yscale);
  }
  
  int indexAtMousePos = max(0, min(SpectrumSize-1, mouseX - xstart));
  text("nm: " + nmForPixel(indexAtMousePos), 150, 390);
  text("At mouse: " + correctedSpectrumData[indexAtMousePos], 350, 390);
  text("MaxValue: " + maxVal, 200, 390);
}

/*
Compute correctedSpectrumData based on rawSpectrumData, whiteReadout and darkReadout
*/
void computeSpectrum() {
  for (int i=0;i<SpectrumSize;i++) {
    correctedSpectrumData[i] = (rawSpectrumData[i] - darkReadout[i]) / ( whiteReadout[i] - darkReadout[i]);
  }
}

//export the spectrum to a csv file to the sketch folder, 
//with timestamp as name
void saveSpectrum()
{
  PrintWriter output;
    
  SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd-HH:mm:ss");
  Date today = Calendar.getInstance().getTime(); 
  String name = formatter.format(today);

  output = createWriter("data/" + name + ".csv");
  
  for(int i = 0; i < SpectrumSize; i++) 
  {
    output.print(correctedSpectrumData[i] + ";"); 
  }
  
  output.flush();  // Writes the remaining data to the file
  output.close(); 
}


void draw() {
  int time = millis();

  if (lastSpectrumUpdate + updateSpeed < time) {
    lastSpectrumUpdate=time;
    readSpectrum();
  }

  background(255);
  text("U=decrease exposure, I=increase exposure", 10, 55);
  text("Exposure time: " + exposureTime + " ms", 10, 75);
  text("D=set dark measurement", 10, 100);
  text("W=set white measurement (no sample)", 10, 115);

  text("Measurements: " + spectraCount, 10, 390);

  text("LED = " + ( ledState ? "ON" : "OFF" ), 700, 55);
  text("L, R, G, B = Toggle LED", 700, 70);
  text("RLED = " + ( rledState ? "ON" : "OFF" ), 700, 85);
  text("GLED = " + ( gledState ? "ON" : "OFF" ), 700, 100);
  text("BLED = " + ( bledState ? "ON" : "OFF" ), 700, 115);
  
  textFont(titleFont);
  fill(0, 0, 0);
  text("BioHackAcademy Spectrophotometer", 10, 20);
  textFont(defaultFont);
  fill(0);
  
  drawSpectrum();
}


void serialEvent(Serial port) {
  while (port.available () >0) {
    char c = port.readChar();
    if (c == '\n' && buffer.length() > 0) {
      char first=buffer.charAt(0);
      if (first >= '0' && first <= '9') {
        int value = Integer.parseInt(buffer.trim());//substring(0,buffer.length()-1));
        rawSpectrumData[spectrumValueIndex++] = value/1024.0f;
        if (spectrumValueIndex==SpectrumSize) {
          computeSpectrum();
          spectrumValueIndex=0;
          spectraCount ++;
        }
      } else if(buffer=="start") {
        spectrumValueIndex=0; // align again
      }
      buffer="";
    } else {
      buffer+=c;
    }
  }
}

void keyPressed() {
  if (key >= 'A' && key <= 'Z')
    key += 'a'-'A'; // make lowercase

  if (key == 'i' || key == 'u') {
    if (key == 'i') exposureTime += 3;
    else exposureTime -= 3;
    exposureTime = max(exposureTime,1);
    
    port.write("exp " + max(1, (int)exposureTime) + "\n");
  }

  if (key == 'l') {
    ledState=!ledState;
    port.write("led " + ( ledState ? "1" : "0" )+ "\n");
  }
  
  if (key == 'r') {
    rledState=!rledState;
    port.write("rled " + ( rledState ? "1" : "0" )+ "\n");
  }
  
  if (key == 'g') {
    gledState=!gledState;
    port.write("gled " + ( gledState ? "1" : "0" )+ "\n");
  }
  
  if (key == 'b') {
    bledState=!bledState;
    port.write("bled " + ( bledState ? "1" : "0" )+ "\n");
  }
  
  if (key == ' ') {
    readSpectrum();
  }
  
  if (key == 'd') {
    for (int i=0;i<SpectrumSize;i++)
      darkReadout[i] = rawSpectrumData[i];
  }
  
  if (key == 'w') {
    for (int i=0;i<SpectrumSize;i++)
      whiteReadout[i] = rawSpectrumData[i];
  }
  
  if (key == 's') 
  {
    println("save spectrum");
    saveSpectrum();
  }
  
}




