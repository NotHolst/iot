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
const int ambientLightMargin = 10000;

long timeOfDay = 0;

struct CurvePoint tempCurve[256];
int tempCurveBufferLength = 0;
struct CurvePoint humidCurve[256];
int humidCurveBufferLength = 0;
struct CurvePoint ambientLightCurve[256];
int ambientCurveBufferLength = 0;

void setCurve(float in[1440], float out[1440])
{
  int i;
  for (i = 0; i < 1440; i++)
  {
    out[i] = in[i];
  }
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

// the setup function runs once when you press reset or power the board
void setup()
{
  //Initiate the Wire library and join the I2C bus
  Wire.begin();
  smeBle.begin();
  SerialUSB.begin(115200);
}

// the loop function runs over and over again forever
char buff[1024];
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


int t = 0;
void loop()
{
  if (millis() % 1000 == 0 ) {
    Serial.print(getCurveValue(tempCurve, tempCurveBufferLength, t));
    Serial.print(" ");
    Serial.print(getCurveValue(humidCurve, humidCurveBufferLength, t));
    Serial.print(" ");
    Serial.println(getCurveValue(ambientLightCurve, ambientCurveBufferLength, t));
    t += 3;
  }
  delay(1);

  char data;
  int count = 0;
  while (smeBle.available())
  {
    count++;
    data = smeBle.read();

    SerialUSB.print(data, DEC);
    SerialUSB.print('\t');
    SerialUSB.println(data);


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

      for (int i = 0; i < tempCurveBufferLength; i++) {
        Serial.print("x: ");
        Serial.print(tempCurve[i].x);
        Serial.print("\ny: ");
        Serial.print(tempCurve[i].y);
        Serial.println();
      }

      for (int i = 0; i < humidCurveBufferLength; i++) {
        Serial.print("x: ");
        Serial.print(humidCurve[i].x);
        Serial.print("\ny: ");
        Serial.print(humidCurve[i].y);
        Serial.println();
      }

      for (int i = 0; i < ambientCurveBufferLength; i++) {
        Serial.print("x: ");
        Serial.print(ambientLightCurve[i].x);
        Serial.print("\ny: ");
        Serial.print(ambientLightCurve[i].y);
        Serial.println();
      }


    }
    else if (chunkMode)
    {
      buff[buffLength++] = data;
    }

  }
  if (count > 0)
  {
    //Serial.println("--------------yay----------------");
  }
}
