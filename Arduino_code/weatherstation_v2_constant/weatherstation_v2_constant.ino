//Weather station code
// Things to modify for each station: filename
// Things to modify in general: delay_time, num_data, setAlarm1
// Using digital pins: 2 (interrupt, clock), 3 (interrupt, cup)
// analog pins: 0(wind vane)
//SPI for SD card 
//I2C for rtc and bme
    // other power for the board, and the sd card, bme?


#include "RTClib.h"
#include <RTClib.h>
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME280.h>
//#include <SD.h>
#include <SdFat.h>
#include <SPI.h>
#include <avr/sleep.h>

//Set up SD card and data management for code
File myFile;
const int chipSelect = 10; //double check this connects to cs on the sd card 53 for mega, 10 for uno
SdFat SD;
char buf [10];
char data[150];
const char filename[] = "weatherstation_36_c.txt"; //Change name

//Set up BME sensor
#define SEALEVELPRESSURE_HPA (1013.25)
Adafruit_BME280 bme;

//Set up RTC
RTC_DS3231 rtc;
char daysOfTheWeek[7][12] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};

//Set up wind wane
#define wind_vane 0
float wind_vane_volt;

//Set upcup anemometer
volatile int cup_count = 0;

//interrupt pin for the clock
// interrupt pin for the counter for cup anemometer 
#define clock_interrupt  2
#define counter_interrupt  3 //use 1 for attach interrupt

long delaytime = 1000; //wait between individual measurements, CHANGE THESE 
int num_data = 60; //number of measurements per burst, CHANGE THESE 

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  pinMode(13, OUTPUT);
  digitalWrite(13,LOW);

  //Start the rtc
   if (! rtc.begin()) {
    Serial.println("Could not find rtc? Check wiring");
    while (1) delay(10);
  }
  // start the bme and set to forced measurements and turn off pressure
   if (! bme.begin()) {
    Serial.println("Could not find bme? Check wiring");
    while (1) delay(10);
  }
    bme.setSampling(Adafruit_BME280::MODE_FORCED,
                Adafruit_BME280::SAMPLING_X4,   // temperature
                Adafruit_BME280::SAMPLING_NONE, // pressure
                Adafruit_BME280::SAMPLING_X16,   // humidity
                Adafruit_BME280::FILTER_OFF );
                // can also set the wait time
  // start SD card
  if (!SD.begin(chipSelect)) {
    Serial.println("initialization failed!");
    while (1) delay(10);
  }
  
  //Set the interrupt pins up
  pinMode(clock_interrupt, INPUT_PULLUP);
  pinMode(counter_interrupt, INPUT_PULLUP);
  
  interrupts();
  attachInterrupt(digitalPinToInterrupt(counter_interrupt), cup_Counter, RISING);
  //attachInterrupt(1, cup_Counter, RISING); //2 per rotation
  
  //Set up alarm clock
  rtc.disable32K();
  rtc.clearAlarm(1);
  rtc.clearAlarm(2);
  rtc.writeSqwPinMode(DS3231_OFF);
  rtc.disableAlarm(2);
  //rtc.setAlarm1(DateTime(0,0,0,0,0,0), DS3231_A1_Minute); //every hour on the hour alarm CHANGE THIS TO CHANGE SLEEP TIME
  //rtc.setAlarm1(DateTime(0,0,0,0,0,0), DS3231_A1_Second);
 
  //Serial.println("ready");
}

void loop() {
  // put your main code here, to run repeatedly:
  //Serial.println("Starting");
  digitalWrite(13, HIGH);
  delay(100);
  digitalWrite(13, LOW);
  cup_count = 0; //restart cup count
 
  myFile = SD.open(filename, FILE_WRITE); // open the file
 
  for (int i = 0; i < num_data; i++) {
      memset(data, 0, sizeof data);
      DateTime now = rtc.now();
      long start = millis();
      bme.takeForcedMeasurement(); //initialize measurements
    
      wind_vane_volt = analogRead(wind_vane);
      
    
      char datetime[] = "YY/MM/DD,hh:mm:ss,";
      strcpy(data, now.toString(datetime));
    
      //rtc temp;
      dtostrf(rtc.getTemperature(), 5, 2, buf);
      strcat(data, buf); strcat(data, ",");
    
      //bme temp;
      dtostrf(bme.readTemperature(), 5, 2, buf);
      strcat(data, buf); strcat(data, ",");
      //bme humidity;
      dtostrf(bme.readHumidity(), 5, 2, buf);
      strcat(data, buf); strcat(data, ",");
    
      //wind vane
      dtostrf(wind_vane_volt, 4, 2, buf);
      strcat(data, buf); strcat(data, ",");

      //cup_counts[10]
      int counts = cup_count;
      dtostrf(counts, 1, 0, buf);
      strcat(data, buf); strcat(data, ";");

      myFile.write(data);
      //Serial.println(data);
      //or use println idk what is better? txtFile.write(buffer.c_str(), chunkSize); or something like this? buffer is String (is bad?)

      
      delay(delaytime - millis() + start);
  }
  myFile.close(); //close the file
}

void cup_Counter(){
  cup_count++;
}

