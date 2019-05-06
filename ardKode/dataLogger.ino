#include <Wire.h>
#include <Arduino.h>

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

float tempCurve[1440];
float humidCurve[1440];
float ambientLightCurve[1440];

void setCurve(float in[1440], float out[1440])
{
    int i;
    for (i = 0; i < 1440; i++)
    {
        out[i] = in[i];
    }
}

// the setup function runs once when you press reset or power the board
void setup()
{
    //Initiate the Wire library and join the I2C bus
    Wire.begin();

    //smeGps.begin();
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
    int i;
    float emptCurve[1440];
    for (i = 0; i < 1440; i++)
    {
        emptCurve[i] = 0;
    }
    setCurve(emptCurve, tempCurve);
    setCurve(emptCurve, humidCurve);
    setCurve(emptCurve, ambientLightCurve);
}

// the loop function runs over and over again forever
void loop()
{
    //    sl868aCachedDataT data;
    //
    //    if (smeGps.ready()) {
    //      data = smeGps.getData();
    //
    //
    //      SerialUSB.print("Hour  =  ");
    //      SerialUSB.println(data.utc_hour, DEC);
    //
    //      SerialUSB.print("Minute  =  ");
    //      SerialUSB.println(data.utc_min, DEC);
    //
    //      SerialUSB.print("Second  =  ");
    //      SerialUSB.println(data.utc_sec, DEC);
    //
    //      timeOfDay = (data.utc_hour * 60 * 60) + (data.utc_min * 60) + data.utc_sec;
    //
    //    } else {
    //      SerialUSB.println("Getting GPS");
    //    }

    //    int index = millis() / 60000;
    //    SerialUSB.println(index);
    //
    //    float humid;
    //    float temp;
    //    float ambient;
    //
    //    humid = smeHumidity.readHumidity();
    //    SerialUSB.print("Humidity   : ");
    //    SerialUSB.print(humid);
    //    SerialUSB.println(" %");
    //
    //    temp = smeHumidity.readTemperature();
    //    SerialUSB.print("Temperature: ");
    //    SerialUSB.print(temp);
    //    SerialUSB.println(" celsius");
    //
    //    ambient = smeAmbient.ligthPollingRead();
    //    SerialUSB.print("Ambient light: ");
    //    SerialUSB.print(ambient);
    //    SerialUSB.println("light");

    //    if(temp < tempCurve[index] - tempMargin) {
    //      ledRedLight(HIGH);
    //    }
    //    if(temp > tempCurve[index] + tempMargin) {
    //      ledRedLight(HIGH);
    //    }
    //
    //    if(humid < humidCurve[index] - humidMargin) {
    //      ledBlueLight(HIGH);
    //    }
    //    if(humid > humidCurve[index] + humidMargin) {
    //      ledBlueLight(HIGH);
    //    }
    //
    //    if(ambient < ambientLightCurve[index] - ambientLightMargin) {
    //      ledGreenLight(HIGH);
    //    }
    //    if(ambient > ambientLightCurve[index] + ambientLightMargin) {
    //      ledGreenLight(HIGH);
    //    }
    char data;
    int count = 0;
    while (smeBle.available())
    {
        count++;
        data = smeBle.read();
        SerialUSB.println(data, HEX);

        switch (data)
        {

        case '1':
            ledRedLight(HIGH);
            break;

        case '0':
            ledBlueLight(HIGH);
            break;

        default:
            ledGreenLight(HIGH);
            break;
        }
    }

    //write to bluetooth

    //    char buf[12];
    //
    //    FloatBytes humidBytes;
    //    humidBytes.floatval = humid;
    //    buf[0] = humidBytes.byteval[0];
    //    buf[1] = humidBytes.byteval[1];
    //    buf[2] = humidBytes.byteval[2];
    //    buf[3] = humidBytes.byteval[3];
    //
    //    FloatBytes tempBytes;
    //    tempBytes.floatval = temp;
    //    buf[4] = tempBytes.byteval[0];
    //    buf[5] = tempBytes.byteval[1];
    //    buf[6] = tempBytes.byteval[2];
    //    buf[7] = tempBytes.byteval[3];
    //
    //    FloatBytes ambientBytes;
    //    ambientBytes.floatval = ambient;
    //    buf[8] = ambientBytes.byteval[0];
    //    buf[9] = ambientBytes.byteval[1];
    //    buf[10] = ambientBytes.byteval[2];
    //    buf[11] = ambientBytes.byteval[3];
    //
    //    smeBle.write(buf, 12);

    //    delay(300);
    //        // turn the LED on
    //        ledRedLight(LOW);
    //        ledBlueLight(LOW);
    //        ledGreenLight(LOW);
    //    delay(700);              // wait for a second
    delay(10);
}