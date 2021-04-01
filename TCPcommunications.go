package BigBFT
//https://www.youtube.com/watch?v=5eQJ-0y8TzE
import (
	"log"
	"net"
	"net/http"
)

// Client interface provides get and put for key value store
type TClient interface {
	GetMUL(Key) ([]Value, []map[string]string)
	PutMUL(Key, Value) []error
	Get(Key) (Value, error)
	Put(Key, Value) error
}

// HTTPClient inplements Client interface with REST API
type TCPClient struct {
	Addrs  map[ID]string
	HTTP   map[ID]string
	ID     ID  // client id use the same id as servers in local site
	N      int // total number of nodes
	LocalN int // number of nodes in local zone

	CID int // command id
	*http.Client
}

// NewHTTPClient creates a new Client from config
func NewTCPClient(id ID) *TCPClient {
	c := &TCPClient{
		ID:     id,
		N:      len(config.Addrs),
		Addrs:  config.Addrs,
		HTTP:   config.HTTPAddrs,
		// creating client request object
		Client: &http.Client{},
	}
	if id != "" {
		i := 0
		for node := range c.Addrs {
			if node.Zone() == id.Zone() {
				i++
			}
		}
		c.LocalN = i
	}

	return c
}
func newClient(address string) {
	conn, err := net.Dial("tcp", address)
	if err != nil{
		log.Fatalln(err)
	}
	defer conn.Close()
}

func newServer(address string) {
	li, err := net.Listen("tcp", address)
	if err != nil {
		log.Fatalln(err)
	}
	defer li.Close()
	for {
		conn, err := li.Accept()
		if err != nil {
			log.Fatalln(err)
			continue
		}
		go handle(conn)
	}
}
func handle(conn net.Conn) {
	defer conn.Close()

	// read request
	request(conn)
	// write response
	respond(conn)
}

func request(conn net.Conn)  {

}
func respond(conn net.Conn)  {

}

//		bs, err := ioutil.ReadAll(c)
//		if err != nil{
//			log.Println(err)
//		}
//		fmt.Println(string(bs))
//	}
//}