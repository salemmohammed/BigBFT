package Blockchain
import "C"
import (
	"Blockchain/lib"
	"Blockchain/log"
	"bufio"
	"container/list"
	"encoding/gob"
	"errors"
	"fmt"
	"io"
	"net"
	"strconv"
	"strings"
	"sync"
	"time"
)
// Client interface provides get and put for key value store
type Client interface {
	Get(Key) (Value, error)
	Put(Key, Value) error
}
// https://www.oreilly.com/content/building-messaging-in-go-network-clients/
// AdminClient interface provides fault injection opeartion
type AdminClient interface {
	Consensus(Key) bool
	Crash(ID, int)
	Drop(ID, ID, int)
	Partition(int, ...ID)
}
type client interface {
	processInfo(line string)
	processMsg(subj string, reply string, sid int, payload []byte)
	processPing()
	processPong()
	processErr(msg string)
	processOpErr(err error)
}
// HTTPClient inplements Client interface with REST API
type HTTPClient struct {
	Addrs  map[ID]string
	ID     ID  // client id use the same id as servers in local site
	N      int // total number of nodes
	LocalN int // number of nodes in local zone
	CID int // command id
	conn net.Conn
	data   chan []byte
	w    *bufio.Writer // ??
	sync.Mutex
	reqSent *list.List  // list of requests sent, waiting for response
	mutex   sync.Mutex
	pending map[uint64]*Request
}
// NewHTTPClient creates a new Client from config
// New client
func NewHTTPClient(id ID) *HTTPClient {
	log.Debugf("I received request from clinet to start NewHTTPClient")
	c := &HTTPClient{
		ID:     id,
		N:      len(config.Addrs),
		Addrs:  config.Addrs,
		//HTTP:   config.HTTPAddrs,
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
// Get gets value of given key (use REST)
// Default implementation of Client interface
func (c *HTTPClient) Get(key Key) (Value, error) {
	c.CID++
	v, _, err := c.RESTGet(c.ID, key)
	return v, err
}
// Put puts new key value pair and return previous value (use REST)
// Default implementation of Client interface
func (c *HTTPClient) Put(key Key, value Value) error {
	log.Debugf("Write Function in Client.go")
	c.CID++
	_, _, err := c.RESTPut(c.ID, key, value)
	return err
}
func (c *HTTPClient) GetURL(id ID, key Key) string {
	if id == "" {
		for id = range c.Addrs {
			if c.ID == "" || id.Zone() == c.ID.Zone() {
				break
			}
		}
	}
	return c.Addrs[id] + "/" + strconv.Itoa(int(key))
}
// Close terminates a connection to NATS.
func (c *HTTPClient) Close() {
	c.Lock()
	defer c.Unlock()
	c.conn.Close()
}
// rest accesses server's REST API with url = http://ip:port/key
// if value == nil, it's a read
func (c *HTTPClient) Send(id ID, key Key, value Value) (Value, map[string]string, error) {
	log.Debugf("rest Function in Client.go")
	log.Debugf("c.Addrs[c.ID] = %v", c.Addrs[c.ID])
	// dial the server
	conn, err := net.Dial("tcp", c.Addrs[c.ID])
	if err != nil {
		return nil, nil, err
	}
	//defer conn.Close()
	log.Debugf("Connected to server...")
	//encoder := gob.NewEncoder(buffer)

	c.mutex.Lock()
	encoder := gob.NewEncoder(conn)
	c.CID++

	cmd := Command{
		Key:       key,
		Value:     value,
		ClientID:  c.ID,
		CommandID: c.CID,
	}

	req := Request{
		Command:    cmd,
		Properties: make(map[string]string),
		Timestamp:  time.Now().UnixNano(),
		NodeID:     id,
		c:          make(chan Reply, 1),
		Done:       nil,
	}

	err = encoder.Encode(req)
	if err != nil {
		log.Fatal("encode error:", err)
	}
	c.mutex.Unlock()

	select {
	case <-req.Done:
	case <-time.After(2 * time.Second):
		req.Error = errors.New("request timeout")
	}
	if req.Error != nil {
		return nil,nil, req.Error
	}
	return req.Command.Value, nil, nil
}

// RESTGet issues a http call to node and return value and headers
func (c *HTTPClient) RESTGet(id ID, key Key) (Value, map[string]string, error) {
	return c.Send(id, key, nil)
}

// RESTPut puts new value as http.request body and return previous value
func (c *HTTPClient) RESTPut(id ID, key Key, value Value) (Value, map[string]string, error) {
	log.Debugf("RESTPut Function in Client.go")
	return c.Send(id, key, value)
}

func (c *HTTPClient) json(id ID, key Key, value Value) (Value, error) {
	////url := c.Addrs[id]
	//cmd := Command{
	//	Key:       key,
	//	Value:     value,
	//	ClientID:  c.ID,
	//	CommandID: c.CID,
	//}
	////data, err := json.Marshal(cmd)
	//res, err := c.Client.Post(url, "json", bytes.NewBuffer(data))
	//if err != nil {
	//	log.Error(err)
	//	return nil, err
	//}
	//defer res.Body.Close()
	//if res.StatusCode == http.StatusOK {
	//	b, _ := ioutil.ReadAll(res.Body)
	//	log.Debugf("key=%v value=%x", key, Value(b))
	//	return Value(b), nil
	//}
	//dump, _ := httputil.DumpResponse(res, true)
	//log.Debugf("%q", dump)
	return nil, nil
}

// JSONGet posts get request in json format to server url
func (c *HTTPClient) JSONGet(key Key) (Value, error) {
	return c.json(c.ID, key, nil)
}

// JSONPut posts put request in json format to server url
func (c *HTTPClient) JSONPut(key Key, value Value) (Value, error) {
	return c.json(c.ID, key, value)
}

// QuorumGet concurrently read values from majority nodes
func (c *HTTPClient) QuorumGet(key Key) ([]Value, []map[string]string) {
	return c.MultiGet(c.N/2+1, key)
}

// MultiGet concurrently read values from n nodes
func (c *HTTPClient) MultiGet(n int, key Key) ([]Value, []map[string]string) {
	valueC := make(chan Value)
	metaC := make(chan map[string]string)
	i := 0
	for id := range c.Addrs {
		go func(id ID) {
			v, meta, err := c.Send(id, key, nil)
			if err != nil {
				log.Error(err)
				return
			}
			valueC <- v
			metaC <- meta
		}(id)
		i++
		if i >= n {
			break
		}
	}

	values := make([]Value, 0)
	metas := make([]map[string]string, 0)
	for ; i > 0; i-- {
		values = append(values, <-valueC)
		metas = append(metas, <-metaC)
	}
	return values, metas
}

func (c *HTTPClient) LocalQuorumGet(key Key) ([]Value, []map[string]string) {
	valueC := make(chan Value)
	metaC := make(chan map[string]string)
	i := 0
	for id := range c.Addrs {
		if c.ID.Zone() != id.Zone() {
			continue
		}
		i++
		if i > c.LocalN/2 {
			break
		}
		go func(id ID) {
			v, meta, err := c.Send(id, key, nil)
			if err != nil {
				log.Error(err)
				return
			}
			valueC <- v
			metaC <- meta
		}(id)
	}

	values := make([]Value, 0)
	metas := make([]map[string]string, 0)
	for ; i >= 0; i-- {
		values = append(values, <-valueC)
		metas = append(metas, <-metaC)
	}
	return values, metas
}

// QuorumPut concurrently write values to majority of nodes
// TODO get headers
func (c *HTTPClient) QuorumPut(key Key, value Value) {
	var wait sync.WaitGroup
	i := 0
	for id := range c.Addrs {
		i++
		if i > c.N/2 {
			break
		}
		wait.Add(1)
		go func(id ID) {
			c.Send(id, key, value)
			wait.Done()
		}(id)
	}
	wait.Wait()
}

// Consensus collects /history/key from every node and compare their values
func (c *HTTPClient) Consensus(k Key) bool {
	h := make(map[ID][]Value)
	n := 0
	for _, v := range h {
		if len(v) > n {
			n = len(v)
		}
	}
	for i := 0; i < n; i++ {
		set := make(map[string]struct{})
		for id := range c.Addrs {
			if len(h[id]) > i {
				set[string(h[id][i])] = struct{}{}
			}
		}
		if len(set) > 1 {
			return false
		}
	}
	return true
}

// Crash stops the node for t seconds then recover
// node crash forever if t < 0
func (c *HTTPClient) Crash(id ID, t int) {
}

// Drop drops every message send for t seconds
func (c *HTTPClient) Drop(from, to ID, t int) {
}

// Partition cuts the network between nodes for t seconds
func (c *HTTPClient) Partition(t int, nodes ...ID) {
	s := lib.NewSet()
	for _, id := range nodes {
		s.Add(id)
	}
	for from := range c.Addrs {
		if !s.Has(from) {
		}
	}
}

// readLoop is ran as a goroutine and processes commands
// sent by the server.
func readLoop(c client, conn net.Conn) {
	r := bufio.NewReader(conn)

	for {
		line, err := r.ReadString('\n')
		if err != nil {
			c.processOpErr(err)
			return
		}
		args := strings.SplitN(line, " ", 2)
		if len(args) < 1 {
			c.processOpErr(errors.New("Error: malformed control line"))
			return
		}

		op := strings.TrimSpace(args[0])
		switch op {
		case "MSG":
			var subject, reply string
			var sid, size int

			n := strings.Count(args[1], " ")
			switch n {
			case 2:
				// No reply is expected in this case (message is just broadcast).
				// MSG foo 1 3\r\n
				// bar\r\n
				_, err := fmt.Sscanf(args[1], "%s %d %d",
					&subject, &sid, &size)
				if err != nil {
					c.processOpErr(err)
					return
				}
			case 3:
				// Reply is expected in this case (a request).
				// MSG foo 1 bar 4\r\n
				// quux\r\n
				_, err := fmt.Sscanf(args[1], "%s %d %s %d",
					&subject, &sid, &reply, &size)
				if err != nil {
					c.processOpErr(err)
					return
				}
			default:
				c.processOpErr(errors.New("nats: bad control line"))
				return
			}

			// Prepare buffer for the payload
			payload := make([]byte, size)
			_, err = io.ReadFull(r, payload)
			if err != nil {
				c.processOpErr(err)
				return
			}
			// In the two-argument case, the reply below is null.
			c.processMsg(subject, reply, sid, payload)
		case "INFO":
			c.processInfo(args[1])
		case "PING":
			c.processPing()
		case "PONG":
			c.processPong()
		case "+OK":
			// Do nothing.
		case "-ERR":
			c.processErr(args[1])
		}
	}
}