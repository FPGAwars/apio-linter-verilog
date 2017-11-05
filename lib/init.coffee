{ CompositeDisposable } = require 'atom'
path = require 'path'
isWindows = Boolean(process.platform.indexOf('win32') > -1)

apioDir = () ->
  return path.join(process.env.HOME || process.env.USERPROFILE, '.apio')

packageDir = () ->
  return path.join(apioDir(), 'packages', 'toolchain-iverilog')

iverilog = () ->
  return path.join(packageDir(), 'bin', 'iverilog')

lint = (editor) ->
  helpers = require('atom-linter')
  regex = /((?:[A-Z]:)?[^:]+):([^:]+):(.+)/
  file = editor.getPath()
  dirname = path.dirname(file)

  args = ("#{arg}" for arg in atom.config.get('apio-linter-verilog.extraOptions'))
  if !isWindows then args = args.concat ['-B', path.join(packageDir(), 'lib', 'ivl')]
  args = args.concat ['-t', 'null', '-I', dirname,  file]
  helpers.exec(iverilog(), args, {stream: 'both'}).then (output) ->
    lines = output.stderr.split("\n")
    messages = []
    for line in lines
      if line.length == 0
        continue;

      # console.log(line)
      parts = line.match(regex)
      if !parts || parts.length != 4
        # console.debug("Droping line:", line)
      else
        message =
          filePath: parts[1].trim()
          range: helpers.rangeFromLineNumber(editor, parseInt(parts[2])-1, 0)
          type: 'Error'
          text: parts[3].trim()

        messages.push(message)

    return messages

module.exports =
  config:
    extraOptions:
      type: 'array'
      default: []
      description: 'Comma separated list of iverilog options'
  activate: ->
    require('atom-package-deps').install('apio-linter-verilog')

  provideLinter: ->
    provider =
      grammarScopes: ['source.verilog']
      scope: 'project'
      lintOnFly: false
      name: 'Verilog'
      lint: (editor) => lint(editor)
