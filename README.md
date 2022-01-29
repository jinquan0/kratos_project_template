# kratos_project_template
创建项目模版,
脚本的参数必须使用 工程名称，大小写敏感
```bash
#Phase#1 创建项目workspace
kratos new testsvcxxx && cd testsvcxxx

#Phase#2 初始化项目框架
---------------------------------------------------------------------------------------------------------------------------
curl -fsS https://raw.githubusercontent.com/jinquan0/kratos_project_template/main/kratos_init2.sh | bash -s testsvcxxx
bash <(curl -fsS https://raw.githubusercontent.com/jinquan0/kratos_project_template/main/main_init.sh) testsvcxxx
---------------------------------------------------------------------------------------------------------------------------
```

# 或者自定义项目框架
```bash
#Phase#1 创建项目workspace
kratos new testsvcxxx && cd testsvcxxx

#Phase#2 自定义项目框架
wget -O framework_init.sh https://raw.githubusercontent.com/jinquan0/kratos_project_template/main/framework_init.sh && chmod 755 framework_init.sh

#Phase#3 根据实际需求调整protobuf
vi framework_init.sh
```

syntax = "proto3";

package api.$project.v1;
import "google/api/annotations.proto";

option go_package = "$project/api/$project/v1;v1";
option java_multiple_files = true;
option java_package = "api.$project.v1";

service ${project^} {
    rpc ~~AckToFrontService~~ AckToClnt (~~RequestFromFrontService~~ RequestFromClnt) returns (~~ReplyToFrontService~~ ReplyToClnt)  {
       
       option (google.api.http) = {
                
		get: "/v1/$project/kv/{mykey}/{myvalue}",
		
		post: "/v1/$project/post_kv",
                
		body: "*"
        };
	
    }
}

message ~~RequestFromFrontService~~ RequestFromClnt {
  string mykey = 1;
  int64 myvalue  = 2;
}

message ~~ReplyToFrontService~~ ReplyToClnt {
  repeated Message messages = 1;
}

message Message {
  string content = 1;
}


```bash
#Phase#4 生成kratos代码框架
./framework_init.sh testsvcxxx
```
# 调整业务逻辑
```bash
vi internal/service/testsvcxxx.go
```
```golang
package service

import (
	"context"

	pb "demo0/api/demo0/v1"
)

type Demo0Service struct {
	pb.UnimplementedDemo0Server
}

func NewDemo0Service() *Demo0Service {
	return &Demo0Service{}
}

func (s *Demo0Service) AckToClnt(ctx context.Context, req *pb.RequestFromClnt) (*pb.ReplyToClnt, error) {
	//return &pb.ReplyToClnt{}, nil

	map_req:=ParseRequestArgsToMap(req.String())

	res := &pb.ReplyToClnt{}
	//for _, v := range BackendServiceReply.Messages {
		res.Messages = append(res.Messages, &pb.Message{Content: "Hello "+map_req["mykey"]+", you are "+map_req["myvalue"]})
	//}
	return res, nil
}

```
# 构建工程
```bash
# 生成api
make api
# 安装依赖package
go mod tidy
# 编译目标
make build

[root@infrago fusetest]# ls -la bin
total 18656
drwxr-xr-x 2 root root       22 Jan 29 15:29 .
drwxr-xr-x 8 root root      265 Jan 29 15:27 ..
-rwxr-xr-x 1 root root 19101612 Jan 29 15:29 fusetest
```

# http通过Nginx Proxy发布
```bash
curl -XPOST -H "Content-Type:application/json" -d '{"mykey": "jinquan", "myvalue": 18}' -k https://fuse-test.supor.com/v1/demo0/post_kv
```
