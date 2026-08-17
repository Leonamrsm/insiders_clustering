FROM metabase/metabase:latest

# Limites rígidos de Heap, Metaspace e CodeCache para não estourar 512MB
ENV JAVA_OPTS="-Xmx240m -Xms128m -XX:+UseSerialGC -XX:MaxMetaspaceSize=160m -XX:ReservedCodeCacheSize=48m -XX:+ExitOnOutOfMemoryError"
ENV MB_JETTY_PORT=10000
ENV PORT=10000

# Desativa telemetria e checagem de atualizações para economizar Threads e RAM
ENV MB_ANONYMOUS_TRACKING_ENABLED=false
ENV MB_CHECK_FOR_UPDATES=false

ENV MB_DB_TYPE=h2
ENV MB_DB_FILE=/app/metabase.db

WORKDIR /app

COPY data/processed/insiders_db.sqlite /app/data.db
COPY metabase.db.mv.db /app/metabase.db.mv.db

EXPOSE 10000