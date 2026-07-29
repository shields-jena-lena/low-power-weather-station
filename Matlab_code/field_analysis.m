%% Example basic analysis of big array of data of multiple weather stations
% Author: Jena Shields
% Last updated: 7/22/26
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

% % get only between 12 am and 4 am, new time range
% TR = (hour(wind_speeds_TT_cut.Time) > 23 | hour(wind_speeds_TT_cut.Time) < 5);
% 
% %Cut smaller arrays to only these time period
% wind_speeds_TT_cut = wind_speeds_TT_cut(TR,:);
% wind_dirs_TT_cut = wind_dirs_TT_cut(TR,:);
% temps_TT_cut = temps_TT_cut(TR,:);

%% get to x and y velocities (velocity toward the north is positive y, velocity toward the east is positive x)

x_vel = wind_speeds_TT_cut.*sind(wind_dirs_TT_cut).*-1; %x velocity
y_vel = wind_speeds_TT_cut.*cosd(wind_dirs_TT_cut).*-1; %y velocity 

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

x_vel_dstd = retime(x_vel,"daily",@std_omitNaN);
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

plot(x_vel_dturb.Time, x_vel_dturb.("3"))
title('Station 3')
xlabel('Time')
ylabel('Daily turbulence estimate')
set(gca, 'FontSize', 16)

%% Plot both the daily mean for wind mag and hourly mean

plot(wind_mag_davg.Time, wind_mag_davg.("3"), 'k--o', 'LineWidth',1)
hold on
plot(wind_mag_havg.Time, wind_mag_havg.("3"), 'LineWidth', 1)
title('Station 3')
xlabel('Time')
ylabel('Wind magnitude [m/s]')
legend(["Daily average", "Hourly average"])
set(gca, 'FontSize', 16)

%% Get daily field averages (average over all stations)
d_turb_x = mean(x_vel_dturb,2,"omitnan");
d_avg_x = mean(x_vel_davg,2,"omitnan");
d_std_x = mean(x_vel_dstd,2,"omitnan");

d_turb_y = mean(y_vel_dturb,2,"omitnan");
d_avg_y = mean(y_vel_davg,2,"omitnan");
d_std_y = mean(y_vel_dstd,2,"omitnan");

d_turb_mag = mean(wind_mag_dturb,2,"omitnan");
d_avg_mag = mean(wind_mag_davg,2,"omitnan");
d_std_mag = mean(wind_mag_dstd,2,"omitnan");

%% Get hourly field averages (average over all stations)
h_turb_x = mean(x_vel_hturb,2,"omitnan");
h_avg_x = mean(x_vel_havg,2,"omitnan");
h_std_x = mean(x_vel_hstd,2,"omitnan");

h_turb_y = mean(y_vel_hturb,2,"omitnan");
h_avg_y = mean(y_vel_havg,2,"omitnan");
h_std_y = mean(y_vel_hstd,2,"omitnan");

h_turb_mag = mean(wind_mag_hturb,2,"omitnan");
h_avg_mag = mean(wind_mag_havg,2,"omitnan");
h_std_mag = mean(wind_mag_hstd,2,"omitnan");

%% Daily average x velocity and std averaged over all stations 

plot(d_avg_x.Time, d_avg_x.mean)
hold on
plot(d_std_x.Time, d_std_x.mean)

ax = gca;
ax.FontSize = 16;

xlabel('Time')
ylabel('Velocity')

legend('Mean x velocity', "Std x velocity")


%% Plot wind magnitude standard deviation versus magnitude for all stations, hourly

x_dat = h_avg_mag.mean; %X axis will be the hourly average wind magnitude
y_dat = h_std_mag.mean; %Y axis will be hourly standard deviation of wind magnitude

scatter(x_dat,y_dat, "filled") %Scatter plot the two variables 

ax = gca;
ax.FontSize = 16;

xlabel('Avg wind magnitude [m/s]')
ylabel('Std wind magnitude [m/s]')

%% Plot wind magnitude standard deviation versus magnitude for all stations, daily

