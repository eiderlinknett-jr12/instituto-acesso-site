FROM nginx:stable-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
EXPOSE 8080
