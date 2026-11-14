#!/usr/bin/env bash
# Publish or refresh every release's notes. Run from the repository root, with the dataset files in DATA_DIR
# (default: current directory). Existing releases get new notes; missing ones are created with their file.
set -euo pipefail
REPO=narasimhankv/india-city-lookup
DATA_DIR=${DATA_DIR:-.}
declare -A FILE=(
  [v8.1]=india_city_lookup.parquet [v8.3]=india_city_lookup_v8.3.parquet [v8.4]=india_city_lookup_v8.4.parquet
  [v8.5]=india_city_lookup_v8.5.parquet [v8.6]=india_city_lookup_v8.6.parquet [v8.7]=india_city_lookup_v8.7.parquet
  [v8.8]=india_city_lookup_v8.8.parquet [v8.9]=india_city_lookup_v8.9.parquet [v8.10]=india_city_lookup_v8.10.parquet [v8.11]=india_city_lookup_v8.11.parquet
)
for tag in v8.1 v8.3 v8.4 v8.5 v8.8 v8.9 v8.10 v8.11; do   # 8.6 and 8.7 are folded into 8.8
  notes=release-notes/$tag.md
  title="Version ${tag#v}"
  if gh release view "$tag" --repo "$REPO" >/dev/null 2>&1; then
    gh release edit "$tag" --repo "$REPO" --title "$title" --notes-file "$notes" --latest=false
    echo "updated notes: $tag"
  else
    f="$DATA_DIR/${FILE[$tag]}"
    extra=()
    [ "$tag" = v8.10 ] && [ -f "$DATA_DIR/v810_left_for_review.csv" ] && extra+=("$DATA_DIR/v810_left_for_review.csv")
    if [ ! -f "$f" ]; then echo "skip $tag: $f not found"; continue; fi
    gh release create "$tag" "$f" "${extra[@]}" --repo "$REPO" --target main --title "$title" --notes-file "$notes" --latest=false
    echo "created: $tag"
  fi
done
gh release edit v8.11 --repo "$REPO" --latest
