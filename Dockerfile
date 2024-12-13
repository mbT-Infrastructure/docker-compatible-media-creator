FROM madebytimo/cron

RUN install-autonomous.sh install Basics FFmpeg Scripts \
    && rm -rf /var/lib/apt/lists/*

COPY files/create-compatibility-version.sh files/entrypoint.sh files/run.sh /usr/local/bin/
RUN mv /entrypoint.sh /entrypoint-cron.sh

ENV CRON_SCHEDULE="0 4 * * 6"

ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "run.sh" ]

LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source=\
"https://github.com/mbt-infrastructure/docker-compatible-media-creator"
