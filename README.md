# India city lookup

One GeoParquet file that turns any latitude/longitude in India into state, district, taluk, village, locality, city and local body, with a single point-in-polygon join. Offline, no per-lookup cost.

**Version 8.1** (November 2026). **Download:** `india_city_lookup.parquet` (225 MB) from the [Releases](../../releases) page. SHA-256 starts `4f768a1c9bc3`.

- 732,764 polygons covering all 36 states and union territories (village polygons, approximate village areas in the Northeast and Ladakh, and taluk polygons as a fallback)
- GeoParquet 1.1, WKB geometry in EPSG:4326, zstd compression, `bbox` covering column

## How close to Google Maps?

On 2,016 random points (56 per state/UT), `google_name` matches the place name Google Maps gives at 55%, and Google's name is among `google_name`, `locality` and `alt_names` at 75%. Strongest: Delhi, Andhra Pradesh, Karnataka, Tamil Nadu (86-98%); weakest: hill and forest areas (Meghalaya, Arunachal Pradesh, Jammu and Kashmir: 12-23%). Most differences are Google naming the neighbouring village, or using hamlet names that no official source has.

## Changes in 8.1

- Old town polygons that were later split into several municipalities now take each municipality's name (e.g. Kalamassery is no longer labelled Thrikkakara; Valanchery no longer Tanur).
- Andhra Pradesh: villages absorbed into expanded corporations keep their village name in `google_name` (as Google does); `city` is still the corporation.
- Lakshadweep: `google_name` drops the "Island" suffix (Amini Island → Amini).
- Kota North/South and Jodhpur North/South corporations are named Kota and Jodhpur.

## Lookup

```python
import geopandas as gpd
areas = gpd.read_parquet("india_city_lookup.parquet")
pts = gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(df.lon, df.lat), crs=4326)
hit = gpd.sjoin(pts, areas, predicate="within").sort_values("lookup_priority")
hit = hit[~hit.index.duplicated()]   # village rows (priority 1) beat taluk rows (priority 2)
```

## Columns

`state`, `district`, `taluk`, `block`, `village`, `village_code`, `village_type`, `locality`, `locality_type`, `city`, `city_type`, `city_distance_km`, `city_method`, `nearest_local_town`, `nearest_local_town_type`, `nearest_local_town_km`, `local_body`, `local_body_type`, `local_body_code`, `geo_level`, `lookup_priority`, `source`, `village_name_in_source`, `geometry`, `google_name`, `alt_names` (list), `bbox`

- `locality`: official village or town name
- `city`: the municipal body containing the area, otherwise the nearest town (`city_distance_km`)
- `google_name`: town name inside a municipal boundary, otherwise `locality`
- `alt_names`: town, bordering villages and gram panchayat, for fuzzy matching against other geocoders or typed addresses

## Sources and attribution

Built from Survey of India and LGD/Bharatmaps village boundaries, Bhuvan (NRSC) village layers, LGD sub-district boundaries and directories, Swachh Bharat Mission municipal boundaries, and Census 2011 village points, largely via the [ramSeraph/indian_admin_boundaries](https://github.com/ramSeraph/indian_admin_boundaries) releases and the [planemad LGD mirror](https://github.com/planemad/india-local-government-directory). Check each source's terms before commercial use.

Locations of about 300 towns come from OpenStreetMap via Nominatim: © OpenStreetMap contributors, available under the [Open Database License](https://opendatacommons.org/licenses/odbl/).

## Known limits

Census 2011 coordinates; LGD directories from 2022; boundaries 2023–25. Village areas in Arunachal Pradesh, Meghalaya, Manipur, Nagaland and Ladakh are approximate (Voronoi cells around census points). No municipal boundaries for West Bengal, Tripura, Manipur, Meghalaya, Mizoram, Andaman and Nicobar, or Dadra and Nagar Haveli and Daman and Diu.
