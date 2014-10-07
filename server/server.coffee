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
  return yes for mail in u.emails when mail.verified is yes; no

Meteor.publish 'doc', (id) -> docs.find {_id: id}, limit: 1
Meteor.publish 'docs', (userId) ->
  if userId?
    if userId is @userId
      docs.find {owner: userId}, fields: text: 0
    else docs.find {owner: userId, public: yes}, fields: text: 0
  else docs.find {}, fields: text: 0
Meteor.publish 'user', (id) ->
  if @userId is id
    Meteor.users.find id, fields: {username: 1, emails: 1}
  else Meteor.users.find id, fields: {username: 1}

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
