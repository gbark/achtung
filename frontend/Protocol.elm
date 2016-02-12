module Protocol where


import SocketIO


socket : Task x SocketIO.Socket
socket =
    SocketIO.io "http://localhost:9000" SocketIO.defaultOptions