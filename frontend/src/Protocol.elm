module Protocol where


import SocketIO
import Task exposing (Task)


type SocketStatus = Connecting
                  | Connected
                  | Disconnected


socket : Task x SocketIO.Socket
socket =
    SocketIO.io "http://localhost:9000" SocketIO.defaultOptions