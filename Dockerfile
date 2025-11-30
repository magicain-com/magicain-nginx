FROM m.daocloud.io/docker.io/nginx:latest

COPY config/nginx/local.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]