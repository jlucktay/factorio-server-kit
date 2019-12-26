package main

import (
	"context"
	"io/ioutil"
	"log"
	"os/exec"
	"strings"
	"time"

	"cloud.google.com/go/logging"
	rcon "github.com/gtaylor/factorio-rcon"
	"github.com/jpillora/backoff"
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
	log.Printf("%s online", logName)
	logger.Printf("%s online", logName)

	// Prepare the RCON password
	pwBytes, errRF := ioutil.ReadFile("/opt/factorio/config/rconpw")
	if errRF != nil {
		log.Printf("error reading password file: %v", errRF)
		logger.Fatalf("error reading password file: %v", errRF)
	}
	rconPassword := strings.TrimSpace(string(pwBytes))

	// Set up exponential backoff
	b := &backoff.Backoff{
		Max:    10 * time.Minute,
		Jitter: true,
	}

	// Creates the RCON client and authenticates with the server
	r, errDial := rcon.Dial("127.0.0.1:27015")
	for errDial != nil {
		log.Printf("error dialing: %v", errDial)
		logger.Fatalf("error dialing: %v", errDial)
		d := b.Duration()
		time.Sleep(d)

		r, errDial = rcon.Dial("127.0.0.1:27015")
	}
	b.Reset()

	defer r.Close()

	errAuth := r.Authenticate(rconPassword)
	for errAuth != nil {
		log.Printf("error authenticating: %v", errAuth)
		logger.Fatalf("error authenticating: %v", errAuth)
		d := b.Duration()
		time.Sleep(d)
		errAuth = r.Authenticate(rconPassword)
	}
	b.Reset()

	// Main monitoring loop
	for {
		time.Sleep(time.Minute)

		players, errCP := r.CmdPlayers()
		if errCP != nil {
			log.Printf("error fetching player count: %v", errCP)
			logger.Fatalf("error fetching player count: %v", errCP)
		}

		logger.Printf("Players: '%+v'", players)

		anyOnline := false

		for _, player := range players {
			if player.Online {
				anyOnline = true
				minutesEmpty = 0

				break
			}
		}

		if !anyOnline {
			minutesEmpty++
			logger.Printf("Minutes without any online players: %d", minutesEmpty)
		}

		if minutesEmpty >= shutdownMinutes {
			logger.Printf("Threshold reached; %d minutes elapsed without any online players", shutdownMinutes)
			break
		}
	}

	// Server seppuku
	cmd := exec.Command("shutdown", "--poweroff", "now")
	logger.Printf("Calling shutdown command: '%+v'", cmd)
	_ = cmd.Start()
}
