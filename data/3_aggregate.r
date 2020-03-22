# ----------------------------------------------
# BASE
# ----------------------------------------------
rm(list=ls())
source("./base/init.r", chdir=TRUE)
# ----------------------------------------------

# ----------------------------------------------
# SETUP
# ----------------------------------------------
year = "2020"
month = "02"
minObservations = 7
# ----------------------------------------------

no2Data = loadData(file.path(folders$tmp, "data", "merged", paste0(month, "_", year, ".rData")))

mData = no2Data[, .(mValue = median(value),
                    obs = .N), by = c("X", "Y")]

mData = mData[obs > minObservations][, obs := NULL]

saveData(mData, file.path(folders$tmp, "data", "aggregated", paste0(month, "_", year, ".rData")))
