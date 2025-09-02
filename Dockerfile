FROM m.daocloud.io/docker.io/nginx:latest

COPY conf/local.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]