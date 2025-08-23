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

COPY <<-EOF >/etc/apt/trusted.gpg.d/microsoft.asc
	-----BEGIN PGP PUBLIC KEY BLOCK-----
	Version: BSN Pgp v1.1.0.0

	mQENBFYxWIwBCADAKoZhZlJxGNGWzqV+1OG1xiQeoowKhssGAKvd+buXCGISZJwT
	LXZqIcIiLP7pqdcZWtE9bSc7yBY2MalDp9Liu0KekywQ6VVX1T72NPf5Ev6x6DLV
	7aVWsCzUAF+eb7DC9fPuFLEdxmOEYoPjzrQ7cCnSV4JQxAqhU4T6OjbvRazGl3ag
	OeizPXmRljMtUUttHQZnRhtlzkmwIrUivbfFPD+fEoHJ1+uIdfOzZX8/oKHKLe2j
	H632kvsNzJFlROVvGLYAk2WRcLu+RjjggixhwiB+Mu/A8Tf4V6b+YppS44q8EvVr
	M+QvY7LNSOffSO6Slsy9oisGTdfE39nC7pVRABEBAAG0N01pY3Jvc29mdCAoUmVs
	ZWFzZSBzaWduaW5nKSA8Z3Bnc2VjdXJpdHlAbWljcm9zb2Z0LmNvbT6JATQEEwEI
	AB4FAlYxWIwCGwMGCwkIBwMCAxUIAwMWAgECHgECF4AACgkQ6z6Urb4SKc+P9gf/
	diY2900wvWEgV7iMgrtGzx79W/PbwWiOkKoD9sdzhARXWiP8Q5teL/t5TUH6TZ3B
	ENboDjwr705jLLPwuEDtPI9jz4kvdT86JwwG6N8gnWM8Ldi56SdJEtXrzwtlB/Fe
	6tyfMT1E/PrJfgALUG9MWTIJkc0GhRJoyPpGZ6YWSLGXnk4c0HltYKDFR7q4wtI8
	4cBu4mjZHZbxIO6r8Cci+xxuJkpOTIpr4pdpQKpECM6x5SaT2gVnscbN0PE19KK9
	nPsBxyK4wW0AvAhed2qldBPTipgzPhqB2gu0jSryil95bKrSmlYJd1Y1XfNHno5D
	xfn5JwgySBIdWWvtOI05gw==
	=zPfd
	-----END PGP PUBLIC KEY BLOCK-----
EOF

COPY <<-EOF >/etc/apt/trusted.gpg.d/git-core.asc
	-----BEGIN PGP PUBLIC KEY BLOCK-----
	Comment: Hostname:
	Version: Hockeypuck 2.2

	xsFNBGYo2OYBEADVRjI+o29u9izslaVr0Xqj8hpmo/2su/Iey1PgoS6A3hMxR4R4
	eZ3u9dRh/gRHXNjxqRMfKj88G6ciqa/7ty8Vfc1eKl3z7yjL1pWOEzcGLKaSB8qd
	MmsxCw31nFNEbzlymgK0+KPubQ5OrIzeSikpfDVGT4HLgO42ppGY+cVy2/bbNv6O
	mmPXcw8gkxRCWFiGAO5jJYG1SyGbhr9Krbf6o+LDUJeDYPTQRMf702IYZ8Bp00ix
	HyK2YOUNM14rr7092o2dw9GKxnJszF4cET+LxRddrREuB3sBlAZav/I0hZtQsKZ3
	QTvpStf2MwIy8Ymj94+BsZaktP0d36wigGn8RWJHrhSVyjujS8YxWRWdjrLUI1ra
	42pyIYZi39IXtsTM71rihQVrsEHbMQ7a5HGRK6eYyHVPrtsXXykNqhVPekLNiFWm
	IekoSH1EwMsQv8y+k3nkCwTCkTHJaueB7awee0Zs5QBwbCm+qPyqCXoVDLEwdQOr
	CHKAfNADtsFQsk/yiTC/+Lmtur/okp38VpJWXg8DphHFjd1KwqQ5E9qZi+tXs/JD
	UXd93VBUdoGGaHK9fj/URxUBOVopGaOXGVYtGFWPn9q8MaNcrESZ48sXDfsVgUVD
	RJ4puKLHjIUtDlCnMQO6lekIhEo4sxtbDnwIUmQp7B9l+U99u+uzBI96cQARAQAB
	zShMYXVuY2hwYWQgUFBBIGZvciBVYnVudHUgR2l0IE1haW50YWluZXJzwsGOBBMB
	CgA4FiEE+RGrGEMXYwxZlwlz42PJD48bYhcFAmYo2OYCGwMFCwkIBwIGFQoJCAsC
	BBYCAwECHgECF4AACgkQ42PJD48bYhdwUQ//UFR3i/6zpizJMTA9mpz7hGC9IJV8
	UDoWoaVgl+OR1Ldfz+jvr3K55LZyIMU1o6bbLqbEnoWa2VpRv2za/SCbPqo1igio
	p97EJ2irGytFOhCDd+o3s0djfsXpA7jygAK6COnMx3ejnPhaBA194HbYDhp7KA5b
	gZcqvYeRN1qk9QL99voFYeUWAPnqkLLrNuAcq9qTotmyYZQI61rdAH8P4odgMtU7
	UiS4yLirkAiNCqT+TK07EXvaWSXcqZhgt1HmP+BZhrx/vLT4FlH52CCjamQWeFA2
	mLKX/RSx/JTux1UDroX6L9JdUyMzOrLk22Zz9Tb3FK2ysHy72jRKmUv87ctIMcgD
	u8BY3Mfe/Rw8vPMuBEaAsVfvWl7uYSt81dzjkxtt6ZvIFF5PBR2IhFJVosDbpSnk
	g9/b22Ipjta3ULW8oOaNZjdcRNQ5StpApzZIUoZoP83ZWafwQoSrW7Rz3KvwYAdL
	d3OAfuiW9i7YdLCkvaujBt6KA4tn56fcsp14FzLZrgcj+7XUpW4/yEJFHCCu5f2l
	NWvN37suUTfzbMLZVS6rC1s3qrjOD+C3dvL/dCUlcTfrrsTcs/UnaVXFq0V6NLhA
	ZZxOIVUedn7nGKbaecwTt6taIjpxj0jCBxWy6RcysIkv2xluRcl2UY+HapB8x1Dx
	8giHUSvkXHr4c7I=
	=uGON
	-----END PGP PUBLIC KEY BLOCK-----
EOF

SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
WORKDIR /tmp

COPY ./scripts /imagegeneration/installers
RUN bash /imagegeneration/installers/${BUILD_TYPE}.sh

USER ${BUILD_RUNNER_USER}
