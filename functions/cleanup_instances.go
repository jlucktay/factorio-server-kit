// Package cleanup holds a func to remove terminated instances and is executed on a regular basis.
package cleanup

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"cloud.google.com/go/compute/metadata"
	"cloud.google.com/go/storage"
	"google.golang.org/api/compute/v1"
)

const (
	statusTerminated = "TERMINATED"

	fmtLocationsBucket = "%s-storage"
	locationsObject    = "lib/locations.json"
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

// Instances iterates across all zones listed in gs://<project>-storage/lib/locations.json file deleting all VMs which:
// (1) are named using the same pattern that /scripts/roll-vm.sh uses to create instances.
// (2) have a status of TERMINATED.
func Instances(ctx context.Context, _ PubSubMessage) error {
	projectID, err := metadata.ProjectID()
	if err != nil {
		return fmt.Errorf("error fetching project ID from metadata: %w", err)
	}

	storageClient, err := storage.NewClient(ctx)
	if err != nil {
		return fmt.Errorf("error creating Storage client: %w", err)
	}

	bucketName := fmt.Sprintf(fmtLocationsBucket, projectID)
	bkt := storageClient.Bucket(bucketName)
	objLocs := bkt.Object(locationsObject)

	r, err := objLocs.NewReader(ctx)
	if err != nil {
		return fmt.Errorf("error reading JSON object: %w", err)
	}
	defer r.Close() //nolint:errcheck // Don't let the door hit you on the way out

	var locs []location

	dec := json.NewDecoder(r)
	if errDecode := dec.Decode(&locs); errDecode != nil {
		return fmt.Errorf("error decoding locations JSON: %w", errDecode)
	}

	computeService, err := compute.NewService(ctx)
	if err != nil {
		return fmt.Errorf("error creating Compute service: %w", err)
	}

	for _, loc := range locs {
		listCall := computeService.Instances.List(projectID, loc.Zone)
		listCall = listCall.Filter(fmt.Sprintf("name:factorio-%s-*", strings.ToLower(loc.Location)))

		list, err := listCall.Do()
		if err != nil {
			return fmt.Errorf("error listing instances in zone %s: %w", loc.Zone, err)
		}

		for _, inst := range list.Items {
			if inst.Status == statusTerminated {
				deleteCall := computeService.Instances.Delete(projectID, loc.Zone, inst.Name)

				_, err := deleteCall.Do()
				if err != nil {
					return fmt.Errorf("error executing delete operation for instance %s in zone %s: %w",
						inst.Name, loc.Zone, err)
				}
			}
		}
	}

	return nil
}
