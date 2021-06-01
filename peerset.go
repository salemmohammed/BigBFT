package BigBFT

import "C"

import (
	"github.com/salemmohammed/BigBFT/log"
	"net"
	"net/url"
	"sync"
)

var (
	mu sync.Mutex
	cm *Memberlist
)

// IPeerSet has a (immutable) subset of the methods of PeerSet.
type IPeerSet interface {
	Has(key ID) bool
	HasIP(ip net.IP) bool
	Get(key ID) Memberlist
	List() []Memberlist
	Size() int
	getProposal() int
}

type Event struct {
	IPAddress string
}

type Memberlist struct {
	Addrs     string
	Neibors   []ID
	available map[ID]bool
	size      int
}

// For status
const (
	RUNNING  = 1
	FAILING  = 2
	FAILED   = 3
	REJOINED = 4
)

func NewMember() *Memberlist {
	newm := &Memberlist{
		Addrs:     "",
		Neibors:   make([]ID, 0),
		available: make(map[ID]bool),
		size:      0,
	}
	return newm
}

func (m *Memberlist) Addmember(id ID) {
	//for i, _ := range config.Addrs {
		ur, _ := url.Parse(config.Addrs[id])
		url := ur.String()
		if !m.available[id] {
			m.Addrs = url
			m.available[id] = true
			m.size++
			m.Neibors = append(m.Neibors, id)
		}
	}
//}

func (m *Memberlist) Delete(id ID) {

	for i, v := range m.Neibors {
		if v == id {
			ret := make([]ID, 0)
			ret = append(ret, m.Neibors[:i]...)
			ret = append(ret, m.Neibors[i+1:]...)
			m.Neibors = ret
			m.size--
			m.available[v] = false
			m.Addrs = ""
		}
	}
}

func (m *Memberlist) Reset() {
	m.Neibors = make([]ID, 0)
	m.available = make(map[ID]bool)
	m.size = 0
	m.Addrs = ""
}

// Size returns the number of unique items in the peerSet.
func (ps *Memberlist) Size() int {
	mu.Lock()
	defer mu.Unlock()
	return len(ps.Neibors)
}

func (ps *Memberlist) ClientSize() int {
	value := config.Benchmark.Concurrency
	log.Debugf("The value of concurrency is:%v", value)
	return value
}

