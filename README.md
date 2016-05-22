# Achtung (in Elm) – [Play!](http://gbark.github.io/achtung)

A browser based clone of **Achtung, die Kurve!** (also known as **Zatacka**) written in Elm.

![screenshot](screenshot.png)

## Run locally

Clone this repo and run using [elm-reactor](https://github.com/elm-lang/elm-reactor)

## Multiplayer Todo

* [x] Build authoritative game server using Node/SocketIO/Immutable/Redux
* [x] Stream client keyboard input to server for processing. Include a sequence timestamp.
* [ ] On the server, apply client input to a rolled back game state matching the timestamp. Then move players back to their correct/current positions.
* [x] Render own player on client. 
* [ ] Reconcile own players actual positions when they arrive from the server.
* [x] Predictively render opponents on client using *dead reckoning*. Reconcile with actual positions when they arrive from the server.
* [ ] Push holes in snake from server to client
* [ ] Introduce game instances to server to handle multiple ongoing games
* [ ] Start a game after 6 players have joined OR 2+ players have joined AND it has passed 25 seconds since the 2nd player joined. Whichever comes first.
* [ ] Private games with secret code or URL
* [ ] Optimise server to client data traffic. 
	- [x] Send only new positions since last serverUpdate
	- [ ] Only send game.gamearea if it has changed
	- [x] Dont send game.mode
	- [x] Dont send game.player.leftKey
	- [x] Dont send game.player.rightKey
	- [x] Dont send game.player.keyDesc
	- [x] Dont send game.player.direction
	- [ ] Only send game.player.angle if it has changed
	- [ ] Only send game.player.alive if it has changed
	- [ ] Only send game.player.score if it has changed
	- [ ] Only send game.player.color if it has changed

## Bugs

* [x] First X no of positions are some times not rendered on client
* [x] Client doesnt clean up fake positions
* [x] Client some times predictively render a position after round is over
* [x] Client some times doesnt render the last real position
* [ ] Client prediction is not very accurate. Off by ~0.5 points compared to server for a player moving straight.
* [ ] Intermittent - Game is not started when enough players have joined
* [ ] Opponents are not moving smoothly enough
* [ ] Client runs at a faster tick rate than server. (performance test server)

## Latency compensation - <https://developer.valvesoftware.com/wiki/Latency_Compensating_Methods_in_Client/Server_In-game_Protocol_Design_and_Optimization#Lag_Compensation>

1. Receive input (LEFT/RIGHT/STRAIGHT)
2. If nextState !== PLAY then do nothing
3. Rewind all snakes to Datetime.now() - RTT
4. Apply input to the snake
5. Run updatePlayer on rewinded snakes. Iterate until they are moved back into present time.
6. Done
