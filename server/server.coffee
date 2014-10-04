docs = new Meteor.Collection 'docs'

Meteor.publish 'doc', (id) -> docs.find _id: id

docs.allow
  insert: -> yes
  update: -> no
  remove: -> no
