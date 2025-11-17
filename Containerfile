ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="43"
ARG SOURCE_IMAGE="${BASE_IMAGE_NAME}-main"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/${SOURCE_IMAGE}:${FEDORA_MAJOR_VERSION}

# not sure why these need to be redefined
ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="43"

ARG AKMODS_FLAVOR="main"
ARG IMAGE_NAME="liamblue"
ARG IMAGE_VENDOR="fruzyna"
ARG UBLUE_IMAGE_TAG="latest"
ARG SHA_HEAD_SHORT="dedbeef"

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build.sh
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
