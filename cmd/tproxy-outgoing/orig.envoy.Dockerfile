FROM ubuntu-base

EXPOSE 4999
EXPOSE 19000
EXPOSE 8443

ENV DEBIAN_FRONTEND noninteractive

ADD ./service-envoy.yaml /etc/service-envoy.yaml
ADD ./start_envoy.sh /usr/local/bin/start_envoy.sh
WORKDIR /usr/local/bin
RUN chmod u+x start_envoy.sh
ENTRYPOINT ./start_envoy.sh
