require 'securerandom'

module HarvardAeon
  class ItemMapper < RequestListItemMapper

    include ManipulateNode

    def map_extensions(mapped, item, repository, resource, resource_json)
      mapped.record.name = mapped.record.name.split(',').uniq.join(',')
      #mapped.ext(:site).name = repo_field_for(repository, 'Site')
      # Populating the 'site' field causes issues for Aeon.
      mapped.ext(:site).name = ''
      mapped.ext(:location).name = repo_field_for(repository, 'Location')
      mapped.ext(:hollis).id = hollis_number_for(resource_json)
      mapped.ext(:physical_location).name = physical_location_for(item.class == Container ? resource_json : item['json'])
      mapped.collection.ext(:access_restrictions, access_restrictions_for(resource_json))
      mapped.record.ext(:access_restrictions, access_restrictions_for(item['json']))

      (item.class == Container ? resource_json : item['json'])['extents'].zip(mapped.extent.multi) do |e, me|
        me.ext(:container_summary, e['container_summary'])
        me.ext(:physical_details, e['physical_details'])
      end
      mapped.extent.ext(:container_summary, mapped.extent.multi.map {|e| e.ext(:container_summary)}.compact.join('; '))
      mapped.extent.ext(:physical_details, mapped.extent.multi.map {|e| e.ext(:physical_details)}.compact.join('; '))

      mapped.ext(:container_profile).name = top_container_name(item['json'])
      #mapped.ext(:container_profile_name) = top_container_name(item['json'])
      
      mapped.collection.ext(:resource_title, resource_title(resource_json))

      mapped.record.ext(:resource_title, resource_title(item['json']))


      containers_for(item).map do |c|
        mapped.container.multi.select {|m| m.uri == c['uri']}.map do |m|
          m.name = m.name.sub(/: .*$/, '')
          m.ext(:indicator, (c['sub_containers'] || []).map {|sc| sc['indicator_2']}.compact.join('; '))
          m.ext(:location, (c['location_display_string_u_sstr'] || []).join('; '))
        end
      end
   
      (@opts[:excluded_request_types] || []).map do |t|
        mapped.ext(:excluded_request_types).add.name = t
      end

      mapped.scrub! {|v| strip_mixed_content(v) }
    end

    def resource_title(item)

      out = item["display_string"] 

      if out.nil?
        out = item["title"]
      end

      out
    end

    def top_container_name(resource)

      # catch edge-case where resource is incomplete or malformed
      if resource.nil? || resource.key?('instances') == false
        return ''
      end

      out = resource['instances'].select {|i| i.has_key?('sub_container') && i['sub_container'].has_key?('top_container')}
                              .map {|i| 
                                instance = i['sub_container']['top_container']['_resolved']
                                top_container_name = instance.dig('container_profile', '_resolved', 'name')

                                next if top_container_name.nil?

                                label_parts = []
                                label_parts << top_container_name
                                label_parts.compact.join("; ")
                              }.compact


      if out
          out.join("; ")
      else
          ''
      end
    end


    def as_aeon_request(item_map)
      num = SecureRandom.hex(4)
      Hash[[['Request', num]] + without_unneeded_fields(item_map).map {|k,v| [k+'_'+num, v[0,255]]}]
    end


    def without_unneeded_fields(map)
      map.delete_if {|k, v| !v || v.strip.empty?} # empty values
    end


    def repo_field_for(repository, field)
      repo_code = repository['repo_code']
      if @opts.has_key?(:repo_fields)
        @opts[:repo_fields].fetch(field, repo_code)
      else
        repo_code
      end
    end


    def hollis_number_for(resource)
      out = resource['notes'].select {|n| n['type'] == 'processinfo' && n['label'] == 'Alma ID'}
                             .map {|n| n['subnotes'].map {|s| s['content'].strip}}
                             .flatten.compact.join('; ')

      return out unless out.empty?

      resource['notes'].select {|n| n['type'] == 'processinfo' && n['label'] == 'Aleph ID'}
                       .map {|n| n['subnotes'].map {|s| s['content'].strip}}
                       .flatten.compact.join('; ')
    end


    def access_restrictions_for(item)
      (item['notes'] || []).select {|n| n['type'] == 'accessrestrict'}
                   .map {|n| n['subnotes'].map {|s| s['content']}}
                   .flatten.compact.join('; ')
    end


    def physical_location_for(item)
      item['notes'].select {|n| n['type'] == 'physloc'}.map {|n| n['content'].join(' ')}.join('; ')
    end


    def with_mapped_container(mapped, item_fields, container)
      item_fields.merge({
        'gid'         => mapped.collection.uri + container.uri,
        'ItemVolume'  => container.name.sub(/: .*$/, ''),
        'ItemInfo1'  => container.id,
        'ItemInfo2'   => [mapped.record.id, container.ext(:subs)].compact.select{|i| !i.empty?}.join(': '),
        'SubLocation'   => container.ext(:location)
      })
    end
  end
end
