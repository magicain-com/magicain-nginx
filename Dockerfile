FROM crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/nginx:1.28-alpine

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]