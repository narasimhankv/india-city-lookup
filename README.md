# India city lookup

One GeoParquet file that turns any latitude/longitude in India into state, district, taluk, village, locality, city and local body, with a single point-in-polygon join. Offline, no per-lookup cost.

**Version 8.8** (November 2026). **Download:** `india_city_lookup_v8.8.parquet` (226 MB) from the [Releases](../../releases) page. SHA-256 starts `54d004ee4510`.

- 732,868 polygons covering all 36 states and union territories (village polygons, approximate village areas in the Northeast and Ladakh, and taluk polygons as a fallback)
- GeoParquet 1.1, WKB geometry in EPSG:4326, zstd compression, `bbox` covering column

## How close to Google Maps?

On 2,016 random points (56 per state/UT, measured on 8.1), `google_name` matches the place name Google Maps gives at 55%, and Google's name is among `google_name`, `locality` and `alt_names` at 75%. Strongest: Delhi, Andhra Pradesh, Karnataka, Tamil Nadu (86-98%); weakest: hill and forest areas (Meghalaya, Arunachal Pradesh, Jammu and Kashmir: 12-23%). Most differences are Google naming the neighbouring village, or using hamlet names that no official source has.

## Changes in 8.8

- Uttarkashi (Uttarakhand) no longer covers 4,136 km² of the Himalaya. The source map drew the town as one polygon over 96% of Bhatwari tehsil, so points at Harsil, Gaumukh or Nelang came back as "Uttarkashi, 0 km". Survey of India's village map has the same polygon and Bhuvan has none there, so it was cut by the rule already used for other oversized towns:
  - the town keeps a 2 km footprint around the town centre (6.8 km²);
  - the empty remainder is split into 104 areas named after the nearest village of Uttarkashi district (`locality_type` "Nearest named village", `geo_level` "village (approx.)"), plus Harsil, a Census 2011 village that had no polygon, as its own approximate village area;
  - each new area names its own nearest town: Gangotri for the upper valley (Harsil 19.8 km, Gaumukh and Nelang 17.6 km), Uttarkashi for the lower valley.
- The town's reference point for nearest-town lookups had been the middle of the big polygon, 45 km from the town. Three villages near Nelang and Jadung that took Uttarkashi as their nearest town through it now name Gangotri.
- 132 villages that bordered the big polygon listed "Uttarkashi" in `alt_names` only because they touched it; it is replaced by the new areas they now border.
- 104 rows are added right after the Uttarkashi row, so row numbers after it shift by 104. No other polygon changed.
- Still to do: a few other town polygons that are far larger than the town (e.g. Valparai, Pokaran, Mudumalai).

## Changes in 8.7

Town pieces and village codes that 8.6 could not settle were checked against OpenStreetMap and Survey of India place names, and every change was confirmed with the Google Maps Geocoding API (231 lookups; Google results were used only to check, not stored).

- 123 town pieces in 76 places that were attached to a same-named town far away are fixed: 56 now take the town they actually lie in (e.g. villages near Kichha no longer say Khatima) and 67 become ordinary villages. In 19 of these places the larger group of pieces was the wrong one (e.g. Erattupetta, Budhlada, Rudraprayag).
- 66 village codes that belong to a same-named village elsewhere are cleared, with the gram panchayat and block that came from them.
- About 5,300 nearby villages that had picked one of those wrong pieces as their nearest town now name their real nearest town.
- Where OpenStreetMap and Google disagreed (two real towns with the same name, e.g. Rampur in Himachal Pradesh, Shahpur in Madhya Pradesh), nothing was changed.

## Changes in 8.6

Every field is now checked against where the polygon actually lies, and the clear errors this found are fixed (23,958 rows changed; polygons and source names unchanged).

- District and taluk come from the location for 474 rows that had been filed under a same-named unit elsewhere, e.g. Chakan (Khed taluk, Pune) was filed under Khed taluk of Ratnagiri.
- Village codes: 2,461 codes that belonged to another village (wrong district, or Census location more than 10 km away) are replaced by the right code from the LGD directory, with its block and gram panchayat; 1,338 codes from another district with no match found are cleared.
- Towns: 250 town pieces that were attached to a town by name only, more than 8 km from it, now take the town they lie in (e.g. the Rajgurunagar polygon is no longer labelled Chakan) or become ordinary villages; 3,946 town rows get their missing local body.
- Nearest town: villages whose nearest town was a same-named town in the wrong place (e.g. Patesar in Kaimur, Bihar named Chakia, the Uttar Pradesh town across the border) now name their real nearest town; 12,022 rows changed `city`, mostly villages that pointed at one of the wrongly placed town pieces.
- `google_name`: villages that only share a name with a renamed city keep their own name (a village called Faizabad no longer shows Ayodhya).
- Still to do: old district and taluk names after reorganisations (Andhra Pradesh 2022 and others, about 48,000 rows), and about 220 town pieces where it is unclear which of two same-named places is right.

## Changes in 8.5

- `city` (for villages outside towns) and `nearest_local_town` now always name a town in the village's own state. Before, a village near a state border could get a town across the border, e.g. Sholayur (Attappadi, Kerala) → Thondamuthur (Tamil Nadu); it now gets Mannarkkad, 23 km away. 26,573 villages changed `city` and 22,296 changed `nearest_local_town`; such rows say "(same state)" in `city_method`. Lakshadweep's islands no longer name mainland Kerala and Karnataka towns.
- In a few remote border areas the nearest town in the same state is far away (e.g. parts of Gariyaband, Chhattisgarh, about 95 km); `city_distance_km` shows it.

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

Checks in 8.7 and 8.8 used OpenStreetMap (© OpenStreetMap contributors, ODbL) via the Overpass API and Survey of India place names (via ramSeraph/indian_admin_boundaries).

Locations of about 300 towns come from OpenStreetMap via Nominatim: © OpenStreetMap contributors, available under the [Open Database License](https://opendatacommons.org/licenses/odbl/).

## Known limits

Census 2011 coordinates; LGD directories from 2022; boundaries 2023–25. Village areas in Arunachal Pradesh, Meghalaya, Manipur, Nagaland and Ladakh are approximate (Voronoi cells around census points). No municipal boundaries for West Bengal, Tripura, Manipur, Meghalaya, Mizoram, Andaman and Nicobar, or Dadra and Nagar Haveli and Daman and Diu.
