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
	Slot    int
	ID      BigBFT.ID
}

func (m Propose) String() string {
	return fmt.Sprintf("Propose {b=%v request=%v slot=%v}", m.Ballot, m.Request, m.Slot)
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