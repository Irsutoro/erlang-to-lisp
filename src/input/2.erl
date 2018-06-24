-module(helloworld).
-export([start/0]).

sayhello() ->
    io:format("Hello")

start() ->
    sayhello()