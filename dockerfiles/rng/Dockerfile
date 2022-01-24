FROM ubuntu:20.10

WORKDIR /rng

# RUN apt update && apt install -y curl tzdata && rm -rf /var/lib/apt/lists/*
RUN cp  /etc/apt/sources.list /etc/apt/sources.list.bak

RUN sed -i -re 's/([a-z]{2}\.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list

RUN apt update --fix-missing

RUN apt -y install git make golang-go --fix-missing

RUN adduser --disabled-password rgs-core

ENV GOPRIVATE "github.com/Arkadia-Tech"

ARG GITHUB_TOKEN=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

ARG REPO=Arkadia-Tech/rng

ARG USERNAME=AlexDespod

RUN git config --global url."https://$USERNAME:$GITHUB_TOKEN@github.com".insteadOf "https://github.com"

RUN git config --global credential.helper store

RUN echo "https://${GITHUB_TOKEN}:x-oauth-basic@github.com" >> ~/.git-credentials

RUN git clone -b dev https://$GITHUB_TOKEN:x-oauth-basic@github.com/$REPO.git .

RUN make rngplugin

RUN chmod 777 ./dist/rng-grpc
RUN date > /version

EXPOSE ${PORT}

USER rgs-core
CMD ["./dist/rng-grpc"]
