docs = new Meteor.Collection 'docs'

cleanDocuments = ->
  docs.remove {
    owner: {$exists: no},
    dateCreated: $lte: moment().subtract(7, 'days').unix()
  }, (e,n) ->
    if e then console.log e
    console.log n+' anonymous documents \
    not updated by more than 7 days have been removed'

Meteor.startup ->
  cleanDocuments()
  Meteor.setInterval cleanDocuments, 3600000

validatedUser = (uid) ->
  return no unless Meteor.users.findOne uid
  u = Meteor.users.findOne uid
  return yes for mail in u.emails when mail.verified is yes; no

Meteor.publish 'doc', (id) -> docs.find {_id: id}, limit: 1
Meteor.publish 'docs', (userId) ->
  if userId? then docs.find {owner: userId}, fields: text: 0
  else docs.find {}, fields: text: 0
Meteor.publish 'user', ->
  if @userId
    Meteor.users.find {_id: @userId}, fields: {dateCreated: 1}
  else @ready()

docs.allow
  insert: (uid,doc) ->
    if doc.text and doc.title
      doc.dateCreated = moment().unix()
      doc.showTitle ?= yes
      if doc.owner and !uid then return no
      if uid then doc.owner = uid
      return yes
    return no
docs.allow
  # Owners can update and remove their documents
  update: (uid,doc) ->
    return no unless uid is doc.owner
    docs.update doc._id, $set: lastModified: moment().unix()
    return yes
  remove: (uid,doc) -> doc.owner is uid
  fetch: ['owner']

# Save account creation date
