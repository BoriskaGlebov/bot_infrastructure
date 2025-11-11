FROM redis:latest

RUN apt-get update && apt-get install -y gettext-base && rm -rf /var/lib/apt/lists/*

COPY redis.conf /usr/local/etc/redis/redis.conf

ENTRYPOINT ["/bin/sh", "-c", "envsubst < /usr/local/etc/redis/redis.conf > /tmp/redis.conf && exec redis-server /tmp/redis.conf"]