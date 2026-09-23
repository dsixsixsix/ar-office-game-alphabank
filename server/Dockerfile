# The plugin must be built by the pluginbuilder image of exactly the same version as the server.
ARG NAKAMA_VERSION=3.40.0

FROM heroiclabs/nakama-pluginbuilder:${NAKAMA_VERSION} AS builder
ENV GO111MODULE=on CGO_ENABLED=1
WORKDIR /backend
COPY modules/go.mod modules/go.sum ./
RUN go mod download
COPY modules/ ./
RUN go build --trimpath --buildmode=plugin -o ./backend.so

FROM heroiclabs/nakama:${NAKAMA_VERSION}
COPY --from=builder /backend/backend.so /nakama/data/modules/
COPY nakama/local.yml /nakama/data/
COPY content/ /nakama/data/content/
