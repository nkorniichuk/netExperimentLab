FROM debian:bookworm-slim AS build

ARG SRT_VERSION=v1.5.4
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential ca-certificates cmake git libssl-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "$SRT_VERSION" https://github.com/Haivision/srt.git /src \
    && cmake -S /src -B /build -DCMAKE_BUILD_TYPE=Release \
       -DENABLE_APPS=ON -DENABLE_STATIC=ON -DENABLE_SHARED=OFF \
    && cmake --build /build --target srt-file-transmit --parallel 2 \
    && cp /build/srt-file-transmit /srt-file-transmit

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends iproute2 libssl3 libstdc++6 time \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /srt-file-transmit /usr/local/bin/srt-file-transmit
RUN srt-file-transmit -h 2>&1 | grep -F 'Usage: srt-file-transmit'
