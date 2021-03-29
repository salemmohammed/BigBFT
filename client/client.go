package main

import (
	"Blockchain/log"
	"encoding/binary"
	"flag"

	"Blockchain"
)

var id = flag.String("id", "", "node id this client connects to")
var algorithm = flag.String("algorithm", "paxos", "Client API type [paxos, chain]")
var load = flag.Bool("load", false, "Load K keys into DB")

// db implements Paxi.DB interface for benchmarking
type db struct {
	Blockchain.Client
}

func (d *db) Init() error {
	return nil
}

func (d *db) Stop() error {
	return nil
}

func (d *db) Read(k int) (int, error) {
	key := Blockchain.Key(k)
	v, err := d.Get(key)
	if len(v) == 0 {
		return 0, nil
	}
	x, _ := binary.Uvarint(v)
	return int(x), err
}

func (d *db) Write(k, v int) error {
	key := Blockchain.Key(k)
	value := make([]byte, binary.MaxVarintLen64)
	binary.PutUvarint(value, uint64(v))
	err := d.Put(key, value)
	return err
}

func main() {
	Blockchain.Init()

	d := new(db)
	switch *algorithm {
	// name of algorithm is blockchain
	case "paxos":
		d.Client = Blockchain.NewHTTPClient(Blockchain.ID(*id))
	default:
		panic("Unknown algorithm")
	}
	// create client and push it to the benchmark
	// Run the benchmark in client section
	b := Blockchain.NewBenchmark(d)
	if *load {
		log.Debugf("Load keys in client")
		b.Load()
	} else {
		log.Debugf("Run in client")
		b.Run()
	}
}