# Achtung (in Elm) – [Play!](http://gbark.github.io/achtung)

A browser based clone of **Achtung, die Kurve!** (also known as **Zatacka**) written in Elm.

![screenshot](screenshot.png)

## Run locally

Clone this repo and run using [elm-reactor](https://github.com/elm-lang/elm-reactor)

## Multiplayer Todo

* Predictively render Player
* Render Opponents at a 100ms delay to smoothen movements
* Introduce Game instances to server to handle multiple ongoing games
* Start a Game after 6 Players have joined OR 2+ Players have joined AND it 
has passed 30 seconds since the 2nd Player joined. Whichever comes first.
* Private Games with secret code or URL
* Optimise server to client data traffic. 
	- Send only the new Player positions since last serverUpdate
	- Only send game.gamearea if it has changed
	- Dont send game.mode
	- Dont send game.player.leftKey
	- Dont send game.player.rightKey
	- Dont send game.player.keyDesc
	- Only send game.player.angle if it has changed
	- Only send game.player.direction if it has changed
	- Only send game.player.alive if it has changed
	- Only send game.player.score if it has changed
	- Only send game.player.color if it has changed