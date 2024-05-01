# 使用官方的 Caddy 镜像作为基础
FROM caddy:2-alpine AS caddy-base

FROM --platform=$BUILDPLATFORM alpine AS v2ray-downloader
ARG V2R_VERSION=v5.15.3
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# 根据目标平台设置 V2Ray 二进制文件的下载 URL
RUN case "${TARGETPLATFORM}" in \
    "linux/amd64") \
    V2R_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2R_VERSION}/v2ray-linux-64.zip" ;; \
    "linux/arm64") \
    V2R_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2R_VERSION}/v2ray-linux-arm64-v8a.zip" ;; \
    *) echo "Unsupported platform ${TARGETPLATFORM}"; exit 1 ;; \
    esac && \
    echo "Downloading V2Ray for ${TARGETPLATFORM} from ${V2R_URL}" && \
    apk add --no-cache curl unzip && \
    curl -L -H "Cache-Control: no-cache" -o /tmp/v2ray.zip ${V2R_URL} && \
    unzip /tmp/v2ray.zip -d /tmp/

# 最终镜像
FROM caddy-base

LABEL org.opencontainers.image.authors="root@gmail.com"

ARG DOMAIN
ARG EMAIL

ENV TZ=Asia/Shanghai \
    DOMAIN=${DOMAIN} \
    EMAIL=${EMAIL} \
    V2R_PATH_CONF=/etc/v2ray \
    CADDY_PATH_CONF=/etc/caddy

COPY --from=v2ray-downloader /tmp/v2ray /usr/bin/v2ray
COPY boot.sh /usr/bin
COPY conf/ /conf/
COPY html/ /var/www/v2ray/

RUN set -xe \
    && apk add --update --no-cache tzdata curl uuidgen openrc \
    && mkdir -p ${CADDY_PATH_CONF} ${V2R_PATH_CONF} \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && chmod +x /usr/bin/v2ray /usr/bin/boot.sh \
    && rm /etc/caddy/Caddyfile

EXPOSE 80 443

ENTRYPOINT ["/usr/bin/boot.sh"]
