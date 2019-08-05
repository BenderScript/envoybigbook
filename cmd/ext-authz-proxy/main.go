package main

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"log"
	"net"
	"strings"

	"github.com/envoyproxy/go-control-plane/envoy/api/v2/core"
	auth "github.com/envoyproxy/go-control-plane/envoy/service/auth/v2"
	envoytype "github.com/envoyproxy/go-control-plane/envoy/type"
	"github.com/golang/protobuf/jsonpb"
	"google.golang.org/grpc"
	rpc "istio.io/gogo-genproto/googleapis/google/rpc"
)

// empty struct because this isn't a fancy example
type AuthorizationServer struct{}

// inject a header that can be used for future rate limiting
func (a *AuthorizationServer) Check(ctx context.Context, req *auth.CheckRequest) (*auth.CheckResponse, error) {

	authHeader, ok := req.Attributes.Request.Http.Headers["authorization"]
	httpRequest := req.Attributes.Request.Http
	marshaler := jsonpb.Marshaler{}
	jsonString, _ := marshaler.MarshalToString(httpRequest)
	println(jsonString)

	var splitToken []string
	if ok {
		splitToken = strings.Split(authHeader, "Bearer ")
	}
	if len(splitToken) == 2 {
		token := splitToken[1]
		sha := sha256.New()
		sha.Write([]byte(token))
		tokenSha := base64.StdEncoding.EncodeToString(sha.Sum(nil))

		// valid tokens have exactly 3 characters. #secure.
		// Normally this is where you'd go check with the system that knows if it's a valid token.

		if len(token) == 3 {
			return &auth.CheckResponse{
				Status: &rpc.Status{
					Code: int32(rpc.OK),
				},
				HttpResponse: &auth.CheckResponse_OkResponse{
					OkResponse: &auth.OkHttpResponse{
						Headers: []*core.HeaderValueOption{
							{
								Header: &core.HeaderValue{
									Key:   "x-ext-auth-ratelimit",
									Value: tokenSha,
								},
							},
						},
					},
				},
			}, nil
		}
	}
	return &auth.CheckResponse{
		Status: &rpc.Status{
			Code: int32(rpc.UNAUTHENTICATED),
		},
		HttpResponse: &auth.CheckResponse_DeniedResponse{
			DeniedResponse: &auth.DeniedHttpResponse{
				Status: &envoytype.HttpStatus{
					Code: envoytype.StatusCode_Unauthorized,
				},
				Body: "Need an Authorization Header with a 3 character bearer token! #secure",
			},
		},
	}, nil
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
