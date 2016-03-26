# Debugging

#### Description of bug
I am testing the evented server using the `netcat` utility.

While making a external call to the Redis database on localhost I expect the connection to block for 3 seconds. Instead `netcat` returns immediately.

Moreover, the socket connected is never removed from the reactor's collection of stream objects when the connection is closed. This is a memory leak.

#### Control scenario
We will use Sprout as a control because the reactor exists the behavior we expect to see.

###### Control Scenario Packet Analysis
* Our `netcat` client initiates and completes the 3-way-handshake from port 49163 to the Sprout::Reactor on port 3030.

* Sprout then sends the customary window size update.

* Netcat immediately sends a push request passing along the string "foo". This is followed by a request to close the connection. The result of these back to back pushes is that the stream will be readable two times!

* When the Netcat socket becomes readable for the first time, our reactor creates a socket connection to the Redis server. Once the 3-way-handshake is complete, it pushes 4 chunks of data to the Redis server.

* The connection is blocked for ~3 seconds.

* Once the 3 second timeout expires, Redis returns its null response `*-1`.

* Because Redis returned a null response, our reactor server does not `PSH` any data into the Netcat socket. Instead, it sends a `FIN` signal and terminates the connection.

###### Control Scenario Reactor Analysis
 * `Sprout::Reactor#tick` was invoked a total of 68755 times before IO.select() blocked.

 * `Sprout::Stream#handle_read` was invoked 72341 times. A large proportion of these invocations occurred while the Redis connection was blocking.

 * I noticed that `Sprout::Stream` only calls close internally in its `handle_read` method if its socket connection is closed. This means it delegates responsibility for explicitly closing the connection to the API. For example, if we create an echo server on top of the reactor, we would explicitly close the connection as part of the implementation of the echo server!
