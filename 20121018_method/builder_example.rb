require 'builder'

xml = Builder::XmlMarkup.new(:target=>STDOUT, :indent=>2)

xml.coder {
  xml.name 'まつもとゆきひろ', nickname => 'Matz'
  xml.language 'Ruby'
}

# => 
# <coder>
#   <name nickname="Matz">まつもとゆきひろ</name>
#   <language>Ruby</language>
# </coder>
