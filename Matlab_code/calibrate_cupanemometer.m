%% Script used to calibrate individual cup anemometer measurements to wind speed
% Author: Jena Shields
% Last updated: 5/30/25
% Matlab version: MATLAB R2023b
% Done with a fan array and handheld anemometer 

%NEEEDS WORK

clear all
close all

%% wind speed measured by anemometer 
v_fpm = 600; %wind speed in feet per minute
v_mps = v_fpm*0.00508; %wind speed in meters per second
%% compute 

%List of stations to be calibrated
ws_list = [3,4,6,7,8,9,10,11,12,13,14,15,16,18,20,21,23,24,25,26,27,29,30,31,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49];
count2mps = zeros(1,length(ws_list)); % cup count two meters per second initialized variable
avg_ccps = zeros(1,length(ws_list)); %average cup count per second initialized variable

for i = 1:length(ws_list)
    num = num2str(ws_list(i)); %Select one weather station at a time, convert number to string
    l_n = strcat('weatherstation_', num, '_c.txt'); %Station file name

    filename = strcat('calibration_',num2str(v_fpm),'fpm\',l_n);

    fid = fopen(filename, 'rt');
    tline = 'temp_RTC,temp,humidity,wind_dir,cup_count';
    headers = strsplit(tline, ',');     %a cell array of strings
    datacell = textscan(fid, '%s%s%f%f%f%f%f', 'Delimiter',',', 'EndOfLine',';', 'CollectOutput', 1 );
    fclose(fid);

    dates =  datacell{1}; 
    data = num2cell(datacell{2});

    dates_temp = strcat(dates(:, 1), {' '}, dates(:, 2));
    dates_in_dt = datetime(dates_temp, 'InputFormat', 'uu/MM/dd HH:mm:ss', 'Format','uu/MM/dd, HH:mm:ss');

    data_table = cell2table(data, "VariableNames", headers);
    final_table = table2timetable(data_table, "RowTimes", dates_in_dt);

    % final_table.cup_count2 = final_table.cup_count;
    % for j = 2:length(final_table.cup_count2)
    %     if final_table.cup_count(j) < final_table.cup_count(j-1)
    %         final_table.cup_count2(j) = final_table.cup_count2(j-1)+ final_table.cup_count2(j);
    %     elseif final_table.cup_count2(j) < final_table.cup_count2(j-1) && final_table.cup_count(j) >= final_table.cup_count(j-1)
    %         final_table.cup_count2(j) = final_table.cup_count2(j-1) + final_table.cup_count(j) - final_table.cup_count(j-1);
    %     end
    % end


    final_table.cupcountps = NaN(size(final_table,1), 1);
    final_table.cupcountp10s = NaN(size(final_table,1), 1);
    final_table.cupcountps(1) = final_table.cup_count(1);

    for j = 2:length(final_table.cup_count)
    if final_table.cup_count(j) < final_table.cup_count(j-1)
        final_table.cupcountps(j) = NaN;
    else
        final_table.cupcountps(j) = final_table.cup_count(j)-final_table.cup_count(j-1);
    end
    end
    
    for j = 11:length(final_table.cup_count)
        if final_table.cup_count(j) < final_table.cup_count(j-10)
            final_table.cupcountp10s(j) = NaN;
        else
            final_table.cupcountp10s(j) = (final_table.cup_count(j)-final_table.cup_count(j-10))/10;
        end
    end

    % for calibration-test
    % if ws_list(i) == 7 
    %     h = rmoutliers(final_table.cupcountp10s);
    % elseif ws_list(i) == 10
    %     h= final_table.cupcountp10s(36:180);
    % elseif ws_list(i) == 11
    %     h = final_table.cupcountp10s(1:180);
    % elseif ws_list(i) == 12
    %     h = final_table.cupcountp10s(19:end);
    % elseif ws_list(i) == 24
    %     h = final_table.cupcountp10s(1:231);
    % elseif ws_list(i) == 39
    %     h = final_table.cupcountp10s(18:end);
    % elseif ws_list(i) == 41
    %     h = final_table.cupcountp10s(31:end);
    % else
    %     h = final_table.cupcountp10s;
    % end

    if v_fpm == 820
        if ws_list(i) == 5
            h = final_table.cupcountp10s(44:end);
        elseif ws_list(i) == 34
            h = rmoutliers(final_table.cupcountp10s);
        elseif ws_list(i) == 23
            h = final_table.cupcountp10s(30:end);
        elseif ws_list(i) == 20
            h = rmoutliers(final_table.cupcountp10s);
        else
            h = final_table.cupcountp10s;
        end
    elseif v_fpm == 600
        if ws_list(i) ==23
            h = [final_table.cupcountp10s(1:81); final_table.cupcountp10s(93:end)];
        elseif ws_list(i) == 39
            h = final_table.cupcountp10s(1:329);
        elseif ws_list(i) == 42
            h = [final_table.cupcountp10s(1:59); final_table.cupcountp10s(84:end)];
        else
            h = final_table.cupcountp10s;
        end
    elseif v_fpm == 405
        if ws_list(i) == 47
            h = [final_table.cupcountp10s(1:92); final_table.cupcountp10s(107:end)];
        elseif ws_list(i) == 42
            h = [final_table.cupcountp10s(1:31); final_table.cupcountp10s(146:end)];
        elseif ws_list(i) == 5
            h = rmoutliers(final_table.cupcountp10s);
        else
            h = final_table.cupcountp10s;
        end
    end


    avg_ccps(i) = nanmean(h);

    count2mps(i) = v_mps/avg_ccps(i); % mps/count/s

    plot(h)
    title(strcat('station ', num, 'ccps ', num2str(avg_ccps(i))))
    pause(1)
end

%% Plot

conversion = 2.4*1000/3600;

histogram(avg_ccps,40)
xlabel('Conversion factor mps / count/s')
ylabel('Count')
hold on
%xline(conversion, 'r--')
title(strcat('Wind Speed = ',num2str(v_mps),' mps'))

%% Make table 
%  calibrations = table(transpose(ws_list), transpose(avg_ccps), transpose(count2mps));
% calibrations.Properties.VariableNames(1:3) = ["station",strcat('ccps_',num2str(v_fpm)), strcat('cc2mps_',num2str(v_fpm))];

load('calibrations.mat')

%% add to table
calibrations.ccps_405 = transpose(avg_ccps);
calibrations.cc2mps_405 = transpose(count2mps);


%% save

save calibrations calibrations

%%

num = num2str(36);
% l_n = strcat('weatherstation_', num, '_c.txt');
% 
% filename = strcat('calibration_',num2str(v_fpm),'fpm\',l_n);
fpm = 600;
l_n = strcat('weatherstation_', num2str(fpm), 'fpm_c.txt');
filename = strcat('calibrations_36\', l_n);
%filename = strcat('calibration-test\',l_n);

fid = fopen(filename, 'rt');
tline = 'temp_RTC,temp,humidity,wind_dir,cup_count';
headers = strsplit(tline, ',');     %a cell array of strings
datacell = textscan(fid, '%s%s%f%f%f%f%f', 'Delimiter',',', 'EndOfLine',';', 'CollectOutput', 1 );
fclose(fid);

dates =  datacell{1}; 
data = num2cell(datacell{2});

dates_temp = strcat(dates(:, 1), {' '}, dates(:, 2));
dates_in_dt = datetime(dates_temp, 'InputFormat', 'uu/MM/dd HH:mm:ss', 'Format','uu/MM/dd, HH:mm:ss');

data_table = cell2table(data, "VariableNames", headers);
final_table = table2timetable(data_table, "RowTimes", dates_in_dt);

% final_table.cup_count2 = final_table.cup_count;
% for j = 2:length(final_table.cup_count2)
%     if final_table.cup_count(j) < final_table.cup_count(j-1)
%         final_table.cup_count2(j) = final_table.cup_count2(j-1)+ final_table.cup_count2(j);
%     elseif final_table.cup_count2(j) < final_table.cup_count2(j-1) && final_table.cup_count(j) >= final_table.cup_count(j-1)
%         final_table.cup_count2(j) = final_table.cup_count2(j-1) + final_table.cup_count(j) - final_table.cup_count(j-1);
%     end
% end


final_table.cupcountps = NaN(size(final_table,1), 1);
final_table.cupcountp10s = NaN(size(final_table,1), 1);
final_table.cupcountps(1) = final_table.cup_count(1);

for j = 2:length(final_table.cup_count)
    if final_table.cup_count(j) < final_table.cup_count(j-1)
        final_table.cupcountps(j) = NaN;
    else
        final_table.cupcountps(j) = final_table.cup_count(j)-final_table.cup_count(j-1);
    end
end

for j = 11:length(final_table.cup_count)
    if final_table.cup_count(j) < final_table.cup_count(j-10)
        final_table.cupcountp10s(j) = NaN;
    else
        final_table.cupcountp10s(j) = (final_table.cup_count(j)-final_table.cup_count(j-10))/10;
    end
end


avg_ccps = nanmean(final_table.cupcountp10s);

plot(final_table.cupcountp10s)
title(strcat('station ', num, 'ccps ', num2str(avg_ccps)))

%%
load calibrations

%%

figure()
slopes = zeros(height(calibrations),1);
for i = 1:height(calibrations)
    plot([820*0.00508, 600*0.00508, 405*0.00508], [calibrations{i,2},calibrations{i,4},calibrations{i,6}])
    xlabel('Wind speed [mps]')
    ylabel('Cup counts per second')
    hold on

    slopes(i) = (820*0.00508-405*0.00508)/(calibrations{i,2}-calibrations{i,6});
end

%% 

conversion = 2.4*1000/3600;

histogram(slopes,40)
xlabel('Conversion factor mps / count/s')
ylabel('Count')
hold on
xline(conversion, 'r--')
title('Slope calibrations')

