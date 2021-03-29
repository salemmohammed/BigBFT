package Blockchain

import (
	"flag"
	"net/http"

	"Blockchain/log"
)

// Init setup Blockchain package
func Init() {
	flag.Parse()
	log.Setup()
	config.Load()
	// What is this?
	http.DefaultTransport.(*http.Transport).MaxIdleConnsPerHost = 1000
}
