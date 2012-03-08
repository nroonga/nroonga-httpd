###
Copyright (C) 2012  Yoji Shidara <dara@shidara.net>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
###

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
