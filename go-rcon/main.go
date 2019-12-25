package main

import (
	"fmt"
	"io/ioutil"
	"log"

	rcon "github.com/gtaylor/factorio-rcon"
)

func main() {
	pwBytes, errRF := ioutil.ReadFile("/opt/factorio/rconpw")
	if errRF != nil {
		log.Fatal(errRF)
	}

	r, errDial := rcon.Dial("127.0.0.1:27015")
	if errDial != nil {
		log.Fatal(errDial)
	}
	defer r.Close()

	errAuth := r.Authenticate(string(pwBytes))
	if errAuth != nil {
		log.Fatal(errAuth)
	}

	players, errCP := r.CmdPlayers()
	if errCP != nil {
		log.Fatal(errCP)
	}

	fmt.Printf("Players: '%+v'\n", players)
}
