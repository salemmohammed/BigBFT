package main

import (
	"flag"
	"Blockchain"
	"Blockchain/log"
	"Blockchain/paxos"
)

var algorithm = flag.String("algorithm", "paxos", "Distributed algorithm")
var id = flag.String("id", "", "ID in format of Zone.Node.")


func replica(id Blockchain.ID) {
	// first thing appear on the screen
	log.Infof("node %v starting...", id)
	// package name then create the instance with an id in the terminals
	// Run function is in Blockchain.node.
	switch *algorithm {
	case "paxos":
		paxos.NewReplica(id).Run()

	default:
		panic("Unknown algorithm")
	}
}

func main() {
	Blockchain.Init() // check this.
	replica(Blockchain.ID(*id))
}