x_dat = d_avg_mag.mean; %X axis will be the daily average wind magnitude
y_dat = d_std_mag.mean; %Y axis will be daily standard deviation of wind magnitude

scatter(x_dat,y_dat, "filled") %Scatter plot the two variables 

%Best fit line found with curve fitter
x = 0:0.1:2;
y = 0.4180*x + 0.2220;
hold on
plot(x,y, '--')

ax = gca;
ax.FontSize = 16;

xlabel('Avg wind magnitude [m/s]')
ylabel('Std wind magnitude [m/s]')
%% Plot all stations hourly averaged wind magnitude and standard deviation
figure()
plot(wind_mag_havg.Time, wind_mag_havg{:,:})
ax = gca;
ax.FontSize = 16;

xlabel('Time')
ylabel('Wind mag')

figure()
plot(wind_mag_hstd.Time, wind_mag_hstd{:,:})
ax = gca;
ax.FontSize = 16;

xlabel('Time')
ylabel('Wind std')

%% Spectral analysis of wind magnitude data section

minutes = minute(Time);
first_0_min = find(minutes == 0, 1, 'first');
data = wind_speeds(first_0_min:end,:); %crop data until first on the hour measurement

f_s = 1; %sampled at 1 Hz
N = 5*60*f_s; % length of data section desired
n = 100; %select a data section 
start = N*(n-1)+1;
fin = N*n;
data = data(start:fin,:); %crop data to data section

T = N/f_s; %time length of data section in seconds 
t_step = 1/f_s; % time between each measurement
t_1 = 1:t_step:(T); %time array for length of data section in seconds

f_step = f_s/N; %Frequency step for fourier analysis
f = f_step/2:f_step:(f_s-(f_step/2)); %Frequency array for fourier analysis

% fft all stations 

M = width(data); %number of stations 

%Initialize arrays for fourier transform
d_f = NaN([width(data),N]);
S_M = NaN([width(data),N]);

%For each station, perform fft and power speciturm 
for i = 1:M
    dat2 = data(:,i)-mean(data(:,i));
    D = fft(dat2);
    d_f(i,:) = D; %Fourier transform 
    S_M(i,:) = D.*conj(D)/(f_s*N); %Power spectrum 
end

%get mean of all the stations combined
d_f_avg = mean(abs(d_f));
S = mean(S_M);

%Plot fourier analysis of the combined stations plotted against frequency 
figure(1)
plot(f, d_f_avg)
xlim([0 0.5])
ax = gca;
ax.FontSize = 16;
xlabel("Freq")
ylabel("fft")

%Plot power against frequency 
figure(2)
loglog(f(2:end),S(2:end), 'k')
xlabel("Freq")
ylabel("Saa")
ax = gca;
ax.FontSize = 16;

%% Plot vertical variation of wind, using stations 3, 4, and 5

%Starting and ending indices of the data
s_i = 1;
f_i = 100;

%Get data for the specific stations wanted for wind mag, u and v, starting
%with zeros for the ground level
wind_speeds=[zeros(f_i-s_i+1,1),wind_mag_havg.("3")(s_i:f_i),wind_mag_havg.("4")(s_i:f_i),wind_mag_havg.("5")(s_i:f_i)];
wind_speeds_x=[zeros(f_i-s_i+1,1),x_vel_havg.("3")(s_i:f_i),x_vel_havg.("4")(s_i:f_i),x_vel_havg.("5")(s_i:f_i)];
wind_speeds_y=[zeros(f_i-s_i+1,1),y_vel_havg.("3")(s_i:f_i),y_vel_havg.("4")(s_i:f_i),y_vel_havg.("5")(s_i:f_i)];

%Make grid with heights of the wind measurements
h_ticks = [0,0.7,1.33,1.48];
[H,T]=meshgrid(h_ticks,(1:1:(f_i-s_i+1))/24);

% Contour plot of the wind speeds at different heights as a function of
% time
figure(1)
[~,h]=contourf(T,H,wind_speeds,40);
xlabel('Time [days]')
xticks([0,1,2,3,4,5,6,7,8])

ylabel('Height [m]')
yticks(h_ticks)

