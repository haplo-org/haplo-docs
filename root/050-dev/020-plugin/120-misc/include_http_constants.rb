
Documentation.after_load do
  File.open("#{ENV['HAPLO_ROOT']}/lib/javascript/lib/constants.js") do |file|
    constants = file.read()
    raise "Can't find HTTP constants" unless constants =~ /var HTTP = ({[^}]+})/
    json = $1
    json.gsub!(/\/\/[^\n]*/,'') # remove comment
    json.gsub!(/([A-Z_]+)/,'"\\1"') # turn into JSON syntax
    constants = JSON.parse(json)

    # Make table
    textile = %Q!\n\n|*Constant name*|*Value*|\n!
    last_code = 0
    constants.each do |key, value|
      raise "bad k/v order" unless value > last_code
      last_code = value
      textile << %Q!|HTTP.#{key}|#{value}|\n!
    end

    # Append to page
    node = Documentation.get_node('dev/plugin/misc/http')
    raise "Can't find node for http constants" unless node != nil
    node.append_textile(textile)
  end
end
