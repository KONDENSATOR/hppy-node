hppy = require '../'
fs   = require 'fs'
_    = require 'underscore'

myfunc = eval hppy (fileName) ->
  fs.readFile fileName, 'utf8', cont 'myfunc', 'readfile', (data) ->
    ret data

myfunc 'testfile', (err, data) ->
  if err?

    # Error management for GUI users
    if _.contains err.id, 'myfunc'
      console.log "Error in myfunc"

    if _.contains err.id, 'readfile'
      console.log "Could not read file"

    else
      console.log "No handler defined for error id #{err.id}"

    # Log output for system administrators
    console.error err
  else
    console.log "No errors"
    console.log data

