# An Overview of ERA5 Reanalysis Datasets

An ERA5 Dataset is defined to be a module containing ERA5 Reanalysis data from the Climate Data Store, and is to distinguish between datasets with differing time-resolution, from hourly to monthly.

ERA5 reanalysis data is stored on the Climate Data Store in several different categories, so different people with different needs may access different data types depending on their research.  In ERA5Reanalysis, we defined these datasets as `ERA5Dataset` Types.

When defining an `ERA5Dataset` container, we also indicate the start and end dates of the dataset that we want to work on.

```@docs
ERA5Dataset
```