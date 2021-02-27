// Package cleanup holds funcs which are executed on a regular basis.
package cleanup

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
