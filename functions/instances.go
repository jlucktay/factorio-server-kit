package cleanup

import (
	"context"
	"fmt"
	"strings"

	"cloud.google.com/go/compute/metadata"
	"google.golang.org/api/compute/v1"
)

// Instances iterates across all zones listed in gs://<project>-storage/lib/locations.json file deleting all VMs which:
// (1) are named using the same pattern that /scripts/roll-vm.sh uses to create instances.
// (2) have a status of TERMINATED.
func Instances(ctx context.Context, _ PubSubMessage) error {
	projectID, err := metadata.ProjectID()
	if err != nil {
		return fmt.Errorf("error fetching project ID from metadata: %w", err)
	}

	locs, err := locations(ctx, projectID)
	if err != nil {
		return err
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

				if _, err := deleteCall.Do(); err != nil {
					return fmt.Errorf("error executing delete operation for instance %s in zone %s: %w",
						inst.Name, loc.Zone, err)
				}
			}
		}
	}

	return nil
}
