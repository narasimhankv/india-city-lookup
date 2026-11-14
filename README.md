# India city lookup

One GeoParquet file that turns any latitude/longitude in India into state, district, taluk, village, locality, city and local body, with a single point-in-polygon join. Offline, no per-lookup cost.

**Version 8.11** (November 2026). **Download:** `india_city_lookup_v8.11.parquet` (226 MB) from the [Releases](../../releases) page. SHA-256 starts `dd9f6cc6525e`.

- 732,868 polygons covering all 36 states and union territories (village polygons, approximate village areas in the Northeast and Ladakh, and taluk polygons as a fallback)
- GeoParquet 1.1, WKB geometry in EPSG:4326, zstd compression, `bbox` covering column

## Versions

| Version | File | Size | Rows | SHA-256 starts | Main change |
|---|---|---|---|---|---|
| [8.11](../../releases/tag/v8.11) | `india_city_lookup_v8.11.parquet` | 226 MB | 732,868 | `dd9f6cc6525e` | Villages follow their nearest town's adjusted_city |
| [8.10](../../releases/tag/v8.10) | `india_city_lookup_v8.10.parquet` | 226 MB | 732,868 | `aa689535bf1a` | Checks tightened; blocks, panchayats, codes, nearest towns fixed |
| [8.9](../../releases/tag/v8.9) | `india_city_lookup_v8.9.parquet` | 226 MB | 732,868 | `3b85a719ea62` | Current district, taluk and town names; old names kept |
| [8.8](../../releases/tag/v8.8) | `india_city_lookup_v8.8.parquet` | 226 MB | 732,868 | `54d004ee4510` | Uttarkashi's oversized town polygon split |
| 8.7 | not released separately (included in 8.8) | — | 732,764 | — | Town pieces and codes settled with OSM + Survey of India |
| 8.6 | not released separately (included in 8.8) | — | 732,764 | — | Every field checked against location |
| [8.5](../../releases/tag/v8.5) | `india_city_lookup_v8.5.parquet` | 226 MB | 732,764 | `3e4bba7b5fcd` | Nearest town always in the same state |
| [8.4](../../releases/tag/v8.4) | `india_city_lookup_v8.4.parquet` | 226 MB | 732,764 | `c47185e4be2a` | Current city limits for 17 cities |
| [8.3](../../releases/tag/v8.3) | `india_city_lookup_v8.3.parquet` | 226 MB | 732,764 | `9054d70f9fcf` | New adjusted_city column |
| [8.1](../../releases/tag/v8.1) | `india_city_lookup.parquet` | 225 MB | 732,764 | `4f768a1c9bc3` | Town splits, Andhra and Lakshadweep names |

8.6 and 8.7 were not published as files of their own; their changes are in 8.8 and later. Full SHA-256 values are in each release's notes. Use the latest version unless you need to reproduce an older result.

## How close to Google Maps?

On 2,016 random points (56 per state/UT, measured on 8.1), `google_name` matches the place name Google Maps gives at 55%, and Google's name is among `google_name`, `locality` and `alt_names` at 75%. Strongest: Delhi, Andhra Pradesh, Karnataka, Tamil Nadu (86-98%); weakest: hill and forest areas (Meghalaya, Arunachal Pradesh, Jammu and Kashmir: 12-23%). Most differences are Google naming the neighbouring village, or using hamlet names that no official source has.

## Changes in 8.11

- **`adjusted_city` for villages outside towns now follows the town they name** (6,440 rows). When a small town was merged into a bigger city, its own rows already showed the bigger city, but villages that named it as their nearest town still showed the small town. Example: Elinjipra is merged into Chalakudy, yet Kodassery, Kuttichira and Pariyaram (nearest town Elinjipra) showed "Elinjipra"; they now show Chalakudy. Other examples: Kharar → S.A.S. Nagar, Mango → Jamshedpur, Kasba Sultanpur → Sultanpur, Swargashram → Rishikesh, Old Malda → English Bazar.
  - 6,182 rows move to the bigger city; 258 rows get the same qualifier their town uses (e.g. Malegaon (Pune), Gaja (Tehri Garhwal)).
  - Each village follows the nearest piece of its named town in the same state, and only when that piece is within the recorded distance plus 5 km, so villages are never matched to a far-away town of the same name.
  - Towns' own rows are unchanged, so towns that were not merged keep their name (e.g. Aluva stays Aluva).
