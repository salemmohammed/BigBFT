package consensus

import (
	"github.com/salemmohammed/BigBFT/log"
	"strconv"
	"time"
	"github.com/salemmohammed/BigBFT"
)

// entry in log
type entry struct {
	ballot    BigBFT.Ballot
	command   BigBFT.Command
	commit    bool
	request   *BigBFT.Request
	quorum    *BigBFT.Quorum
	timestamp time.Time
}

type Consensus struct {
	BigBFT.Node

	log        map[int]*entry // log ordered by slot
	execute    int            // next execute slot number
	active     bool           // active leader
	ballot     BigBFT.Ballot    // highest ballot number
	slot       int            // highest slot number

	quorum     *BigBFT.Quorum    // phase 1 quorum
	requests   []*BigBFT.Request // phase 1 pending requests

	Q1         func(*BigBFT.Quorum) bool
	Q2         func(*BigBFT.Quorum) bool
}

// NewPaxos creates new paxos instance
func NewConsensus(n BigBFT.Node, options ...func(*Consensus)) *Consensus {
	p := &Consensus{
		Node:            n,
		log:             make(map[int]*entry, BigBFT.GetConfig().BufferSize),
		slot:            -1,
		quorum:          BigBFT.NewQuorum(),
		requests:        make([]*BigBFT.Request, 0),
		Q1:              func(q *BigBFT.Quorum) bool { return q.Majority() },
		Q2:              func(q *BigBFT.Quorum) bool { return q.Majority() },
	}
	for _, opt := range options {
		opt(p)
	}

	return p
}

func (p *Consensus) HandleRequest(r BigBFT.Request) {
	p.active = true
	p.slot++
	p.ballot.Next(p.ID())
	p.requests = append(p.requests, &r)
	p.Propose(&r)
}

func (p *Consensus) Propose(r *BigBFT.Request) {
	// create the log entry
	p.log[p.slot] = &entry{
		ballot:    p.ballot,
		request:   r,
		command:   r.Command,
		timestamp: time.Now(),
		quorum:    BigBFT.NewQuorum(),
		commit:    false,
	}

	p.Broadcast(Propose{Ballot: p.ballot, ID: p.ID(), Request: *r, Slot:p.slot})
}

func (p *Consensus) HandlePropose(m Propose) {

	log.Debugf("HandlePropose = %v", m)
	e, exist := p.log[m.Slot]
	if !exist {
		p.log[m.Slot] = &entry{
			ballot:    m.Ballot,
			request:   &m.Request,
			command:   m.Request.Command,
			timestamp: time.Now(),
			quorum:    BigBFT.NewQuorum(),
			commit:    false,
		}
		e = p.log[m.Slot]
	}
	e.commit = false
	p.Broadcast(Vote{Ballot: m.Ballot, ID: p.ID(), Command: m.Request.Command, Slot: m.Slot})
}

func (p *Consensus) HandleVote(m Vote) {

	e, exist := p.log[m.Slot]
	if !exist {
		p.log[m.Slot] = &entry{
			ballot:  m.Ballot,
			command: m.Command,
			quorum:    BigBFT.NewQuorum(),
			commit:  false,
		}
		e = p.log[m.Slot]
	}
	e.quorum.ACK(m.ID)
	e.quorum.ACK(p.ID())
	log.Debugf("size %v", e.quorum.Size())
	if e.quorum.Majority() {
		e.command = m.Command
		e.commit = true
		p.exec()
	}
}
func (p *Consensus) exec() {
	for {
		e, ok := p.log[p.execute]
		if !ok || !e.commit {
			break
		}
		log.Debugf("Replica %s execute [s=%d, cmd=%v]", p.ID(), p.execute, e.command)
		value := p.Execute(e.command)
		if e.request != nil {
			reply := BigBFT.Reply{
				Command:    e.command,
				Value:      value,
				Properties: make(map[string]string),
			}
			reply.Properties[HTTPHeaderSlot] = strconv.Itoa(p.execute)
			reply.Properties[HTTPHeaderBallot] = e.ballot.String()
			reply.Properties[HTTPHeaderExecute] = strconv.Itoa(p.execute)
			e.request.Reply(reply)
			e.request = nil
		}
		// TODO clean up the log periodically
		delete(p.log, p.execute)
		p.execute++
		log.Debugf("Done")
	}
}