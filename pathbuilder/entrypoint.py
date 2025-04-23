from scripts import path_builder

from pathlib import Path
from shutil import rmtree
import sys

INPUT_OSM = "/data/raw/gnv.osm.pbf"
INPUT_GEOJSON = "/data/geojson/crashes.json"

OUTPUTDIR = "/data/path/"
OUTPUT = OUTPUTDIR + "path.msgpack"

def main():
    # rm -rf path data if we are told to reset
    if len(sys.argv) > 1 and sys.argv[1] == "reset" and Path(OUTPUTDIR).is_dir():
        try:
            print("[pathbuilder] resetting")
            for path in Path(OUTPUTDIR).iterdir():
                print("removing: " + str(path))
                if path.is_file():
                    path.unlink()
                elif path.is_dir():
                    rmtree(path)
            return 0
        except: return 1

    if Path(OUTPUT).is_file():
        print("[pathbuilder] path data already processed")
        return 0

    if not (Path(INPUT_OSM).is_file() and Path(INPUT_GEOJSON).is_file()):
        print("[pathbuilder] missing input files, make sure raw data and geojson is generated")
        return 1

    print("[pathbuilder] building path")

    if path_builder.build_path(INPUT_OSM, INPUT_GEOJSON, OUTPUT) == 0:
        return 0
    else:
        print("[pathbuilder] failed to build path")
        return 1

if __name__ == '__main__':
    sys.exit(main())
