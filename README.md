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

或者自定义项目框架
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
                get: "/v1/$project/user/{id}~~/{count}~~",
                body: "*"
        };
    }
}

message RequestFromFrontService {
  int64 id = 1;
  ~~int64 count = 2;~~
}

message ReplyToFrontService {
  repeated Message messages = 1;
}

message Message {
  string content = 1;
}

```bash
#Phase#4 生成kratos代码框架
./framework_init.sh testsvcxxx
```
