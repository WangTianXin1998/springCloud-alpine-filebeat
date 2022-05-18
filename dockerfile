FROM alpine:3.14.0

# 设置时区为上海
RUN apk add tzdata && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && apk update
RUN apk add --update-cache curl bash libc6-compat

RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk/jre
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

ENV JAVA_ALPINE_VERSION 8.302.08-r1

RUN set -x \
	&& apk add --no-cache \
		openjdk8-jre="$JAVA_ALPINE_VERSION" \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

WORKDIR /opt/filebeat
WORKDIR /opt/es-apm

COPY filebeat-7.3.2-linux-x86_64.tar.gz /opt
COPY apm-server-7.3.2-linux-x86_64.tar.gz /opt
COPY elastic-apm-agent-1.30.1.jar /opt


RUN cd /opt && \
    tar -xzf filebeat-7.3.2-linux-x86_64.tar.gz -C /opt/filebeat --strip-components=1 && \
    rm -f filebeat-7.3.2-linux-x86_64.tar.gz && \
    chmod +x /opt/filebeat

RUN cd /opt && \
    tar -xzf apm-server-7.3.2-linux-x86_64.tar.gz -C /opt/es-apm --strip-components=1 && \
    rm -f apm-server-7.3.2-linux-x86_64.tar.gz && \
    chmod +x /opt/es-apm

CMD ["/bin/sh"]