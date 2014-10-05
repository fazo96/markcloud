# Homework - Server side accounts code

# Regular Expression to see if an email can be valid
validateEmail = (email) ->
  x = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/
  x.test email

Accounts.config {
  sendVerificationEmail: true
  loginExpirationInDays: 5
}

# Code that checks if a new user request is valid
Accounts.validateNewUser (user) ->
  user.dateCreated = moment().unix()
  mail = user.emails[0].address
  if Match.test(mail,String) is no or validateEmail(mail) is no
    throw new Meteor.Error 403, "Invalid Email"
  return yes

# Email configuration code
Accounts.emailTemplates.siteName = "MarkCloud"
Accounts.emailTemplates.verifyEmail.text = (user,url) ->
  urlist = url.split('/'); token = urlist[urlist.length-1]
  url = Meteor.absoluteUrl 'verify/'+token
  '''Welcome to MarkCloud! To activate your account, click on the \
  following link: '''+url