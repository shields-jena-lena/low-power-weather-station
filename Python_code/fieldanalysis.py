# -*- coding: utf-8 -*-
"""
 Example basic analysis of big array of data of multiple weather stations
 Author: Jena Shields
 Last updated: 7/22/26
 Python version: Python 3.14.2
 (time, stations, variables) order in array

 Translated from matlab version with help from claude ai
"""

# %%
"""
Output from Claude ai 

Python (NumPy/pandas/matplotlib) conversion of the MATLAB field_data
analysis script.

Conversion notes:
  - MATLAB's array2timetable -> a pandas DataFrame with a DatetimeIndex.
  - MATLAB's timerange(start, end) is a HALF-OPEN interval by default
    (includes start, excludes end). Reproduced explicitly below rather
    than using df.loc[start:end], which is inclusive on both ends.
  - retime(TT, "hourly", "mean") -> DataFrame.resample("h").mean()
  - retime(TT, "hourly", @std_omitNaN) -> DataFrame.resample("h").std()
    (pandas .std() skips NaNs by default and uses ddof=1, same as
    MATLAB's std with 'omitnan').
  - mean(TT, 2, "omitnan") (mean across columns/stations) ->
    DataFrame.mean(axis=1, skipna=True)
  - sind/cosd (degrees) -> np.sin/np.cos with np.deg2rad()
  - fft/power spectrum section uses numpy.fft directly.

"""
 #%%
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# %%
# ---------------------------------------------------------------------------
# Load in field data
# ---------------------------------------------------------------------------
folder = Path("sample_data")
npz = np.load(folder / "fielddata_sample.npz", allow_pickle=True)

field_data = npz["field_data"].astype(float)                # (n_times, n_stations, n_params)
Time = pd.DatetimeIndex(npz["Time"])
name_list = [str(n) for n in npz["name_list"]]
parameter_list = list(npz["parameter_list"])

# parameter_list = ["temperature_C", "temp_rtc_C", "humidity_%",
#                    "winddir_from_deg", "windspeed_mps"]
# -> Python indices 0-4 correspond to MATLAB's 1-5

# %%
# ---------------------------------------------------------------------------
# Put each wanted variable into its own DataFrame (station columns, Time index)
# ---------------------------------------------------------------------------
wind_speeds = pd.DataFrame(field_data[:, :, 4], index=Time, columns=name_list)
wind_dirs   = pd.DataFrame(field_data[:, :, 3], index=Time, columns=name_list)
temps       = pd.DataFrame(field_data[:, :, 0], index=Time, columns=name_list)

# %%
# ---------------------------------------------------------------------------
# Choose time range of interest
# ---------------------------------------------------------------------------
start, end = pd.Timestamp("2023-08-23"), pd.Timestamp("2023-09-20")

# half-open interval, matching MATLAB's timerange default
in_range = (wind_speeds.index >= start) & (wind_speeds.index < end)
wind_speeds_cut = wind_speeds.loc[in_range]
wind_dirs_cut   = wind_dirs.loc[in_range]
temps_cut       = temps.loc[in_range]

# get only between 12am and 4am (see note above re: hour > 23)
mask = (wind_speeds_cut.index.hour > 23) | (wind_speeds_cut.index.hour < 5)
wind_speeds_cut = wind_speeds_cut.loc[mask]
wind_dirs_cut   = wind_dirs_cut.loc[mask]
temps_cut       = temps_cut.loc[mask]

# %%
# ---------------------------------------------------------------------------
# Get x and y velocities (north = +y, east = +x)
# ---------------------------------------------------------------------------
x_vel = wind_speeds_cut * np.sin(np.deg2rad(wind_dirs_cut)) * -1
y_vel = wind_speeds_cut * np.cos(np.deg2rad(wind_dirs_cut)) * -1

