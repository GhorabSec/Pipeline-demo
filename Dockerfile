# =============================================================================
# Stage 1: Build the frontend (Vite/React/Angular/whatever SPA)
# =============================================================================
FROM node:20-alpine AS builder

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

WORKDIR /app
RUN chown -R appuser:appgroup /app

COPY --chown=appuser:appgroup package*.json ./
RUN npm ci --prefer-offline --no-audit --fund=false

COPY --chown=appuser:appgroup . .
RUN npm run build && \
    chown -R appuser:appgroup /app/dist

USER appuser

# =============================================================================
# Stage 2: Production - nginx non-root
# =============================================================================

FROM nginx:1.29-alpine

# Remove default config & content
RUN rm -f /etc/nginx/conf.d/default.conf \
 && rm -rf /usr/share/nginx/html/*  \
 && sed -i 's|pid\s*.*;|pid /tmp/nginx.pid;|g' /etc/nginx/nginx.conf


# Create writable runtime directories + the temp subfolders nginx needs
RUN mkdir -p /var/cache/nginx \
    /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp \
 && mkdir -p /var/run /var/log/nginx \
 && chown -R nginx:nginx /var/cache/nginx /var/run /var/log/nginx \
 && chmod -R 755 /var/cache/nginx \
 && chmod -R 750 /var/run /var/log/nginx

# Copy build output
COPY --from=builder /app/dist /usr/share/nginx/html
RUN chown -R nginx:nginx /usr/share/nginx/html \
 && chmod -R 755 /usr/share/nginx/html

# Copy config
COPY nginx-hardened.conf /etc/nginx/conf.d/default.conf
RUN chmod 644 /etc/nginx/conf.d/default.conf

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
