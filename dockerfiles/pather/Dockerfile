FROM ubuntu:22.04 AS pather-builder

RUN apt-get update \
    && apt-get -y install cmake ninja-build git g++ libboost-all-dev libnanoflann-dev

COPY . /tmp/pather-src
WORKDIR /tmp/pather-src

RUN cmake -Bbuild -GNinja
RUN cmake --build build --target pather --config Release

FROM ubuntu:22.04
COPY --from=pather-builder /tmp/pather-src/build/pather /usr/local/bin/pather
