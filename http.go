package BigBFT

import (
	"github.com/salemmohammed/BigBFT/log"
	//"bytes"
	"encoding/gob"
	"fmt"
	"net"
	"os"
)
// Client holds info about connection
type Clients struct {
	conn   net.Conn
	Server *server
}
type server struct {
	address string
	conn   net.Conn
}

// serve serves the http REST API request from clients
func (n *node) http() {
	log.Debugf("In http() : %v", config.Addrs[n.id])
	n.server = &server{
		address: config.Addrs[n.id],
	}
	log.Info("The server starting on ", n.server.address)
	// Listen for incoming connections.
	ln, err := net.Listen("tcp", n.server.address)
	if err != nil {
		fmt.Println("Error listening:", err.Error())
		os.Exit(1)
	}
	// Close the listener when the application closes.
	defer ln.Close()
	fmt.Println("Listening on", n.server.address)
	for {
		// Listen for an incoming connection.
		conn, err := ln.Accept()
		if err != nil {
			log.Fatal("tcp server accept error", err)
		}else{
			n.server.conn = conn
			// Handle connections in a new goroutine.
			go n.handleRequest(n.server.conn)
		}
	}
}
// Handles incoming requests.
func (n *node) handleRequest(conn net.Conn) {

	var req Request
	var err error
	log.Debugf("Server is Read client data from channel")
	dec := gob.NewDecoder(conn)
	err = dec.Decode(&req)
	if err != nil {
		panic(err)
	}
	// lets print out!
	fmt.Println(req) // reflects.TypeOf(tmpstruct) == Message{}
	log.Debugf("Before sending Request on the channel n.MessageChan %v", req)
	n.MessageChan <- req
	log.Debugf("After sending Request on the channel n.MessageChan %v", req)
	reply := <-req.c
	req.Done <- true
	fmt.Println("Reply: %v", reply)
}