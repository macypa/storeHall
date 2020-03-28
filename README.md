# StoreHall

General install guide:
https://gist.github.com/beaorn/7b90a21b7e80e7744d8d2d08e49efcee

To install Erlang and Elixir:
  https://lobotuerto.com/blog/how-to-install-elixir-in-manjaro-linux/
  https://gist.github.com/rubencaro/6a28138a40e629b06470

To install Phoenix:
  https://medium.com/@rpw952/elixir-development-on-windows-10-ff7ca03769d

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server` in root dir

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).
To update assets run:
npm run deploy --prefix ./assets/
MIX_ENV=prod mix phx.digest

to start psql:
'psql -U postgres'
'sudo -u postgres psql' for linux
'\password' - to change the password before running mix ecto.setup
'\l' - list databases
'\dt' - display tables when connected to database
'\c storehall_dev' - connect to storehall_dev database
"SET CLIENT_ENCODING TO 'utf-8';" - change client encoding

Install imagemagick on unix
https://linuxconfig.org/how-to-install-imagemagick-7-on-ubuntu-18-04-linux

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk


List of technologies that could be useful:
https://letsencrypt.org/getting-started/  to configure on linux https://medium.com/@a4word/phoenix-app-secured-with-let-s-encrypt-469ac0995775
https://github.com/annkissam/rummage_phoenix or https://github.com/duffelhq/paginator
https://tg.pl/drab
https://github.com/nico-amsterdam/phoenix_form_awesomplete
https://select2.org/getting-started/basic-usage
https://jqueryui.com/
