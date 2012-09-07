# Nanoc::Sftp

An SFTP-only deploy script for nanoc

## Installation

Add this line to your application's Gemfile:

    gem 'nanoc-sftp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nanoc-sftp

## Usage

In the `deploy:` area of your configu.yalm file,
change the target similar to this:

    staging:
      kind: sftp
      user: "account)name"
      host: "your_server"
      path: "/target/server/dir"
      port: 1337

Specifying the port is optional; it will use
the standard port `22/tcp` if you leave it out, which is
likely to work most of the time.

Then, simply run:

$ nanoc deploy --target staging

You will be prompted for missing credentials, such
as the password, as necessary.


## Copyright

Copyright (c) 2012 Brent Sanders

See LICENSE.txt for details.

