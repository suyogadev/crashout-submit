FROM python:3.13-slim

RUN apt-get update \
    && apt-get -y install build-essential cmake libboost-dev \
    libexpat1-dev zlib1g-dev libbz2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir geopandas rtree osmium msgpack