# %%
# ---------------------------------------------------------------------------
# Hourly averages and standard deviations (wind magnitude, x vel, y vel)
# ---------------------------------------------------------------------------
x_vel_havg = x_vel.resample("h").mean()
y_vel_havg = y_vel.resample("h").mean()
wind_mag_havg = wind_speeds_cut.resample("h").mean()

x_vel_hstd = x_vel.resample("h").std()
y_vel_hstd = y_vel.resample("h").std()
wind_mag_hstd = wind_speeds_cut.resample("h").std()

#%%
# ---------------------------------------------------------------------------
# Daily averages/std (note: x_vel_dstd is resampled from the HOURLY average,
# same as the original MATLAB -- y_vel_dstd and wind_mag_dstd use the raw
# cut data. Kept exactly as in the source script.)
# ---------------------------------------------------------------------------
x_vel_davg = x_vel.resample("D").mean()
y_vel_davg = y_vel.resample("D").mean()
wind_mag_davg = wind_speeds_cut.resample("D").mean()

x_vel_dstd = x_vel.resample("D").std()
y_vel_dstd = y_vel.resample("D").std()
wind_mag_dstd = wind_speeds_cut.resample("D").std()

temps_davg = temps_cut.resample("D").mean()
temps_dstd = temps_cut.resample("D").std()

#%%
# ---------------------------------------------------------------------------
# Turbulence estimates (hourly and daily)
# ---------------------------------------------------------------------------
x_vel_hturb = x_vel_hstd / x_vel_havg.abs()
y_vel_hturb = y_vel_hstd / y_vel_havg.abs()
wind_mag_hturb = wind_mag_hstd / wind_mag_havg

x_vel_dturb = x_vel_dstd / x_vel_davg.abs()
y_vel_dturb = y_vel_dstd / y_vel_davg.abs()
wind_mag_dturb = wind_mag_dstd / wind_mag_davg

#%%
# ---------------------------------------------------------------------------
# Plot the daily turbulence versus time for a specific station
# ---------------------------------------------------------------------------
plt.figure()
plt.plot(x_vel_dturb.index, x_vel_dturb["6"])
plt.title("Station 6")
plt.xlabel("Time")
plt.ylabel("Daily turbulence")

#%%
# ---------------------------------------------------------------------------
# Daily field averages (average over all stations)
# ---------------------------------------------------------------------------
d_turb_x = x_vel_dturb.mean(axis=1, skipna=True)
d_avg_x  = x_vel_davg.mean(axis=1, skipna=True)
d_std_x  = x_vel_dstd.mean(axis=1, skipna=True)

d_turb_y = y_vel_dturb.mean(axis=1, skipna=True)
d_avg_y  = y_vel_davg.mean(axis=1, skipna=True)
d_std_y  = y_vel_dstd.mean(axis=1, skipna=True)

d_turb_mag = wind_mag_dturb.mean(axis=1, skipna=True)
d_avg_mag  = wind_mag_davg.mean(axis=1, skipna=True)
d_std_mag  = wind_mag_dstd.mean(axis=1, skipna=True)

# %%

# ---------------------------------------------------------------------------
# Hourly field averages (average over all stations)
# ---------------------------------------------------------------------------
h_turb_x = x_vel_hturb.mean(axis=1, skipna=True)
h_avg_x  = x_vel_havg.mean(axis=1, skipna=True)
h_std_x  = x_vel_hstd.mean(axis=1, skipna=True)

h_turb_y = y_vel_hturb.mean(axis=1, skipna=True)
h_avg_y  = y_vel_havg.mean(axis=1, skipna=True)
h_std_y  = y_vel_hstd.mean(axis=1, skipna=True)

h_turb_mag = wind_mag_hturb.mean(axis=1, skipna=True)
h_avg_mag  = wind_mag_havg.mean(axis=1, skipna=True)
h_std_mag  = wind_mag_hstd.mean(axis=1, skipna=True)

