# India city lookup

One GeoParquet file that turns any latitude/longitude in India into state, district, taluk, village, locality, city and local body, with a single point-in-polygon join. Offline, no per-lookup cost.

**Download:** `india_city_lookup.parquet` (226 MB) from the [Releases](../../releases) page.

- 733,811 polygons covering all 36 states and union territories (village polygons, approximate village areas in the Northeast and Ladakh, and taluk polygons as a fallback)
- GeoParquet 1.1, WKB geometry in EPSG:4326, zstd compression, `bbox` covering column

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
