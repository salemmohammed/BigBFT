package consensus

import (
	"encoding/gob"
	"fmt"
	"github.com/salemmohammed/BigBFT"
)

func init() {
	gob.Register(Propose{})
	gob.Register(Vote{})
}

type Propose struct {
	Ballot  BigBFT.Ballot
	Request BigBFT.Request
	Command BigBFT.Command
	Slot    int
	ID      BigBFT.ID
	Leader  bool
}

func (m Propose) String() string {
	return fmt.Sprintf("Propose {b=%v Command=%v slot=%v Leader=%v}", m.Ballot, m.Command, m.Slot, m.Leader)
}

type Vote struct {
	Slot  int
	Id	  BigBFT.ID
	L    map[int]*CommandBallot
}

func (m Vote) String() string {
	return fmt.Sprintf("Vote {L=%v}", m.L)
}

// CommandBallot conbines each command with its ballot number
type CommandBallot struct {
	//Request BigBFT.Request
	Command BigBFT.Command
	Slot  int
	Id	  BigBFT.ID
}

func (cb CommandBallot) String() string {
	return fmt.Sprintf("cmd=%v s=%v", cb.Command, cb.Slot)
}