set(h,'linecolor','none')
title('Wind speed magnitude')

colormap(('parula'))
hh=colorbar;
ylabel(hh,'m/s','FontSize',16,'Rotation',270)
ax = gca;
ax.FontSize = 16;

%Contour plots of u wind at different heights as a function of time
figure(2)
[~,h]=contourf(T,H,wind_speeds_x,40);
xlabel('Time [days]')
xticks([0,1,2,3,4,5,6,7,8])

ylabel('Height [m]')
yticks(h_ticks)

set(h,'linecolor','none')
title('Wind speed x direction')

colormap(('parula'))
hh=colorbar;
ylabel(hh,'m/s','FontSize',16,'Rotation',270)
ax = gca;
ax.FontSize = 16;

%Contour plots of u wind at different heights as a function of time
figure(3)
[~,h]=contourf(T,H,wind_speeds_y,40);
xlabel('Time [days]')
xticks([0,1,2,3,4,5,6,7,8])

ylabel('Height [m]')
yticks(h_ticks)

set(h,'linecolor','none')
title('Wind speed y direction')

colormap(('parula'))
hh=colorbar;
ylabel(hh,'m/s','FontSize',16,'Rotation',270)
ax = gca;
ax.FontSize = 16;

%% Plot vertical variation of wind direction

%Make a cyclical version of the parula color map
c = parula(128);
c_parula = [c; flipud(c)];

% Get hourly averages of wind direction
wind_dir_havg = retime(wind_dirs_TT_cut,"hourly","mean");

%Compile the wind direction data for the index range of the three stations 
wind_dirs = [wind_dir_havg.("3")(s_i:f_i),wind_dir_havg.("4")(s_i:f_i),wind_dir_havg.("5")(s_i:f_i)];

%The heights of the stations and make a meshgrid for space and time
h_ticks = [0.7,1.33,1.48];
[H,T]=meshgrid(h_ticks,(1:1:(f_i-s_i+1))/24);
    
%Contour plot for wind direction at different heights versus time
figure(4)
[~,h]=contourf(T,H,wind_dirs,40);
xlabel('Time [days]')
xticks([0,1,2,3,4,5,6,7,8])

ylabel('Height [m]')
yticks(h_ticks)

title('Wind direction')
set(h,'linecolor','none')

colormap(c_parula)
hh=colorbar;
clim([0 360])
ylabel(hh,'degree','FontSize',16,'Rotation',90)
ax = gca;
ax.FontSize = 16;

%% Plot vertical variation of temperature

%Retime to temperature data to hourly averages 
temps_havg = retime(temps_TT_cut,"hourly","mean");

%Compile the temperature data for the index range for the 3 stations
temps = [temps_havg.("3")(s_i:f_i),temps_havg.("4")(s_i:f_i),temps_havg.("5")(s_i:f_i)];

% The heights of the temp sensors, and make a meshgrid of space and time
h_ticks = [0.3, 0.93, 1.09];
[H,T]=meshgrid(h_ticks,(1:1:(f_i-s_i+1))/24);
    
%Contour plot of temperature as a function of height versus time
figure(5)
[~,h]=contourf(T,H,temps,40);
xlabel('Time [days]')
xticks([0,1,2,3,4,5,6,7,8])

ylabel('Height [m]')
yticks(h_ticks)

title('Temperature')

set(h,'linecolor','none')

colormap(('jet'))
hh = colorbar;
ylabel(hh,'^{\circ}C','FontSize',16,'Rotation',0)
ax = gca;
ax.FontSize = 16;

%% Horizontal variation of wind between stations 3, 6, and 7

%Starting and ending indices
s_i = 1;
f_i = 100;

%Get data for the specific stations wanted for wind mag, u and v
wind_speeds=[wind_mag_havg.("3")(s_i:f_i),wind_mag_havg.("6")(s_i:f_i),wind_mag_havg.("7")(s_i:f_i)];
wind_speeds_x=[x_vel_havg.("3")(s_i:f_i),x_vel_havg.("6")(s_i:f_i),x_vel_havg.("7")(s_i:f_i)];
wind_speeds_y=[y_vel_havg.("3")(s_i:f_i),y_vel_havg.("6")(s_i:f_i),y_vel_havg.("7")(s_i:f_i)];

