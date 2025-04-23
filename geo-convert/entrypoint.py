import pandas as pd
import geopandas as gpd

from pathlib import Path
from shutil import rmtree
import sys

INPUT = "/data/raw/crashes.csv"
XCOL = "Geox"
YCOL = "Geoy"
SCALE = 100
IPROJ = "EPSG:2238"

OUTPUTDIR = "/data/geojson/"
OUTPUT = OUTPUTDIR + "crashes.json"
OPROJ = "EPSG:4326"

def main():
    # rm -rf geojson if we are told to reset
    if len(sys.argv) > 1 and sys.argv[1] == "reset" and Path(OUTPUTDIR).is_dir():
        try:
            print("[geo-convert] resetting")
            for path in Path(OUTPUTDIR).iterdir():
                print("removing: " + str(path))
                if path.is_file():
                    path.unlink()
                elif path.is_dir():
                    rmtree(path)
            return 0
        except: return 1

    if Path(OUTPUT).is_file():
        print("[geo-convert] data already converted to geojson")
        return 0

    try:
        print("[geo-convert] converting data to geojson")
        df = pd.read_csv(INPUT)
        gdf = gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(df[XCOL] / SCALE, df[YCOL] / SCALE), crs=IPROJ)
        gdf = gdf.to_crs(OPROJ)
        gdf.to_file(OUTPUT, driver="GeoJSON")
        print("[geo-convert] conversion success")
        return 0
    except: return 1

if __name__ == '__main__':
    sys.exit(main())
