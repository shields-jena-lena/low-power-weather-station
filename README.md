# low-power-weather-station
Circuity and code for a low-power weather station design used for agricultural research

Build instructions will be available in Hardware X article once published

https://doi.org/10.5281/zenodo.22212162

# File summaries:

## 3.1	Arduino_code: different code versions to upload to weather station boards
  -	weatherstation_v2.ino
    - Arduino code to run the second version of the weather station build, this version allows for sleep.
  -	weatherstation_v2_constant.ino
    - Arduino code to run the second version of the weather station build, data is taken continuously.
  -	weatherstation_v5.ino
    -	Arduino code the run the 5th version of the weather station build, this version allows sleep and includes more code for low power optimization.
  -	Weatherstation_v5_constant.ino
    -	Arduino code to run the 5th version of the weather station build, data is taken continuously.

## 3.2	CAD_files: .stl files for 3D printed sensor box
  -	Humidity box bottom 1.stl
    -	STL file to print the bottom half of the box to hold the humidity and temperature sensor.
  -	Humidity box top 1.stl
    - STL file to print the top half of the box to hold the humidity and temperature sensor.

## 3.3	KiCAD_files: Circuit design and PCB design for custom circuity for weather stations
  -	Libraries
    -	Footprints and symbols for electronic components custom designed or downloaded from digikey.
  -	weather_station_v2
    -	Complete KiCAD project files for the design and PCB layout of the 2nd version of the weather station. Includes the schematic, project file, board design, bill of materials, backups, custom_footprints, and gerber files.
  -	weather_station_v5
    -	Complete KiCAD project files for the design and PCB layout of the 5th version of the weather station. Includes the schematic, project file, board design, bill of materials, backups, and gerber files.
      
## 3.4	Matlab_code – Matlab scripts to calibrate, process, and analyze weather station data, includes sample data
  -	txtfile_to_table.m
    -	MATLAB script to convert raw data from Arduino output to a .mat table.
  -	txtfile_to_table_parpool.m
    -	MATLAB script to convert raw data from Arduino output to a .mat table, using parpool to loop through all raw data in one script.
  -	std_omidNaN.m
    -	Custom function to support other MATLAB scripts that need the standard deviation while omitting NaN values.
  -	makebigarray.m
    -	MATLAB script to take the .mat tables of each weather station and combine into a large array with data from all the stations.
  -	field_analysis.m
    -	MATLAB script to do some basic analysis on the data in the large array created by makebigarray.m.
  -	calibrate_cupanemometer.m 
    - MATLAB script to calibrate cup anemometers if you have test chamber with known wind speed and raw cup count data from the weather stations. 
  -	sample_data (Both in Matlab_code/ and in Python_code/)
    - Raw text file data from weather stations. Each data file is labeled “weather_station_b#” where # is the number of the station. Data from stations 3 through 7 is included. The station_heights.csv file reports the height of the wind measurements and temperature/humidity measurements for each station. The image field28_layout_8-29-23 shows the relative location of each station to each other. The calibration_data folder includes raw data from each weather station in a testing chamber with known wind speed.
       
## 3.5	Python_code – Python scripts to calibrate, process, and analyze wather station data, includes sample data
  -	txtfile_to_table.py
    -	Python script to convert raw data from weather station to .csv file. 
  -	txtfile_to_table_forloop.py
    -	Python script to convert raw data from weather station to .csv file, a for loop is used to loop through all weather stations in one script.
  -	makebigarray.py
    -	Python script to take the .csv tables of each weather station and combine into a large array with data from all the stations.
  -	fieldanalysis.py
    -	Python script to take the output of makebigarray.py and do some basic analysis.
  -	calibrate_cupanemometer.py
    -	Python script to calibrate cup anemometer if you have test chamber with known wind speed and raw cup count data from the weather stations. 
  -	sample_data (Both in Matlab_code/ and in Python_code/)
    -	Raw text file data from weather stations. Each data file is labeled “weather_station_b#” where # is the number of the station. Data from stations 3 through 7 is included. The station_heights.csv file reports the height of the wind measurements and temperature/humidity measurements for each station. The image field28_layout_8-29-23 shows the relative location of each station to each other. The calibration_data folder includes raw data from each weather station in a testing chamber with known wind speed. 

