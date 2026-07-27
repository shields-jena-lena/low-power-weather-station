# -*- coding: utf-8 -*-
"""
 Script used to calibrate individual cup anemometer measurements to wind speed
 Author: Jena Shields
 Last updated: 7/22/26
 Python version: Python 3.14.2

 Translated from matlab version with help from claude ai
"""

"""
Python (NumPy/pandas) conversion of the MATLAB anemometer calibration script.

Conversion notes:
  - The .txt calibration files use ';' as the record/line separator and ','
    as the field separator within a record (MATLAB's textscan used
    'EndOfLine', ';'). This is NOT a normal CSV, so pandas.read_csv won't
    work directly -- the file is read as raw text and split manually.
  - table2timetable -> a pandas DataFrame with a DatetimeIndex.
  - MATLAB's datetime format 'uu/MM/dd HH:mm:ss' (2-digit year) ->
    Python's strptime format "%y/%m/%d %H:%M:%S".
  - rmoutliers (default "median" method: remove points more than 3 scaled
    MADs from the median, scale factor 1.4826) is reproduced by hand, since
    there's no direct NumPy/pandas equivalent.
  - mean(h, "omitmissing") -> np.nanmean(h)
  - array2table -> a pandas DataFrame with named columns.
  - Saved as .csv at the end (a calibration table is naturally tabular);
    swap for np.savez if you'd rather keep everything in .npz for
    consistency with the rest of your pipeline -- see the commented
    block at the bottom.
"""
#%% Import dependences
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

#%%
# ---------------------------------------------------------------------------
# Wind speeds measured by handheld anemometer
# ---------------------------------------------------------------------------
vs_fpm = np.array([405, 600, 820])       # wind speed, feet per minute -- change for your measurements
vs_mps = vs_fpm * 0.00508                # wind speed, meters per second


#%%
# ---------------------------------------------------------------------------
# Helper: read one calibration .txt file into a DataFrame
# ---------------------------------------------------------------------------
def read_calibration_file(filename):
    """
    Parses a calibration .txt file where records are separated by ';'
    and fields within a record are separated by ','. Each record is:
    date, time, temp_RTC, temp, humidity, wind_dir, cup_count
    """
    headers = ["temp_RTC", "temp", "humidity", "wind_dir", "cup_count"]

    with open(filename, "r") as f:
        content = f.read()

    records = [r.strip() for r in content.split(";") if r.strip()]

    dates = []
    rows = []
    for rec in records:
        fields = [x.strip() for x in rec.split(",")]
        date_str, time_str = fields[0], fields[1]
        nums = [float(x) for x in fields[2:7]]
        dt = pd.to_datetime(f"{date_str} {time_str}", format="%y/%m/%d %H:%M:%S")
        dates.append(dt)
        rows.append(nums)

    df = pd.DataFrame(rows, columns=headers, index=pd.DatetimeIndex(dates))
    return df


# ---------------------------------------------------------------------------
# Helper: MATLAB rmoutliers default ("median" method) -- remove points more
# than 3 scaled MADs (scale factor 1.4826) from the median
# ---------------------------------------------------------------------------
def rmoutliers_median(x, threshold=3.0):
    x = np.asarray(x, dtype=float)
    med = np.nanmedian(x)
    scaled_mad = 1.4826 * np.nanmedian(np.abs(x - med))
    keep = np.abs(x - med) <= threshold * scaled_mad
    return x[keep]


# ---------------------------------------------------------------------------
# Loop through txt files to get data
# ---------------------------------------------------------------------------
ws_list = [3, 4, 5, 6, 7]  # list of stations to be calibrated

count2mps = np.zeros((len(vs_mps), len(ws_list)))  # cup count -> m/s
avg_ccps = np.zeros((len(vs_mps), len(ws_list)))   # avg cup count per second

plt.ion()  # allow non-blocking plots so the loop can keep going

