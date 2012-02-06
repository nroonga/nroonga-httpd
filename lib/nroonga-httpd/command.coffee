express = require('express')
nroonga = require('nroonga')
{spawn} = require('child_process')
optimist = require('optimist')
cluster = require('cluster')

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
  if cluster.isMaster
    parseOptions (opt) ->
      argv = opt.argv
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
    parseOptions (opt) ->
      argv = opt.argv
      dbPath = argv._[0]
      db = if dbPath?
        new nroonga.Database(dbPath)
      else
        new nroonga.Database()

      app = express.createServer()

      if argv.v
        app.use express.logger()

      app.use express.static(argv['document-root'])

      app.get '/d/:command', (req, res) ->
        startAt = (new Date()).getTime() / 1000
        db.command req.params.command, req.query, (error, data) ->
          doneAt = (new Date()).getTime() / 1000
          duration = doneAt - startAt
          if error?
            console.log(error)
            res.send([[-1, startAt, duration, error.toString(), []]], 500)
          else
            res.send([[0, startAt, duration], data])

      app.listen(argv.p)
