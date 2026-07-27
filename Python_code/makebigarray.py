# -*- coding: utf-8 -*-
"""
 Script to make a big array of weather station data compiled from multiple stations
 Author: Jena Shields
 Last updated: 7/22/26
 Python version: Python 3.14.2
 After weather station is in .xlsx form, combined into one big array for one season
 (time, stations, variables) order in array

 Translated from matlab version with help from claude ai
"""


"""
Output from claude ai:

Python (NumPy/pandas) conversion of the MATLAB weather-station compilation script.

Original MATLAB workflow:
  - Load one .mat file per weather station (now .xlsx files instead)
  - Drop rows with missing Time
  - Pull out temp, temp_RTC, humidity, windAngle, windSpeed
  - `synchronize` each variable across stations (i.e. outer-join on Time)
  - Stack the five variables into a 3-D array: (time, station, parameter)
  - Save field_data, Time, name_list, parameter_list

Notes on the conversion:
  - MATLAB's `synchronize` (default union) across timetables is the same as an
    outer join on a datetime index in pandas -> unmatched timestamps get NaN.
  - MATLAB is 1-indexed; this script uses standard 0-indexed Python loops,
    but the *logic* (loop over stations, first iteration initializes, rest
    join) is preserved exactly.
  - `Time = Time + years(2000)` fixes a logger bug where the year was stored
    as e.g. 23 instead of 2023. Reproduced with pandas.DateOffset(years=2000).
  - Saving is done with `np.savez` instead of MATLAB's `-v7.3` .mat file,
    since the goal is a pure NumPy/Python pipeline. If you still need a
    .mat file for interop, see the commented `scipy.io.savemat` block below.
"""

import numpy as np
import pandas as pd
from pathlib import Path



# ---------------------------------------------------------------------------
# Designate station numbers that will be included
# ---------------------------------------------------------------------------
folder = Path("Python_code/sample_data")       # location of data
nums = [3, 4, 5, 6, 7]              # number of stations to be included
name_list = [str(n) for n in nums]  # string versions of station numbers

# Containers that will hold the per-variable, multi-station tables
temp = humidity = winddir = windspeed = temp_rtc = None

for i, (num, name) in enumerate(zip(nums, name_list)):
    l_n = folder / f"ws_{name}.xlsx"        # weather station data file
    final_table = pd.read_excel(l_n)        # load in data

    # --- Filter out rows without time information ---
    filteredtable = final_table.dropna(subset=["Time"]).copy()
    filteredtable["Time"] = pd.to_datetime(filteredtable["Time"])
    filteredtable = filteredtable.set_index("Time")

    # --- Grab each variable, rename its column to the station number ---
    t   = filteredtable[["temp"]].rename(columns={"temp": name})
    h   = filteredtable[["humidity"]].rename(columns={"humidity": name})
    wd  = filteredtable[["windAngle"]].rename(columns={"windAngle": name})
    ws  = filteredtable[["windSpeed"]].rename(columns={"windSpeed": name})
    trc = filteredtable[["temp_RTC"]].rename(columns={"temp_RTC": name})

    if i == 0:
        # initialize compiled variables (first station)
        temp, humidity, winddir, windspeed, temp_rtc = t, h, wd, ws, trc
    else:
        # add to compiled variables (equivalent of MATLAB's `synchronize`)
        temp      = temp.join(t, how="outer")
        humidity  = humidity.join(h, how="outer")
        winddir   = winddir.join(wd, how="outer")
        windspeed = windspeed.join(ws, how="outer")
        temp_rtc  = temp_rtc.join(trc, how="outer")

# ---------------------------------------------------------------------------
# Make sure all five compiled tables share one common, sorted Time index
# (guards against any station having a slightly different set of timestamps)
# ---------------------------------------------------------------------------
union_index = temp.index
for df in (humidity, winddir, windspeed, temp_rtc):
    union_index = union_index.union(df.index)
union_index = union_index.sort_values()

temp      = temp.reindex(union_index)
humidity  = humidity.reindex(union_index)
winddir   = winddir.reindex(union_index)
windspeed = windspeed.reindex(union_index)
temp_rtc  = temp_rtc.reindex(union_index)

# ---------------------------------------------------------------------------
# Retrieve time information as its own variable
# ---------------------------------------------------------------------------
Time = union_index
# Make year 2023 instead of 0023
#Time = Time + pd.DateOffset(years=2000) - if the years are wrong

# ---------------------------------------------------------------------------
# Make big array in order of parameter list
# field_data shape: (n_times, n_stations, n_parameters)
# ---------------------------------------------------------------------------
parameter_list = [
    "temperature_C",
    "temp_rtc_C",
    "humidity_%",
    "winddir_from_deg",
    "windspeed_mps",
]

field_data = np.stack(
    [
        temp.to_numpy(),
        temp_rtc.to_numpy(),
        humidity.to_numpy(),
        winddir.to_numpy(),
        windspeed.to_numpy(),
    ],
    axis=2,
)

# ---------------------------------------------------------------------------
# Save the final big array (field_data) with Time, name_list, parameter_list
# ---------------------------------------------------------------------------
np.savez(
    folder / "fielddata_sample.npz",
    field_data=field_data,
    Time=Time.to_numpy(),
    name_list=np.array(name_list),
    parameter_list=np.array(parameter_list),
)

# If you need a .mat file instead (e.g. to hand off to a MATLAB user):
# from scipy.io import savemat
# savemat(
#     folder / "fielddata_sample.mat",
#     {
#         "field_data": field_data,
#         "Time": Time.to_numpy(),
#         "name_list": np.array(name_list, dtype=object),
#         "parameter_list": np.array(parameter_list, dtype=object),
#     },
# )

