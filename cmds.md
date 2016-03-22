View TCP connections on localhost. Good for viewing the connection status between client and server sockets as well as the amount of bytes remaining in the Recv-Q and Send-Q.

```
netstat -p tcp | grep localhost

# This one shows the flow hash
netstat -A | grep "localhost"
```


Show the size of the various listen queues. The first count shows the number of unaccepted connections. The second count shows the amount of unaccepted incomplete connections. The third count is the maximum number of queued connections.
```
netstat -a -L
```

View such information on individual TCP connections as the process id, the command that opened the socket, the owner, host, port, and status.
```
lsof -i -n -P | grep TCP
```
