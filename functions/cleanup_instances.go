package cleanup

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"cloud.google.com/go/storage"
	"google.golang.org/api/compute/v1"
)

const (
	project          = "jlucktay-factorio"
	statusTerminated = "TERMINATED"

	locationsBucket = project + "-storage"
	locationsObject = "lib/locations.json"
)

// PubSubMessage is the payload of a Pub/Sub event.
// See here for the whole enchilada:
// https://github.com/googleapis/google-cloud-go/blob/da586d9883c96cfded5bd0286f1f7ae7fac58c92/pubsub/message.go#L25
type PubSubMessage struct {
	Data []byte `json:"data"`
}

// location describes the structure of a JSON file that we use to denote which GCP regions and zones are in use by this
// project.
type location struct {
	Location string `json:"location"`
	Zone     string `json:"zone"`
}

// Instances will iterate across all zones listed in our gs://jlucktay-factorio-storage/lib/locations.json file and
// delete all instances which:
// (1) are named using the same pattern that /scripts/roll-vm.sh uses to create instances
// (2) have a status of TERMINATED
func Instances(ctx context.Context, _ PubSubMessage) error {
	storageClient, errStorage := storage.NewClient(ctx)
	if errStorage != nil {
		return fmt.Errorf("error creating Storage client: %v", errStorage)
	}

	bkt := storageClient.Bucket(locationsBucket)
	objLocs := bkt.Object(locationsObject)

	r, errReader := objLocs.NewReader(ctx)
	if errReader != nil {
		return fmt.Errorf("error reading JSON object: %v", errReader)
	}
	defer r.Close()

	var locs []location

	dec := json.NewDecoder(r)
	if errDecode := dec.Decode(&locs); errDecode != nil {
		return fmt.Errorf("error decoding locations JSON: %v", errDecode)
	}

	computeService, errService := compute.NewService(ctx)
	if errService != nil {
		return fmt.Errorf("error creating Compute service: %v", errService)
	}

	for _, loc := range locs {
		listCall := computeService.Instances.List(project, loc.Zone)
		listCall = listCall.Filter(fmt.Sprintf("name:factorio-%s-*", strings.ToLower(loc.Location)))

		list, errList := listCall.Do()
		if errList != nil {
			return fmt.Errorf("error listing instances in zone %s: %v", loc.Zone, errList)
		}

		for _, inst := range list.Items {
			if inst.Status == statusTerminated {
				deleteCall := computeService.Instances.Delete(project, loc.Zone, inst.Name)

				_, errDelete := deleteCall.Do()
				if errDelete != nil {
					return fmt.Errorf("error executing delete operation for instance %s in zone %s: %v",
						inst.Name, loc.Zone, errDelete)
				}
			}
		}
	}

	return nil
}
