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

```
