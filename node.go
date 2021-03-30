package BigBFT

import (
	"github.com/salemmohammed/BigBFT/log"
	"reflect"
	"sync"
)
// Node is the primary access point for every replica
// it includes networking, state machine and RESTful API server
type Node interface {
	Socket
	Database
	ID() ID
	Run()
	Retry(r Request)
	Forward(id ID, r Request)
	Register(m interface{}, f interface{})
}
// node implements Node interface
type node struct {
	id ID
	Socket
	Database
	MessageChan chan interface{}
	handles     map[string]reflect.Value
	server      *server
	sync.RWMutex
	forwards map[string]*Request
}
// NewNode creates a new Node object from configuration
func NewNode(id ID) Node {
	log.Debugf("New node")
	return &node{
		id:          id,
		Socket:      NewSocket(id, config.Addrs),
		Database:    NewDatabase(),
		MessageChan: make(chan interface{}, config.ChanBufferSize),
		handles:     make(map[string]reflect.Value),
		forwards:    make(map[string]*Request),
	}
}
func (n *node) ID() ID {
	return n.id
}
func (n *node) Retry(r Request) {
	log.Debugf("node %v retry reqeust %v", n.id, r)
	n.MessageChan <- r
}
// Register a handle function for each message type
func (n *node) Register(m interface{}, f interface{}) {
	t := reflect.TypeOf(m)
	fn := reflect.ValueOf(f)
	if fn.Kind() != reflect.Func || fn.Type().NumIn() != 1 || fn.Type().In(0) != t {
		panic("register handle function error")
	}
	n.handles[t.String()] = fn
}
// Run start and run the node
func (n *node) Run() {
	log.Infof("node %v start running", n.id)
	if len(n.handles) > 0 {
		go n.handle()
		go n.recv()
	}
	n.http()
}
// recv receives messages from socket and pass to message channel
func (n *node) recv() {
	for {
		log.Debugf("recv receives messages from socket and pass to message channel")
		m := n.Recv()
		switch m := m.(type) {
		case Request:
			m.c = make(chan Reply, 1)
			go func(r Request) {
				n.Send(r.NodeID, <-r.c)
			}(m)
			n.MessageChan <- m
			continue

		case Reply:
			n.RLock()
			r := n.forwards[m.Command.String()]
			//log.Debugf("node) %v received reply %v", n.id, m)
			n.RUnlock()
			r.Reply(m)
			continue
		}
		n.MessageChan <- m
	}
}
// handle receives messages from message channel and calls handle function using refection
func (n *node) handle() {
	log.Debugf("handle() node")
	for {
		msg := <-n.MessageChan
		v := reflect.ValueOf(msg)
		log.Debugf("v: %v",v)
		name := v.Type().String()
		f, exists := n.handles[name]
		if !exists {
			log.Fatalf("no registered handle function for message type %v", name)
		}
		f.Call([]reflect.Value{v})
	}
}
func (n *node) Forward(id ID, m Request) {
	log.Debugf("Node %v forwarding %v to %s", n.ID(), m, id)
	m.NodeID = n.id
	n.Lock()
	n.forwards[m.Command.String()] = &m
	n.Unlock()
	n.Send(id, m)
}