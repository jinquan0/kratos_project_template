# kratos_project_template
创建项目模版,
脚本的参数必须使用 工程名称，大小写敏感
```bash
Phase#1 创建项目workspace
kratos new testsvcxxx && cd testsvcxxx

Phase#2 初始化项目框架
---------------------------------------------------------------------------------------------------------------------------
curl -fsS https://raw.githubusercontent.com/jinquan0/kratos_project_template/main/kratos_init2.sh | bash -s testsvcxxx
bash <(curl -fsS https://raw.githubusercontent.com/jinquan0/kratos_project_template/main/main_init.sh) testsvcxxx
---------------------------------------------------------------------------------------------------------------------------
或者直接一步到位
bash <(curl -fsS https://raw.githubusercontent.com/jinquan0/kratos_project_template/main/framework_init.sh) testsvcxxx
```
