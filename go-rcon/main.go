package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"strings"

	rcon "github.com/gtaylor/factorio-rcon"
)

func main() {
	pwBytes, errRF := ioutil.ReadFile("/opt/factorio/config/rconpw")
	if errRF != nil {
		log.Fatalf("error reading password file: %v", errRF)
	}

	r, errDial := rcon.Dial("127.0.0.1:27015")
	if errDial != nil {
		log.Fatalf("error dialing: %v", errDial)
	}
	defer r.Close()

	errAuth := r.Authenticate(strings.TrimSpace(string(pwBytes)))
	if errAuth != nil {
		log.Fatalf("error authenticating: %v", errAuth)
	}

	players, errCP := r.CmdPlayers()
	if errCP != nil {
		log.Fatalf("error fetching player count: %v", errCP)
	}

	fmt.Printf("Players: '%+v'\n", players)
}
