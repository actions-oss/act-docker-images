ARG FROM_IMAGE_NAME="ubuntu"
ARG FROM_IMAGE_TAG="latest"
FROM ${FROM_IMAGE_NAME}:${FROM_IMAGE_TAG}

# > automatic buildx ARGs
ARG TARGETARCH

# > ARGs before FROM are not accessible
ARG FROM_IMAGE
ARG FROM_TAG

ARG BUILD_NODE_VERSION
ARG BUILD_DISTRO
ARG BUILD_TYPE
ARG BUILD_RUNNER_USER

# > Force apt to not be interactive/not ask
ENV DEBIAN_FRONTEND=noninteractive

COPY <<-EOF >/etc/apt/apt.conf.d/80-retries
	APT::Acquire::Retries "10";
EOF

COPY <<-EOF >/etc/apt/apt.conf.d/90-assume-yes
	APT::Get::Assume-Yes "true";
EOF

SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
WORKDIR /tmp

COPY ./scripts /imagegeneration/installers
# COPY ./${BUILD_DISTRO}/pgp /imagegeneration/pgp
RUN bash /imagegeneration/installers/${BUILD_TYPE}.sh

USER ${BUILD_RUNNER_USER}
