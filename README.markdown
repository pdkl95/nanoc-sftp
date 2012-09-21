nanoc-sftp
===========

A deploy script for [nanoc](http://nanoc.stoneship.org/),
that uses only SFTP to talk to the server.

**NOTE:** this is unfinished, and currently requires you to have
[yad](http://code.google.com/p/yad/) installed for some things
that will hopefully be made optional in the future.


Installation
------------

Add this line to your application's Gemfile:

```bash
gem 'nanoc-sftp'
```

And then run:

```bash
bundle
```

Or install it yourself with:

```bash
gem install nanoc-sftp
```

Usage
-----

This is still broken, due to what may be a bug in nanoc.
Currently, the only way to guarantee that this gem is loaded
soon enough is to patch one of the loaders for the `nanoc` tool
itself.

For example, if you add the above `gem 'nanoc-sftp'` line to your
`Gemfile`, run the gem bundler to install local binstubs:

```bash
gem install --binstubs
```
    
Then, patch the file `bin/nanoc` to include the line
'require 'nanoc/sftp'` **before** the main program is loaded. For
example, it should end up looking something like this:

```ruby
require 'pathname'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path("../../Gemfile",
  Pathname.new(__FILE__).realpath)

require 'rubygems'
require 'bundler/setup'

require 'nanoc'
require 'nanoc/sftp'

load Gem.bin_path('nanoc', 'nanoc')
```

Then, you will need to run nanoc through both this binstub loader AND
the bunder environment:

```bash
bundle exec ./bin/nanoc deploy --target staging
```

For the moment, I suggest setting up a simple alias in your shell
to wrap this up. This will create such an alias for you. (you may need
to modify it slightly if your aliases are not stored in `~/.bash_aliases`

```bash
echo 'alias nanoc_deploy_staging="bundle exec ./bin/nanoc deploy --target staging"' >> "${HOME}/.bash_aliases"
```

Hopefully, a better solution will happen soon-ish.

Configuration
-------------

The deployment settings are listed in your `config.yaml` file.
If you wanted to deploy to `myusername@server.example.com`, using
the non-standard SFTP port `1337`, into the remote directory
`/foo/bar`, it would look like this:

```yaml
deploy:
  staging:
    kind: sftp
    user: "myusername"
    host: "server.example.com"
    port: 1337
    path: "/foo/bar"
```

You can leave out the `port:` line to use the standard 
SFTP port.

You will be prompted for the password each time the deploy
script is found, if the authentication isn't handled automagically
by a pre-shared key, etc.

Requirements
------------

Because of a personal need, this gem currently relies
on the utility `[yad](http://code.google.com/p/yad/)` which
implements a simple GUI.

This currently is used to provide a login prompt and a
verification step before overwriting files. I intend to make
this optional in the future, but right now it's required
that the `yad` binary be somewhere in your `$PATH`.

Copyright
---------

Copyright (c) 2012 Brent Sanders

See LICENSE.txt for details.



