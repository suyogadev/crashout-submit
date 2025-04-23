from scripts import osm_parser
from scripts import crash_util
import msgpack

def build_path(INPUT_OSM, INPUT_GEOJSON, OUTPUT_MSGPACK):
    nodes, segments = osm_parser.parse(INPUT_OSM)
    segments = crash_util.add_crashes(INPUT_GEOJSON, segments)
    data = [len(nodes), len(segments), nodes, segments]
    try:
        with open(OUTPUT_MSGPACK, "wb") as file:
            msgpack.dump(data, file, use_bin_type=True)
        return 0
    except:
        return 1