- Only `adjusted_city` changed; every other column and all polygons are identical to 8.10.

## Changes in 8.10

The review checks were rebuilt so that they flag only real errors (against the current Local Government Directory, with stricter name and distance rules), and what they found is fixed. On 8.9 the checks found 93,083 problems; on 8.10, 309 are left, mostly cases with conflicting sources (below). Polygons are unchanged.

- **Block** (63,019 rows): 38,975 blank blocks filled and 24,044 outdated blocks updated from the village's current LGD block (e.g. Mangaluru → Ullal). The old block is kept in the new column `old_block`.
- **Gram panchayat** (16,078 rows): `local_body` and `local_body_code` follow the village's current panchayat after reorganisations.
- **Village code** (215 rows) that named a different village (different name and its Census point far away): 98 replaced by the right village of the same taluk, 117 cleared with the panchayat that came from them.
- **Nearest town** (1,855 rows) and **nearest local town** (7,363 rows) where another town was clearly nearer (at least 5 km and 30% closer), the named town did not exist, or the recorded distance was more than 10 km off. `adjusted_city` follows. 17 villages that were in a town only by name (e.g. Jalalpur, Barharia in Bihar) now name their nearest town.
- **Taluk** (436 rows): Andhra Pradesh mandals split into Urban and Rural (e.g. Kurnool → Kurnool Rural).
- **alt_names**: 4,704 names of far-away namesakes dropped (e.g. Panihati on villages near Bongaon). Old official names stay.
- Smaller fixes: leftover spellings of renamed towns (Ahmedanagar, Rourkela Town, Uran Islampur Muncipal), a "Municipal boundary" placeholder used as a town name in Jalandhar, `adjusted_city` "Boundary" for Sri Hargobindpur, Faizabad (Haryana) no longer shown as Ayodhya, and 22 town rows whose locality named another town.
- Left for review (`v810_left_for_review.csv` with the release): 194 villages that lie well inside a different municipality on the Swachh Bharat map (that map and the municipal directory disagree), 75 village codes found in neither LGD nor Census 2011, and 37 nearest-town distances where a town has pieces far apart.

## Changes in 8.9

State, district and taluk names now follow the current official list (the Local Government Directory as of 12 November 2026), and towns that were renamed by notification carry their new name. Old names are kept for lookups. Polygons are unchanged.

