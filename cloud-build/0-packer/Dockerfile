FROM alpine:3 AS checksum

ARG PACKER_VERSION
ARG PACKER_VERSION_SHA256SUM

COPY packer_${PACKER_VERSION}_linux_amd64.zip .
RUN sha256sum -c <<< "${PACKER_VERSION_SHA256SUM}  packer_${PACKER_VERSION}_linux_amd64.zip" \
  && /usr/bin/unzip packer_${PACKER_VERSION}_linux_amd64.zip

FROM gcr.io/cloud-builders/gcloud-slim

COPY --from=checksum packer /usr/bin/packer

RUN apt-get update \
  && apt-get --assume-yes --no-install-recommends install \
  jq \
  nmap \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "/usr/bin/packer" ]
