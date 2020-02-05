#!/usr/bin/env bash
set -exu

# because things are never simple.
# See https://github.com/codecov/example-go#caveat-multiple-files
# and https://github.com/insomniacslk/dhcp/tree/master/.travis/tests.sh

set -e

# enable Go modules for older versions of Go
export GO111MODULE=on

# disable CGO for the build
export CGO_ENABLED=0
for d in $(go list ./cmds/... | grep -v vendor); do
    go build "${d}"
done

# CGO required for the race detector
export CGO_ENABLED=1
echo "" > coverage.txt

for d in $(go list ./... | grep -v vendor); do
    go test -race -coverprofile=profile.out -covermode=atomic "${d}"
    if [ -f profile.out ]; then
        cat profile.out >> coverage.txt
        rm profile.out
    fi
done

for d in $(go list -tags=integration ./... | grep integ | grep -v vendor); do
    # integration tests
    go test -c -tags=integration -race -coverprofile=profile.out -covermode=atomic "${d}"
    testbin="./$(basename "${d}").test"
    # only run it if it was built - i.e. if there are integ tests
    test -x "${testbin}" && sudo "./${testbin}"
    if [ -f profile.out ]; then
        cat profile.out >> coverage.txt
        rm profile.out
    fi
done