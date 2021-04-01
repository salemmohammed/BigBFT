package consensus

import (
	"github.com/salemmohammed/BigBFT"
	"github.com/salemmohammed/BigBFT/log"
)

const (
	HTTPHeaderSlot       = "Slot"
	HTTPHeaderBallot     = "Ballot"
	HTTPHeaderExecute    = "Execute"
)

type Replica struct {
	BigBFT.Node
	*Consensus
}

func NewReplica(id BigBFT.ID) *Replica {
	r := new(Replica)
	r.Node = BigBFT.NewNode(id)
	r.Consensus = NewConsensus(r)
	r.Register(BigBFT.Request{}, r.handleRequest)
	r.Register(Propose{}, r.HandlePropose)
	r.Register(Vote{}, r.HandleVote)
	return r
}

func (r *Replica) handleRequest(m BigBFT.Request) {
	log.Debugf("Replica %s received %v\n", r.ID(), m)
	r.Consensus.HandleRequest(m)
}