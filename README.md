# India city lookup

One GeoParquet file that turns any latitude/longitude in India into state, district, taluk, village, locality, city and local body, with a single point-in-polygon join. Offline, no per-lookup cost.

**Version 8.4** (November 2026). **Download:** `india_city_lookup.parquet` (226 MB) from the [Releases](../../releases) page. SHA-256 starts `c47185e4be2a`.

- 732,764 polygons covering all 36 states and union territories (village polygons, approximate village areas in the Northeast and Ladakh, and taluk polygons as a fallback)
- GeoParquet 1.1, WKB geometry in EPSG:4326, zstd compression, `bbox` covering column

## How close to Google Maps?

On 2,016 random points (56 per state/UT, measured on 8.1), `google_name` matches the place name Google Maps gives at 55%, and Google's name is among `google_name`, `locality` and `alt_names` at 75%. Strongest: Delhi, Andhra Pradesh, Karnataka, Tamil Nadu (86-98%); weakest: hill and forest areas (Meghalaya, Arunachal Pradesh, Jammu and Kashmir: 12-23%). Most differences are Google naming the neighbouring village, or using hamlet names that no official source has.

## Changes in 8.4

- City limits brought up to date for 17 cities whose municipal boundary had been expanded since our source maps were drawn, using current municipal ward maps: Pune, Chennai, Coimbatore, Madurai, Tiruchirappalli, Tiruppur, Erode, Karur, Kancheepuram, Hosur, Warangal, Prayagraj, Guwahati, Silchar, Srinagar, Jammu and Sonipat. For example, Pune grows from 219 to 486 km² (Wagholi and the other merged villages), Warangal from 63 to 392 km², and Chennai takes in the 16 municipalities and town panchayats merged in 2011 (Ambattur, Alandur, Tiruvottiyur and others). Villages and census towns inside the new limits are now part of the city in `city` and the local body columns (their village name stays in `locality` and `google_name`), and about 1,900 nearby villages now name the grown city as their nearest town.
- `Phulpur_Al` is now `Phulpur`.

## Changes in 8.3

- New column `adjusted_city`: the city as people use it, with one clean, unique name per place.
  - Suburbs that touch a main city, lie inside its built-up area (GHSL urban centres) and are in the same state are counted as that city: 558 suburbs across 185 main cities (e.g. Thrippunithura, Kalamassery and Kakkanad → Kochi; Secunderabad → Hyderabad; Alandur → Chennai). Main cities are the Census 2011 urban agglomeration cores plus any town with a municipal corporation or over 3 lakh people, so Thane, Navi Mumbai, Howrah and Pimpri-Chinchwad stay separate. Villages outside towns keep their own nearest town.
  - Spelling variants of one town are merged (GIridih/Giridih, Kalyan Dombivali Muncipal → Kalyan Dombivli, Greateer Jaipur → Jaipur, Jodhpur-South → Jodhpur); capitals, admin suffixes and punctuation cleaned (VIJAYAWADA (M Corp+OG) → Vijayawada).
  - Every value names exactly one place: where names repeat, the larger place keeps the plain name and others get a qualifier, e.g. Bilaspur (Himachal Pradesh), Rampur (Saharanpur).
- Fixed 1,346 villages that were wrongly placed inside a town with a similar or identical name (e.g. Kamalapuram → Amalapuram, Keraput → Koraput, ten villages named Fatehpur → Fatehpur town 25–60 km away). They are now ordinary villages with their own gram panchayat, and about 100,000 surrounding villages that had picked one of them as their nearest town now point to their real nearest town (`city`, `city_type`, `city_distance_km`, `nearest_local_town`).

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

`state`, `district`, `taluk`, `block`, `village`, `village_code`, `village_type`, `locality`, `locality_type`, `city`, `city_type`, `city_distance_km`, `city_method`, `nearest_local_town`, `nearest_local_town_type`, `nearest_local_town_km`, `local_body`, `local_body_type`, `local_body_code`, `geo_level`, `lookup_priority`, `source`, `village_name_in_source`, `geometry`, `google_name`, `alt_names` (list), `bbox`, `adjusted_city`

- `locality`: official village or town name
- `city`: the municipal body containing the area, otherwise the nearest town (`city_distance_km`)
- `google_name`: town name inside a municipal boundary, otherwise `locality`
- `alt_names`: town, bordering villages and gram panchayat, for fuzzy matching against other geocoders or typed addresses
- `adjusted_city`: `city` with suburbs merged into their main city and names cleaned and made unique (see Changes in 8.3)

## Sources and attribution

Built from Survey of India and LGD/Bharatmaps village boundaries, Bhuvan (NRSC) village layers, LGD sub-district boundaries and directories, Swachh Bharat Mission municipal boundaries, and Census 2011 village points, largely via the [ramSeraph/indian_admin_boundaries](https://github.com/ramSeraph/indian_admin_boundaries) releases and the [planemad LGD mirror](https://github.com/planemad/india-local-government-directory). Check each source's terms before commercial use.

Urban centre outlines for `adjusted_city`: European Commission, Joint Research Centre, GHS Urban Centre Database R2024A (GHSL), CC BY 4.0. Main-city list: Census of India 2011 urban agglomerations.

Current city limits (8.4): municipal ward maps from Swachh Bharat Mission and the NIUA Living Atlas (via ramSeraph/indian_admin_boundaries), the Pune ward map from OpenCity (Open Database License), and the Tiruchirappalli corporation limits from OpenStreetMap.

Locations of about 300 towns come from OpenStreetMap via Nominatim: © OpenStreetMap contributors, available under the [Open Database License](https://opendatacommons.org/licenses/odbl/).

## Known limits

Census 2011 coordinates; LGD directories from 2022; boundaries 2023–25. Village areas in Arunachal Pradesh, Meghalaya, Manipur, Nagaland and Ladakh are approximate (Voronoi cells around census points). No municipal boundaries for West Bengal, Tripura, Manipur, Meghalaya, Mizoram, Andaman and Nicobar, or Dadra and Nagar Haveli and Daman and Diu.
