# Envoy Proxy Big Book of Examples

I had a dream! I tried to understand Kubernetes/Istio's data plane in detail...unsuccessfully. Every time I would ask a deeper question the answer would inevitably be "oh, this is done by Envoy and IPTables, but I do not know what goes under the hood". 

Therefore it became clear that understanding Envoy and the IPTables associated with each scenario was key to understanding data plane and provisioning in Kubernetes. During this journey it dawned on me how amazing is Envoy Proxy.

I decide to compile each example as best as I could to help others going through the same pains since documentation is at times fragmented and incomplete. 

Please be aware that all these examples were tested on **AWS Ubuntu 18.04**

## Envoy Resources

Started a new document on Envoy Resources such as [videos](resources.md)

## 1. Examples:

### 1.1 [Forward Proxy](./forward-proxy)

In this example of we run a [Forward Envoy Proxy](https://www.envoyproxy.io/docs/envoy/v1.13.0/configuration/http/http_filters/dynamic_forward_proxy_filter) that listens on port 4999 and directs requests to their original destination. 

The practical use-case is to confine applications running on the same host as the envoy proxy by using a combination of forward proxy and IPTables rules.

### 1.2 [Explicit Proxy Config](./explicit-proxy-config)

This example uses the same container as the Envoy Forward Proxy example but instead of using IPTables to redirect packets, we explicitly set HTTP Proxy environment variables.

### 1.3 [Original Destination](./original-dst)

This tutorial is one of the most interesting to me because it lays the ground work to understand workload identification and policy by creating an administrative boundary around an application

This tutorial shows how to use a [original destination cluster](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#arch-overview-service-discovery-types-original-destination) to run Envoy Proxy as a forward proxy. There is no need to explicitly configure cluster IP addresses and ports since Envoy will proxy connections to the original destination IP:port  


### 1.4 [Transparent Proxy (TPROXY)](./tproxy-outgoing)

Certainly the more challenging example but one that does not require changes to client applications. 

This tutorial shows how to use Envoy in [Transparent Proxy](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/lds.proto#envoy-api-field-listener-transparent) mode. The distinguishing feature in this scenario is that **there is no NAT**.

Transparent Proxy or TPROXY is a Linux Kernel feature without a lot of documentation. The common referenced documentation is the [original feature write-up](https://www.kernel.org/doc/Documentation/networking/tproxy.txt)

### 1.5 [Simple Front Proxy](./simple-front-proxy)

In this example of we run a Envoy Proxy on that listens on port 4999 and directs to a server running on port 5000.
 
 The web server runs as a separate container from Envoy so any web server will do as long as it is listening on port 5000. 

### 1.6 [External Authorization](./ext-authz-proxy)
 
 This example shows Envoy proxy using an external authorization server to decide whether requests should be forwarded. This has quite a few practical applications such as:
 
 * Client Identity (JWT)
 * Workload Identity
 * Policy Enforcement
 * In-depth statistics

This is example is based on the [rate limit example](https://github.com/jbarratt/envoy_ratelimit_example) 


### 1.7 [Custom HTTP Headers](./custom-headers)
 
 This example shows Envoy proxy adding custom HTTP headers to a request. I wanted to understand how to add more than one header and also append to an existing header. It turns out Envoy appends by adding a copy of the header with a different value.
 
 My goal is to use this setup in the external authz with workload identity.
 
### 1.8 [Workload-Identity](./workload-identity)

This example demonstrates how to use Envoy Proxy and Authz server to create a soft boundary around an **existing** application in order to create or provide **workload identity**. The operative word here is **existing**. There are many practical applications such as:

* Policy
* Telemetry
* Audit
* Security

### 1.9 [Workload-Identity-AWS](./workload-identity-aws)

This example demonstrates how to use Envoy Proxy and Authz server to create a soft boundary around an application in order to create or provide **workload identity** within an AWS EC2 deployment.

More specifically, it integrates AWS EC2 instance and user metadata into the application identity. It seems clear to me that any serious workload identity solution needs to incorporate a cloud provider's information in order to be deployed seamlessly and provide useful information.

### 1.10 [Transparent Proxy (TPROXY) AWS Identity](./tproxy-aws-identity)

WIP

### 1.11 [TCP-Proxy](./tcp-proxy)

This example demonstrates just a plain TCP Proxy. Interestingly I could not find official documentation on how to configure it, but managed to dig an example from a github issue.

Even more interesting is that a simple TCP Proxy can be used for HTTP traffic if there is no interest in HTTP specific functionality. Based on the logs we can see the amount of processing is much lower and therefore performance should be much higher.