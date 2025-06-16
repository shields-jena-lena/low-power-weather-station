%% Script to convert raw data from weather stations in .txt format to a matlab timetable
% Author: Jena Shields
% Last updated: 6/16/25
% Matlab version: MATLAB R2023b
% Recommended to run by section

clear all
close all

%% load file, set final name
%In my convention, I had each weather station save data with the file name:
% weatherstation_b[num].txt
% This code reads one file, indicated by the num value
% Change 'num', 'filename', and 'fin_name' as needed

%Specify which weather station data I want to open 
num = 3;

%name of data file to be read, edit this is file naming convention is different
filename = strcat('sample_data/weatherstation_b', num2str(num), '.txt');

%folder and name where timetable will be saved
fin_name = strcat('sample_data/ws_', num2str(num));

%Open the .txt file, read it, and close it
fid = fopen(filename, 'rt'); %Open the file to read it in text mode
tline = 'temp_RTC,temp,humidity,wind_dir,cup_count'; %The order of measurements saved (this should match the arduino code order)
headers = strsplit(tline, ','); %a cell array of strings of the measurement names
datacell = textscan(fid, '%s%s%f%f%f%f%f', 'Delimiter',',', 'EndOfLine',';', 'CollectOutput', 1 ); %Data is read from the text file, 2 strings, 5 floating point numbers, each value separated by a comma, each line separated by a ; 
fclose(fid); %Close the file

% take text data and make table
dates =  datacell{1}; %This is where the string values are stored (has date and time info)
data = num2cell(datacell{2}); %This is where the numerical data are stored

dates_temp = strcat(dates(:, 1), {' '}, dates(:, 2)); %Combine the two string arrays to make one date/time string array
dates_in_dt = datetime(dates_temp, 'InputFormat', 'uu/MM/dd HH:mm:ss', 'Format','uu/MM/dd, HH:mm:ss'); %Turn into a datetime array in specified format

data_table = cell2table(data, "VariableNames", headers); %Make a table with the numerical data with the specified variable names 

% In case there is one extra datetime element, delete the last one
if length(dates_in_dt) ~= length(data)
    dates_in_dt = dates_in_dt(1:length(data));
end

%Form a time table with the numerical data and datetime array
final_table = table2timetable(data_table, "RowTimes", dates_in_dt);

%% wind direction calibration
%Run this section and see if the horizontal lines separate the different
%domains of voltage readings from the wind vane, adjust as neccessary

%Horizontal line values
t_16 = 73;
t_15 = 87;
t_14 = 105;
t_13 = 150;
t_12 = 210;
t_11 = 267;
t_10 = 340;
t_9 = 430;
t_8 = 515;
t_7 = 615;
t_6 = 670;
t_5 = 730;
t_4 = 805;
t_3 = 860;
t_2 = 920;
t_1 = 1000;

%Plot the wind vane analog voltage data
plot(final_table.Time, final_table.wind_dir, 'o', MarkerSize=1)
hold on
xlabel('Time')
ylabel('Wind analog measurement')

%Plot the horizontal lines
yline([t_16 t_15 t_14 t_13 t_12 t_11 t_10 t_9 t_8 t_7 t_6 t_5 t_4 t_3 t_2 t_1], 'r--')

%If this separates the 16 wind direction values, move on
%% wind position set up

%Make new variables for the wind position, wind angle, and wind name
windPos = NaN(size(final_table,1), 1);
windAngle= NaN(size(final_table,1), 1);
windName = repmat("", size(final_table,1), 1);

%Initialize first values for windPos and windAngle
windPos(1) = 0;
windAngle(1) = 0;

%height of the data table
end_size = height(final_table);

% wind pos conversion
wind_dir = final_table.wind_dir;

