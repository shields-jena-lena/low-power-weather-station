%% making a big array of weather station data compiled from multiple stations
% Author: Jena Shields
% Last updated: 5/30/25
% Matlab version: MATLAB R2023b
% After weather station data is in .mat form, they can be combined into one
% big array for one season

% (time, stations, variables) order in array
close all
clear all

%% Designate station numbers that will be included

%location of data
folder = 'sample_data/';

%number of stations to be included
nums = [3,4,5,6,7];
name_list = string(nums);

%%
for i = 1:length(nums)

    num = nums(i); %select one weather station at a time, number
    name = name_list(i); %string of the number of the selected station
    l_n = strcat(folder,'ws_',name, '.mat'); %name of weather station .mat file
    load(l_n) %Load in data, variable final_table
    
    %Filter out rows without time information
    natRowTimes = ismissing(final_table.Time); %flag rows without time
    filteredtable = final_table(~natRowTimes,:); %remove rows without time
    clear final_table %clear table with missing time

    if i == 1 %initialize compiled variables
        temp = filteredtable(:,"temp"); %Grab temp values from first station
        temp.Properties.VariableNames(i) = name; %Name column the number of station
        humidity = filteredtable(:,"humidity"); %Grab humidity values from first station
        humidity.Properties.VariableNames(i) = name; %Name column the number of station
        winddir = filteredtable(:,"windAngle"); %Grab wind direction from first station
        winddir.Properties.VariableNames(i) = name; %Name column the number of station
        windspeed = filteredtable(:,"windSpeed"); %Grab wind speed values from first station
        windspeed.Properties.VariableNames(i) = name; %Name column the number of station
        temp_rtc = filteredtable(:,"temp_RTC"); %Grab temp_rtc values from first station
        temp_rtc.Properties.VariableNames(i) = name; %Name column the number of station
    else %add to compiled variables
        temp = synchronize(temp,filteredtable(:,"temp")); %Grab temp values from following stations
        temp.Properties.VariableNames(i) = name; %Name column the number of station
        humidity = synchronize(humidity,filteredtable(:,"humidity")); %Grab humidity values from following stations
        humidity.Properties.VariableNames(i) = name; %Name column the number of station
        winddir = synchronize(winddir,filteredtable(:,"windAngle")); %Grab wind direction values from following stations
        winddir.Properties.VariableNames(i) = name; %Name column the number of station
        windspeed = synchronize(windspeed,filteredtable(:,"windSpeed")); %Grab wind speed values from following stations
        windspeed.Properties.VariableNames(i) = name; %Name column the number of station
        temp_rtc = synchronize(temp_rtc,filteredtable(:,"temp_RTC")); %Grab temp_rtc values from following stations
        temp_rtc.Properties.VariableNames(i) = name; %Name column the number of station
    end
    clear filteredtable %clear loaded .mat variable
end

%% Retrieve time information as its own variable
Time = winddir.Time; %grab the time info from one of the compiled variables

% Make year 2023 instead of 0023
Time = Time + years(2000);

%% make big array in order of parameter list

%Name of all the variables measured and recorded in array with unit
parameter_list = ["temperature_C", "temp_rtc_C", "humidity_%", "winddir_from_deg","windspeed_mps"]; 

field_data = temp{:,1:end}; %initialize field_data with temp
field_data(:,:,2) = temp_rtc{:,1:end}; % Add temp_rtc to field data
field_data(:,:,3) = humidity{:,1:end}; % Add humidity to field data
field_data(:,:,4) = winddir{:,1:end}; % Add wind direction to field data
field_data(:,:,5) = windspeed{:,1:end}; % Add wind speed to field data

%% Save the final big array (field_Data) with Time data, name_list (which stations), and parameter list (variables measured)
save(strcat(folder,'fielddata_sample'), "field_data", "Time", "name_list", "parameter_list", '-v7.3')




