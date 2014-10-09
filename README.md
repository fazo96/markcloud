# MarkCloud
Create a markdown document then share it with the world with a permanent link.

### Try it

MarkCloud is [hosted online](http://markcloud.meteor.com).

### Development

Clone the repository, make sure you installed [Meteor](http://meteor.com) then
run `meteor` in the project folder. Yep, that's it.

If you want to set up a server, make sure to configure the `MAIL_URL`
and `ROOT_URL` environment variables as explained in the
[Meteor Docs](http://docs.meteor.com).

You'll probably also need [phantomjs](http://phantomjs.org/) installed
since the apps now depends on Meteor's
[spiderable](http://docs.meteor.com/#spiderable) package.

#### Twitter Authentication

Create this file: `server/settings.coffee` with this content:

```coffeescript
Meteor.startup ->
  Accounts.loginServiceConfiguration.remove service : 'twitter'
  Accounts.loginServiceConfiguration.insert
    service: 'twitter'
    consumerKey: 'Your API key'
    secret: 'Your API secret'
```

Your users will now be able to login using twitter. You may want to disable the
button if you don't configure twitter authentication.

## License

The MIT License (MIT)

Copyright (c) 2014 Enrico Fasoli (fazo96)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
