expect = require('expect.js')
{spawn} = require('child_process')
http = require('http')

run = (options, callback) ->
  commandPath = __dirname + '/../bin/nroonga-httpd'
  command = spawn commandPath, options
  output = {stdout: '', stderr: ''}
  command.stdout.on 'data', (data) ->
    output.stdout += data
  command.stderr.on 'data', (data) ->
    output.stderr += data

  callback(null, command, output)

describe 'nroonga-httpd command', ->
  it 'should output help for --help', (done) ->
    run ['--help'], (error, command, output) ->
      command.on 'exit', ->
        expect(output.stderr).to.contain("Usage:")
        done()

  it 'should listen 3000/TCP as default', (done) ->
    run ['-v'], (error, command, output) ->
      buffer = ''
      command.stdout.on 'data', (data) ->
        buffer += data
        if buffer.match(/\n/g).length >= 2
          command.kill()
      command.on 'exit', ->
        expect(buffer).to.match(/Server listening at port 3000/)
        done()

  it 'should acts as groonga http server', (done) ->
    run [], (error, command, output) ->
      attempt = setInterval ->
        received = ''
        req = http.request {
          host: 'localhost'
          port: 3000
          path: '/d/status'
          method: 'GET'
        }, (res) ->
          clearInterval(attempt)
          expect(res.statusCode).to.eql(200)
          command.kill()
          done()
        req.end()
      , 100
