# Docker images

[![Scheduled build (Ubuntu)](https://github.com/actions-oss/docker-images/actions/workflows/build-ubuntu.yml/badge.svg?event=schedule)][build-ubuntu]
[![On-demand build (Ubuntu)](https://github.com/actions-oss/docker-images/actions/workflows/build-ubuntu.yml/badge.svg?event=workflow_dispatch)](https://github.com/actions-oss/docker-images/actions/workflows/build-ubuntu.yml)

## Images available

- [ChristopherHX/runner-image-blobs](https://github.com/ChristopherHX/runner-image-blobs) GitHub Actions Hosted runner image copy containing almost all possible tools (image is extremely big, 20GB compressed, ~60GB extracted)
  - A tar backup of the GitHub Hosted Runners are uploaded once a week via a custom docker image upload script in runner-image-blobs repository
  - Synced by cron job `.github/workflows/copy-full-image.yml` to the following tags
  - You can verify if the Image is still updated regulary by inspecting the dates in `docker buildx imagetools inspect actions-oss/ubuntu:full-latest --format "{{ json . }}"`
    - The friendly tag name version in the output can be looked up here <https://github.com/actions/runner-images/releases> to find out more about the sources
  - available tags are
    - `ghcr.io/actions-oss/ubuntu:full-latest` (aka `full-22.04`)
    - `ghcr.io/actions-oss/ubuntu:full-24.04` (beta image)
    - `ghcr.io/actions-oss/ubuntu:full-22.04`
    - `ghcr.io/actions-oss/ubuntu:full-20.04` (Updated as long ubuntu-20.04 free public GitHub Hosted Runners are available)

- [`/ubuntu/act`](./ubuntu/scripts/act.sh) - image used in [github.com/nektos/act][nektos/act] as medium size image retaining compatibility with most actions while maintaining small size
  - `ghcr.io/actions-oss/ubuntu:act-20.04`
  - `ghcr.io/actions-oss/ubuntu:act-22.04`
  - `ghcr.io/actions-oss/ubuntu:act-latest`
- [`/ubuntu/runner`](./ubuntu/scripts/runner.sh) - `ghcr.io/actions-oss/ubuntu:act-*` but with `runner` as user instead of `root`
  - `ghcr.io/actions-oss/ubuntu:runner-20.04`
  - `ghcr.io/actions-oss/ubuntu:runner-22.04`
  - `ghcr.io/actions-oss/ubuntu:runner-latest`
- [`/ubuntu/js`](./ubuntu/scripts/js.sh) - `ghcr.io/actions-oss/ubuntu:act-*` but with `js` tools installed (`yarn`, `nvm`, `node` v16/v18, `pnpm`, `grunt`, etc.)
  - `ghcr.io/actions-oss/ubuntu:js-20.04`
  - `ghcr.io/actions-oss/ubuntu:js-22.04`
  - `ghcr.io/actions-oss/ubuntu:js-latest`
- [`/ubuntu/rust`](./ubuntu/scripts/rust.sh) - `ghcr.io/actions-oss/ubuntu:act-*` but with `rust` tools installed (`rustfmt`, `clippy`, `cbindgen`, etc.)
  - `ghcr.io/actions-oss/ubuntu:rust-20.04`
  - `ghcr.io/actions-oss/ubuntu:rust-22.04`
  - `ghcr.io/actions-oss/ubuntu:rust-latest`
- [`/ubuntu/pwsh`](./ubuntu/scripts/pwsh.sh) - `ghcr.io/actions-oss/ubuntu:act-*` but with `pwsh` tools and modules installed
  - `ghcr.io/actions-oss/ubuntu:pwsh-20.04`
  - `ghcr.io/actions-oss/ubuntu:pwsh-22.04`
  - `ghcr.io/actions-oss/ubuntu:pwsh-latest`

## Licence

### Repository contains parts of [`actions/virtual-environments`][actions/virtual-environments] which is licenced under ["MIT License"](https://github.com/actions/virtual-environments/blob/main/LICENSE)

[nektos/act]: https://github.com/nektos/act
[actions/virtual-environments]: https://github.com/actions/virtual-environments
[build-ubuntu]: https://github.com/actions-oss/docker-images/actions/workflows/build-ubuntu.yml
