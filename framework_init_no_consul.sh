#!/bin/bash

usage="Usage: ./kratos_init.sh project_name"

if [ $# -ne 1 ]; then
        echo $usage
else
project=$1

#echo "[`date +"%Y-%m-%d %H:%M:%S"`] Kratos create project $project"
#kratos new $project && cd $project

echo "[`date +"%Y-%m-%d %H:%M:%S"`] Kratos remove demo files"
rm -rf internal/service/greeter.go
rm -rf api/helloworld
rm -rf internal/biz/greeter.go
rm -rf internal/data/greeter.go

echo "[`date +"%Y-%m-%d %H:%M:%S"`] Kratos generate protobuf template"
kratos proto add api/$project/v1/$project.proto
cat << EOF > api/$project/v1/$project.proto
syntax = "proto3";

package api.$project.v1;
import "google/api/annotations.proto";

option go_package = "$project/api/$project/v1;v1";
option java_multiple_files = true;
option java_package = "api.$project.v1";

service ${project^} {
    rpc AckToClnt  (RequestFromClnt) returns (ReplyToClnt)  {
        option (google.api.http) = {
                post: "/api/v1/$project",
                body: "*"
        };
    }
}

message RequestFromClnt {
    string mykey = 1; 
    int64 myvalue_i = 2;
    double myvalue_f = 3;
}

message ReplyToClnt {
  repeated Message messages = 1;
}

message Message {
  string content = 1;
}
EOF
#cat api/$project/v1/$project.proto


echo "[`date +"%Y-%m-%d %H:%M:%S"`] Kratos generate server template"
kratos proto server api/$project/v1/$project.proto -t internal/service

wireNewSet="New${project^}Service"
echo "[`date +"%Y-%m-%d %H:%M:%S"`] Reconfig 'wire' ProviderSet to $wireNewSet"
sed -i "s/NewGreeterService/$wireNewSet/" internal/service/service.go

echo "[`date +"%Y-%m-%d %H:%M:%S"`] http-server reconfig"
sed -i "s/helloworld/$project/" internal/server/http.go
sed -i "s/Greeter/${project^}/" internal/server/http.go

echo "[`date +"%Y-%m-%d %H:%M:%S"`] gRPC-server reconfig"
sed -i "s/helloworld/$project/" internal/server/grpc.go
sed -i "s/Greeter/${project^}/" internal/server/grpc.go

echo "[`date +"%Y-%m-%d %H:%M:%S"`] comment data&biz in wire.go"
sed -i "s/\"$project\/internal\/biz\"/\/\/\"$project\/internal\/biz\"/" cmd/$project/wire.go
sed -i "s/\"$project\/internal\/data\"/\/\/\"$project\/internal\/data\"/" cmd/$project/wire.go
sed -i 's/data.ProviderSet, biz.ProviderSet,/\/*data.ProviderSet, biz.ProviderSet,*\//' cmd/$project/wire.go

echo "[`date +"%Y-%m-%d %H:%M:%S"`] 'wire' inject dependency modules"
sed -i "s/greeter/$project/" cmd/$project/wire_gen.go
sed -i "s/Greeter/${project^}/" cmd/$project/wire_gen.go
cd cmd/$project/
wire
cd ../..

#############################################################################################################################

cat << EOF > internal/server/jaeger_trace.go
package server

import (
    "fmt"
    "github.com/go-kratos/kratos/v2/config"

        "go.opentelemetry.io/otel"
        "go.opentelemetry.io/otel/attribute"
        "go.opentelemetry.io/otel/exporters/jaeger"
        "go.opentelemetry.io/otel/sdk/resource"
        tracesdk "go.opentelemetry.io/otel/sdk/trace"
        semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
)

var JaegerClient struct {
  Myjaeger struct {
    CollectorUrl  string \`json:"url"\`
    SampleRate  float64 \`json:"rate"\`
    ServiceName  string \`json:"service"\`
    AttrKey  string \`json:"attrkey"\`
    AttrVal string \`json:"attrval"\`
  } \`json:"myjaeger"\`
}

func MyJaegerClient(c config.Config) {
    if err := c.Scan(&JaegerClient); err != nil {
        panic(err)
    }
    fmt.Printf("%+v\n", JaegerClient)
}

// set trace provider
func setTracerProvider(url string, rate float64, service string, attrkey string, attrval string) error {
        // Create the Jaeger exporter
        exp, err := jaeger.New(jaeger.WithCollectorEndpoint(jaeger.WithEndpoint(url)))
        if err != nil {
                return err
        }
        tp := tracesdk.NewTracerProvider(
                // Set the sampling rate based on the parent span to 100%
                tracesdk.WithSampler(tracesdk.ParentBased(tracesdk.TraceIDRatioBased(rate))),
                // Always be sure to batch in production.
                tracesdk.WithBatcher(exp),
                // Record information about this application in an Resource.
                tracesdk.WithResource(resource.NewSchemaless(
                        semconv.ServiceNameKey.String(service),  // Service Tag
                        attribute.String(attrkey, attrval),
                )),
        )
        otel.SetTracerProvider(tp)
        return nil
}


func MyJaegerTraceProvider(c config.Config) {
        MyJaegerClient(c)
        err := setTracerProvider(JaegerClient.Myjaeger.CollectorUrl,
                                                        JaegerClient.Myjaeger.SampleRate,
                                                        JaegerClient.Myjaeger.ServiceName,
                                                        JaegerClient.Myjaeger.AttrKey,
                                                        JaegerClient.Myjaeger.AttrVal)
        if err != nil {
                //log.Error(err)
        }
}
EOF

sed -i 's/recovery.Recovery(),/ & \
                        middleware.Chain( \
                                tracing.Server(), \
                        ),\n /g' internal/server/grpc.go
sed -i 's/"github.com\/go-kratos\/kratos\/v2\/transport\/grpc"/ & \
        "github.com\/go-kratos\/kratos\/v2\/middleware" \
        "github.com\/go-kratos\/kratos\/v2\/middleware\/tracing" \n /g' internal/server/grpc.go

sed -i 's/recovery.Recovery(),/ & \
                        middleware.Chain( \
                                tracing.Server(), \
                        ),\n /g' internal/server/http.go
sed -i 's/"github.com\/go-kratos\/kratos\/v2\/transport\/http"/ & \
        "github.com\/go-kratos\/kratos\/v2\/middleware" \
        "github.com\/go-kratos\/kratos\/v2\/middleware\/tracing" \n /g' internal/server/http.go

################################################################################################################

fi
