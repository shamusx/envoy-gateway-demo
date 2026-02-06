
### Test redirect
```sh
curl --resolve web.httpbin.io:8080:127.0.0.1 http://web.httpbin.io:8080/get -I
```

### Test SSL
```sh
curl --resolve web.httpbin.io:8443:127.0.0.1 https://web.httpbin.io:8443/get -k -I
```