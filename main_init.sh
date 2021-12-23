#!/bin/bash

usage="Usage: ./kratos_init.sh project_name"

if [ $# -ne 1 ]; then
        echo $usage
else
project=$1

sed -i '58s/^/\/\//' cmd/$project/main.go
sed -i '59s/^/\/\//' cmd/$project/main.go
sed -i '60s/^/\/\//' cmd/$project/main.go
sed -i '61s/^/\/\//' cmd/$project/main.go
sed -i '62s/^/\/\//' cmd/$project/main.go

sed -i "s/Name string/Name string = \"$project\"/" cmd/$project/main.go
sed -i "s/Version string/Version string = \"1.0-alpha\"/" cmd/$project/main.go
sed -i 's/id, _ = os.Hostname()/ \
    ConsulAddress string = "iconsul.supor.com:30058" \
    ConsulKeyValuePath string = "app\/cart\/configs\/config.yaml"\n &/g' cmd/$project/main.go


sed -i 's/defer c.Close/ \
    consulClient, err := api.NewClient(\&api.Config{ \
      Address: ConsulAddress, \
    }) \
    if err != nil { \
      panic(err) \
    } \
    cs, err := consul.New(consulClient, consul.WithPath(ConsulKeyValuePath)) \
    if err != nil { \
      panic(err) \
    } \
    \/\/ Create kratos config instance \
    var c config.Config  \
    c = config.New(config.WithSource(cs))\n &/g' cmd/$project/main.go

sed -i 's/"github.com\/go-kratos\/kratos\/v2\/config\/file"/\/\/"github.com\/go-kratos\/kratos\/v2\/config\/file"/' cmd/$project/main.go

sed -i "N; 10 a \"github.com/hashicorp/consul/api\"\n \
        // Consul Key/Value configuration center\n \
        \"github.com/go-kratos/kratos/contrib/config/consul/v2\"\n \
        // Consul service registry\n \
        consul_r \"github.com/go-kratos/kratos/contrib/registry/consul/v2\"\n \
        \"fmt\"\n \
        \"$project/internal/service\"\n" cmd/$project/main.go

sed -i 's/flag.StringVar/\/\/flag.StringVar/' cmd/$project/main.go

sed -i 's/return kratos.New/ \
    consulClient, err := api.NewClient(\&api.Config{ \
      Address: ConsulAddress, \
    }) \
    if err != nil { \
      fmt.Println(err) \
    } \
    r := consul_r.New(consulClient)\n &/g' cmd/$project/main.go

sed -i 's/return kratos.New(/&\n\t\tkratos.Registrar(r), \/\/Service regist to consul./g' cmd/$project/main.go
sed -i 's/app, cleanup, err := initApp/\tservice.MyConfigFromConsul(c)  \/\/Load configuration-fields from consul-server to Golang-Structures.\n & /g' cmd/$project/main.go

cat << EOF > internal/service/mylogic.go
package service

import(
    "fmt"
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

func MyConfigFromConsul(c config.Config) {
    // MySQL database endpoint configuration
    // MyDatabaseEndpoint(c)

    // Redis endpoint configuration
    // ... ...
}
EOF



fi
