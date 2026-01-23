# Available ERA5 Datasets

An ERA5 Dataset is defined to be a module containing ERA5 Reanalysis data from the Climate Data Store, and is used to distinguish between datasets with differing time-resolution, from hourly to monthly.

ERA5 reanalysis data is stored on the Climate Data Store in several different categories. In ERA5Reanalysis.jl, we define these datasets as `ERA5Dataset` Types.

The `ERA5Dataset` Type has the following sub-Types:
* `ERA5CDStore` for datasets available directly from the Climate Data Store
* `ERA5Custom` for custom datasets derived from ERA5 data (e.g., daily averages)
* `ERA5Dummy` for specifying paths without date information

All subTypes of `ERA5Dataset` have the [same basic fields and structure](/basics#The-ERA5Dataset-Type).

## Summary Table

The following are the different available Types and functions used to define them:

|      Type       |    SuperType    |    Resolution   |       Function       |
| :-------------: | :-------------: | :-------------: | :------------------: |
|  `ERA5Hourly`   |  `ERA5CDStore`  |     Hourly      |    `ERA5Hourly()`    |
|  `ERA5Monthly`  |  `ERA5CDStore`  |     Monthly     |   `ERA5Monthly()`    |
| `ERA5MonthlyHour` | `ERA5CDStore` | Monthly by Hour | `ERA5Monthly(hours=...)` |
|   `ERA5Daily`   |  `ERA5Custom`   |      Daily      |    `ERA5Daily()`     |
|   `ERA5Dummy`   |  `ERA5Dataset`  |       N/A       |    `ERA5Dummy()`     |

## Climate Data Store Datasets

The `ERA5CDStore` datasets can be downloaded directly using the CDS API:
* **ERA5Hourly** - Hourly ERA5 reanalysis data
* **ERA5Monthly** - Monthly-averaged ERA5 reanalysis data
* **ERA5MonthlyHour** - Monthly data by hour-of-day (accessed via `ERA5Monthly(hours=...)`)

See the [CDS Datasets](cds.md) page for more information.

## Custom Datasets

ERA5Reanalysis.jl also provides custom datasets that are derived from the CDS datasets:
* **ERA5Daily** - Daily-averaged data computed from `ERA5Hourly` data

See the [Custom Datasets](custom.md) page for more information.

## Dummy Datasets

Dummy datasets are used to specify paths to the ERA5 data directories without needing date inputs. This is useful for operations like retrieving Land-Sea masks.

See the [Dummy Datasets](dummy.md) page for more information.
