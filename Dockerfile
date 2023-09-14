FROM public.ecr.aws/docker/library/rust:slim-buster AS build

ENV PKG_CONFIG_ALLOW_CROSS=1

# Build the real project.
COPY ./ ./

RUN cargo build --release

RUN \
	mkdir -p /build && \
	cp "target/release/rudolfs" /build/ && \
	strip /build/rudolfs

FROM public.ecr.aws/debian/debian:buster-slim AS run

EXPOSE 8080
VOLUME ["/data"]

COPY --from=build /build/ /

ENV DEBIAN_FRONTEND=noninteractive

RUN \
	apt-get update && \
	apt-get -y install ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Use Tini as our PID 1. This will enable signals to be handled more correctly.
#
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini
RUN chmod +x /tini

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crttt

ENTRYPOINT ["/tini", "--", "/rudolfs"]
CMD ["--cache-dir", "/data"]
