require 'rubygems'
require 'nokogiri'

class FIXDictionary
  def self.load filename
    parser = FIXDictionary.new Nokogiri::XML( open filename )
    parser.parse
    parser
  end
  
  attr_reader :fields, :messages
  def initialize doc
    @doc = doc
  end
  
  def parse
    @fields = load_fields
    @messages = create_messages
  end

  def msg_by_type msg_type
    @messages.select { |msg| msg[:msgtype] == msg_type }.pop
  end

  def fld_by_tag tag
    @fields.values.select {|fld| fld[:tag] == tag}.pop
  end

  def fld_by_name name
    @fields[name]
  end
  
  def field_value fld_name, val
    fld = fld_by_name(fld_name.to_s)
    raise "Field not found: #{fld_name}" if fld.nil?
    fld[:values].select { |v| v[:enum] == val.to_s }.pop
  end
  
  def field_enum fld_name, desc
    fld = fld_by_name(fld_name.to_s)
    raise "Field not found: #{fld_name}" if fld.nil?
    fld[:values].select { |v| v[:desc] == desc.to_s }.pop
  end

  private
    
  def load_fields
    @fields = {}
    @doc.xpath( '//fields/field' ).each { |field| add_field( field ) }
    @fields
  end
    
  def add_field(fld_el)
    fld_name = fld_el['name']
    fld = { :fldtype=>fld_el['type'], :name=>fld_name, :tag=>fld_el['number'].to_i }
    values = fld_el.xpath('.//value').map { |val| {:enum=>val['enum'], :desc=>val['description']} }
    fld[:values] = values unless values.empty?
    @fields[fld_name] = fld
  end
  
  def create_messages
    @doc.xpath( '//messages/message' ).map { |msg| new_msg( msg ) }
  end
    
  def headerel
    @headerel ||= @doc.xpath( '//header' ).pop
  end
  
  def trailerel
    @trailerel ||= @doc.xpath( '//trailer' ).pop
  end
  
  def new_msg( msgel )
    name = msgel['name']
    msg = { :name=>name, :msgtype=>msgel['msgtype'], :fields=>[], :groups=>[] }
    parse_element( headerel, msg, true, false ) unless headerel.nil?
    parse_element( msgel, msg )
    parse_element( trailerel, msg, false, true ) unless trailerel.nil?
    msg
  end
  
  def parse_element( el, fixel, header=false, trailer=false )
    el.children.each do |child|
      next unless child.element?
      cname = child['name']
      
      case child.node_name
        when 'field'
          raise "field not found! #{cname}" unless @fields.include?(cname)
          fixel[:fields] << @fields[cname]
      
        when 'group'
          grp = {:name=>cname, :fields=>[], :groups=>[]}
          parse_element(child, grp, header, trailer )
          
        when 'component'
          component_el = @doc.xpath("//components/component[@name='#{cname}']")
          parse_element component_el, fixel, header, trailer
      end
    end
  end  
end