for k, (v_fpm, v_mps) in enumerate(zip(vs_fpm, vs_mps)):
    for i, station in enumerate(ws_list):
        num = str(station)  # station number as string

        filename = (
            Path("sample_data") / "calibration_data" / f"calibration_{v_fpm}fpm"
            / f"weatherstation_{num}_c.txt"
        )

        final_table = read_calibration_file(filename)
        cup_count = final_table["cup_count"].to_numpy()
        n = len(cup_count)

        # --- cup count per second (handles counter resets) ---
        cupcountps = np.full(n, np.nan)
        cupcountps[0] = cup_count[0]
        for j in range(1, n):
            if cup_count[j] < cup_count[j - 1]:
                cupcountps[j] = np.nan
            else:
                cupcountps[j] = cup_count[j] - cup_count[j - 1]
        final_table["cupcountps"] = cupcountps

        # --- cup count averaged over 10 seconds (handles counter resets) ---
        cupcountp10s = np.full(n, np.nan)
        for j in range(10, n):
            if cup_count[j] < cup_count[j - 10]:
                cupcountp10s[j] = np.nan
            else:
                cupcountp10s[j] = (cup_count[j] - cup_count[j - 10]) / 10
        final_table["cupcountp10s"] = cupcountp10s

        # --- filter raw values for known outliers/anomalies ---
        if v_fpm == 820:
            if station == 5:
                h = final_table["cupcountp10s"].to_numpy()[43:]  # first few points abnormal
            else:
                h = final_table["cupcountp10s"].to_numpy()
        elif v_fpm == 600:
            h = final_table["cupcountp10s"].to_numpy()
        elif v_fpm == 405:
            if station == 5:
                h = rmoutliers_median(final_table["cupcountp10s"].to_numpy())
            else:
                h = final_table["cupcountp10s"].to_numpy()

        avg_ccps[k, i] = np.nanmean(h)               # avg cup count/sec for this station/speed
        count2mps[k, i] = v_mps / avg_ccps[k, i]     # m/s per (count/s)

        # If these have outliers, filter h above and rerun
        plt.figure()
        plt.plot(h)
        plt.title(f"station {num} ccps {avg_ccps[k, i]}")
        plt.pause(1)

# %%
# ---------------------------------------------------------------------------
# Make table
# ---------------------------------------------------------------------------
avg_ccps_T = avg_ccps.T     # stations x speeds
count2mps_T = count2mps.T   # stations x speeds

calibrations_arr = np.column_stack([np.array(ws_list), avg_ccps_T, count2mps_T])

var_names = ["station"]
for v in vs_fpm:
    var_names.append(f"ccps_{v}fps")
for v in vs_fpm:
    var_names.append(f"cc2mps_{v}fps")

calibrations = pd.DataFrame(calibrations_arr, columns=var_names)

#%%
# ---------------------------------------------------------------------------
# Calculate the slope of cup count per second / wind speed for calibration
# ---------------------------------------------------------------------------
plt.figure()
slopes = np.zeros(len(calibrations))

for i in range(len(calibrations)):
    row = calibrations.iloc[i]
    plt.plot(vs_mps, [row["ccps_405fps"], row["ccps_600fps"], row["ccps_820fps"]])

    slopes[i] = (820 * 0.00508 - 405 * 0.00508) / (row["ccps_820fps"] - row["ccps_405fps"])

plt.xlabel("Wind speed [mps]")
plt.ylabel("Cup counts per second")

calibrations["slopes"] = slopes

#%%
# ---------------------------------------------------------------------------
# Save the calibration data
# ---------------------------------------------------------------------------
out_folder = Path("sample_data")
calibrations.to_csv(out_folder / "calibrations.csv", index=False)

# If you'd rather keep this in .npz format for consistency with the rest of
# the pipeline:
# np.savez(
#     out_folder / "calibrations.npz",
#     station=calibrations["station"].to_numpy(),
#     var_names=np.array(calibrations.columns),
#     data=calibrations.to_numpy(),
# )
# %%
