FROM alpine:3 AS checksum

ARG PACKER_VERSION
ARG PACKER_VERSION_SHA256SUM

WORKDIR /workdir
COPY packer_${PACKER_VERSION}_linux_amd64.zip .
RUN echo "${PACKER_VERSION_SHA256SUM}  packer_${PACKER_VERSION}_linux_amd64.zip" > checksum \
  && sha256sum -c checksum \
  && /usr/bin/unzip packer_${PACKER_VERSION}_linux_amd64.zip

# The 'gcloud-slim' image doesn't tag versions, only 'latest'
# hadolint ignore=DL3006
FROM gcr.io/cloud-builders/gcloud-slim

COPY --from=checksum /workdir/packer /usr/bin/packer

RUN apt-get update \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "/usr/bin/packer" ]