- **District** (83,496 rows): each village is placed in its current district through its village code (or, without a code, through the villages around it), so the new districts formed since the old maps are filled in, e.g. Mauganj (from Rewa), Balotra, Phalodi, Salumbar and the other new Rajasthan districts, the 2022 Andhra Pradesh districts, Vav-Tharad, Bengaluru South, the new Ladakh and Delhi districts. Renamed districts take the new name: Ahmednagar → Ahilyanagar, Aurangabad → Chhatrapati Sambhajinagar, Osmanabad → Dharashiv, Karimganj → Sribhumi, Hoshangabad → Narmadapuram, Medinipur West → Paschim Medinipur, Cuttack → Kataka, Y.S.R. → Y.S.R. Kadapa and others. Spelling variants are left alone unless the government issued an official spelling correction (e.g. Uttar Kashi → Uttarkashi, Pondicherry → Puducherry, and Odisha's 2026 spelling list).
- **Taluk** (84,763 rows): the same for sub-districts, including the new tehsils created since 2022 and renamed ones (e.g. Velhe → Rajgad, Mugalsarai → Pandit Deendayal Upadhyay Nagar).
- **State**: Kerala → Keralam (Kerala (Alteration of Name) Act, 2026, in force from 25 August 2026).
- **Towns**: renamed towns take the new name in `city`, `google_name`, `adjusted_city`, `nearest_local_town`, the municipal `local_body` and the town's `locality`, for example Ahmednagar → Ahilyanagar, Aurangabad (Maharashtra) → Chhatrapati Sambhajinagar, Islampur (Sangli) → Ishwarpur, Mughalsarai → Pandit Deen Dayal Upadhyaya Nagar, Babai → Makhan Nagar, Nasrullaganj → Bhairunda, Bhavra → Chandra Shekhar Azad Nagar, and the 64 Odisha spellings of June 2026 (Cuttack → Kataka, Berhampur → Brahmapur, Jeypore → Jayapur, Talcher → Talacher, Rourkela → Raurkela and others; blocks too).
- **Old names for lookups**: new columns `old_state`, `old_district` and `old_taluk` hold the previous name (empty when unchanged); a renamed town's old name is added to `alt_names`.
- Left as they were: Mahe and Yanam (Puducherry), and the Pakistan-administered districts listed under Jammu and Kashmir. Jalalabad (Shahjahanpur) → Parshurampuri is not applied yet because its gazette notification has not been published.

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

`state`, `district`, `taluk`, `block`, `village`, `village_code`, `village_type`, `locality`, `locality_type`, `city`, `city_type`, `city_distance_km`, `city_method`, `nearest_local_town`, `nearest_local_town_type`, `nearest_local_town_km`, `local_body`, `local_body_type`, `local_body_code`, `geo_level`, `lookup_priority`, `source`, `village_name_in_source`, `geometry`, `google_name`, `alt_names` (list), `bbox`, `adjusted_city`, `old_state`, `old_district`, `old_taluk`, `old_block`

- `locality`: official village or town name
- `city`: the municipal body containing the area, otherwise the nearest town (`city_distance_km`)
- `google_name`: town name inside a municipal boundary, otherwise `locality`
- `alt_names`: town, bordering villages and gram panchayat, for fuzzy matching against other geocoders or typed addresses
- `adjusted_city`: `city` with suburbs merged into their main city and names cleaned and made unique (see Changes in 8.3)
- `old_state`, `old_district`, `old_taluk`, `old_block`: the earlier name where the state, district, taluk or block was renamed or the area moved to a new unit (see Changes in 8.9 and 8.10)

## Sources and attribution

Built from Survey of India and LGD/Bharatmaps village boundaries, Bhuvan (NRSC) village layers, LGD sub-district boundaries and directories, Swachh Bharat Mission municipal boundaries, and Census 2011 village points, largely via the [ramSeraph/indian_admin_boundaries](https://github.com/ramSeraph/indian_admin_boundaries) releases and the [planemad LGD mirror](https://github.com/planemad/india-local-government-directory). Check each source's terms before commercial use.

Urban centre outlines for `adjusted_city`: European Commission, Joint Research Centre, GHS Urban Centre Database R2024A (GHSL), CC BY 4.0. Main-city list: Census of India 2011 urban agglomerations.

Current city limits (8.4): municipal ward maps from Swachh Bharat Mission and the NIUA Living Atlas (via ramSeraph/indian_admin_boundaries), the Pune ward map from OpenCity (Open Database License), and the Tiruchirappalli corporation limits from OpenStreetMap.

Current district and taluk names (8.9): Local Government Directory (lgdirectory.gov.in) daily exports via ramSeraph/opendata.

Checks in 8.7 and 8.8 used OpenStreetMap (© OpenStreetMap contributors, ODbL) via the Overpass API and Survey of India place names (via ramSeraph/indian_admin_boundaries).

Locations of about 300 towns come from OpenStreetMap via Nominatim: © OpenStreetMap contributors, available under the [Open Database License](https://opendatacommons.org/licenses/odbl/).

## Known limits

Census 2011 coordinates; district and taluk names from the LGD directory of November 2026; boundaries 2023–25. Village areas in Arunachal Pradesh, Meghalaya, Manipur, Nagaland and Ladakh are approximate (Voronoi cells around census points). No municipal boundaries for West Bengal, Tripura, Manipur, Meghalaya, Mizoram, Andaman and Nicobar, or Dadra and Nagar Haveli and Daman and Diu.
