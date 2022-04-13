module HarvardAeon
  class ArchivalObjectMapper < ItemMapper

    RequestList.register_item_mapper(self, :harvard_aeon, ArchivalObject)

    def map_extensions(mapped, item, repository, resource, resource_json)
      super
      mapped.ext(:level).name = item['level'].capitalize
    end


    def form_fields(mapped)
      shared_fields = {
        'Site'           => mapped.ext(:site).name,
        'ReferenceNumber' => mapped.ext(:hollis).id,
        #'ItemTitle'      => mapped.collection.name,
        'ItemTitle'      => mapped.collection.ext(:resource_title),
        'ItemSubTitle'   => mapped.ext(:level).name + ': ' + ((mapped.ext(:level).name == 'Series' || mapped.ext(:level).name == 'Subseries') && !mapped.record.id.empty? ? mapped.record.id + ' ' : '') + mapped.record.name,
        'ItemCitation'   => mapped.collection.ext(:access_restrictions),
        'ItemAuthor'     => mapped.creator.name,
        'Location'       => mapped.ext(:location).name,
        'ItemInfo3'      => mapped.ext(:container_profile).name,
        #'ItemInfo3'      => mapped.ext(:container_profile_name),
        'CallNumber'     => mapped.collection.id,
        'ItemInfo5'      => mapped.record.ext(:access_restrictions),
        'ItemInfo2'      => mapped.record.id,
      }

      return [as_aeon_request(shared_fields)] unless mapped.container.has_multi?

      mapped.container.multi.map {|c|
        as_aeon_request(with_mapped_container(mapped, shared_fields, c))
      }
    end

  end
end
