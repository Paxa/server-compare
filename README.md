Tracks repo: https://bitbucket.org/paxa/server-compare-tracks

Copy `servers.yml` from https://bitbucket.org/paxa/server-compare-tracks to `./`

```
./bin/sc-collect :turbo_sandbox
./bin/sc-collect :vtweb_sandbox
./bin/sc-collect ...

# or all servers in config
./bin/sc-collect :all

./bin/sc-push
./bin/sc-push-config
```

TODO:

* users' .profile & .bashrc
