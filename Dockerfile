FROM madebytimo/cron

RUN install-autonomous.sh install Basics FFmpeg Scripts \
    && rm -rf /var/lib/apt/lists/*

COPY files/create-compatibility-version.sh files/entrypoint.sh files/run.sh /usr/local/bin/
RUN mv /entrypoint.sh /entrypoint-cron.sh

ENV CRON_SCHEDULE="0 4 * * 6"
ENV ENCODER_CPU="false"
ENV NICENESS_ADJUSTMENT="19"
ENV SCHED_POLICY="idle"

ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "sleep", "infinity" ]

LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source=\
"https://github.com/mbt-infrastructure/docker-compatible-media-creator"
