#!/bin/bash

usage="Usage: ./kratos_init.sh project_name"

if [ $# -ne 1 ]; then
        echo $usage
else
project=$1

#echo "[`date +"%Y-%m-%d %H:%M:%S"`] Kratos create project $project"
#kratos new $project && cd $project

echo "[`date +"%Y-%m-%d %H:%M:%S"`] Kratos remove demo service"
rm -rf internal/service/greeter.go


echo "[`date +"%Y-%m-%d %H:%M:%S"`] Kratos generate user service template"
kratos proto add api/$project/v1/$project.proto
cat << EOF > api/$project/v1/$project.proto
syntax = "proto3";

package api.$project.v1;
import "google/api/annotations.proto";

option go_package = "$project/api/$project/v1;v1";
option java_multiple_files = true;
option java_package = "api.$project.v1";

service ${project^} {
  rpc ProcLogic (Request) returns (Reply)  {
        option (google.api.http) = {
                post: "/v1/$project",
                body: "*"
        };
    }
}

message Request {
  int32 userID = 1;
  string userName = 2;
}

message Reply {
  string message = 1;
}
EOF
cat api/$project/v1/$project.proto


echo "[`date +"%Y-%m-%d %H:%M:%S"`] Kratos generate user procedure-logic template"
kratos proto server api/$project/v1/$project.proto -t internal/service
cat << EOF > internal/service/$project.go
package service
 
import (
        "context"
        pb "$project/api/$project/v1"
        "$project/internal/biz"
        "github.com/go-kratos/kratos/v2/log"
)
 
type ${project^}Service struct {
        pb.Unimplemented${project^}Server
        uc  *biz.GreeterUsecase
        log *log.Helper
}
 
func New${project^}Service(uc *biz.GreeterUsecase, logger log.Logger) *${project^}Service {
        return &${project^}Service{uc: uc, log: log.NewHelper(logger)}
}
 
func (s *${project^}Service) ProcLogic(ctx context.Context, req *pb.Request) (*pb.Reply, error) {
        s.log.WithContext(ctx).Infof("Request: %v", req.String())
        return &pb.Reply{Message: "-> " + req.String()}, nil
}
EOF
cat internal/service/$project.go


wireNewSet="New${project^}Service"
echo "[`date +"%Y-%m-%d %H:%M:%S"`] Reconfig 'wire' ProviderSet to $wireNewSet"
sed -i "s/NewGreeterService/$wireNewSet/" internal/service/service.go

echo "[`date +"%Y-%m-%d %H:%M:%S"`] Template http-server reconfig"
sed -i "s/helloworld/$project/" internal/server/http.go
sed -i "s/Greeter/${project^}/" internal/server/http.go

echo "[`date +"%Y-%m-%d %H:%M:%S"`] Template gRPC-server reconfig"
sed -i "s/helloworld/$project/" internal/server/grpc.go
sed -i "s/Greeter/${project^}/" internal/server/grpc.go

echo "[`date +"%Y-%m-%d %H:%M:%S"`] 'wire' inject dependency modules"
sed -i "s/greeter/$project/" cmd/$project/wire_gen.go
sed -i "s/Greeter/${project^}/" cmd/$project/wire_gen.go
cd cmd/$project/
wire
cd ../..

fi
