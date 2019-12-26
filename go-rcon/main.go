package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"log"
	"os"
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
	// Address of RCON server
	const rconAddress = "127.0.0.1:27015"

	// Keep track of how long the server has been empty for
	minutesEmpty := 0
	// Create a logger client
	ctx := context.Background()

	client, err := logging.NewClient(ctx, projectID)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	defer client.Close()
	logger := client.Logger(logName)
	logger.Log(logging.Entry{
		Payload:  fmt.Sprintf("%s online", logName),
		Severity: logging.Notice,
	})

	// Prepare the RCON password
	pwBytes, errRF := ioutil.ReadFile("/opt/factorio/config/rconpw")
	if errRF != nil {
		logger.Log(logging.Entry{
			Payload:  fmt.Sprintf("error reading password file: %v", errRF),
			Severity: logging.Critical,
		})
		logger.Flush()
		os.Exit(1)
	}

	rconPassword := strings.TrimSpace(string(pwBytes))

	// Set up exponential backoff
	b := &backoff.Backoff{
		Max:    10 * time.Minute,
		Jitter: true,
	}

	// Creates the RCON client and authenticates with the server
	r, errDial := rcon.Dial(rconAddress)
	for errDial != nil {
		d := b.Duration()

		logger.Log(logging.Entry{
			Payload:  fmt.Sprintf("error dialing: %v", errDial),
			Severity: logging.Error,
		})
		time.Sleep(d)

		r, errDial = rcon.Dial(rconAddress)
	}
	b.Reset()

	defer r.Close()

	errAuth := r.Authenticate(rconPassword)
	for errAuth != nil && errDial != nil {
		logger.Log(logging.Entry{
			Payload:  fmt.Sprintf("error authenticating: %v", errAuth),
			Severity: logging.Error,
		})
		time.Sleep(d)
		r.Close()

		r, errDial = rcon.Dial(rconAddress)
		if errDial != nil {
			logger.Log(logging.Entry{
				Payload:  fmt.Sprintf("error redialing: %v", errAuth),
				Severity: logging.Critical,
			})

			continue
		}

		errAuth = r.Authenticate(rconPassword)
	}
	b.Reset()

	// Main monitoring loop
	for {
		time.Sleep(time.Minute)

		players, errCP := r.CmdPlayers()
		if errCP != nil {
			logger.Log(logging.Entry{
				Payload:  fmt.Sprintf("error fetching player count: %v", errCP),
				Severity: logging.Error,
			})

			continue
		}

		logger.Log(logging.Entry{
			Payload:  fmt.Sprintf("Players: '%+v'", players),
			Severity: logging.Info,
		})

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
			logger.Log(logging.Entry{
				Payload:  fmt.Sprintf("Minutes without any online players: %d", minutesEmpty),
				Severity: logging.Info,
			})
		}

		if minutesEmpty >= shutdownMinutes {
			logger.Log(logging.Entry{
				Payload:  fmt.Sprintf("Threshold reached; %d minutes elapsed without any online players", shutdownMinutes),
				Severity: logging.Notice,
			})

			break
		}
	}

	// Server seppuku
	cmd := exec.Command("shutdown", "--poweroff", "now")

	logger.Log(logging.Entry{
		Payload:  fmt.Sprintf("Calling shutdown command: '%+v'", cmd),
		Severity: logging.Notice,
	})
	logger.Flush()

	_ = cmd.Start()
}
