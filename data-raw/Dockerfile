FROM rocker/r-ver:4.6.1@sha256:a5df0ae591422cc1733e97da03a9f4eff4cf172e40895225959aa93bb7ff7517

RUN apt-get update \
    && apt-get install -y --no-install-recommends libcurl4-openssl-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY data-raw/vendor/pak_0.11.1.tar.gz /tmp/pak_0.11.1.tar.gz
RUN echo "762ec8acc2d2ccbe5a217859c846c2de83254e3948112b437dde7a0ad5b15999  /tmp/pak_0.11.1.tar.gz" | sha256sum --check \
    && R CMD INSTALL /tmp/pak_0.11.1.tar.gz

COPY data-raw/pkg.lock /tmp/zipcodeR-pkg.lock
RUN Rscript -e 'pak::lockfile_install("/tmp/zipcodeR-pkg.lock")'

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work/zipcodeR
COPY . .

ENV PIPELINE_DATA_VERSION=2026.08
ENV PIPELINE_BUILD_TIMESTAMP=2026-08-24T00:00:00Z
ENV PIPELINE_BASELINE_REF=master
ENV PIPELINE_MODE=rebuild

CMD ["Rscript", "data-raw/run_pipeline.R"]
