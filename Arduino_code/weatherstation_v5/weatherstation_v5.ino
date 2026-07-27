// Weather station code for v5
// Code to modify for each station: filename
// Code to modify in general: delay_time, num_data, setAlarm1/alarm_type
// Using digital pins: 2 (interrupt, clock), 3 (interrupt, cup), 7 (wind sensors), 8 (SD card)
// analog pins: 0(wind vane)
// SPI for SD card (Use pins 10-13)
// I2C for real time clock (rtc) and humidity/temperature sensor (bme280)
// Written by: Jena Shields
// Last updated: 7/22/26
// Software: Arduino IDE 2.0.1

#include <RTClib.h> //Needed for the real time clock (RTC)
#include <SPI.h> //Needed for SPI connection, used for SD card
#include <Wire.h> //Needed for I2C connection, used for the RTC and BME280
#include <Adafruit_Sensor.h> //Needed for the ada fruit sensors (BME280)
#include <Adafruit_BME280.h> //Needed for the temp/humidity sensor (BME280)
#include <SdFat.h> //Needed for running the SD card storage
#include <avr/sleep.h> //Needed for putting into sleep mode

//Change these variables as needed:
const char filename[] = "weatherstation_b5_1.txt";
long delaytime = 1000; //wait between individual measurements
int num_data = 10; //number of measurements taken before sleeping
int alarm_type = 2; //Alarm type 1 = every hour, type 2 = every minute, if you want something else must change code below

//Set up SD card and data management for code
File myFile;
// These values depend on the type of arduino used 
const int chipSelect = 10; //connection to chip select (cs) on the sd card, 53 for mega, 10 for uno
const int MOSIPin = 11; //MOSI connection between SD and arduino
const int MISOPin = 12; //MISO connection between SD and arduino
const int SCKPin = 13; //Serial clock connection between SD and arduino
SdFat SD; //Initialize the SD card 
char buf [10]; //set buffer size for SD card
char data[150]; //measured data in each measurement stored here

//Set up BME sensor
#define SEALEVELPRESSURE_HPA (1013.25) //Needed for pressure measurements of BME280, sea level pressure
Adafruit_BME280 bme; //initialize the BME280

//Set up RTC
RTC_DS3231 rtc; //initialze the real time clock
char daysOfTheWeek[7][12] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}; //set the days of the week 

//Set up wind wane
#define wind_vane 0 //set pin reading in the voltage for the wind vane
float wind_vane_volt; //initialize variable to store the measurement from wind vane

//Set up cup anemometer
#define counter_interrupt  3 //interrupt pin for cup anemometer counter
volatile int cup_count = 0; //This integer will count up everytime the interrupt is triggered

//interrupt pin for the RTC alarm to wake up system
#define clock_interrupt  2

void setup() {
  Serial.begin(9600); //Set baud rate for serial communication

  //set up SPI pins
  pinMode(chipSelect, OUTPUT);
  pinMode(MOSIPin, OUTPUT);
  pinMode(MISOPin, INPUT);
  pinMode(SCKPin, OUTPUT);
  digitalWrite(13,LOW);

 //turn unused pins low power 
 pinMode(0, INPUT_PULLUP);
 pinMode(1, INPUT_PULLUP);
 pinMode(4, INPUT_PULLUP);
 pinMode(5, INPUT_PULLUP);
 pinMode(6, INPUT_PULLUP);
 pinMode(9, INPUT_PULLUP);
 pinMode(A1, INPUT_PULLUP);
 pinMode(A2, INPUT_PULLUP);
 pinMode(A3, INPUT_PULLUP);

 //turn on SD card and wind sensors, activates MOSFET to allow power to these components 
  pinMode(7, OUTPUT); //wind sensors, 
  pinMode(8, OUTPUT); //SD card
  digitalWrite(7, HIGH);
  digitalWrite(8, LOW);

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
  
  //Set up the interrupt pins
  pinMode(clock_interrupt, INPUT_PULLUP);
  pinMode(counter_interrupt, INPUT_PULLUP);
  
  // set up cup counter to count everytime an interrupt is read
  interrupts();
  attachInterrupt(digitalPinToInterrupt(counter_interrupt), cup_Counter, RISING);
  
  //Set up alarm clock
  rtc.disable32K();
  rtc.clearAlarm(1);
  rtc.clearAlarm(2);
  rtc.writeSqwPinMode(DS3231_OFF);
  rtc.disableAlarm(2);

  //CHANGE THIS TO CHANGE SLEEP TIME
  if (alarm_type == 1){
    rtc.setAlarm1(DateTime(0,0,0,0,0,0), DS3231_A1_Minute); //every hour on the hour alarm
  }
  else if (alarm_type == 2){
    rtc.setAlarm1(DateTime(0,0,0,0,0,0), DS3231_A1_Second); // every minute alarm
  }
  else {
    rtc.setAlarm1(DateTime(0,0,0,0,0,0), DS3231_A1_Second); // every minute alarm
  }
}

