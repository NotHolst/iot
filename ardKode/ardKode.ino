#include <Wire.h>
#include <Arduino.h>
#include "./ardKode.h"

#include <sl868a.h>
#include <cc2541.h>
#include <VL6180.h>
#include <HTS221.h>

typedef union {
  unsigned char byteval[4];
  float floatval;
} FloatBytes;

int led_status = HIGH;

const int tempMargin = 1;
const int humidMargin = 10;
const int ambientLightMargin = 1000000;

long timeOfDay = 0;

struct CurvePoint tempCurve[256];
int tempCurveBufferLength = 0;
struct CurvePoint humidCurve[256];
int humidCurveBufferLength = 0;
struct CurvePoint ambientLightCurve[256];
int ambientCurveBufferLength = 0;

int heaterPin = 9;
int coolerPin = 10;

int lightIntensity = 0;
int lightPin = 5;

void setCurve(float in[1440], float out[1440])
{
  int i;
  for (i = 0; i < 1440; i++)
  {
    out[i] = in[i];
  }
}

float getTempCurveValue(int t){
  return 50 * getCurveValue(tempCurve, tempCurveBufferLength, t)/100;
}

float getAmbientCurveValue(int t){
  return 93440 * getCurveValue(ambientLightCurve, ambientCurveBufferLength, t)/100;
}

float getHumidCurveValue(int t){
  return 100 * getCurveValue(humidCurve, humidCurveBufferLength, t)/100;
}

float getCurveValue(CurvePoint curve[], int pointCount, int t)
{
  if (pointCount == 0)
  {
    return 0;
  }

  int prevIndex = -1;
  for (int i = 0; i < pointCount; i++)
  {
    CurvePoint current = curve[i];
    if (current.x < t)
    {
      prevIndex = i;
    }
    else
      break;
  }

  struct CurvePoint prev = curve[prevIndex];
  struct CurvePoint next = prev;

  if (prevIndex == -1)
  {
    return curve[0].y;
  }
  else if (prevIndex < pointCount)
  {
    next = curve[prevIndex + 1];
  }

  if (t > curve[pointCount - 1].x)
  {
    return curve[pointCount - 1].y;
  }

  int ti = floor(pointCount * t);
  float subTime = 1 - (next.x - t) / (next.x - prev.x);

  return (1.0 - subTime) * prev.y + subTime * next.y;
}

void adjustLight(int index){
    float ambient = smeAmbient.ligthPollingRead();
    boolean adjustingLight = true;
    int counter = 0;
    
    while(adjustingLight && counter < 100){
      if(ambient < getAmbientCurveValue(index) - ambientLightMargin) {
        if(lightIntensity + 10 > 255) {
          lightIntensity = 1;
          adjustingLight = false;
        } else {
          lightIntensity+= 10;
        }
      }
      else if(ambient > getAmbientCurveValue(index) + ambientLightMargin) {
        if(lightIntensity - 10 < 0) {
          lightIntensity = 0;
          adjustingLight = false;
        } else {
          lightIntensity-= 10;
        }
      }
      else {
        adjustingLight = false;
      }
      analogWrite(lightPin, lightIntensity);
      counter++;
      delay(300);
      //Serial.print("Adjusting Light ");
      //Serial.println(lightIntensity);
      ambient = smeAmbient.ligthPollingRead();
    }
    //Serial.print("Finished Adjusting Light");
}

void setup()
{
  //Initiate the Wire library and join the I2C bus
  Wire.begin();
  smeBle.begin();

  pinMode(heaterPin, OUTPUT);
  pinMode(coolerPin, OUTPUT);
  pinMode(lightPin, OUTPUT);

  smeGps.begin();
  smeBle.begin();
  smeHumidity.begin();
  if (!smeAmbient.begin())
  {
      while (1)
      {
          ; // endless loop due to error on VL6180 initialization
      }
  }
  
  SerialUSB.begin(115200);
}

int t = 0;
char buff[2048];
int buffLength = 0;
bool chunkMode = false;

