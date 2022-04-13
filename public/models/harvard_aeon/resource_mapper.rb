module HarvardAeon
  class ResourceMapper < ItemMapper

    RequestList.register_item_mapper(self, :harvard_aeon, Resource)

    def request_permitted?(item)
      # only if childless
      ArchivesSpaceClient.instance.get_raw_record(item['uri'] + '/tree/root')['child_count'] == 0
    end


    def form_fields(mapped)
      shared_fields = {
        'Site'          => mapped.ext(:site).name,
        'ReferenceNumber' => mapped.ext(:hollis).id,
        'ItemTitle'     => mapped.collection.name,
        #'ItemTitle'     => mapped.collection.ext(:resource_title),
        'ItemAuthor'    => mapped.creator.name,
        'Location'      => mapped.ext(:location).name,
        'CallNumber'    => mapped.collection.id,
        'ItemCitation'   => mapped.collection.ext(:access_restrictions),
      }

      return [as_aeon_request(shared_fields)] unless mapped.container.has_multi?

      mapped.container.multi.map {|c|
        as_aeon_request(with_mapped_container(mapped, shared_fields, c))
      }
    end

  end
end
