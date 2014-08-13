require "koala"
require "yaml"
config = YAML.load_file("/tmp/_facy_session.yml")
@oauth = Koala::Facebook::OAuth.new("666851166740481", "efa360c9db9c38c824d3b31b87b21b4e", "https://www.facebook.com/connect/login_success.html")
token =  @oauth.get_token_from_session_key(config["session_key"])
@rest = Koala::Facebook::API.new(token)
p @oauth.url_for_oauth_code(:permissions => "publish_stream", :state => "RANDOMSTRING")

profile = @rest.get_object("me")
friends = @rest.get_connections("me", "friends")
ret = @rest.put_wall_post "21785951839_10152581462351840"
p ret