# %%
# ---------------------------------------------------------------------------
# Daily average x velocity and std, averaged over all stations
# ---------------------------------------------------------------------------
plt.figure()
plt.plot(d_avg_x.index, d_avg_x.values, label="Mean x velocity")
plt.plot(d_std_x.index, d_std_x.values, label="Std x velocity")
plt.xlabel("Time")
plt.ylabel("Velocity")
plt.legend()
plt.tick_params(labelsize=16)

#%%
# ---------------------------------------------------------------------------
# Wind magnitude std vs magnitude, all stations, hourly
# ---------------------------------------------------------------------------
x_dat = h_avg_mag.values
y_dat = h_std_mag.values

plt.figure()
plt.scatter(x_dat, y_dat)
plt.xlabel("Avg wind magnitude [m/s]")
plt.ylabel("Std wind magnitude [m/s]")
plt.tick_params(labelsize=16)

#%%
# ---------------------------------------------------------------------------
# Wind magnitude std vs magnitude, all stations, daily
# ---------------------------------------------------------------------------
x_dat = d_avg_mag.values
y_dat = d_std_mag.values

plt.figure()
plt.scatter(x_dat, y_dat)

# Best-fit line found with curve fitter
x = np.arange(0, 2 + 0.1, 0.1)
y = 0.4180 * x + 0.2220
plt.plot(x, y, "--")

plt.xlabel("Avg wind magnitude [m/s]")
plt.ylabel("Std wind magnitude [m/s]")
plt.tick_params(labelsize=16)

#%%
# ---------------------------------------------------------------------------
# All-stations hourly averaged wind magnitude and standard deviation
# ---------------------------------------------------------------------------
plt.figure()
plt.plot(wind_mag_havg.index, wind_mag_havg.values)
plt.xlabel("Time")
plt.ylabel("Wind mag")
plt.tick_params(labelsize=16)

plt.figure()
plt.plot(wind_mag_hstd.index, wind_mag_hstd.values)
plt.xlabel("Time")
plt.ylabel("Wind std")
plt.tick_params(labelsize=16)

#%%
# ---------------------------------------------------------------------------
# Spectral analysis of wind magnitude data
# (uses the FULL, un-cut wind_speeds array, select an section in code section)
# ---------------------------------------------------------------------------
minutes = Time.minute
first_0_min = int(np.argmax(minutes == 0))  # first index where minute == 0

data = wind_speeds.to_numpy()[first_0_min:, :]  # crop to first on-the-hour reading

f_s = 1                      # sampled at 1 Hz
N = 5 * 60 * f_s              # length of data section desired
n = 100                       # select a data section
start_idx = N * (n - 1)
end_idx = N * n
data = data[start_idx:end_idx, :]  # crop to the chosen data section

T = N / f_s                  # time length of data section, seconds
t_step = 1 / f_s
t_1 = np.arange(1, T + t_step, t_step)  # time array (kept for parity; unused below)

f_step = f_s / N
f = np.arange(f_step / 2, f_s, f_step)  # frequency array for Fourier analysis

M = data.shape[1]  # number of stations

d_f = np.full((M, N), np.nan, dtype=complex)
S_M = np.full((M, N), np.nan)

for i in range(M):
    dat2 = data[:, i] - np.mean(data[:, i])
    D = np.fft.fft(dat2)
    d_f[i, :] = D                          # Fourier transform
    S_M[i, :] = (D * np.conj(D)).real / (f_s * N)  # power spectrum

# mean across stations
d_f_avg = np.mean(np.abs(d_f), axis=0)
S = np.mean(S_M, axis=0)

# Fourier analysis of combined stations vs frequency
plt.figure()
plt.plot(f, d_f_avg)
plt.xlim(0, 0.5)
plt.xlabel("Freq")
plt.ylabel("fft")
plt.tick_params(labelsize=16)

# Power vs frequency, log-log
plt.figure()
plt.loglog(f[1:], S[1:], "k")
plt.xlabel("Freq")
plt.ylabel("Saa")
plt.tick_params(labelsize=16)

plt.show()
# %%
