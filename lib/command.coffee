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

{spawn} = require('child_process')
optimist = require('optimist')
cluster = require('cluster')
nroongaHttpd = require('./server')

numCPUs = require('os').cpus().length

getGroongaDocumentRoot = (callback) ->
  pkgconfig = spawn 'pkg-config', ['--variable', 'document_root', 'groonga']
  buffer = ""
  pkgconfig.stdout.on 'data', (data) ->
    buffer += data
  pkgconfig.on 'exit', (code) ->
    if code == 0
      path = buffer.slice(0, -1)
      callback(path)
    else
      callback(null)

parseOptions = (callback) ->
  getGroongaDocumentRoot (groongaDocumentRoot) ->
    defaultDocumentRoot = groongaDocumentRoot || __dirname + '/public'
    opt = optimist
      .usage('groonga http server.\nUsage: $0')
      .options
        p:
          alias: 'port'
          integer: true
          default: 3000
        h:
          alias: 'help'
          describe: 'show this help'
        'document-root':
          describe: 'document root path'
          default: defaultDocumentRoot
        v:
          alias: 'verbose'
          describe: 'increase verbosity'
          default: false
        t:
          alias: 'workers'
          describe: 'number of workers'
          default: numCPUs
    callback(opt)

exports.run = ->
  parseOptions (opt) ->
    argv = opt.argv
    if cluster.isMaster
      if argv.help
        opt.showHelp()
        process.exit(0)
      else
        if argv.v
          console.log "Server listening at port #{argv.p} (#{argv.t} workers)."
          console.log "Document root is #{argv['document-root']}"

        for i in [0...argv.t]
          cluster.fork()
        cluster.on 'death', (worker) ->
          console.log "worker #{worker.pid} died"
    else
      app = nroongaHttpd.createServer
        dbPath: argv._[0]
        verbose: argv.v
        documentRoot: argv['document-root']
      app.listen(argv.p)
