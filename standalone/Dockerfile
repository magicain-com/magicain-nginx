FROM docker.xuanyuan.run/nginx:1.25-alpine

COPY conf/standalone.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]