%% Script used to calibrate individual cup anemometer measurements to wind speed
% Author: Jena Shields
% Last updated: 6/16/25
% Matlab version: MATLAB R2023b
% Done with a fan array and handheld anemometer 
% Each station is put in front of fan array at a particular wind speed,
% collect data for a few minutes. Upload the data into this script in
% batches by each wind speed. I did three wind speeds in total 

clear all
close all

%% wind speeds measured by handheld anemometer 
vs_fpm = [405,600,820]; %wind speed in feet per minute, change for your measurements
vs_mps = vs_fpm*0.00508; %wind speed in meters per second
%% Loop through txt files to get data 

%List of stations to be calibrated
ws_list = [3,4,5,6,7];
count2mps = zeros(length(vs_mps),length(ws_list)); % cup count to meters per second initialized variable
avg_ccps = zeros(length(vs_mps),length(ws_list)); %average cup count per second initialized variable


for k = 1:length(vs_mps)
    v_fpm = vs_fpm(k);
    v_mps = vs_mps(k);
    for i = 1:length(ws_list)
        num = num2str(ws_list(i)); %Select one weather station at a time, convert number to string
        %File name for station with this speed
        filename= strcat('sample_data\calibration_data\calibration_',num2str(v_fpm), 'fpm\weatherstation_', num, '_c.txt'); %File name for station with this speed
        
        %Open the .txt file, read it, and close it
        fid = fopen(filename, 'rt');  %Open the file to read it in text mode
        tline = 'temp_RTC,temp,humidity,wind_dir,cup_count'; %The order of measurements saved (this should match the arduino code order)
        headers = strsplit(tline, ',');     %a cell array of strings of the measurement names
        datacell = textscan(fid, '%s%s%f%f%f%f%f', 'Delimiter',',', 'EndOfLine',';', 'CollectOutput', 1 ); %Data is read from the text file, 2 strings, 5 floating point numbers, each value separated by a comma, each line separated by a ;
        fclose(fid); %Close the file
    
        % take text data and make table
        dates =  datacell{1}; %This is where the string values are stored (has date and time info)
        data = num2cell(datacell{2}); %This is where the numerical data are stored
    
        dates_temp = strcat(dates(:, 1), {' '}, dates(:, 2)); %Combine the two string arrays to make one date/time string array
        dates_in_dt = datetime(dates_temp, 'InputFormat', 'uu/MM/dd HH:mm:ss', 'Format','uu/MM/dd, HH:mm:ss'); %Turn into a datetime array in specified format
    
        data_table = cell2table(data, "VariableNames", headers); %Make a table with the numerical data with the specified variable names 
        final_table = table2timetable(data_table, "RowTimes", dates_in_dt);  %Form a time table with the numerical data and datetime array
    
        %Initialize new variables in the data table for:
        final_table.cupcountps = NaN(size(final_table,1), 1); %cup count per second
        final_table.cupcountp10s = NaN(size(final_table,1), 1); %cup count averaged over 10 seconds
        final_table.cupcountps(1) = final_table.cup_count(1); %The first value in cupcount per second the first measurement of cup_count from text file
    
        %Cup count per second calculation, takes into account the cup_count
        %variable resetting to zero regularly 
        for j = 2:length(final_table.cup_count)
            if final_table.cup_count(j) < final_table.cup_count(j-1) %If the next cup count value is less than the previous, cup count per second is undefined
                final_table.cupcountps(j) = NaN;
            else
                final_table.cupcountps(j) = final_table.cup_count(j)-final_table.cup_count(j-1); %If the next cup count value is greater than previous, cup count per second is the difference 
            end
        end
        
        %Cup count averaged over 10 seconds calculation, takes into account the
        %cup_count variable resetting to zero regularly 
        for j = 11:length(final_table.cup_count)
            if final_table.cup_count(j) < final_table.cup_count(j-10) %If the 10th next cup count value is less than the current, cup count per 10 seconds is undefined
                final_table.cupcountp10s(j) = NaN;
            else
                final_table.cupcountp10s(j) = (final_table.cup_count(j)-final_table.cup_count(j-10))/10; %If the 10th next cup count value is greater than current, cup count averaged over 10 seconds is the difference, divded by 10
            end
        end
    
        %Filter final_table raw values if outliers/anomalies 
        if v_fpm == 820
            if ws_list(i) == 5
                h = final_table.cupcountp10s(44:end); %first few data points abnormal
            else
                h = final_table.cupcountp10s;
            end
        elseif v_fpm == 600
            h = final_table.cupcountp10s;
        elseif v_fpm == 405
            if ws_list(i) == 5
                h = rmoutliers(final_table.cupcountp10s); %remove outliers 
            else
                h = final_table.cupcountp10s;
            end
        end

        avg_ccps(k,i) = mean(h,"omitmissing"); %Calculate average cup count per second for this station for this speed

        count2mps(k,i) = v_mps/avg_ccps(k,i); % mps/count/s, conversion from average cup count per second to counts per m/s

        %If these have outliers, filter h above and rerun
        plot(h)
        title(strcat('station ', num, 'ccps ', num2str(avg_ccps(i))))
        pause(1)
        
    end
end   

%% Make table 

 avg_ccps = transpose(avg_ccps); %transpose the array of average cup count per second values
 count2mps = transpose(count2mps); %transpose the array of count to m/s vlaues
 calibrations = [transpose(ws_list), avg_ccps, count2mps]; %Make an array with the first column being station number, then the cup count per second values, then the conversion values
 
 %Make a string array to name each variable in the calibrations array
 var_names = strings(1,width(calibrations));
 var_names(1) = 'station';

 %Loops through the different speeds to make labels for the calibrations
 %array
 for i = 1:length(vs_mps)
     var_names(1+i) = strcat('ccps_', num2str(vs_fpm(i)), 'fps');

     var_names(1+length(vs_mps)+i) = strcat('cc2mps_',num2str(vs_fpm(i)),'fps');
 end

 %Convert the calibrations array two a table with the variable names
 %compiled above
 calibrations = array2table(calibrations, "VariableNames",var_names);

%% Calculate the slope of the cup count per second/wind speed for calibration

figure()
slopes = zeros(height(calibrations),1); %Initialize slopes variable
for i = 1:height(calibrations)
    plot(vs_mps, [calibrations{i,2},calibrations{i,3},calibrations{i,4}]) %Plot the cup count per second versus wind speed 
    xlabel('Wind speed [mps]')
    ylabel('Cup counts per second')
    hold on

    slopes(i) = (820*0.00508-405*0.00508)/(calibrations{i,4}-calibrations{i,2}); %Calculate the slope for each station
end

calibrations.slopes = slopes; %Save the slope in the calibrations table(calibration between cup count to m/s)

%% Save the calibration data 

save("sample_data\calibrations.mat","calibrations","-mat")


