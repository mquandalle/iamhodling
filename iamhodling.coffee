@Votes = new Meteor.Collection "votes"

if Meteor.isServer
  Meteor.methods
    'myVote': ->
      ip = @connection.clientAddress
      Votes.findOne(votesIp: ip)?._id

    'vote': (id) ->
      ip = @connection.clientAddress
      unless Votes.findOne(votesIp: ip)?
        Votes.update _id: id,
          $inc: score: 1
          $push: votesIp: ip

  # Bootstrap ranges
  Meteor.startup ->
    if Votes.find().count() == 0
      _.range(12).forEach (i) ->
        Votes.insert
          _id: i.toString()
          score: 0
          votesIp: []

  # Publish ranges and results
  Meteor.publish 'votes', ->
    Votes.find {},
      fields: score: 1
      sort: _id: 1

if Meteor.isClient
  Meteor.subscribe 'votes'

  Meteor.call 'myVote', (err, res) ->
    Session.set 'myVote', res

  Deps.autorun ->
    Session.set 'totalVotes',
      _.reduce Votes.find().fetch(), ((a, b) -> a + b.score), 0

  formatPrice = (index) -> "$#{index*100}"

  UI.body.helpers
    votes: ->
      Votes.find()

    instruction: ->
      unless Session.get('myVote')?
        "Click to vote"

    cursor: ->
      if Session.get('myVote')? then "normal" else "pointer"

    barWidth: ->
      if Session.get('myVote')?
        @score / Session.get('totalVotes') * 100
      else
        100

    label: ->
      id = parseInt(@_id)
      formatPrice(id) + " - " + formatPrice(id+1)

  UI.body.events
    'click .range': ->
      Session.set 'myVote', @_id # Latency compensation
      Meteor.call 'vote', @_id
