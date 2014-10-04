docs = new Meteor.Collection 'docs'

validatedUser = (uid) ->
  return no unless Meteor.users.findOne uid
  u = Meteor.users.findOne uid
  return yes for mail in u.emails when mail.verified is yes; no

Meteor.publish 'doc', (id) -> docs.find {_id: id}, limit: 1
Meteor.publish 'docs', -> docs.find {}, fields: text: 0
Meteor.publish 'user', ->
  if @userId
    docs.find {_id:@userId}, fields: {dateCreated: 1}
  else @ready()

docs.allow
  insert: (uid,doc) ->
    return no unless doc.text and doc.title
    if uid then doc.owner = uid; return yes
    else if doc.owner then return no
  # Owners can update and remove their documents
  update: (uid,doc) -> doc.owner is uid
  remove: (uid,doc) -> doc.owner is uid
  fetch: ['owner'] # Only fetch the owner field from the database documents

# Save account creation date
