require 'hashie'

module Reader
  def read_version_index(data)
    json = Hashie::Mash.new JSON.parse(data, symbolize_names: true)

    index = VersionIndex.new json.uid
    index.name = json.name
    json.versions.each do |ver|
      v = Version.new
      v.is_complete = false
      v.uid = json.uid
      v.versionName = ver[:id] ? ver.id : ver.version
      v.versionId = ver[:id] ? ver.version : nil
      v.type = ver[:type]
      v.time = ver[:time]
      index.versions << v
    end

    return index
  end

  def read_library(json)
    lib = VersionLibrary.new
    lib.name = json.name
    lib.url = json.url
    lib.absoluteUrl = json.absoluteUrl
    lib.checksums = json.checksums
    lib.platforms = json.platforms
    lib.natives = json[:natives] if json[:natives]
    return lib
  end

  def read_version(data)
    json = Hashie::Mash.new JSON.parse(data)

    file = Version.new
    file.is_complete = true

    file.uid = json.uid
    file.versionId = json[:versionId] ? json.versionId : json.version
    file.versionName = json[:versionId] ? json.version : nil
    file.time = json.time
    file.type = json.type

    file.mainClass = json.mainClass
    file.appletClass = json.appletClass
    file.assets = json.assets
    file.minecraftArguments = json.minecraftArguments
    file.tweakers = json.tweakers
    file.requires = json.requires
    file.traits = json.traits ? json.traits : []

    file.libraries = []
    json.libraries.each do |lib|
      file.libraries << read_library(lib)
    end if json.libraries

    return file
  end

  def read_index(data)
    JSON.parse data, symbolize_names: true
  end
end

module Writer
  def write_version_index(index)
    json = {
        uid: index.uid,
        name: index.name,
        versions: []
    }
    index.versions.each do |ver|
      obj = nil
      if ver.versionName
        obj = {
            id: ver.versionName,
            version: ver.versionId
        }
      else
        obj = { id: ver.versionId }
      end
      obj[:type] = ver.type
      obj[:time] = ver.time
      obj[:releaseTime] = ver.time
      json[:versions] << obj
    end

    return JSON.pretty_generate json
  end

  def write_library(library)
    json = { name: library.name }
    json[:url] = library.url                 if library.url and library.url != ''
    json[:absoluteUrl] = library.absoluteUrl if library.absoluteUrl and library.absoluteUrl != ''
    json[:checksums] = library.checksums     if library.checksums and library.checksums != ''
    json[:platforms] = library.platforms     if library.platforms and library.platforms != VersionLibrary.possiblePlatforms
    json[:natives] = library.natives         if library.natives
    return json
  end

  def write_version(version)
    json = {
        uid: version.uid,
        versionId: version.versionId
    }

    json[:time] = version.time                             if version.time and version.time != ''
    json[:type] = version.type                             if version.type and version.type != ''

    json[:'+tweakers'] = version.tweakers                  if version.tweakers and not version.tweakers.empty?
    json[:requires] = version.requires                     if version.requires and not version.requires.empty?
    json[:'+libraries'] = version.libraries.reverse.map do |lib|
      js = write_library lib
      js['insert'] = 'prepend'
      js
    end if version.libraries
    # TODO versionName and versionId
    if version.versionName
      json[:version] = version.versionName
      json[:versionId] = version.versionId
    else
      json[:version] = version.versionId
      json[:versionId] = version.versionId
    end
    json[:mainClass] = version.mainClass                   if version.mainClass and version.mainClass != ''
    json[:appletClass] = version.appletClass               if version.appletClass and version.appletClass != ''
    json[:assets] = version.assets                         if version.assets and version.assets != ''
    json[:minecraftArguments] = version.minecraftArguments if version.minecraftArguments and version.minecraftArguments != ''
    json[:'+traits'] = version.traits                      if version.traits and not version.traits.empty?

    return JSON.pretty_generate json
  end

  def write_index(index)
    return JSON.pretty_generate index
  end
end

class RW
  include Writer
  include Reader
end
$rw = RW.new