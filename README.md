# springCloud-alpine-filebeat
一个基于alpine的基础镜像，基础镜像包含：

1. jdk1.8

2. alpine3.14.0

3. ElasticSearch Filebeat

4. ElasticSearch Apm

镜像地址：
1.javab/alpine-filebeat-6.8.1:1.0.4
2.javab/alpine-filebeat-7.3.2:latest
   

**其中ElasticSearch产品需要根据ElasticSearch具体版本使用，目前现有支持版本ElasticSearch v6.8.1、v7.3.1、v7.3.2**

使用配置文件示例 

Dockerfile

```
FROM javab/alpine-filebeat-xxx
ENV APPLICATION_NAME <appname>.jar #你项目的jar包 需要以模块命名
ADD $APPLICATION_NAME /data/tsf/

ENV APP_LOG_PATH /opt/logs
RUN mkdir -p $APP_LOG_PATH
COPY run.sh /data/project/

COPY ["filebeat-sit.yml","filebeat-uat.yml", "filebeat-prod.yml", "/opt/filebeat/"]

COPY ["apm-server-sit.yml", "apm-server-uat.yml", "apm-server-prod.yml", "/opt/es-apm/"]
EXPOSE 8080

WORKDIR /data/project
CMD ["sh", "-c", "cd /data/tsf; sh run.sh $APPLICATION_NAME /data/tsf"]

```

filebeat.yml

```sh
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /opt/logs/*.log
  json.keys_under_root: true
  json.overwrite_keys: true

filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.name: "你的服务名称"
setup.template.pattern: "你的服务名称*"
setup.template.fields: "fields.yml"
setup.template.overwrite: false
setup.template.settings:
  index.number_of_shards: 3
  index.number_of_replicas: 0

output.elasticsearch:
  hosts: ["你的es地址"]
  username: es账号
  password: es密码
  indices:
    - index: "你的服务名称-%{+yyyy.MM.dd}"

processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~

```

apm.yml

```sh
apm-server:
  host: "localhost:8200"
#-------------------------- Elasticsearch output ------------------------------
output.elasticsearch:
  hosts: ["你的es地址"]
  username: elastic
  password: Passw0rd
  indices:
    - index: "apm-%{[beat.version]}-sourcemap"
      when.contains:
        processor.event: "sourcemap"

    - index: "apm-%{[beat.version]}-error-%{+yyyy.MM.dd}"
      when.contains:
        processor.event: "error"

    - index: "apm-%{[beat.version]}-transaction-%{+yyyy.MM.dd}"
      when.contains:
        processor.event: "transaction"

    - index: "apm-%{[beat.version]}-span-%{+yyyy.MM.dd}"
      when.contains:
        processor.event: "span"

    - index: "apm-%{[beat.version]}-metric-%{+yyyy.MM.dd}"
      when.contains:
        processor.event: "metric"

    - index: "apm-%{[beat.version]}-onboarding-%{+yyyy.MM.dd}"
      when.contains:
        processor.event: "onboarding"

```

run.sh

```sh
echo "start java now ..."

echo "JAVA_OPTS=${JAVA_OPTS}"
TmpProf=`echo "${JAVA_OPTS}" | grep -Eoi "spring.profiles.active=sit|spring.profiles.active=uat|spring.profiles.active=prod"`
echo "TmpProf=[${Profile}]"
if [ -n "${TmpProf}" ];then
  SP=`echo ${TmpProf#*=}`
  echo "SP=[${SP}]"
  if [ "${SP}"x = "uat"x ];then
    echo "This is uat env"
    nohup /opt/filebeat/filebeat -e -c /opt/filebeat/filebeat-uat.yml > /opt/filebeat.log &
    nohup /opt/es-apm/apm-server -e -c /opt/es-apm/apm-server-uat.yml > /opt/apm-server.log &
  elif [ "${SP}"x = "prod"x ];then
    echo "This is prod env"
    nohup /opt/filebeat/filebeat -e -c /opt/filebeat/filebeat-prod.yml > /opt/filebeat.log &
    nohup /opt/es-apm/apm-server -e -c /opt/es-apm/apm-server-prod.yml > /opt/apm-server.log &
  elif [ "${SP}"x = "sit"x ];then
    echo "This is sit env"
    nohup /opt/filebeat/filebeat -e -c /opt/filebeat/filebeat-sit.yml > /opt/filebeat.log &
    nohup /opt/es-apm/apm-server -e -c /opt/es-apm/apm-server-sit.yml > /opt/apm-server.log &
  fi
fi



JAVA_AGENT="-javaagent:/opt/elastic-apm-agent-1.30.1.jar -Delastic.apm.service_name=$1 -Delastic.apm.server_url=http://127.0.0.1:8200 -Delastic.apm.secret_token= -Delastic.apm.application_packages=你服务的包名"

java $JAVA_AGENT -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap ${JAVA_OPTS} -jar $1 > $stout_log 2>&1

```



