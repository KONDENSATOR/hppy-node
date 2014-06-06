esprima    = require 'esprima'
escodegen  = require 'escodegen'
_          = require 'underscore'
util       = require 'util'

_.mixin clear: (obj) ->
  keys = _.keys obj
  delete obj[key] for key in keys

_.mixin replace: (current, other) ->
  _.clear current
  _.extend current, other

_.mixin inspect: (tree) ->
  console.log(util.inspect(tree, {colors:true, depth:null}))
  tree

traverse = (ast, fn) ->
  if ast.type == 'Program'
    ast.body = _(ast.body).map((child) ->
      traverse(child, fn))

  else if ast.type == 'MemberExpression'
  else if ast.type == 'Literal'
  else if ast.type == 'Identifier'
  else if ast.type == 'VariableDeclaration'

  else if ast.type == 'ExpressionStatement'
    ast.expression = traverse(ast.expression, fn)

  else if ast.type == 'AssignmentExpression'
    ast.right = traverse(ast.right, fn)

  else if ast.type == 'FunctionExpression'
    ast.body = traverse(ast.body, fn)

  else if ast.type == 'BlockStatement'
    ast.body = _(ast.body).map((child) ->
      traverse(child, fn))

  else if ast.type == 'CallExpression'
    ast.arguments = _(ast.arguments).map((child) ->
      traverse(child, fn))

  else if ast.type == 'ReturnStatement'
    ast.argument = traverse(ast.argument, fn)

  else if ast.type == 'IfStatement'
    ast.test = traverse(ast.test, fn)
    ast.consequent = traverse(ast.consequent, fn)
    if ast.alternate?
      ast.alternate = traverse(ast.alternate, fn)

  else if ast.type == 'BinaryExpression'
    ast.left = traverse(ast.left, fn)
    ast.right = traverse(ast.right, fn)

  fn(ast)

_.mixin traverse: traverse

macros = {}

define = (defines) ->
  macros = _(macros).extend(defines)

inspect = (fn) ->
  code = "a=#{fn.toString()}"
  _(esprima.parse(code)).inspect()

evaluate = (fn) ->
  code = "a=#{fn.toString()}"
  ast = _(esprima.parse(code)).traverse((node) ->
    if _(node.type).isEqual('CallExpression') and
       _(macros).has(node.callee.name)
      macros[node.callee.name](node)
    else
      node)
  ast.body = _(ast.body[0].expression.right.body.body).map((node) ->
    if node.type == "ReturnStatement"
      type: "ExpressionStatement"
      expression: node.argument
    else
      node
  )
  #_(ast).inspect()
  code = escodegen.generate(ast)
  console.log code
  code

evaluate.define = define
evaluate.inspect = inspect

module.exports = evaluate
