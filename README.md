Tracks repo: https://bitbucket.org/paxa/server-compare-tracks

Copy `servers.yml` from https://bitbucket.org/paxa/server-compare-tracks to `./`

```
./bin/sc-collect :turbo_sandbox
./bin/sc-collect :vtweb_sandbox
./bin/sc-collect ...

# or all servers in config
./bin/sc-collect :all

# or manually
./bin/sc-collect root@hostname --password=123123 --pem=./server_key.pem

./bin/sc-push
./bin/sc-push-config
```

### `servers.yml` format

```yml
repo_dir: ./servers_data
repo_url: git@bitbucket.org:paxa/server-compare-tracks.git

servers:
  server_a:
    user: root
    host: 123.123.123.123
    pem: ~/.ssh/pems/server_a.pem
    preserve_files:
      - /opt/nginx/conf/nginx.conf
      - /etc/inspeqtor/**/*
      - /etc/init/inspeqtor.conf
      - /etc/init.d/inspeqtor
      - /etc/init.d/delayed_job
      - /etc/init.d/nginx
      - /etc/bashrc
  server_b:
    user: root
    host: 123.123.123.124
    pem: ~/.ssh/pems/server_b.pem
  server_c:
    user: root
    host: 123.123.123.125
    pem: ~/.ssh/pems/server_c.pem
```

TODO:

* users' .profile & .bashrc
