docs = new Meteor.Collection 'docs'

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
      if doc.owner and !uid then return no
      if uid then doc.owner = uid
      console.log doc.dateCreated
      return yes
    return no
docs.allow
  # Owners can update and remove their documents
  update: (uid,doc) -> doc.owner is uid
  remove: (uid,doc) -> doc.owner is uid
  fetch: ['owner'] # Only fetch the owner field from the database documents

# Save account creation date
