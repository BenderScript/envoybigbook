package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net"

	"github.com/envoyproxy/go-control-plane/envoy/api/v2/core"
	auth "github.com/envoyproxy/go-control-plane/envoy/service/auth/v2"
	"github.com/golang/protobuf/jsonpb"
	"google.golang.org/grpc"
	rpc "istio.io/gogo-genproto/googleapis/google/rpc"
)

// empty struct because this isn't a fancy example
type AuthorizationServer struct{}

// inject a header that can be used for future rate limiting
func (a *AuthorizationServer) Check(ctx context.Context, req *auth.CheckRequest) (*auth.CheckResponse, error) {

	httpRequest := req.Attributes.Request.Http
	socketAddress := req.Attributes.Source.Address.GetSocketAddress()
	fmt.Printf("Source IP:port %s:%d\n", socketAddress.GetAddress(), socketAddress.GetPortValue())

	process := findProcessSourcePort(socketAddress.GetPortValue())
	fmt.Printf("Process name: %s \n", process.Name)
	fmt.Printf("Process Exe: %s \n", process.Exe)
	fmt.Printf("Process User: %s \n", process.User)
	fmt.Printf("Process State: %s \n", process.State)
	marshaler := jsonpb.Marshaler{}
	jsonString, _ := marshaler.MarshalToString(httpRequest)
	var out bytes.Buffer
	err := json.Indent(&out, []byte(jsonString), "", "  ")
	if err == nil {
		println(out.String())

		return &auth.CheckResponse{
			Status: &rpc.Status{
				Code: int32(rpc.OK),
			},
			HttpResponse: &auth.CheckResponse_OkResponse{
				OkResponse: &auth.OkHttpResponse{
					// https://www.envoyproxy.io/docs/envoy/latest/api-v2/service/auth/v2/external_auth.proto#service-auth-v2-checkrequest
					Headers: []*core.HeaderValueOption{
						{
							Header: &core.HeaderValue{
								Key:   "x-workload-id",
								Value: process.Name,
							},
						},
						{
							Header: &core.HeaderValue{
								Key:   "x-workload-user",
								Value: process.User,
							},
						},
					},
				},
			},
		}, nil
	} else {
		println("Error encoding JSON: " + err.Error())
		return &auth.CheckResponse{
			Status: &rpc.Status{
				Code: int32(rpc.PERMISSION_DENIED),
			},
			HttpResponse: &auth.CheckResponse_DeniedResponse{},
		}, nil
	}
}

func main() {
	// create a TCP listener on port 5010
	lis, err := net.Listen("tcp", ":5010")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	log.Printf("listening on %s", lis.Addr())

	grpcServer := grpc.NewServer()
	authServer := &AuthorizationServer{}
	auth.RegisterAuthorizationServer(grpcServer, authServer)

	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
