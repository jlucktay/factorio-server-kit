package cleanup

import (
	"context"
	"fmt"

	"cloud.google.com/go/compute/metadata"
	"google.golang.org/api/compute/v1"
)

// Disks iterates across all available zones deleting disks that are no longer attached to an instance.
func Disks(ctx context.Context, _ PubSubMessage) error {
	projectID, err := metadata.ProjectID()
	if err != nil {
		return fmt.Errorf("error fetching project ID from metadata: %w", err)
	}

	computeService, err := compute.NewService(ctx)
	if err != nil {
		return fmt.Errorf("error creating Compute service: %w", err)
	}

	zoneList, err := computeService.Zones.List(projectID).Do()
	if err != nil {
		return fmt.Errorf("could not retrieve list of zones: %w", err)
	}

	for _, zone := range zoneList.Items {
		diskList, err := computeService.Disks.List(projectID, zone.Name).Do()
		if err != nil {
			return fmt.Errorf("error listing disks in zone %s: %w", zone.Name, err)
		}

		for _, disk := range diskList.Items {
			if len(disk.Users) == 0 {
				if _, err := computeService.Disks.Delete(projectID, zone.Name, disk.Name).Do(); err != nil {
					return fmt.Errorf("error deleting disk %s in zone %s: %w", disk.Name, zone.Name, err)
				}
			}
		}
	}

	return nil
}
