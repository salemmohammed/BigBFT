package consensus

import (
	"github.com/salemmohammed/BigBFT"
	"github.com/salemmohammed/BigBFT/log"
	"sync"
	"time"
)
var mutex = &sync.Mutex{}
type entry struct {
	ballot    BigBFT.Ballot
	commit    bool
	request   *BigBFT.Request
	command   BigBFT.Command
	quorum    *BigBFT.Quorum
	timestamp time.Time
	received    bool
	Voted	  bool
	leader    bool
}
type Consensus struct {
	BigBFT.Node
	log        map[int]*entry
	execute    int
	active     bool
	ballot     BigBFT.Ballot
	slot       int
	quorum     *BigBFT.Quorum
	requests   []*BigBFT.Request
	Q1         func(*BigBFT.Quorum) bool
	Q2         func(*BigBFT.Quorum) bool
	l           map[int]*CommandBallot
	Flag	   bool
	count      int
	Counter    int

	Member       *BigBFT.Memberlist
}
func NewConsensus(n BigBFT.Node, options ...func(*Consensus)) *Consensus {
	p := &Consensus{
		Node:            n,
		log:             make(map[int]*entry, BigBFT.GetConfig().BufferSize),
		slot:            -1,
		quorum:          BigBFT.NewQuorum(),
		requests:        make([]*BigBFT.Request, 0),
		Q1:              func(q *BigBFT.Quorum) bool { return q.Majority() },
		Q2:              func(q *BigBFT.Quorum) bool { return q.Majority() },
		Member:          BigBFT.NewMember(),
		l: 				 make(map[int]*CommandBallot),
		Flag:			false,
		count:          -1,
		Counter:		-1,
	}
	for _, opt := range options {
		opt(p)
	}

	return p
}
func (p *Consensus) HandleRequest(r BigBFT.Request) {
	p.active = true
	p.slot = r.Command.Counter
	p.ballot.Next(p.ID())
	p.requests = append(p.requests, &r)
	p.Propose(&r)
}
func (p *Consensus) Propose(r *BigBFT.Request) {

	p.log[p.slot] = &entry{
		ballot:    p.ballot,
		request:   r,
		command:   r.Command,
		timestamp: time.Now(),
		quorum:    BigBFT.NewQuorum(),
		commit:    false,
		received:  false,
		Voted:	   false,
		leader:    true,
	}

	mutex.Lock()
	p.l[p.slot] = &CommandBallot{r.Command,p.slot,p.ID()}
	p.count++
	mutex.Unlock()

	log.Debugf("p.l[%v] created = %v", p.slot, p.l[p.slot].Command)
	log.Debugf("size log %v", len(p.l))

	p.Broadcast(Propose{Ballot: p.ballot, Request: *r, Slot:p.slot, ID: p.ID()})

	log.Debugf("-------------------------------------------------------")
	t := p.execute + 3
	log.Debugf("t %v", t)
	log.Debugf("p.count %v", p.count)

	if p.count >= t {
		log.Debugf("p.HandlePropose")
		p.HandlePropose(Propose{Ballot: p.ballot, Request: *r,Slot:p.slot, ID: p.ID()})
	}

	if len(p.l) >= p.log[p.slot].quorum.Total() - 1{
		log.Debugf(" Local HandlePropose")
		p.HandlePropose(Propose{Ballot: p.ballot, Request: *r,Slot:p.slot, ID: p.ID()})
	}

	log.Debugf("-------------------------------------------------------")

}
func (p *Consensus) HandlePropose(m Propose) {
	log.Debugf("HandlePropose = %v", m.Slot)
	log.Debugf("------HandlePropose------")
	startTime := time.Now()
	log.Debugf("------startTime------ = %v", startTime)
	if p.ballot < m.Ballot {
		p.ballot = m.Ballot
	}
	_, exist := p.log[m.Slot]
	if !exist {
		p.log[m.Slot] = &entry{
			ballot:    m.Ballot,
			request:   &m.Request,
			command:   m.Request.Command,
			timestamp: time.Now(),
			quorum:    BigBFT.NewQuorum(),
			commit:    false,
			received:  false,
			Voted:	   false,
			leader:    false,
		}
		p.count++
		log.Debugf("%v Slot is created", m.Slot)
	}
	//e = p.log[m.Slot]

	log.Debugf("p.count = %v", p.count)
	log.Debugf("p.slot = %v", p.slot)

	mutex.Lock()
	p.l[m.Slot] = &CommandBallot{m.Request.Command,m.Slot, p.ID()}
	log.Debugf("p.l[%v] created = %v", m.Slot, p.l[m.Slot].Command)
	mutex.Unlock()


	e := p.log[m.Slot]
	t := p.execute + e.quorum.Total() - 1
	log.Debugf("t %v", t)
	log.Debugf("p.count %v", p.count)
	log.Debugf("p.l %v", len(p.l))
	log.Debugf("p.count >= t %v", p.count >= t)

	log.Debugf("m.ID %v", m.ID)
	p.Member.Addmember(m.ID)
	log.Debugf("Nighbors %v", p.Member.Neibors)

	if p.count >= t || len(p.l) >= e.quorum.Total() - 1{
		for ss , _ := range p.log {
			e := p.log[ss]
			log.Debugf("ss =  %v", ss)
			e.Voted= true
		}
	}

	//e = p.log[m.Slot]
	//if (p.count >= t || len(p.l) >= e.quorum.Total() - 1)  && p.Member.Size() == p.Member.ClientSize()-2{
	//	log.Debugf("conditions")
	//	p.Broadcast(Vote{
	//		Slot: m.Slot,
	//		Id:   p.ID(),
	//		L:    p.l,
	//	})
	//	p.l = make(map[int]*CommandBallot)
	//	p.Member.Reset()
	//}

	c1 := make(chan Vote)

	go func() {
		//time.Sleep(1 * time.Second)
		c1 <- Vote{
			Slot: m.Slot,
			Id:   p.ID(),
			L:    p.l,
		}
	}()

	timer := time.NewTimer(10*time.Millisecond)
	flag := false
	loop:
	for{
		select {
		case m := <- c1:
			e := p.log[m.Slot]
			if p.count >= t || len(m.L) >= e.quorum.Total() - 1  || p.Member.Size() == 3{
				p.Member.Reset()
				log.Debugf("conditions")
				p.Broadcast(Vote{
					Slot: m.Slot,
					Id:   p.ID(),
					L:    p.l,
				})
				p.l = make(map[int]*CommandBallot)
			}
		case <- timer.C:
			flag = true
			log.Debugf("time.After")
			break loop
		}
	}



	if len(p.l) >= e.quorum.Total()/2 && flag == true && p.Member.Size() >= e.quorum.Total()/2{
		p.Member.Reset()
		log.Debugf("p.count >= t || len(p.l) >= e.quorum.Total() - 2 = %v ", e.quorum.Total()-2)
		log.Debugf("p.count >= t || len(p.l) >= e.quorum.Total()/2 = %v ", e.quorum.Total()/2)
		p.Broadcast(Vote{
			Slot: m.Slot,
			Id:   p.ID(),
			L:    p.l,
		})
		p.l = make(map[int]*CommandBallot)
	}
}

