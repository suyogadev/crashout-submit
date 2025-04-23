. *
{
  "sources": {
    "route": {
      "type": "geojson",
      "data": { "type": "FeatureCollection", "features": [] }
    }
  }
}

| .layers +=
[
  {
    "id": "route-line",
    "type": "line",
    "source": "route",
    "layout": { "line-join": "round", "line-cap": "round" },
    "paint": { "line-color": "#1e90ff", "line-width": 4, "line-opacity": 0.8 }
  }
]
