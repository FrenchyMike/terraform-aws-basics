#/bin/bash

printf '{
	"user": "%s",
	"commit": "%s"
}' "$USER" "$(git rev-parse --short HEAD)"
