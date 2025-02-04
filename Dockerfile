FROM public.ecr.aws/docker/library/rust:slim-bookworm AS build

ENV PKG_CONFIG_ALLOW_CROSS=1

# Build the real project.
COPY ./ ./

RUN cargo build --release

RUN \
	mkdir -p /build && \
	cp "target/release/rudolfs" /build/ && \
	strip /build/rudolfs

FROM public.ecr.aws/debian/debian:bookworm-slim AS run

EXPOSE 8080
VOLUME ["/data"]

COPY --from=build /build/ /

ENV DEBIAN_FRONTEND=noninteractive


RUN \
	apt-get update \
  && apt-get -y install --no-install-recommends \
    ca-certificates \
    tini \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crttt

# Use Tini as our PID 1. This will enable signals to be handled more correctly.
ENTRYPOINT ["/usr/bin/tini", "--", "/rudolfs"]
CMD ["--cache-dir", "/data"]
