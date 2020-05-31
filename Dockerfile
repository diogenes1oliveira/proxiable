FROM python:3.7
LABEL maintainer="diogenes1oliveira@gmail.com"

ARG BUILD_DATE
ARG BUILD_VERSION
ARG BOM_PATH="/docker/eni"

LABEL org.opencontainers.image.authors="diogenes1oliveira@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/diogenes1oliveira/proxiable"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.title="diogenes1oliveira/proxiable"
LABEL org.opencontainers.image.description="Nice and easy intercepting, filtering and transforming of HTTP(S) requests "
LABEL org.opencontainers.image.source="${BUILD_VERSION}"

WORKDIR /app

COPY ./requirements.txt ./
RUN pip install -r requirements.txt

COPY ./docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

COPY ./proxiable.py ./README.md ./LICENSE ./

ENV PROXIABLE_WEBUI_HOST="0.0.0.0"
ENV PROXIABLE_WEBUI_PORT="8001"
ENV PROXIABLE_PROXY_HOST="0.0.0.0"
ENV PROXIABLE_PROXY_PORT="8000"
ENV PROXIABLE_SCRIPTS_LOCATION="/var/proxiable/scripts/"
ENV PROXIABLE_SITES_LOCATION="/var/proxiable/sites/"
ENV PROXIABLE_INDEX_FILE="INDEX"

WORKDIR /root/.mitmproxy/
WORKDIR /var/proxiable/scripts/
WORKDIR /var/proxiable/sites/

CMD [ "mitmweb" ]

# Save Bill of Materials to image
COPY ./README.md ./CHANGELOG.md ./LICENSE ./Dockerfile "${BOM_PATH}"/
