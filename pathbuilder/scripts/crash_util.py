import geopandas as gpd
from shapely.ops import transform
import pyproj

def add_crashes(INPUT_GEOJSON, segments):
    crashes_df = gpd.read_file(INPUT_GEOJSON)
    crash_crs = "EPSG:2238"
    crashes_df = crashes_df.to_crs(crash_crs)
    crashes_index = crashes_df.sindex

    projection = pyproj.Transformer.from_crs("EPSG:4326", crash_crs, always_xy=True)

    for segment in segments:
        projected_segment = transform(projection.transform, segment[0])
        buffer = projected_segment.buffer(120)
        segment[6] = len(crashes_index.query(buffer, predicate='intersects'))
        segment.pop(0)

    return segments
