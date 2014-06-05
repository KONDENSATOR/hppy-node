esprima    = require 'esprima'
escodegen  = require 'escodegen'
_          = require 'underscore'
astral     = require('astral')()
astralPass = require('astral-pass')

_.mixin clear: (obj) ->
  keys = _.keys obj
  delete obj[key] for key in keys

_.mixin replace: (current, other) ->
  _.clear current
  _.extend current, other

_.mixin putt: (tree) ->
  console.log(JSON.stringify(tree, null, 2))

codeIfErr = (decorations) ->
  type: "IfStatement"
  test:
    type: "LogicalExpression"
    operator: "&&"
    left:
      type: "BinaryExpression"
      operator: "!=="
      left:
        type: "UnaryExpression"
        operator: "typeof"
        argument:
          type: "Identifier"
          name: "err"
        prefix: true
      right:
        type: "Literal"
        value: "undefined"
    right:
      type: "BinaryExpression"
      operator: "!=="
      left:
        type: "Identifier"
        name: "err"
      right:
        type: "Literal"
        value: null
  consequent:
    type: "BlockStatement"
    body: [
        type: "ReturnStatement"
        argument:
          type: "CallExpression"
          callee:
            type: "Identifier"
            name: "fncallback"
          arguments: [
            type: "ObjectExpression"
            properties: [
                type: "Property"
                key:
                  type: "Identifier"
                  name: "id"
                value:
                  type: "ArrayExpression"
                  elements: decorations
                kind: "init"
              ,
                type: "Property"
                key:
                  type: "Identifier"
                  name: "err"
                value:
                  type: "Identifier"
                  name: "err"
                kind: "init"
            ]
          ]
    ]
  alternate: null

nullArgument =
  type: 'Literal'
  value: null

asyncFunctionPass = astralPass()
asyncFunctionPass.name = "asyncFunctionPass"
callbackPass = astralPass()
callbackPass.name = "callbackPass"
returnPass = astralPass()
returnPass.name = "returnPass"

asyncFunctionPass.when(
  type: "AssignmentExpression"
  operator: "="
  left:
    type: "Identifier"
    name: "a"
  right:
    type: "FunctionExpression"
).do (chunk, info) ->
  chunk.right.params.push {type:"Identifier", name:"fncallback"}
  chunk

callbackPass.when(
  type : "CallExpression"
  callee :
    type : "Identifier"
    name : "cont"
).do (chunk, info) ->
  fun    = chunk.arguments.pop()
  fun.params.unshift {type:"Identifier",name:"err"}
  fun.body.body.unshift codeIfErr(chunk.arguments)

  _.replace chunk, fun

returnPass.when(
  type: "ReturnStatement"
  argument:
    type: "CallExpression"
    callee:
      type: "Identifier"
      name: "ret"
).when(
  type: "ReturnStatement"
  argument:
    type: "CallExpression"
    callee:
      type: "Identifier"
      name: "err"
).do (chunk, info) ->
  if chunk.argument.callee.name == "ret"
    chunk.argument.arguments.unshift(nullArgument)
  chunk.argument.callee.name = "fncallback"

astral.register asyncFunctionPass
astral.register callbackPass
astral.register returnPass

module.exports = (fn) ->
  code = "a=#{fn.toString()}"
  tree = esprima.parse(code)
  tree = astral.run(tree)
  escodegen.generate tree