%Convert analog values to binned positions, wind angle, and wind name
%i.e. Wind from the North is given name 'N' and angle 0 degrees
for i = 1:end_size
    if wind_dir(i) < t_16
        windPos(i) = -16;
        windAngle(i) = 112.5;
        windName(i) = "ESE";
    elseif (wind_dir(i) > t_16) && (wind_dir(i) < t_15)
        windPos(i) = -15;
        windAngle(i) = 67.5;
        windName(i) = "ENE";
    elseif (wind_dir(i) > t_15) && (wind_dir(i) < t_14)
        windPos(i) = -14;
        windAngle(i) = 90;
        windName(i) = "E";
    elseif (wind_dir(i) > t_14) && (wind_dir(i) < t_13)
        windPos(i) = -13;
        windAngle(i) = 157.5;
        windName(i) = "SSE";
    elseif (wind_dir(i) > t_13) && (wind_dir(i) < t_12)
        windPos(i) = -12;
        windAngle(i) = 135;
        windName(i) = "SE";
    elseif (wind_dir(i) > t_12) && (wind_dir(i) < t_11)
        windPos(i) = -11;
        windAngle(i) = 202.5;
        windName(i) = "SSW";
    elseif (wind_dir(i) > t_11) && (wind_dir(i) < t_10)
        windPos(i) = -10;
        windAngle(i) = 180;
        windName(i) = "S";
    elseif (wind_dir(i) > t_10) && (wind_dir(i) < t_9)
        windPos(i) = -9;
        windAngle(i) = 22.5;
        windName(i) = "NNE";
    elseif (wind_dir(i) > t_9) && (wind_dir(i) < t_8)
        windPos(i) = -8;
        windAngle(i) = 45;
        windName(i) = "NE";
    elseif (wind_dir(i) > t_8) && (wind_dir(i) < t_7)
        windPos(i) = -7;
        windAngle(i) = 247.5;
        windName(i) = "WSW";
    elseif (wind_dir(i) > t_7) && (wind_dir(i) < t_6)
        windPos(i) = -6;
        windAngle(i) = 225;
        windName(i) = "SW";
    elseif (wind_dir(i) > t_6) && (wind_dir(i) < t_5)
        windPos(i) = -5;
        windAngle(i) = 337.5;
        windName(i) = "NNW";
    elseif (wind_dir(i) > t_5) && (wind_dir(i) < t_4)
        windPos(i) = -4;
        windAngle(i) = 0;
        windName(i) = "N";
    elseif (wind_dir(i) > t_4) && (wind_dir(i) < t_3)
        windPos(i) = -3;
        windAngle(i) = 292.5;
        windName(i) = "WNW";
    elseif (wind_dir(i) > t_3) && (wind_dir(i) < t_2)
        windPos(i) = -2;
        windAngle(i) = 315;
        windName(i) = "NW";
    elseif (wind_dir(i) > t_2) && (wind_dir(i) < t_1) 
        windPos(i) = -1;
        windAngle(i) = 270;
        windName(i) = "W";
    else
        windPos(i) = NaN;
        windAngle(i) = NaN;
        windName(i) = "unknown";
    end
end

%Put the wind variables in the final table
final_table.windPos = windPos;
final_table.windAngle = windAngle;
final_table.windName = windName;

%% wind speed calibration set up

%Move the variable cup_count to the end of the table
final_table = movevars(final_table,'cup_count','after','windName');

%If you have calibration data for your specific data, use here, if not use
%the datasheet value for your cup anemometer

%From datasheet
conversion = 2.4*1000/3600; % m/s/click/s

%Self-calibration
%Load in calibration data, get conversion factor for specific station
% load('sample_data\calibrations.mat') %My calibration data
% conversion = calibrations.slopes(find(calibrations.station == num));

%Initialize new variable for wind speed (m/s)
windSpeed = zeros(size(final_table,1), 1); %Converted for each measurement
windSpeed_b10m = NaN(size(final_table,1), 1); %averaged over ten measurements

%Make local variable for cup_count and the value before it, and get the length of it
cup_count = final_table.cup_count;
cup_count_min1 = [NaN; cup_count(1:end-1)];
l = length(cup_count);

% wind speed calibration conversion for first measurement
windSpeed(1) = cup_count(1)*conversion;
windSpeed_b10m(10) = cup_count(10)*conversion/10;

% wind speed calibration conversion other measurements for each measurement
for i = 2:l
    if cup_count(i) == 0 
        windSpeed(i) = 0; %If cup count is zero, windspeed is zero
    elseif (cup_count(i)-cup_count_min1(i)) < 0 %If the cup counter reset, just convert current cup count to a wind speed
        windSpeed(i) = cup_count(i)*conversion; 
    else %Cup count from this time step-last time step, converted
        windSpeed(i) = (cup_count(i)-cup_count_min1(i))*conversion;
    end
end

% wind speed calibration conversion other measurements for moving average

cup_count_min10 = [NaN(10,1); cup_count(1:end-1)];
for i = 11:l
    if cup_count(i) == 0
        windSpeed_b10m(i) = 0;
    elseif (cup_count(i)-cup_count_min10(i)) < 0
        windSpeed_b10m(i) = NaN;
    else
        windSpeed_b10m(i) = (cup_count(i)-cup_count_min10(i))*conversion/10;
    end
end

%Get wind speeds into the final_table
final_table.windSpeed_b10m = windSpeed_b10m;
final_table.windSpeed = windSpeed;


%% save file as a .mat 
save_name=strcat(fin_name,'.mat');
save(save_name, "final_table")
%% Plot each variable by time
figure()
plot(final_table.Time, final_table.windAngle, 'o', MarkerSize=1)
xlabel('Time')
ylabel('Wind angle [deg]')

figure()
plot(final_table.Time, final_table.cup_count, 'o', MarkerSize=1)
xlabel('Time')
ylabel('Cup Count')

figure()
plot(final_table.Time, final_table.temp, 'o', MarkerSize=1)
xlabel('Time')
ylabel('Temp [C]')

figure()
plot(final_table.Time, final_table.humidity, 'o', MarkerSize=1)
xlabel('Time')
ylabel('Humidity [%rH]')

figure()
plot(final_table.Time, final_table.temp_RTC, 'o', MarkerSize=1)
xlabel('Time')
ylabel('Temp [C]')

figure()
plot(final_table.Time, final_table.windSpeed, 'o', MarkerSize=2)
xlabel('Time')
ylabel('Wind speed [m/s]')

figure()
plot(final_table.Time, final_table.windSpeed_b10m, 'o', MarkerSize=2)
xlabel('Time')
ylabel('Wind speed avg [m/s]')





