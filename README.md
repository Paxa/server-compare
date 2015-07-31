Tracks repo: https://bitbucket.org/paxa/server-compare-tracks

Copy `servers.yml` from https://bitbucket.org/paxa/server-compare-tracks to `./`

```
./bin/sc-collect :turbo_sandbox
./bin/sc-collect :vtweb_sandbox
./bin/sc-collect ...

./bin/sc-push
./bin/sc-push-config
```

TODO:

* save host IP address
* save host hardware info: ram, swap, CPUs, storage, mac address

