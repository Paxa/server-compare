# Server Compare

Collect remote servers configuration and store it in a git repository.

*Currently it works only with CentOS, this is still alfa version*


After you create `servers.yml`, collect infromation from servers:

```
./bin/sc-collect :my_server_a
./bin/sc-collect :my_server_b

# or all servers in config
./bin/sc-collect :all

# or manually
./bin/sc-collect root@hostname --password=123123 --pem=./server_key.pem
```

Then push it to remote server
```
./bin/sc-push
./bin/sc-push-config
```

### `servers.yml` format

```yml
repo_dir: ./servers_data
repo_url: git@bitbucket.org:yourname/my-servers-tracks.git

servers:
  server_a:
    user: root
    host: 123.123.123.123
    pem: ~/.ssh/pems/server_a.pem
    preserve_files:
      - /opt/nginx/conf/nginx.conf
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
* open network ports (eg 21, 22, 80 etc.)
