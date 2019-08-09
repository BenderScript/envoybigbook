FROM envoyproxy/envoy:v1.11.0

EXPOSE 4999
EXPOSE 19000
EXPOSE 8443

RUN apt-get -qq update -&& apt-get -qq install -iputils-ping
RUN apt-get -qq install curl

ADD ./service-envoy.yaml /etc/service-envoy.yaml
ADD ./start_envoy.sh /usr/local/bin/start_envoy.sh
RUN chmod u+x /usr/local/bin/start_envoy.sh
ENTRYPOINT /usr/local/bin/start_envoy.sh
