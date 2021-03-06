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
  u = Meteor.users.findOne uid
  return no unless u
  return yes if u.services.twitter
  return yes for mail in u.emails when mail.verified is yes; no

Meteor.publish 'doc', (id) -> docs.find {_id: id}, limit: 1
Meteor.publish 'docs', (owner) ->
  if owner?
    u = Meteor.users.findOne username: owner
    if @userId and Meteor.users.findOne(@userId)._id is u._id
      docs.find {owner: u._id}, fields: text: 0
    else docs.find {owner: u._id, public: yes}, fields: text: 0
  else docs.find {}, fields: text: 0
Meteor.publish 'user', (name) ->
  if !name?
    u = Meteor.users.findOne @userId
    if u then name = u.username
  return @ready() unless name?
  if u and u.username is name
    Meteor.users.find {username: name},
    fields: { username: 1, emails: 1, profile: 1 }
  else Meteor.users.find {username: name}, fields: { username : 1, profile: 1 }

docs.allow
  insert: (uid,doc) ->
    return no if uid and !validatedUser(uid)
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
    return no if uid and !validatedUser(uid)
    return no unless uid is doc.owner
    docs.update doc._id, $set: lastModified: moment().unix()
    return yes
  remove: (uid,doc) -> doc.owner is uid
  fetch: ['owner','emails']

Meteor.methods
  'deleteMe': ->
    if @userId
      Meteor.users.remove @userId
      docs.remove owner: @userId
  'amIValid': -> validatedUser @userId
  'sendVerificationEmail': ->
    if @userId and not validatedUser @userId
      Accounts.sendVerificationEmail @userId
      return 'email sent'
    else return 'could not send email'