func (p *Consensus) HandleVote(m Vote) {
	log.Debugf("------HandleVote------")


	for s, sc := range m.L{
		log.Debugf("s  =%v",s )
		e , ok := p.log[s]
		if !ok{
			if p.execute > s {
				log.Debugf("continue")
				continue
			}else{
				p.log[s] = &entry{
					command:   sc.Command,
					timestamp: time.Now(),
					quorum:    BigBFT.NewQuorum(),
					commit:    false,
					received:  false,
					Voted:	   false,
					leader:    false,
				}
			}
			log.Debugf("%v s is created", s)
		}
		e = p.log[s]
		e.received = true
		log.Debugf("e  =%v",e.command )
		e.commit = true
		e.quorum.ACK(sc.Id)
		log.Debugf("e  =%v",e.quorum.Size() )
		if e.quorum.Size() == e.quorum.Total() - 1 {
			e.Voted = true
			//e.quorum.Reset()
		}
	}
	//mutex.Unlock()
	p.exec()
}
func (p *Consensus) exec() {
	for {
		log.Debugf("------exec------")
		e, ok := p.log[p.execute]
		log.Debugf("p.execute = %v ", p.execute)
		if !ok{
			log.Debugf("!ok break")
			break
		}
		if !e.commit{
			log.Debugf("!e.commit break")
			break
		}
		if e.Voted == false {
			log.Debugf("e.Voted break")
			break
		}
		log.Debugf("Replica %s execute [s=%d, cmd=%v]", p.ID(), p.execute, e.command)
		value := p.Execute(e.command)
		log.Debugf("p.Execute(e.command)")
		if e.request != nil {
			if e.leader{
				log.Debugf("inside if reply ")
				reply := BigBFT.Reply{
					Command:    e.command,
					Value:      value,
					Properties: make(map[string]string),
				}
				log.Debugf("e.request.Reply(reply) B/F")
				e.request.Reply(reply)
				log.Debugf("e.request.Reply(reply) A/F")
			}
		}
		delete(p.log,p.execute)
		mutex.Lock()
		delete(p.l,p.execute)
		mutex.Unlock()
		p.execute++
		log.Debugf("Done")
	}
}