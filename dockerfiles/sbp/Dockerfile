FROM golang:1.14-alpine

# clone pitboss repo into this container and build binary with debugging information attached
# ENV USERNAME "diogojsdias"
# ENV GITHUB_TOKEN "a2981114f2c951b6e2ff3a4ef9b57d41d928649c"
ENV REPO "Arkadia-Tech/skill-balance-pot"
# ENV GOPRIVATE "github.com/Arkadia-Tech"

WORKDIR /sbp

RUN apk --update --no-cache add git

ARG GITHUB_TOKEN=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
RUN git config --global credential.helper store
RUN echo "https://${GITHUB_TOKEN}:x-oauth-basic@github.com" >> ~/.git-credentials

RUN git clone -b dev https://$GITHUB_TOKEN:x-oauth-basic@github.com/$REPO.git .

RUN CGO_ENABLED=0 go build -gcflags "all=-N -l" -o /bin/sbp ./cmd/server/main.go

RUN go get -v github.com/go-delve/delve

RUN chmod +x /bin/sbp

ENTRYPOINT ["/bin/sbp"]