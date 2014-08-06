require "koala"
require "yaml"
config = YAML.load_file("/tmp/session.yml")
@oauth = Koala::Facebook::OAuth.new("666851166740481", "efa360c9db9c38c824d3b31b87b21b4e", "https://www.facebook.com/connect/login_success.html")
token =  @oauth.get_token_from_session_key(config["session_key"])
@rest = Koala::Facebook::API.new(token)
profile = @rest.get_object("me")
friends = @rest.get_connections("me", "friends")
feed = @rest.get_connections("me", "home")
p feed
