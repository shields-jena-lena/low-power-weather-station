# -*- coding: utf-8 -*-
"""
 Script to convert raw data from weather stations in .txt format to a .xlsx file
 Author: Jena Shields
 Last updated: 7/22/26
 Python version: Python 3.14.2
 Translated from matlab version with help from chatgpt
"""
# %% import dependencies 
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

# %% load text file, set final name, get data into dataframe structure

#In my convention, I had each weather station save data with the file name:
# weatherstation_b[num].txt
# This code reads one file, indicated by the num value
# Change 'num', 'filename', and 'fin_name' as needed

# Specify which weather station data I want to open 
num = 3

# name of data file to be read, edit this is file naming convention is different
filename = f"sample_data/weatherstation_b{num}.txt"

# folder and name where timetable will be saved
fin_name = f"sample_data/ws_{num}.xlsx"

# Define headers for measured variables, this is the order saved in Arduino
headers = ['date', 'time','temp_RTC', 'temp', 'humidity', 'wind_dir', 'cup_count']

# Read the data using pandas
with open(filename, 'r') as f:
    raw_text = f.read().strip()

# A semicolon signifies a new line
lines = raw_text.split(';')
lines = [line for line in lines if line.strip()]  # Remove empty lines

# Convert to DataFrame
from io import StringIO
csv_text = '\n'.join(lines)
final_table = pd.read_csv(StringIO(csv_text), header=None, names=headers) #this is our data frame with our named headers

#Make a datetime variable with our dates/times, delete the date and time columns
final_table['Time'] = pd.to_datetime(final_table['date'] + ' ' + final_table['time'], format = '%y/%m/%d %H:%M:%S' )
final_table = final_table.drop(['date','time'], axis = 1)

#Move the datetime variable to the beginning of the dataframe
cols = list(final_table.columns)
cols.insert(0, cols.pop(-1))
final_table = final_table[cols]

#Remove last row if it is incomplete
if final_table.iloc[-1].isnull().any():
    print("Last row had incomplete data and was removed.")
    final_table = final_table.iloc[:-1]

#Delete variables we no longer need
del raw_text, csv_text, lines, cols

#%% Wind direction calibration

#Run this section and see if the horizontal lines separate the different
#domains of voltage readings from the wind vane, adjust as neccessary

#Horizontal line values
t_16 = 73
t_15 = 87
t_14 = 105
t_13 = 150
t_12 = 210
t_11 = 267
t_10 = 340
t_9 = 430
t_8 = 515
t_7 = 615
t_6 = 670
t_5 = 730
t_4 = 805
t_3 = 860
t_2 = 920
t_1 = 1000

# Plot the time variable versus the analog reading of the wind vane
plt.plot(final_table['Time'], final_table['wind_dir'], 'o', markersize=1)
plt.xlabel('Time')
plt.ylabel('Wind analog measurement')

# Plot horizontal dashed red lines at the specified y-values
y_values = [t_16, t_15, t_14, t_13, t_12, t_11, t_10, t_9, t_8, t_7, t_6, t_5, t_4, t_3, t_2, t_1]
for y in y_values:
    plt.axhline(y=y, color='r', linestyle='--')

# Format x-axis with dates
ax = plt.gca()  # get current axis
ax.xaxis.set_major_locator(mdates.AutoDateLocator())  # automatic tick positions
ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))  # format the date labels

plt.xticks(rotation=45)  # rotate date labels for readability
plt.tight_layout()       # adjust layout to fit labels

plt.show() #Show the plot

#If this separates the 16 wind direction values, move on

#%% Loop to define wind angle and position 

#Get the number of time points in final_table
n_rows = final_table.shape[0]

#Make new variables for the wind position, wind angle, and wind name
windPos = np.full((n_rows, 1), np.nan)
windAngle = np.full((n_rows, 1), np.nan)
windName = np.full((n_rows, 1), "", dtype=object)  # For string array

#Initialize first values for windPos and windAngle
windPos[0] = 0
windAngle[0] = 0

#Get local variable for the wind direction measurement
wind_dir = final_table['wind_dir']

