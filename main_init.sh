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
    fmt.Printf("Consul Server -> %s\\n", ConsulAddress) \
    fmt.Printf("Config Path -> %s\\n", ConsulKeyValuePath) \
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
        \"$project/internal/service\"\n \
        \"$project/internal/server\"\n" cmd/$project/main.go

sed -i 's/flag.StringVar/ \
    \/\/ Consul Key\/Value(service configuration) \
    flag.StringVar (\&ConsulAddress, "consul-server", "iconsul.supor.com:30058", "consul server, eg: --consul-server iconsul.supor.com:30058") \
    flag.StringVar (\&ConsulKeyValuePath, "config-path", "app\/cart\/configs\/config.yaml", "config path, eg: --config-path app\/cart\/configs\/config.yaml") \
    \n\/\/ Prometheus metrics. \
    server.Http_prometheus_init() \n & /g' cmd/$project/main.go

sed -i 's/flag.StringVar (\&flagconf/\/\/flag.StringVar (\&flagconf/' cmd/$project/main.go

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

sed -i 's/"github.com\/go-kratos\/kratos\/v2\/log"/ \
    \/\/ Prometheus metrics \
    "github.com\/prometheus\/client_golang\/prometheus" \
    prom "github.com\/go-kratos\/kratos\/contrib\/metrics\/prometheus\/v2" \
    "github.com\/go-kratos\/kratos\/v2\/middleware\/metrics" \
    "github.com\/prometheus\/client_golang\/prometheus\/promhttp"\n\n &/g' internal/server/http.go

sed -i 's/\/\/ NewHTTPServer new a HTTP server./ \
\/\/ Prometheus metrics \
var ( \
    _metricSeconds = prometheus.NewHistogramVec(prometheus.HistogramOpts{ \
        Namespace: "server", \
        Subsystem: "requests", \
        Name:      "duration_sec", \
        Help:      "server requests duration(sec).", \
        Buckets:   []float64{0.005, 0.01, 0.025, 0.05, 0.1, 0.250, 0.5, 1}, \
    }, []string{"kind", "operation"}) \
\
    _metricRequests = prometheus.NewCounterVec(prometheus.CounterOpts{ \
        Namespace: "client", \
        Subsystem: "requests", \
        Name:      "code_total", \
        Help:      "The total number of processed requests", \
    }, []string{"kind", "operation", "code", "reason"}) \
) \
\
func Http_prometheus_init() { \
    prometheus.MustRegister(_metricSeconds, _metricRequests) \
}\n &/g' internal/server/http.go


sed -i 's/recovery.Recovery(),/ & \
    \/\/ Prometheus metrics \
                metrics.Server( \
                metrics.WithSeconds(prom.NewHistogram(_metricSeconds)), \
                metrics.WithRequests(prom.NewCounter(_metricRequests)), \
            ), \n /g' internal/server/http.go

sed -i 's/srv := http.NewServer(opts...)/ & \
    \n\/\/ Prometheus metrics route. \
    srv.Handle("\/metrics", promhttp.Handler()) \n /g' internal/server/http.go


fi
