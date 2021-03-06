Given /^the rest api is enabled$/ do
  Setting.rest_api_enabled = "1"
end

Given /^the following languages are available:$/ do |table|
  Setting.available_languages += table.raw.map(&:first)
end

#Given /^the "(.+?)" setting is set to (true|false)$/ do |name, trueish|
#  Setting[name.to_sym] = (trueish == "true" ? "1" : "0")
#end

Given /^the "(.+?)" setting is set to (.+)$/ do |name, value|
  value = case value
          when "true"
            "1"
          when "false"
            "0"
          else
            value
          end

  value = value.to_i if Setting.available_settings[name]["format"] == "int"

  Setting[name.to_sym] = value
end

Then /^the "(.+?)" setting should be (true|false)$/ do |name, trueish|
  Setting.send((name + "?").to_sym).should == (trueish == "true")
end
