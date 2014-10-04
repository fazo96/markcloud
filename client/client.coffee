docs = new Meteor.Collection 'docs'

Router.configure
  layoutTemplate: 'layout'

Router.map ->
  @route 'home', path: '/'
  @route 'doc',
    path: '/d/:_id'
    layoutTemplate: 'docLayout'
    waitOn: -> @docHandle = Meteor.subscribe 'doc', @params._id
    data: -> docs.findOne @params._id
  @route 'new'

Template.new.events
  'click #new-btn': (e,t) ->
    id = docs.insert
      text: t.find('#editor').value
    if id?
      Router.go 'doc', _id: id
