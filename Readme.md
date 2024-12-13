# compatible-media-creator image

## Installation

1. Pull from [Docker Hub], download the package from [Releases] or build using `builder/build.sh`

## Usage

### Environment variables

-   `CRON_SCHEDULE`
    -   The time to run at as cron schedule, default `0 4 * * 6`.
-   `ENCODER_CPU`
    -   Set to `true` to enable cpu encoding.
-   `NICENESS_ADJUSTMENT`
    -   Set a custom niceness adjustment, default `19`.
-   `SCHED_POLICY`
    -   Set the specified scheduling policy, default `idle`.

### Volumes

-   `/media/compatible-media-creator/input`
    -   The original media library.
-   `/media/compatible-media-creator/output`
    -   The output folder for the compatibility files.
-   `/media/workdir`
    -   The directory which is used as temporary directory to process files.

## Development

To run for development execute:

```bash
docker compose --file docker-compose-dev.yaml up --build
```

[Docker Hub]: https://hub.docker.com/r/madebytimo/compatible-media-creator
[Releases]: https://github.com/mbt-infrastructure/docker-compatible-media-creator/releases
