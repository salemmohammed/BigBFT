package BigBFT

import "C"
import (
	"bytes"
	"encoding/json"
	"errors"
	"github.com/salemmohammed/BigBFT/lib"
	"github.com/salemmohammed/BigBFT/log"
	"io"
	"io/ioutil"
	"net/http"
	"net/http/httputil"
	"strconv"
	"sync"
)
var List []ID
var rr int = 0
//type SafeCounter struct {
//	mu sync.Mutex
//	v  map[string]int
//}
// Client interface provides get and put for key value store
type Client interface {
	GetMUL(Key) ([]Value, []map[string]string)
	PutMUL(Key, Value) []error
	Get(Key) (Value, error)
	Put(Key, Value,int) error
	Next([]ID) ID
}
// AdminClient interface provides fault injection opeartion
type AdminClient interface {
	Consensus(Key) bool
	Crash(ID, int)
	Drop(ID, ID, int)
	Partition(int, ...ID)
}
// HTTPClient inplements Client interface with REST API
type HTTPClient struct {
	Addrs   map[ID]string
	HTTP    map[ID]string
	ID      ID  // client id use the same id as servers in local site
	N       int // total number of nodes
	LocalN  int // number of nodes in local zone
	C 		int
	CID 	int // command id
	Increase map[int]ID
	*http.Client
	mu sync.Mutex

}
// NewHTTPClient creates a new Client from config
func NewHTTPClient(id ID) *HTTPClient {
	var i int
	// round robin approach for the leaders
	for i=1; i<=len(config.Addrs); i++ {
		List = append(List,NewID(1,i))
		log.Debugf("id = %v", List)
	}
	c := &HTTPClient{
		ID:     id,
		N:      len(config.Addrs),
		Addrs:  config.Addrs,
		HTTP:   config.HTTPAddrs,
		Client: &http.Client{},
		C	   : -1,
		Increase: make(map[int]ID),
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

func (c *HTTPClient) Next(lst []ID) (ID) {

	c.ID = lst[rr]
	rr++
	rr = rr % len(config.Addrs)
	c.C++
	//c.Increase[c.C] := c.ID
	return c.ID
}


//// Put puts new key value pair and return previous value (use REST)
//// Default implementation of Client interface
func (c *HTTPClient) Put(key Key, value Value, Globalcounter int) error {
	//c.Counter++
	log.Debugf("Put Function Globalcounter = %v", Globalcounter)
	c.CID++
	c.ID = c.Next(List)
	log.Debugf("c.ID = %v", c.ID)
	_, _, err := c.RESTPut(c.ID, key, value, Globalcounter)
	return err
}

func (c *HTTPClient) GetMUL(key Key) ([]Value, []map[string]string) {
	log.Debugf("<--------------GetMUL-------------->")
	valueChannel := make(chan Value, len(c.HTTP))
	MetaChannel := make(chan map[string]string,len(c.HTTP))
	//log.Debugf("valueChannel_0_0=%v",<- valueChannel)
	i := 0
	for id := range c.HTTP {
		go func(id ID) {
			c.CID++
			v, meta, err := c.rest(id, key, nil,c.CID,0)
			if err != nil {
				log.Error(err)
				return
			}
			valueChannel <- v
			MetaChannel <- meta
		}(id)
		i++
	}
	values := make([]Value,0)
	metas := make([]map[string]string,0)
	for ; i>0; i--{
		values = append(values, <-valueChannel)
		metas = append(metas, <-MetaChannel)
	}
	//log.Debugf("values %v ", values)
	//log.Debugf("metas %v ", metas)
	return values, metas
}

// Put puts new key value pair and return previous value (use REST)
// Default implementation of Client interface
func (c *HTTPClient) PutMUL(key Key, value Value) []error {
	log.Debugf("<----------------PutMUL---------------->")
	i := 0
	errs := make(chan error,len(c.HTTP))
	for id := range c.HTTP {
		//log.Debugf("id=%v",id)
		go func(id ID) {
			c.CID++
			_, _, err := c.rest(id, key, value,c.CID,0)
			if err != nil {
				log.Error(err)
				return
			}
			errs <- err
		}(id)
		i++
	}
	errors := make([]error,0)
	for ; i>0; i-- {
		errors = append(errors, <-errs)
	}
	//log.Debugf("errors %v ", errors)
	return errors
}

func (c *HTTPClient) GetURL(id ID, key Key) string {
	if id == "" {
		for id = range c.HTTP {
			if c.ID == "" || id.Zone() == c.ID.Zone() {
				break
			}
		}
	}
	return c.HTTP[id] + "/" + strconv.Itoa(int(key))
}
// rest accesses server's REST API with url = http://ip:port/key
func (c *HTTPClient) rest(id ID, key Key, value Value,count int, Globalcounter int) (Value, map[string]string, error) {
	url := c.GetURL(id, key)
	method := http.MethodGet
	var body io.Reader
	if value != nil {
		method = http.MethodPut
		body = bytes.NewBuffer(value)
	}
	// Create Request object
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		log.Debugf("we cannot create a request")
		log.Error(err)
		return nil, nil, err
	}

	req.Header.Set(HTTPClientID, string(id))
	req.Header.Set(HTTPClientCounter, strconv.Itoa(Globalcounter))
	req.Header.Set(HTTPCommandID, strconv.Itoa(count))

	rep, err := c.Client.Do(req)
	if err != nil {
		log.Error(err)
		return nil, nil, err
	}

	defer rep.Body.Close()

	// get headers
	metadata := make(map[string]string)
	for k := range rep.Header {
		metadata[k] = rep.Header.Get(k)
	}

	if rep.StatusCode == http.StatusOK {
		b, err := ioutil.ReadAll(rep.Body)
		if err != nil {
			log.Error(err)
			return nil, metadata, err
		}

		if value == nil{
			log.Debugf("node=%v type=%s key=%v value=%x", id, method, key, Value(b))
		} else {
			log.Debugf("node=%v type=%s key=%v value=%x", id, method, key, value)
		}
		return Value(b), metadata, nil
	}

	// http call failed
	dump, _ := httputil.DumpResponse(rep, true)
	log.Debugf("%q", dump)
	return nil, metadata, errors.New(rep.Status)
}

// RESTGet issues a http call to node and return value and headers
func (c *HTTPClient) RESTGet(id ID, key Key) (Value, map[string]string, error) {
	return c.rest(id, key, nil,c.CID,0)
}

// RESTPut puts new value as http.request body and return previous value
func (c *HTTPClient) RESTPut(id ID, key Key, value Value, counter int) (Value, map[string]string, error) {
	log.Debugf("RESTPut = %v", c.ID)
	log.Debugf("counter = %v", counter)
	return c.rest(id, key, value,c.CID,counter)
}

func (c *HTTPClient) json(id ID, key Key, value Value) (Value, error) {
	url := c.HTTP[id]
	cmd := Command{
		Key:       key,
		Value:     value,
		ClientID:  c.ID,
		CommandID: c.CID,
	}
	data, err := json.Marshal(cmd)
	res, err := c.Client.Post(url, "json", bytes.NewBuffer(data))
	if err != nil {
		log.Error(err)
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode == http.StatusOK {
		b, _ := ioutil.ReadAll(res.Body)
		log.Debugf("key=%v value=%x", key, Value(b))
		return Value(b), nil
	}
	dump, _ := httputil.DumpResponse(res, true)
	log.Debugf("%q", dump)
	return nil, errors.New(res.Status)
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
	for id := range c.HTTP {
		go func(id ID) {
			v, meta, err := c.rest(id, key, nil,c.CID,0)
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
	for id := range c.HTTP {
		if c.ID.Zone() != id.Zone() {
			continue
		}
		i++
		if i > c.LocalN/2 {
			break
		}
		go func(id ID) {
			v, meta, err := c.rest(id, key, nil,c.CID,0)
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
	for id := range c.HTTP {
		i++
		if i > c.N/2 {
			break
		}
		wait.Add(1)
		go func(id ID) {
			c.rest(id, key, value,c.CID,0)
			wait.Done()
		}(id)
	}
	wait.Wait()
}

// Consensus collects /history/key from every node and compare their values
func (c *HTTPClient) Consensus(k Key) bool {
	h := make(map[ID][]Value)
	for id, url := range c.HTTP {
		h[id] = make([]Value, 0)
		r, err := c.Client.Get(url + "/history?key=" + strconv.Itoa(int(k)))
		if err != nil {
			log.Error(err)
			continue
		}
		b, err := ioutil.ReadAll(r.Body)
		if err != nil {
			log.Error(err)
			continue
		}
		holder := h[id]
		err = json.Unmarshal(b, &holder)
		if err != nil {
			log.Error(err)
			continue
		}
		h[id] = holder
		log.Debugf("node=%v key=%v h=%v", id, k, holder)
	}
	n := 0
	for _, v := range h {
		if len(v) > n {
			n = len(v)
		}
	}
	for i := 0; i < n; i++ {
		set := make(map[string]struct{})
		for id := range c.HTTP {
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
	url := c.HTTP[id] + "/crash?t=" + strconv.Itoa(t)
	r, err := c.Client.Get(url)
	if err != nil {
		log.Error(err)
		return
	}
	r.Body.Close()
}

// Drop drops every message send for t seconds
func (c *HTTPClient) Drop(from, to ID, t int) {
	url := c.HTTP[from] + "/drop?id=" + string(to) + "&t=" + strconv.Itoa(t)
	r, err := c.Client.Get(url)
	if err != nil {
		log.Error(err)
		return
	}
	r.Body.Close()
}

// Partition cuts the network between nodes for t seconds
func (c *HTTPClient) Partition(t int, nodes ...ID) {
	s := lib.NewSet()
	for _, id := range nodes {
		s.Add(id)
	}
	for from := range c.Addrs {
		if !s.Has(from) {
			for _, to := range nodes {
				c.Drop(from, to, t)
			}
		}
	}
}