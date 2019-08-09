FROM envoyproxy/envoy:v1.11.0

EXPOSE 4999
EXPOSE 19000
EXPOSE 8443

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && \
    apt-get -qq install  \
                apt-utils \
                iputils-ping \
                curl \
                < /dev/null > /dev/null

ADD ./service-envoy.yaml /etc/service-envoy.yaml
ADD ./start_envoy.sh /usr/local/bin/start_envoy.sh
RUN chmod u+x /usr/local/bin/start_envoy.sh
ENTRYPOINT /usr/local/bin/start_envoy.sh
