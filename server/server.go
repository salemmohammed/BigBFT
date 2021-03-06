package main

import (
	"flag"
	"github.com/salemmohammed/BigBFT"
	"github.com/salemmohammed/BigBFT/consensus"
	"github.com/salemmohammed/BigBFT/log"
)

var algorithm = flag.String("algorithm", "consensus", "Distributed algorithm")
var id = flag.String("id", "", "ID in format of Zone.Node.")


func replica(id BigBFT.ID) {
	// first thing appear on the screen
	log.Infof("node %v starting...", id)
	// package name then create the instance with an id in the terminals
	// Run function is in Blockchain.node.
	switch *algorithm {
	case "consensus":
		consensus.NewReplica(id).Run()


	default:
		panic("Unknown algorithm")
	}
}

func main() {
	BigBFT.Init() // check this.
	replica(BigBFT.ID(*id))
}
