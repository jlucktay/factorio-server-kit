package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"

	"cloud.google.com/go/storage"
	"google.golang.org/api/compute/v1"
)

const (
	project          = "jlucktay-factorio"
	statusTerminated = "TERMINATED"

	locationsBucket = project + "-asia"
	locationsObject = "lib/locations.json"
)

type location struct {
	Location string `json:"location"`
	Zone     string `json:"zone"`
}

type locations []location

func main() {
	storageClient, errStorage := storage.NewClient(context.TODO())
	if errStorage != nil {
		log.Fatalf("error creating Storage client: %v", errStorage)
	}

	bkt := storageClient.Bucket(locationsBucket)
	objLocs := bkt.Object(locationsObject)

	r, errReader := objLocs.NewReader(context.TODO())
	if errReader != nil {
		log.Fatalf("error reading JSON object: %v", errReader)
	}
	defer r.Close()

	var locs locations

	dec := json.NewDecoder(r)
	if errDecode := dec.Decode(&locs); errDecode != nil {
		log.Fatalf("error decoding locations JSON: %v", errDecode)
	}

	computeService, errService := compute.NewService(context.TODO())
	if errService != nil {
		log.Fatalf("error creating Compute service: %v", errService)
	}

	for _, loc := range locs {
		listCall := computeService.Instances.List(project, loc.Zone)
		listCall = listCall.Filter(fmt.Sprintf("name:factorio-%s-*", strings.ToLower(loc.Location)))

		list, errList := listCall.Do()
		if errList != nil {
			log.Fatalf("error listing instances in zone %s: %v", loc.Zone, errList)
		}

		for _, inst := range list.Items {
			if inst.Status == statusTerminated {
				deleteCall := computeService.Instances.Delete(project, loc.Zone, inst.Name)

				_, errDelete := deleteCall.Do()
				if errDelete != nil {
					log.Fatalf("error executing delete operation for instance %s in zone %s: %v", inst.Name, loc.Zone, errDelete)
				}
			}
		}
	}
}
