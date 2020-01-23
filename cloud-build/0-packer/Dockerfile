FROM alpine:3.11 as checksum

ARG PACKER_VERSION
ARG PACKER_VERSION_SHA256SUM

COPY packer_${PACKER_VERSION}_linux_amd64.zip .
RUN echo "${PACKER_VERSION_SHA256SUM}  packer_${PACKER_VERSION}_linux_amd64.zip" > checksum \
  && sha256sum -c checksum \
  && /usr/bin/unzip packer_${PACKER_VERSION}_linux_amd64.zip

FROM gcr.io/cloud-builders/gcloud

COPY --from=checksum packer /usr/bin/packer

ENTRYPOINT ["/usr/bin/packer"]