void loop() {
  cup_count = 0; //restart cup count at beginning of measurement burst
  myFile = SD.open(filename, FILE_WRITE); // open the file in the SD card
 
 // take num_data amount of measurements 
  for (int i = 0; i < num_data; i++) {
      memset(data, 0, sizeof data); //clear the variable data
      DateTime now = rtc.now(); //get current time
      long start = millis(); //log starting time of measurement
      bme.takeForcedMeasurement(); //initialize measurements 
      
      //time stamp
      char datetime[] = "YY/MM/DD,hh:mm:ss,"; //format to save date time info
      strcpy(data, now.toString(datetime)); //get date time in string format
       
      //rtc temp;
      dtostrf(rtc.getTemperature(), 5, 2, buf); //measure temperature with rtc
      strcat(data, buf); strcat(data, ","); //save measurement as string
    
      //bme temp;
      dtostrf(bme.readTemperature(), 5, 2, buf); //measure temperature with bme
      strcat(data, buf); strcat(data, ","); //save measurement as string

      //bme humidity;
      dtostrf(bme.readHumidity(), 5, 2, buf); //measure humidity with bme
      strcat(data, buf); strcat(data, ","); //save measurement as string
    
      //wind vane
      wind_vane_volt = analogRead(wind_vane); //read wind vane voltage measurement
      dtostrf(wind_vane_volt, 4, 2, buf); //get voltage measurement as string
      strcat(data, buf); strcat(data, ","); //save measurement as string

      //cup_counts
      int counts = cup_count; //cup_counts has been growing, record current number
      dtostrf(counts, 1, 0, buf); //convert number to string
      strcat(data, buf); strcat(data, ";"); //save measurement of cup rotations

      myFile.write(data); //write data to SD card
      //Serial.println(data);
      delay(delaytime - millis() + start); //wait until next time to take data
  }
  myFile.close(); //close the file

   // go to sleep
   bme.setSampling(Adafruit_BME280::MODE_SLEEP); //put bme in sleep mode
   delay(100); //delay to allow bme to sleep

   byte adcsra_save = ADCSRA; //Save state of Analog to digital converty
   ADCSRA = 0; //turn of Analog to digital converter
   SD.end(); //"close" SD Card
   SPI.end(); // end SPI transmission

   digitalWrite(7, LOW); // turn off wind sensors
   digitalWrite(8, HIGH); // turn off sd card

   Going_To_Sleep();//turn on alarm clock and alarm interrupt, turn off arduino, alarm set
    
   //awake again
   ADCSRA = adcsra_save; // turn on ADC, set to setting before sleep
   digitalWrite(7, HIGH); // turn on wind sensors
   digitalWrite(8, LOW); // turn on sd card 
   SPI.begin(); // restart SD Card 
   if (!SD.begin(chipSelect)) {
    Serial.println("initialization failed!");
    while (1) delay(10);
   }

   attachInterrupt(digitalPinToInterrupt(counter_interrupt), cup_Counter, RISING); //turn on cup anemometer counter
   //turn on bme 
   bme.setSampling(Adafruit_BME280::MODE_FORCED,
            Adafruit_BME280::SAMPLING_X4,   // temperature
            Adafruit_BME280::SAMPLING_NONE, // pressure
            Adafruit_BME280::SAMPLING_X16,   // humidity
            Adafruit_BME280::FILTER_OFF );
                // can also set the wait time
}

//How the interrupt works to count cup anemometer
void cup_Counter(){
  cup_count++;
}

void Going_To_Sleep(){
  sleep_enable();
  //rtc.setAlarm1(rtc.now() + TimeSpan(0,1,0,0),DS3231_A1_Hour); // this mode triggers the alarm in an hour when minutes +seconds match)
  rtc.clearAlarm(1);
  detachInterrupt(digitalPinToInterrupt(counter_interrupt)); //turn off cup counter interrupt
  attachInterrupt(0, onAlarm, LOW); //turn on clock alarm interrupt
  set_sleep_mode(SLEEP_MODE_PWR_DOWN); //set sleep mode
  delay(1000);
  sleep_cpu(); //sleep mode for arduino
}

void onAlarm(){ 
  sleep_disable();  //wake up arduino
  detachInterrupt(0);  //turn off clock alarm 
}
