package main

import (
	"context"
	"io/ioutil"
	"log"
	"strings"
	"time"

	"cloud.google.com/go/logging"
	rcon "github.com/gtaylor/factorio-rcon"
)

func main() {
	// GCP project to send Stackdriver logs to
	const projectID = "jlucktay-factorio"
	// Sets the name of the log to write to
	const logName = "goppuku"
	// Number of minutes for the server to be empty before shutting down
	const shutdownMinutes = 15

	// Keep track of how long the server has been empty for
	minutesEmpty := 0

	// Creates a logger client
	ctx := context.Background()

	client, err := logging.NewClient(ctx, projectID)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	defer client.Close()
	logger := client.Logger(logName).StandardLogger(logging.Info)

	pwBytes, errRF := ioutil.ReadFile("/opt/factorio/config/rconpw")
	if errRF != nil {
		logger.Fatalf("error reading password file: %v", errRF)
	}

	r, errDial := rcon.Dial("127.0.0.1:27015")
	if errDial != nil {
		logger.Fatalf("error dialing: %v", errDial)
	}
	defer r.Close()

	errAuth := r.Authenticate(strings.TrimSpace(string(pwBytes)))
	if errAuth != nil {
		logger.Fatalf("error authenticating: %v", errAuth)
	}

	for {
		players, errCP := r.CmdPlayers()
		if errCP != nil {
			logger.Fatalf("error fetching player count: %v", errCP)
		}

		logger.Printf("Players: '%+v'\n", players)

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
}
