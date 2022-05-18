# springCloud-alpine-filebeat
一个基于alpine的基础镜像，基础镜像包含：

1. jdk1.8

2. alpine3.14.0

3. ElasticSearch Filebeat

4. ElasticSearch Apm

   

**其中ElasticSearch产品需要根据ElasticSearch具体版本使用，目前现有支持版本ElasticSearch v6.8.1、v7.3.1、v7.3.2**

使用配置文件示例 

```
FROM javab/alpine-filebeat-xxx
ENV APPLICATION_NAME <appname>.jar #你项目的jar包 需要以模块命名
ADD $APPLICATION_NAME /data/tsf/

ENV APP_LOG_PATH /opt/logs/faw
RUN mkdir -p $APP_LOG_PATH
COPY run.sh /data/project/

COPY ["filebeat-sit.yml","filebeat-uat.yml", "filebeat-prod.yml", "/opt/filebeat/"]

COPY ["apm-server-sit.yml", "apm-server-uat.yml", "apm-server-prod.yml", "/opt/es-apm/"]
EXPOSE 8080

WORKDIR /data/project
CMD ["sh", "-c", "cd /data/tsf; sh run.sh $APPLICATION_NAME /data/tsf"]

```


