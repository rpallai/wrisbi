class Transaction < ActiveResource::Base
  self.site = YAML.load(open("config/wrisbi.yml").read)['site']
  self.user = YAML.load(open("config/wrisbi.yml").read)['login']
  self.password = YAML.load(open("config/wrisbi.yml").read)['password']
end
