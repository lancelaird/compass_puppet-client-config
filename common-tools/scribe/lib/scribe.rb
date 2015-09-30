require 'yaml'
require 'nokogiri'
require 'active_support/all'

class Scribe
  def ensure_presence_of statement
    @statement = statement

    self
  end

  def compassin_hiera file_location
    orignal_content = YAML::load_file(file_location)

    write file_location, orignal_content.deep_merge('compass::packages' => @statement).to_yaml
  end

  def in_hiera file_location
    orignal_content = YAML::load_file(file_location)

    write file_location, orignal_content.deep_merge('packages' => @statement).to_yaml
  end

  def in_nolio file_location
    artifact = nil

    doc = xml_from(file_location)

    required_pattern = pattern_from(artifact_name_from(@statement['url']))

    doc.css("release>server-type>artifact").each do | node |
      if artifact_name_from(node['url']) =~ required_pattern
        artifact = doc.at_css(node.css_path)
        break
      end
    end

    if artifact.nil?
      artifact = doc.create_element 'artifact'
      doc.css("release>server-type>artifact").after(artifact)
    end

    artifact['url'] = @statement['url']
    artifact['md5'] = @statement['md5']

    write file_location, doc.to_xml(:indent => 2)
  end

  def update_nolio config_xml, values
    doc = xml_from(config_xml)

    doc.root['name']    = values[:release_name]    unless values[:release_name].empty?
    doc.root['version'] = values[:release_version] unless values[:release_version].empty?

    write config_xml, doc.to_xml(:indent => 2)
  end


  private

  def xml_from file_location
    # http://blog.slashpoundbang.com/post/1454850669/how-to-pretty-print-xml-with-nokogiri
    doc = Nokogiri::XML(File.read(file_location)) do | config |
      config.default_xml.noblanks
    end

    doc
  end

  def write location, content
    File.open(location, 'w') do |f|
      f.write content
    end
  end

  def pattern_from artifact_name
    pattern = Regexp.escape(artifact_name).gsub(/[\d]+/, '\d+')
    #Special case for Eikonmon zip where version can be either 3 or 4 digits and should only have one artifact entry
    pattern.gsub!(/Eikonmon\\-.*\.zip/,'Eikonmon\\-.*\.zip')
    Regexp.new pattern
  end

  def artifact_name_from url
    url.rpartition('/').last
  end
end
