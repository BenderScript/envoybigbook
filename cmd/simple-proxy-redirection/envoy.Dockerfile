FROM envoyproxy/envoy:v1.11.0

EXPOSE 4999
EXPOSE 1900

RUN apt-get update
RUN apt-get install -y iputils-ping
RUN apt-get install -y curl0

ADD ./service-envoy.yaml /etc/service-envoy.yaml
ADD ./start_envoy.sh /usr/local/bin/start_envoy.sh
RUN chmod u+x /usr/local/bin/start_envoy.sh
ENTRYPOINT /usr/local/bin/start_envoy.sh


