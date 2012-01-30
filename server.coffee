express = require('express')
nroonga = require('nroonga')
opt = require('optimist')
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
      default: __dirname + '/public'
argv = opt.argv

if argv.help
  opt.showHelp()
  process.exit(0)

dbPath = argv._[0]
db = if dbPath?
  new nroonga.Database(dbPath)
else
  new nroonga.Database()

app = express.createServer()
app.use express.logger()
app.use express.static(argv['document-root'])

app.get '/d/:command', (req, res) ->
  startAt = new Date()
  db.command req.params.command, req.query, (error, data) ->
    doneAt = new Date()
    duration = startAt - doneAt
    if error?
      console.log(error)
      res.send([[-1, startAt, duration, error.toString(), []]], 500)
    else
      res.send([[0, startAt, duration], data])

app.listen(argv.p)
console.log "Server listening at port #{argv.p}."
