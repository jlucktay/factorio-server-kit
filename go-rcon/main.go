package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"strings"
	"time"

	rcon "github.com/gtaylor/factorio-rcon"
)

func main() {
	// Number of minutes for the server to be empty before shutting down
	const shutdownMinutes = 15

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

	minutesEmpty := 0

	for {
		players, errCP := r.CmdPlayers()
		if errCP != nil {
			log.Fatalf("error fetching player count: %v", errCP)
		}

		fmt.Printf("Players: '%+v'\n", players)

		anyOnline := false

		for _, player := range players {
			if player.Online {
				anyOnline = true
				break
			}
		}

		if !anyOnline {
			minutesEmpty++
		}

		if minutesEmpty >= shutdownMinutes {
			break
		}

		time.Sleep(time.Minute * shutdownMinutes)
	}

	fmt.Printf("Players: '%+v'\n", players)
}
