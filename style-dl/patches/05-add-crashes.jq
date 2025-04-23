. *
{
  "sources": {
    "crashes": { "type": "vector", "url": "pmtiles:///tiles/crashes.pmtiles" }
  }
}

| .layers +=
[
  {
    "id": "crashes",
    "type": "circle",
    "source": "crashes",
    "source-layer": "crashes",
    "paint": { "circle-radius": 3, "circle-color": "#a00000" }
  }
]