%Make grid with station locations (approximate)
h_ticks = [0,6, 12]; %in meters
[H,T]=meshgrid(h_ticks,(1:1:(f_i-s_i+1))/24);

%Contour plot of wind magnitude as a function of space and time
figure(1)
[~,h]=contourf(T,H,wind_speeds,40);
xlabel('Time [days]')
xticks([0,1,2,3,4,5,6,7,8])

ylabel('Station')
yticks(h_ticks)
yticklabels(["#3", "#6", "#7"])

set(h,'linecolor','none')
title('Wind speed magnitude')

colormap(('parula'))
hh=colorbar;
ylabel(hh,'m/s','FontSize',16,'Rotation',270)
ax = gca;
ax.FontSize = 16;

%Contour plot of u velocity as a function of space and time
figure(2)
[~,h]=contourf(T,H,wind_speeds_x,40);
xlabel('Time [days]')
xticks([0,1,2,3,4,5,6,7,8])

ylabel('Station')
yticks(h_ticks)
yticklabels(["#3", "#6", "#7"])

set(h,'linecolor','none')
title('Wind speed x direction')

colormap(('parula'))
hh=colorbar;
ylabel(hh,'m/s','FontSize',16,'Rotation',270)
ax = gca;
ax.FontSize = 16;

%Contour plot of v velocity as a function of space and time
figure(3)
[~,h]=contourf(T,H,wind_speeds_y,40);
xlabel('Time [days]')
xticks([0,1,2,3,4,5,6,7,8])

ylabel('Station')
yticks(h_ticks)
yticklabels(["#3", "#6", "#7"])

set(h,'linecolor','none')
title('Wind speed y direction')

colormap(('parula'))
hh=colorbar;
ylabel(hh,'m/s','FontSize',16,'Rotation',270)
ax = gca;
ax.FontSize = 16;

%% Plot horizontal variation of wind direction

%Make cyclical parula color map
c = parula(128);
c_parula = [c; flipud(c)];

%Compile wind direction data for the selected stations for the selected
%index range
wind_dirs = [wind_dir_havg.("3")(s_i:f_i),wind_dir_havg.("6")(s_i:f_i),wind_dir_havg.("7")(s_i:f_i)];

%Approximate horizontal locations of stations and make mesh grid for space
%and time
h_ticks = [0,6, 12];
[H,T]=meshgrid(h_ticks,(1:1:(f_i-s_i+1))/24);
    
%Contour plot of wind direction as a function of space and time
figure(4)
[~,h]=contourf(T,H,wind_dirs,40);
xlabel('Time [days]')
xticks([0,1,2,3,4,5,6,7,8])

ylabel('Station')
yticks(h_ticks)
yticklabels(["#3", "#6", "#7"])

title('Wind direction')

set(h,'linecolor','none')

colormap(c_parula)
hh=colorbar;
clim([0 360])
ylabel(hh,'degree','FontSize',16,'Rotation',90)
ax = gca;
ax.FontSize = 16;


%% Plot horizontal variation of temperature

%Compile temp data for selected stations for selected index range
temps = [temps_havg.("3")(s_i:f_i),temps_havg.("6")(s_i:f_i),temps_havg.("7")(s_i:f_i)];

%Approximate station locations and make a meshgrid of space and time
h_ticks = [0,6, 12];
[H,T]=meshgrid(h_ticks,(1:1:(f_i-s_i+1))/24);
    
%Contour plot of temperature as a function of space and time
figure(5)
[~,h]=contourf(T,H,temps,40);
xlabel('Time [days]')
xticks([0,1,2,3,4,5,6,7,8])

ylabel('Station')
yticks(h_ticks)
yticklabels(["#3", "#6", "#7"])

title('Temperature')

set(h,'linecolor','none')

colormap(('jet'))
hh = colorbar;
ylabel(hh,'^{\circ}C','FontSize',16,'Rotation',0)
ax = gca;
ax.FontSize = 16;




