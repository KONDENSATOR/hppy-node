hppy = require '../'
fs   = require 'fs'
_    = require 'underscore'

HPPY_CALLBACK_NAME = "hppy_callback"
HPPY_ERROR_NAME = "hppy_error"

NULLARG =
  type: 'Literal'
  value: null
  raw: 'null'
ERRORARG =
  type: 'Identifier'
  name: HPPY_ERROR_NAME
CALLBACKARG =
  type: 'Identifier'
  name: HPPY_CALLBACK_NAME

hppy.define(
  cps: (ast) ->
    # Get the real function from the last argument of CPS
    f = _(ast.arguments).last()
    # Push the callback template parameter to the function arguments
    f.params.push(CALLBACKARG)
    # Return the modified function
    f

  cont: (ast) ->
    console.log("CONT")
    _(ast).inspect()
    # Get the real function from the last argument of CPS
    f = _(ast.arguments).last()
    # Push the callback template parameter to the function arguments
    f.params.unshift(ERRORARG)
    # Return the modified function
    body = f.body.body
    f.body.body = [ {
      type: 'IfStatement'
      test: {
        type: 'BinaryExpression'
        operator: '!='
        left: { type: 'Identifier', name: HPPY_ERROR_NAME }
        right: { type: 'Literal', value: null, raw: 'null' } }
      consequent: {
        type: 'BlockStatement'
        body: [ {
          type: 'ReturnStatement'
          argument: {
            type: 'CallExpression'
            callee: { type: 'Identifier', name: HPPY_CALLBACK_NAME }
            arguments: [ { type: 'Identifier', name: HPPY_ERROR_NAME } ] } } ] }
      alternate: {
        type: 'BlockStatement'
        body: body
      } } ]
    f

  ret: (ast) ->
    # Clone the ret arguments
    args = ast.arguments.slice()
    # Add a NULL template in the begining
    args.unshift(NULLARG)

    # Return new AST node
    type      : 'CallExpression'
    arguments : args
    callee    :
      type    : 'Identifier'
      name    : HPPY_CALLBACK_NAME

  err: (ast) ->
    ast.callee.name = HPPY_CALLBACK_NAME
    console.log("ERR")
    _(ast).inspect())

console.log "================ TEMPLATE  =============="
hppy.inspect(() ->
  myfunc = (fileName, cb) ->
    fs.readFile(fileName, 'utf8', (err, data) ->
      if err?
        cb(err)
      else
        cb(null, data)))

console.log "================ PRODUCT  =============="

eval(hppy(() ->
  myfunc = cps((fileName) ->
    fs.readFile(fileName, 'utf8', cont('myfunc', 'readfile', (data) ->
      if data.length == 0
        err("File empty!")
      else
        ret(data))))

  add = () -> 1 + 1

  add()

  myfunc('testfile', (err, data) ->
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
      console.log data)))
