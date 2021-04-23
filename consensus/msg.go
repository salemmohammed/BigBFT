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
	ID      BigBFT.ID
	Request BigBFT.Request
	Slot    int
}

func (m Propose) String() string {
	return fmt.Sprintf("Propose {b=%v id=%s request=%v slot=%v}", m.Ballot, m.ID, m.Request, m.Slot)
}

type Vote struct {
	Ballot  BigBFT.Ballot
	Slot    int
	Request BigBFT.Request
	ID     BigBFT.ID
}

func (m Vote) String() string {
	return fmt.Sprintf("Voted {b=%v s=%d R=%v id=%s}", m.Ballot, m.Slot, m.Request, m.ID)
}