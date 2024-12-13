# compatible-media-creator image

## Installation

1. Pull from [Docker Hub], download the package from [Releases] or build using `builder/build.sh`

## Usage

### Environment variables

- `CRON_SCHEDULE`
    - The time to run at as cron schedule, default `0 4 * * 6`.
- `ENCODER_CPU`
    - Set to `true` to enable cpu encoding.

### Volumes

-   `/media/compatible-media-creator/input`
    -   The original media library.
-   `/media/compatible-media-creator/output`
    -   The output folder for the compatibility files.
- `/media/workdir`
    - The directory which is used as temporary directory to process files.

## Development

To run for development execute:

```bash
docker compose --file docker-compose-dev.yaml up --build
```

[base image]: https://github.com/mbT-Infrastructure/docker-base
[Docker Hub]: https://hub.docker.com/r/madebytimo/media-compatibility-creator
[Releases]: https://github.com/madebytimo/docker-media-compatibility-creator/releases
