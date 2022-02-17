# kratos_project_template
创建项目模版,
脚本的参数必须使用 工程名称：
	
	大小写敏感 ；
	
	不能使用下划线_、短横线- ； 
	
	首字符必须小写字母； 
	
	首字符不能使用数字
	
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
```protobuf
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
		// 或者使用GET方法
		get: "/api/v1/$project/{mykey}/{myvalue_i}/{myvalue_f}",
                body: "*"
        };
    }
}

message RequestFromClnt {
    string mykey = 1; 
    int64 myvalue_i = 2;
    double myvalue_f = 3;  // protobuf中使用 double 表示float64
}

message ReplyToClnt {
  repeated Message messages = 1;
}

message Message {
  string content = 1;
}
```

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

	pb "demo2/api/demo2/v1"
	"fmt"
)

type Demo2Service struct {
	pb.UnimplementedDemo2Server
}

func NewDemo2Service() *Demo2Service {
	return &Demo2Service{}
}

func (s *Demo2Service) AckToClnt(ctx context.Context, req *pb.RequestFromClnt) (*pb.ReplyToClnt, error) {
	//return &pb.ReplyToClnt{}, nil

	map_req:=ParseRequestArgsToMap(req.String())

	S,S_str := ArgsAutoType(map_req["mykey"])
	i,i_str := ArgsAutoType(map_req["myvalue_i"])
	f,f_str := ArgsAutoType(map_req["myvalue_f"])
	
	if S != nil {
		fmt.Printf("mykey: %s\n", S.(string))		//string 类型断言
	}
	if i != nil {
		fmt.Printf("myvalue_i: %d\n", i.(int64))	//int64 类型断言
	}
	if f != nil {
		fmt.Printf("myvalue_f: %f\n", f.(float64))	//float64 类型断言
	}

	res := &pb.ReplyToClnt{}
	//for _, v := range BackendServiceReply.Messages {
		res.Messages = append(res.Messages, &pb.Message{Content: "Hello "+ S_str +", you have "+i_str+" real numbers: "+f_str})
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
curl -XPOST -H "Content-Type:application/json" -d '{"mykey":"jinquan", "myvalue_i":100, "myvalue_f":3.1415}' -k https://fuse-test.supor.com/api/v1/mytest0
```
