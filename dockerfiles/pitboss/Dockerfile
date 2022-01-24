FROM golang:1.12.9-alpine

# clone pitboss repo into this container and build binary with debugging information attached


WORKDIR /pitboss

RUN apk --update --no-cache add git

ENV GOPRIVATE "github.com/Arkadia-Tech"

ARG GITHUB_TOKEN=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

ARG REPO=Arkadia-Tech/pitboss

ARG USERNAME=AlexDespod

RUN git config --global url."https://$USERNAME:$GITHUB_TOKEN@github.com".insteadOf "https://github.com"

RUN git config --global credential.helper store

RUN echo "https://${GITHUB_TOKEN}:x-oauth-basic@github.com" >> ~/.git-credentials

RUN git clone -b dev https://$GITHUB_TOKEN:x-oauth-basic@github.com/$REPO.git .

RUN CGO_ENABLED=0 go build -gcflags "all=-N -l" -o /bin/pitboss ./internal/main/main.go

RUN go get -v github.com/go-delve/delve

RUN chmod +x /bin/pitboss

ENTRYPOINT ["/bin/pitboss"]
