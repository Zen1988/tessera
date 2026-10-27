FROM ubuntu:26.04 AS dependencies
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PATH="/opt/venv/bin:$PATH"
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends python3 python3-venv ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m venv /opt/venv
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM dependencies AS verification
RUN pip install --no-cache-dir PyYAML==6.0.3
COPY monitor.py recovery.py longhorn_recovery.py redis_recovery.py redis-policy-ncs.json config.example.json k8s.yaml ./
COPY package.py Dockerfile .dockerignore ./
COPY tests ./tests
USER 65532:65532
RUN python -m unittest discover -s tests -v \
    && python monitor.py --config config.example.json --validate

FROM dependencies AS runtime
LABEL org.opencontainers.image.title="TESSERA Operator" \
      org.opencontainers.image.version="0.3.5" \
      org.opencontainers.image.description="Internal infrastructure monitoring with optional policy-bound recovery"
# Consuming the verified source forces the verification stage to complete.
COPY --from=verification /app/monitor.py .
COPY --from=verification /app/recovery.py .
COPY --from=verification /app/redis_recovery.py .
COPY --from=verification /app/longhorn_recovery.py .
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["python", "/app/monitor.py"]
