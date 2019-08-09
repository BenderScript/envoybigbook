FROM envoyproxy/envoy:v1.11.0

EXPOSE 4999
EXPOSE 19000
EXPOSE 8443

RUN apt-get -qq -o=Dpkg::Use-Pty=0 update && apt-get -qq -o=Dpkg::Use-Pty=0 install iputils-ping
RUN apt-get -qq -o=Dpkg::Use-Pty=0 install curl

ADD ./service-envoy.yaml /etc/service-envoy.yaml
ADD ./start_envoy.sh /usr/local/bin/start_envoy.sh
RUN chmod u+x /usr/local/bin/start_envoy.sh
ENTRYPOINT /usr/local/bin/start_envoy.sh
