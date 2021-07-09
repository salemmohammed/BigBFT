package consensus

import (
	"crypto/md5"
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
	Slot      int
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
	flag2      int

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
		flag2:           0,
	}
	for _, opt := range options {
		opt(p)
	}

	return p
}
func GetMD5Hash(r *BigBFT.Request) []byte {
	hasher := md5.New()
	hasher.Write([]byte(r.Command.Value))
	return []byte(hasher.Sum(nil))
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
		Voted:	   true,
		leader:    true,
	}

	mutex.Lock()
	p.l[p.slot] = &CommandBallot{r.Command,p.slot,p.ID()}
	p.count++
	mutex.Unlock()

	log.Debugf("p.l[%v] created = %v", p.slot, p.l[p.slot].Command)
	log.Debugf("size log %v", len(p.l))
	e := p.log[p.slot]
	p.Broadcast(Propose{Ballot: p.ballot, Command: r.Command, Slot:p.slot, ID: p.ID(), Leader: e.leader})

	log.Debugf("-------------------------------------------------------")
	t := p.execute + (p.log[p.slot].quorum.Total() - 1)
	log.Debugf("t %v", t)
	log.Debugf("p.count %v", p.count)

	//if len(p.l) >= e.quorum.Total() {
	//	log.Debugf("p.HandlePropose")
	//	p.HandlePropose(Propose{Ballot: p.ballot, Command: r.Command, Slot:p.slot, ID: p.ID(),Leader: e.leader})
	//}

	//if len(p.l) >= e.quorum.Size(){
	//	log.Debugf(" Local HandlePropose")
	//	//p.HandlePropose(Propose{Ballot: p.ballot, Command: r.Command, Slot:p.slot, ID: p.ID(),Leader: e.leader})
	//	p.Broadcast(Vote{L:p.l,})
	//}

	log.Debugf("-------------------------------------------------------")

}
func (p *Consensus) HandlePropose(m Propose) {
	log.Debugf("HandlePropose = %v", m.Slot)



	if p.ballot < m.Ballot {
		p.ballot = m.Ballot
	}
	e, exist := p.log[m.Slot]
	if !exist {
		p.log[m.Slot] = &entry{
			ballot:    m.Ballot,
			//request:   &m.Request,
			command:   m.Command,
			timestamp: time.Now(),
			quorum:    BigBFT.NewQuorum(),
			commit:    false,
			received:  false,
			Voted:	   false,
			leader:    false,
			Slot :     m.Slot,
		}
		p.count++
		log.Debugf("%v Slot is created", m.Slot)
	}
	e = p.log[m.Slot]
	e.leader = false
	log.Debugf("p.count = %v", p.count)
	log.Debugf("p.slot = %v", p.slot)

	log.Debugf("-----------------Change------------------------")
	mutex.Lock()

	p.l[m.Slot] = &CommandBallot{m.Command,m.Slot, p.ID()}
	log.Debugf("p.l[%v] created = %v", m.Slot, p.l[m.Slot].Command)
	mutex.Unlock()

	e = p.log[m.Slot]
	t := ( p.execute + e.quorum.Total()			      )
	log.Debugf("t %v", t             		  )
	log.Debugf("p.count %v", p.count 		  )
	log.Debugf("p.l %v", len(p.l)    		  )
	log.Debugf("p.count >= t %v", p.count >= t )

	log.Debugf("m.ID %v", m.ID 				  )
	//p.Member.Addmember(m.ID 	      				  )
	//log.Debugf("Nighbors %v", p.Member.Neibors )

	if p.count >= t || len(p.l) >= e.quorum.Total() {
		for ss , _ := range p.log {
			e := p.log[ss]
			log.Debugf("ss =  %v", ss)
			e.Voted= true
			if ss > p.flag2{
				p.flag2 = ss
			}
		}
	}
	flag := false
	if m.Slot < p.flag2 {
		log.Debugf("m.Slot < flag2 = %v", m.Slot < p.flag2)
		flag = true
	}
	log.Debugf("m.Slot < flag2 = %v", m.Slot < p.flag2)
	//e.Voted = true
	if p.count >= t || (len(p.l) >= e.quorum.Total()){
		//p.Member.Reset()
		log.Debugf("conditions")
		if e.leader != true && len(p.l) >= e.quorum.Total(){
			p.Broadcast(Vote{
				Slot: m.Slot,
				Id:   p.ID(),
				L:    p.l,
			})
			p.l = make(map[int]*CommandBallot)
		}
	}
	if (len(p.l) >= e.quorum.Total() ) || flag==true {
		p.Member.Reset()
		for ss, _ := range p.log {
			e := p.log[ss]
			log.Debugf("ss =  %v", ss)
			e.Voted = true
			if ss > p.flag2 {
				p.flag2 = ss
			}
			if e.commit == true{
				p.exec()
			}
		}
		//log.Debugf("p.count >= t || len(p.l) >= e.quorum.Total() - 2 = %v ", e.quorum.Total()-2)
		//log.Debugf("p.count >= t || len(p.l) >= e.quorum.Total()/2 = %v ", e.quorum.Total()/2)
		//if e.leader != true && len(p.l) > 0{
		//	log.Debugf("Un - conditions")
		//	p.Broadcast(Vote{
		//		Slot: m.Slot,
		//		Id:   p.ID(),
		//		L:    p.l,
		//	})
		//	p.l = make(map[int]*CommandBallot)
		//}
	}
	log.Debugf("-----------------------------------------")

}

func (p *Consensus) HandleVote(m Vote) {
	log.Debugf("------HandleVote------ %v", m.Slot)

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
		log.Debugf("e  =%v",e.command )
		e.quorum.ACK(sc.Id)
		log.Debugf("e  =%v",e.quorum.Size() )
		log.Debugf("e.quorum.Majority()  =%v",e.quorum.Majority() )
		//if e.quorum.Size() == e.quorum.Size() - 1 {
		if e.quorum.Majority(){
			log.Debugf("e.commit = True  =%v",e.command.Key )
			e.commit = true
			e.received = true
			p.exec()
		}
	}
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
			log.Debugf("Vote exec()")
			if e.quorum.Size() >= e.quorum.Total(){
				e.quorum.Reset()
				log.Debugf("Vote from exec()")
				p.Broadcast(Vote{
					Slot: p.execute,
					Id:   p.ID(),
					L:    p.l,
				})
				log.Debugf("e.Voted break")
				break
			}
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
		delete(p.l,p.execute)
		p.execute++
		log.Debugf("Done")
	}
}