require_relative 'base_version_list'
require 'zip'

class FMLVersionList < BaseVersionList
  def initialize
    super('net.minecraftforge.fml')
    @input = ForgeInstallerProfileInput.new('net.minecraftforge.fml')
  end

  def get_versions
    result = BaseVersionList.get_json 'http://files.minecraftforge.net/maven/net/minecraftforge/fml/json'

    out = {}
    result[:number].values.each do |obj|
      out[obj[:build]] = obj.merge({
                                       artifact: result[:artifact],
                                       baseurl: result[:webpath]
                                   })
    end
    return out
  end

  def get_version(id)
    version = id[1][:mcversion] + '-' + id[1][:version]
    version += '-' + id[1][:branch] unless id[1][:branch].nil?

    result = []

    files = id[1][:files]
    installerFile = files.find do |file| file[1] == 'installer' end
    # installer versions of forge
    if not installerFile.nil? and id[1][:mcversion] != '1.5.2'
      path = version + '/' + id[1][:artifact] + '-' + version + '-' + installerFile[1] + '.' + installerFile[0]
      url = id[1][:baseurl] + '/' + path
      HTTPCatcher.get url, 'forgeinstallers/' + path
      arch = Zip::File.open 'cache/network/forgeinstallers/' + path do |jarfile|
        result << @input.parse(jarfile.glob('install_profile.json').first.get_input_stream.read, id[1][:version])
      end
    else
      # non-installer versions of forge
    end
    return result
  end
end