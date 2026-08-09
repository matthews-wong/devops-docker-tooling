# syntax=docker/dockerfile:1
FROM nginx:1.27-alpine

# nginx needs writable cache/pid dirs; runtime user comes from the base image.
# Remove the default config so the port + server block below are the only one.
RUN rm -f /etc/nginx/conf.d/default.conf && \
    chown -R nginx:nginx /var/cache/nginx /var/run

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY content/ /usr/share/nginx/html/

# Service runs as nginx, not root.
USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1