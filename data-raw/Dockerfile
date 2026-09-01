FROM rocker/r-ver:4.6.1@sha256:a5df0ae591422cc1733e97da03a9f4eff4cf172e40895225959aa93bb7ff7517

# Published hashes are defined on the same architecture as GitHub's Ubuntu
# runner. Building without `--platform linux/amd64` must fail visibly.
RUN test "$(uname -m)" = "x86_64"

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

ENV PIPELINE_MODE=rebuild

CMD ["sh", "-c", "Rscript data-raw/restore_rebuild_inputs.R && Rscript data-raw/run_pipeline.R"]
