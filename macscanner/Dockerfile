ARG BUILD_FROM=ghcr.io/hassio-addons/base-python:latest
FROM $BUILD_FROM

RUN \
  apk add --no-cache \
    python3 \
    sudo \
    nmap \
    mosquitto-clients

WORKDIR /data

# Copy data for add-on
COPY rootfs /
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]


