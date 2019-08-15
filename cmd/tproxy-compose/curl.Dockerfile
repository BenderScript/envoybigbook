FROM envoyproxy/envoy:v1.11.0

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && \
    apt-get -qq install  \
                apt-utils \
                iputils-ping \
                curl \
                < /dev/null > /dev/null

ENTRYPOINT ["/bin/bash"]
