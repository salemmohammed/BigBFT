package consensus

import (
	"github.com/salemmohammed/BigBFT"
)

// Client overwrites read operation for Paxos
type Client struct {
	*BigBFT.HTTPClient
	ballot BigBFT.Ballot
}

func NewClient(id BigBFT.ID) *Client {
	return &Client{
		HTTPClient: BigBFT.NewHTTPClient(id),
	}
}

func (c *Client) Put(key BigBFT.Key, value BigBFT.Value) error {
	c.HTTPClient.CID++
	_, meta, err := c.RESTPut(c.ID, key, value)
	if err == nil {
		b := BigBFT.NewBallotFromString(meta[HTTPHeaderBallot])
		if b > c.ballot {
			c.ballot = b
		}
	}

	return err
}