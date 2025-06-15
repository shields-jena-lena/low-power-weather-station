%% Example basic analysis of big array of data of multiple weather stations
% Author: Jena Shields
% Last updated: 5/30/25
% Matlab version: MATLAB R2023b

clear all
close all

%Load in field data
load('sample_data\fielddata_sample.mat')

%% Put each wanted variable into its own array, can tell location by parameter_list location
wind_speeds = field_data(:,:,5); %Grab wind speed
wind_speeds_TT = array2timetable(wind_speeds, "VariableNames",name_list, "RowTimes",Time);
wind_dirs = field_data(:,:,4); %Grab wind direction
wind_dirs_TT = array2timetable(wind_dirs, "VariableNames",name_list, "RowTimes",Time);
temps = field_data(:,:,1); %Grad temperature measurements
temps_TT = array2timetable(temps, "VariableNames",name_list, "RowTimes",Time);
%% Choose time range of interested

%Time range of interest
TR = timerange("2023-08-23","2023-09-20");

%Make smaller arrays to just be this time range
wind_speeds_TT_cut = wind_speeds_TT(TR,:);
wind_dirs_TT_cut = wind_dirs_TT(TR,:);
temps_TT_cut = temps_TT(TR,:);

% get only between 12 am and 4 am, new time range
TR = (hour(wind_speeds_TT_cut.Time) > 23 | hour(wind_speeds_TT_cut.Time) < 5);

%Cut smaller arrays to only these time period
wind_speeds_TT_cut = wind_speeds_TT_cut(TR,:);
wind_dirs_TT_cut = wind_dirs_TT_cut(TR,:);
temps_TT_cut = temps_TT_cut(TR,:);

%% get to x and y velocities 

x_vel = wind_speeds_TT_cut.*sind(wind_dirs_TT_cut).*-1;
y_vel = wind_speeds_TT_cut.*cosd(wind_dirs_TT_cut).*-1;

%% get hourly averages and standard deviations, for wind magnitude, x velocity, and y velocity

x_vel_havg = retime(x_vel,"hourly","mean");
y_vel_havg = retime(y_vel,"hourly","mean");
wind_mag_havg = retime(wind_speeds_TT_cut,"hourly","mean");

x_vel_hstd = retime(x_vel,"hourly",@std_omitNaN);
y_vel_hstd = retime(y_vel,"hourly",@std_omitNaN);
wind_mag_hstd = retime(wind_speeds_TT_cut,"hourly",@std_omitNaN);

%% Get daily averages of standard deviations, for wind magnitude, x velocity, and y velocity 

x_vel_davg = retime(x_vel,"daily","mean");
y_vel_davg = retime(y_vel,"daily","mean");
wind_mag_davg = retime(wind_speeds_TT_cut,"daily","mean");

x_vel_dstd = retime(x_vel_havg,"daily",@std_omitNaN);
y_vel_dstd = retime(y_vel,"daily",@std_omitNaN);
wind_mag_dstd = retime(wind_speeds_TT_cut,"daily",@std_omitNaN);

temps_davg = retime(temps_TT_cut, "daily", "mean");
temps_dstd = retime(temps_TT_cut, "daily", @std_omitNaN);

%% Get estimations of turbulence from hourly binning and daily binning

x_vel_hturb = x_vel_hstd./abs(x_vel_havg);
y_vel_hturb = y_vel_hstd./abs(y_vel_havg);
wind_mag_hturb = wind_mag_hstd./wind_mag_havg;

x_vel_dturb = x_vel_dstd./abs(x_vel_davg);
y_vel_dturb = y_vel_dstd./abs(y_vel_davg);
wind_mag_dturb = wind_mag_dstd./wind_mag_davg;
%% Plot the daily turbulence versus time for a specific station

plot(x_vel_dturb.Time, x_vel_dturb.("6"))
title('Station 6')
xlabel('Time')
ylabel('Daily turbulence')

%% Get field averages (average over multiple stations)
d_turb_x = mean(x_vel_dturb,2,"omitnan");
d_avg_x = mean(x_vel_davg,2,"omitnan");
d_std_x = mean(x_vel_dstd,2,"omitnan");
temps_avg = mean(temps_davg, 2, "omitnan");

d_turb_y = mean(y_vel_dturb,2,"omitnan");
d_avg_y = mean(y_vel_davg,2,"omitnan");
d_std_y = mean(y_vel_dstd,2,"omitnan");

d_turb_mag = mean(wind_mag_dturb,2,"omitnan");
d_avg_mag = mean(wind_mag_davg,2,"omitnan");
d_std_mag = mean(wind_mag_dstd,2,"omitnan");

%% FIX onward
%%

plot(catch_28_40.Time, catch_28_40.mean_d_avg_28_40)
hold on
plot(catch_28_40.Time, catch_28_40.mean_d_std_28_40)

ax = gca;
ax.FontSize = 16;

xlabel('Time')
ylabel('Velocity')

legend('Average x velocity', "std x velocity")


%%

x_dat = d_avg_mag.Variables;
y_dat = d_std_mag.Variables;

scatter(x_dat,y_dat, "filled")

x = 0:0.1:2;
y = 0.4180*x + 0.2220;
hold on
plot(x,y, '--')

ax = gca;
ax.FontSize = 16;

xlabel('Wind avg magnitude [m/s]')
ylabel('Wind std [m/s]')

%%
figure()
plot(wind_mag_28_40_havg.Time, wind_mag_28_40_havg{:,:})
ax = gca;
ax.FontSize = 16;

xlabel('Time')
ylabel('Wind mag')

figure()
plot(wind_mag_28_40_hstd.Time, wind_mag_28_40_hstd{:,:})
ax = gca;
ax.FontSize = 16;

xlabel('Time')
ylabel('Wind std')

%%
h = height(wind_speeds_28_40);
num = h/300;

for j = 6 
    s = 300*(j-1)+1;
    fin = 300*j;

    data = wind_speeds_28_40{s:fin,:};
    data = rmmissing(data,2);

    plot(data)
    pause(0.1)
end

dat2 = mean(data, 'all');

% spectral analysis

f_s = 1; %sampled at 1 Hz
N = 5*60*f_s; % length of data

T = N/f_s; %time length of data in seconds 

f_step = f_s/N;
t_step = 1/f_s;

t_1 = 1:t_step:(T);
plot(t_1,data)

f = f_step/2:f_step:(f_s-(f_step/2));


%% fft all stations 

M = width(data);

d_f = NaN([width(data),N]);
S_M = NaN([width(data),N]);

for i = 1:M
    dat2 = data(:,i)-mean(data(:,i));
    D = fft(dat2);
    d_f(i,:) = D;
    S_M(i,:) = D.*conj(D)/(f_s*N);
end

d_f_avg = mean(abs(d_f));
S = mean(S_M);

figure(1)
plot(f, d_f_avg)
xlim([0 0.5])
ax = gca;
ax.FontSize = 16;
xlabel("Freq")
ylabel("fft")

figure(2)
loglog(f(2:end),S(2:end), 'k')
xlabel("Freq")
ylabel("Saa")
ax = gca;
ax.FontSize = 16;







