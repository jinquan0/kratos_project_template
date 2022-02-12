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

########################################## other ############################################################

sed -i "s/Name string/Name string = \"$project\"/" cmd/$project/main.go
sed -i "s/Version string/Version string = \"1.0-alpha\"/" cmd/$project/main.go

####################################################### My Own logic #############################################################
cat << EOF > internal/service/mylogic.go
package service

import(
    "fmt"
    "regexp"
    "strconv"
    "strings"
    "reflect"
    "github.com/go-kratos/kratos/v2/config"
    // Add MySQL package
    // Add Redis package
)

var DbEndpoint struct {
  Mysqlendpoint struct {
    Host  string \`json:"host"\`
    Port  string \`json:"port"\`
    User  string \`json:"user"\`
    Pass  string \`json:"pass"\`
    Sslca string \`json:"sslca"\`
  } \`json:"mysqlendpoint"\`
}

func MyDatabaseEndpoint(c config.Config) {
    if err := c.Scan(&DbEndpoint); err != nil {
        panic(err)
    }
    fmt.Printf("%+v\n", DbEndpoint)
}

func ParseRequestArgsToMap(req string) (map[string]string) {
	// ----------------------------------------------------------------
	r_kv_array, _ := regexp.Compile(\`([^:]+):([^:]+)(?: |$)\`)
	r_kv, _ := regexp.Compile(\`[^:]+\`)
	r_val,_ := regexp.Compile(\`"\s*(.*?)\s*"\`)
	// ----------------------------------------------------------------
	
	MKV := make(map[string]string, len(r_kv_array.FindAllString(req, -1)))

	for idx,kv:=range r_kv_array.FindAllString(req, -1) { // string array
		idx = idx // key-value pair index(integer)
		// fmt.Println(reflect.TypeOf(kv)) // 'string' type
		x:=r_kv.FindAllString(kv, -1) // [some_key "some_value"]
		matches := r_val.FindAllStringSubmatch(x[1], -1)  // ["some_value" some_value]
		if len(matches) > 0 {  // 0 or 1
	    	// fmt.Println(matches[0][1])
	      	MKV[x[0]] = matches[0][1]
	    } else{
	    	// fmt.Println(x[1])
	    	MKV[x[0]] = x[1]
	    }
	}
        return MKV
}

func ArgsAutoType(arg string) (interface{}, string) {

	arg_s := strings.TrimSpace(arg)  // 删除字符串首尾的空格

	r_float64, _ := regexp.Compile(\`^-?([1-9]\d*\.\d*|0\.\d*[1-9]\d*|0?\.0+|0)$\`)
	r_int64, _ := regexp.Compile(\`^-?[1-9]\d*$\`)

	f_match := r_float64.MatchString(arg_s)		// true or false
	i_match := r_int64.MatchString(arg_s)		// true or false

	var err error
	var x interface{}
	if f_match == true && i_match == false {
		x, err = strconv.ParseFloat(arg_s, 64)
	} else if f_match == false && i_match == true {
		x, err = strconv.ParseInt(arg_s, 10, 64)
	} else if f_match == false && i_match == false {
		x = arg_s
	}

	if err != nil {
		return nil,""
	} 
	return x, arg_s
}

func ArgsAutoPrint(argument interface{}) {
	// fmt.Println(reflect.TypeOf(argument))
	switch reflect.ValueOf(argument).Kind() {
	case reflect.Int64:
		fmt.Printf("%d\n", reflect.ValueOf(argument))
	case reflect.Float64:
		fmt.Printf("%f\n", reflect.ValueOf(argument))
	case reflect.String:
		fmt.Printf("%s\n", reflect.ValueOf(argument))
	}
}

EOF

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



################################################################################################################

fi