#Convert analog values to binned positions, wind angle, and wind name
#i.e. Wind from the North is given name 'N' and angle 0 degrees
for i in range(n_rows):
    if wind_dir[i] < t_16:
        windPos[i] = -16
        windAngle[i] = 112.5
        windName[i] = "ESE"
    elif t_16 < wind_dir[i] < t_15:
        windPos[i] = -15
        windAngle[i] = 67.5
        windName[i] = "ENE"
    elif t_15 < wind_dir[i] < t_14:
        windPos[i] = -14
        windAngle[i] = 90
        windName[i] = "E"
    elif t_14 < wind_dir[i] < t_13:
        windPos[i] = -13
        windAngle[i] = 157.5
        windName[i] = "SSE"
    elif t_13 < wind_dir[i] < t_12:
        windPos[i] = -12
        windAngle[i] = 135
        windName[i] = "SE"
    elif t_12 < wind_dir[i] < t_11:
        windPos[i] = -11
        windAngle[i] = 202.5
        windName[i] = "SSW"
    elif t_11 < wind_dir[i] < t_10:
        windPos[i] = -10
        windAngle[i] = 180
        windName[i] = "S"
    elif t_10 < wind_dir[i] < t_9:
        windPos[i] = -9
        windAngle[i] = 22.5
        windName[i] = "NNE"
    elif t_9 < wind_dir[i] < t_8:
        windPos[i] = -8
        windAngle[i] = 45
        windName[i] = "NE"
    elif t_8 < wind_dir[i] < t_7:
        windPos[i] = -7
        windAngle[i] = 247.5
        windName[i] = "WSW"
    elif t_7 < wind_dir[i] < t_6:
        windPos[i] = -6
        windAngle[i] = 225
        windName[i] = "SW"
    elif t_6 < wind_dir[i] < t_5:
        windPos[i] = -5
        windAngle[i] = 337.5
        windName[i] = "NNW"
    elif t_5 < wind_dir[i] < t_4:
        windPos[i] = -4
        windAngle[i] = 0
        windName[i] = "N"
    elif t_4 < wind_dir[i] < t_3:
        windPos[i] = -3
        windAngle[i] = 292.5
        windName[i] = "WNW"
    elif t_3 < wind_dir[i] < t_2:
        windPos[i] = -2
        windAngle[i] = 315
        windName[i] = "NW"
    elif t_2 < wind_dir[i] < t_1:
        windPos[i] = -1
        windAngle[i] = 270
        windName[i] = "W"
    else:
        windPos[i] = np.nan
        windAngle[i] = np.nan
        windName[i] = "unknown"

#Put the wind variables in the final table
final_table['windPos'] = windPos
final_table['windAngle'] = windAngle
final_table['windName'] = windName.ravel()

#%% Wind speed calibration set up 
 
#Move the variable cup_count to the end of the final_table
cols = list(final_table.columns) #Get the list of columns
cols.remove('cup_count')
insert_pos = cols.index('windName') + 1
cols.insert(insert_pos, 'cup_count')
final_table = final_table[cols]

#If you have calibration data for your specific data, use here, if not use
#the datasheet value for your cup anemometer

#From datasheet
conversion = 2.4*1000/3600 #m/s/click/s

#Initialize new variable for wind speed (m/s)
windSpeed = np.zeros((n_rows, 1)) #Converted for each measurement
windSpeed_b10m = np.full((n_rows, 1), np.nan) #averaged over ten measurements

#Make local variable for cup_count and the value before it
cup_count = final_table['cup_count']
cup_count_min1 = cup_count.shift(1)

# wind speed calibration conversion for first measurement
windSpeed[0] = cup_count[0] * conversion
windSpeed_b10m[9] = cup_count[9] * conversion / 10

# wind speed calibration conversion other measurements for each measurement
for i in range(1, n_rows):
    if cup_count[i] == 0:
        windSpeed[i] = 0
    elif (cup_count[i] - cup_count_min1[i]) < 0:
        windSpeed[i] = cup_count[i] * conversion
    else:
        windSpeed[i] = (cup_count[i] - cup_count_min1[i]) * conversion

#  wind speed calibration conversion other measurements for moving average
cup_count_min10 = cup_count.shift(10)
for i in range(10, n_rows):
    if cup_count[i] == 0:
        windSpeed_b10m[i] = 0
    elif (cup_count[i]-cup_count_min10[i]) < 0:
        windSpeed_b10m[i] = np.nan
    else:
        windSpeed_b10m[i] = (cup_count[i] - cup_count_min10[i]) * conversion/10

# Get wind speeds into the final_table
final_table['windSpeed_b10m'] = windSpeed_b10m
final_table['windSpeed'] = windSpeed

#%% Save final_table as a .xlsx file 

final_table.to_excel(fin_name, index=False)


# %%
