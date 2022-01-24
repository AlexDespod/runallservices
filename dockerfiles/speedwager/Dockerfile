##############################################################################
# Base for local development                                                 #
# (this target is intended for generating a base layer for the next targets) #
##############################################################################
FROM golang:1.15.7-alpine as env

WORKDIR /src



RUN apk --update --no-cache add unzip git wget make

ARG GITHUB_TOKEN=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
ARG REPO=Arkadia-Tech/speedwager

RUN git config --global credential.helper store
RUN echo "https://${GITHUB_TOKEN}:x-oauth-basic@github.com" >> ~/.git-credentials

RUN git clone -b dev https://$GITHUB_TOKEN:x-oauth-basic@github.com/$REPO.git .

# install glibc && protoc
ENV GLIBC_VERSION=2.32-r0
RUN wget -q https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -O /etc/apk/keys/sgerrand.rsa.pub \
    && wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk -O glibc.apk \
    && apk add glibc.apk \
    && rm /etc/apk/keys/sgerrand.rsa.pub glibc.apk

ENV PROTOC_VERSION=3.11.2
RUN wget -q https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -O protoc.zip \
    && unzip protoc.zip -d /usr/local \
    && rm protoc.zip \
    && chmod +x /usr/local/bin/protoc

# install go dependencies
RUN go get -v google.golang.org/grpc
RUN go get -v github.com/golang/protobuf/protoc-gen-go
RUN go get -v google.golang.org/grpc/cmd/protoc-gen-go-grpc




##########################################################
# Setup a build container with all dependencies          #
# Compile everything and generate runnable binaries      #
##########################################################
FROM env as build

WORKDIR /src

# generate go code from protos
RUN make gen-protos

# build app binary
RUN make build-binary

##############################################################
# Create clean container with binary only                    #
# (this target is intended for generating DEV image)         #
##############################################################
FROM golang:alpine as dev


RUN apk --update --no-cache add git build-base gcc 

ARG GITHUB_TOKEN=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
RUN git config --global credential.helper store
RUN echo "https://${GITHUB_TOKEN}:x-oauth-basic@github.com" >> ~/.git-credentials

RUN go get -v github.com/go-delve/delve

WORKDIR /app
COPY --from=build /src/bin/speed-wager-dev ./speed-wager

EXPOSE 50051
ENTRYPOINT ["/app/speed-wager"]

##############################################################
# Create clean container with binary only                    #
# (this target is intended for generating PRODUCTION image)  #
##############################################################
FROM scratch as release

WORKDIR /app
COPY --from=build /src/bin/speed-wager-release ./speed-wager

EXPOSE 50051
ENTRYPOINT ["/app/speed-wager"]