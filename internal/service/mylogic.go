package service

import(
    "fmt"
    "github.com/go-kratos/kratos/v2/config"
    // Add MySQL package
    jq "github.com/jinquan0/jqdb/jqmysql"
    // Add Redis package
        "encoding/json"
        "strconv"
        "regexp"
)

var DbEndpoint struct {
  Mysqlendpoint struct {
    Host  string `json:"host"`
    Port  string `json:"port"`
    User  string `json:"user"`
    Pass  string `json:"pass"`
    Sslca string `json:"sslca"`
  } `json:"mysqlendpoint"`
}

func MyDatabaseEndpoint(c config.Config) {
    if err := c.Scan(&DbEndpoint); err != nil {
        panic(err)
    }
    fmt.Printf("%+v\n", DbEndpoint)
}

func MyConfigFromConsul(c config.Config) {
    // MySQL database endpoint configuration
     MyDatabaseEndpoint(c)

    // Redis endpoint configuration
    // ... ...
}

///////////////////////////////////////////////////////////////////////////////////////////
type ST_MyFields_1 struct{
    Id         int    `json:"id"`
    Product_key    string  `json:"product_key"`
    Verbose_name   string  `json:"verbose_name"`
}

func AnyarrayAlloc(sz int) []interface{} {
    any_array := make([]interface{}, sz, sz)
    for i:=0; i < sz; i++ { 
        any_array[i]=new(ST_MyFields_1) 
    }
    return any_array
}

func DbEndpointConstruct(db string) *jq.ST_MySQL_Endpoint {
        e := &jq.ST_MySQL_Endpoint {
          Host:  DbEndpoint.Mysqlendpoint.Host,
          Port:  DbEndpoint.Mysqlendpoint.Port,
          User:  DbEndpoint.Mysqlendpoint.User,
          Pass:  DbEndpoint.Mysqlendpoint.Pass,
          Sslca: DbEndpoint.Mysqlendpoint.Sslca,
          Db:    db,
        }
        return e    
}

func InsertData()  {
        e:=DbEndpointConstruct("test01")

        d:=&ST_MyFields_1{
                Id: 11,
                Product_key: "jinquan",
                Verbose_name: "k8s",
        }

        db := jq.MyConn(e)
        jq.MyInsert( db, 
                        "INSERT IGNORE INTO bledev(`id`, `product_key`, `verbose_name`) VALUES (?,?,?)", *d ) 
        jq.MyDisconn(db)
}

/* 
    curl -XPOST -H "Content-Type:application/json" -d '{"Id":9, "Name":"*"}' http://172.24.16.6:8000/v1/testsvc0
    /usr/local/apache_httpd/bin/ab -n 50000 -c 2000 -T application/json -p /tmp/post.json http://172.24.16.6:8000/v1/demoapi7
*/
func SelectData(query_id int) string {
        e:=DbEndpointConstruct("test01")

        var dout ST_MyFields_1
        db := jq.MyConn(e)
        jq.MySelect( db, 
                        "select id,product_key,verbose_name from bledev where `id`="+strconv.Itoa(query_id)+";",       
                        &dout.Id, &dout.Product_key, &dout.Verbose_name ) 
        jq.MyDisconn(db)
        jsonBytes,_ := json.Marshal(dout)
        jsonString := string(jsonBytes)
        return jsonString
}

func GetInteger_Id(src_req string) int {
        re:=regexp.MustCompile(`(\d+)`)
        match:=re.FindString(src_req)
        i,err:=strconv.Atoi(match)
        if err != nil {
                fmt.Printf("Atoi/> %v", err)
                return -1
        }
        return i
}
