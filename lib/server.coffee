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

express = require('express')
nroonga = require('nroonga')

exports.createServer = (config={}) ->
  db = if config.dbPath?
    new nroonga.Database(config.dbPath)
  else
    new nroonga.Database()

  app = express.createServer()

  if config.verbose?
    app.use express.logger()

  if config.documentRoot?
    app.use express.static(config.documentRoot)

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
  app
