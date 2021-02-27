package cleanup

import (
	"context"
	"encoding/json"
	"fmt"

	"cloud.google.com/go/storage"
)

// locations returns a slice of location structs based on what is stored in gs://<project>-storage/lib/locations.json.
func locations(ctx context.Context, projectID string) ([]location, error) {
	storageClient, err := storage.NewClient(ctx)
	if err != nil {
		return nil, fmt.Errorf("error creating Storage client: %w", err)
	}

	bucketName := fmt.Sprintf(fmtLocationsBucket, projectID)
	bkt := storageClient.Bucket(bucketName)
	objLocs := bkt.Object(locationsObject)

	r, err := objLocs.NewReader(ctx)
	if err != nil {
		return nil, fmt.Errorf("error reading JSON object: %w", err)
	}

	var locs []location

	dec := json.NewDecoder(r)
	if errDecode := dec.Decode(&locs); errDecode != nil {
		return nil, fmt.Errorf("error decoding locations JSON: %w", errDecode)
	}

	if err := r.Close(); err != nil {
		return nil, fmt.Errorf("could not close Storage reader: %w", err)
	}

	return locs, nil
}
