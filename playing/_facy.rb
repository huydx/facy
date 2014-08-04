%w(  
  koala
).each { |lib| require lib }

token = "666851166740481|VfThRE5Qraib9yhri8BLoSpE6pc"
rest = Koala::Facebook::RestAPI.new(token)

arg_hash = {auth_token: "USZ58X"}
p rest.rest_call("auth.getSession", arg_hash)

arg_hash2 = {
  session_key: "4.0.6306c9757b97fdbf03f40baf.0-Aa6xpjz8WnTnGDEkASNv17Q05Go",
  uid: "10152386579729219"
}

p rest.rest_call("stream.get", arg_hash2).first[1].each { |m| p m["message"] + "\n" }
