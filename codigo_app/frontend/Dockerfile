FROM nginx:alpine

# Copiar el archivo HTML estático
COPY index.html /usr/share/nginx/html/index.html

# Configurar Nginx para escuchar en el puerto 8080 y permitir ejecución sin privilegios
RUN sed -i -E 's/listen(\s+)80;/listen\18080;/g; s/listen(\s+)\[::\]:80;/listen\1[::]:8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i -E 's|/(var/)?run/nginx\.pid|/tmp/nginx.pid|g' /etc/nginx/nginx.conf && \
    touch /tmp/nginx.pid && \
    chown -R nginx:nginx /tmp/nginx.pid /var/cache/nginx /var/log/nginx /usr/share/nginx/html
    
RUN apk update && apk upgrade --no-cache

# Ejecutar como usuario no privilegiado
USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