void parseBuffer(char curveToEdit)
{
  String bufferStr = (String)buff;
  int cursorIndex = 0;

  struct CurvePoint point;
  for (int index = 0; index < buffLength; index++)
  {
    char ch = bufferStr[index];
    if (ch == ',')
    {
      point.x = bufferStr.substring(cursorIndex, index ).toInt();
      cursorIndex = index;
    }
    else if (ch == ' ')
    {
      point.y = bufferStr.substring(cursorIndex + 1, index ).toInt();
      cursorIndex = index;
      switch (curveToEdit) {
        case 't':
          tempCurve[tempCurveBufferLength++] = point;
          break;
        case 'h':
          humidCurve[humidCurveBufferLength++] = point;
          break;
        case 'a':
          ambientLightCurve[ambientCurveBufferLength++] = point;
          break;
      }
    }
  }
  buffLength = 0;
}

void loop()
{
  int index = millis() / 60000;

  float humid;
  float temp;
  float ambient;

  humid = smeHumidity.readHumidity();
  SerialUSB.print("Humidity ");
  SerialUSB.print(humid);
  SerialUSB.print(" Expected:");
  SerialUSB.print(getHumidCurveValue(index));
  SerialUSB.print("\t");

  temp = smeHumidity.readTemperature();
  SerialUSB.print("Temperature ");
  SerialUSB.print(temp);
  SerialUSB.print(" Expected:");
  SerialUSB.print(getTempCurveValue(index));
  SerialUSB.print("\t\t");

  ambient = smeAmbient.ligthPollingRead();
  SerialUSB.print("Ambient light ");
  SerialUSB.print(ambient);
  SerialUSB.print(" Expected:");
  SerialUSB.print(getAmbientCurveValue(index));
  SerialUSB.println("");


  if(temp < getTempCurveValue(index) - tempMargin) {
    digitalWrite(heaterPin, HIGH);
    digitalWrite(coolerPin, LOW);
  }
  if(temp > getTempCurveValue(index) + tempMargin) {
    digitalWrite(heaterPin, LOW);
    digitalWrite(coolerPin, HIGH);
  }

  if(ambient < getAmbientCurveValue(index) - ambientLightMargin || 
  ambient > getAmbientCurveValue(index) + ambientLightMargin) {
    adjustLight(index);
  }

  volatile char data;
  int count = 0;
  while (smeBle.available())
  {
    count++;
    data = smeBle.read();
    delay(10); // wait for ble or whatever
    char curveToEdit;
    if (data == 's')
    {
      chunkMode = true;
    } else if ( data == 't' || data == 'h' || data == 'a' ) {
      curveToEdit = data;
      switch (curveToEdit) {
        case 't':
          tempCurveBufferLength = 0;
          break;
        case 'h':
          humidCurveBufferLength = 0;
          break;
        case 'a':
          ambientCurveBufferLength = 0;
          break;
      }
    }
    else if (data == 'e')
    {
      chunkMode = false;
      Serial.println("--------------BUFFER----------------");
      Serial.println(buff);
      parseBuffer(curveToEdit);
      Serial.println("--------------BUFFER----------------");
      t = 0;
    }
    else if (chunkMode)
    {
      buff[buffLength++] = data;
    }

  }
  if (count > 0)
  {
    Serial.println("--------------yay----------------");
  }

  //write to bluetooth
  char buf[12];

  FloatBytes humidBytes;
  humidBytes.floatval = humid;
  buf[0] = humidBytes.byteval[0];
  buf[1] = humidBytes.byteval[1];
  buf[2] = humidBytes.byteval[2];
  buf[3] = humidBytes.byteval[3];

  FloatBytes tempBytes;
  tempBytes.floatval = temp;
  buf[4] = tempBytes.byteval[0];
  buf[5] = tempBytes.byteval[1];
  buf[6] = tempBytes.byteval[2];
  buf[7] = tempBytes.byteval[3];

  FloatBytes ambientBytes;
  ambientBytes.floatval = ambient;
  buf[8] = ambientBytes.byteval[0];
  buf[9] = ambientBytes.byteval[1];
  buf[10] = ambientBytes.byteval[2];
  buf[11] = ambientBytes.byteval[3];

  smeBle.write(buf, 12);
}
