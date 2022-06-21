AppConfig[:request_list] = {
  :button_position => 0,
  :record_types => ['archival_object', 'resource', 'top_container'],
  :request_handlers => {
    :harvard_aeon => {
      :name => 'Harvard Aeon',
      :profile => :harvard_aeon,
      :url => 'https://burnsaccount.bc.edu/logon?Action=11&Form=31',
      :list_opts => {
        :return_link_label => 'Return to Search Burns Archives',
        :form_target => 'RequestForm',
        :aeon_link_url => 'https://burnsaccount.bc.edu/logon',
        :request_types => {
          'Visit' => {
            'RequestType' => 'Loan',
            'UserReview' => 'No',
            'SkipOrderEstimate' => '',
          },
           'Copy' => {
            'RequestType' => 'Copy',
            'UserReview' => 'No',
            'SkipOrderEstimate' => 'Yes',
          }
        },
        :format_options => [
                            'Reference PDF (1 week)',
                            'Reference JPG (1 week)'
                           ],
        :delivery_options => [
                              'Download'
                             ]
      }
    }
  },
  :repositories => {
    :default => {
      :handler => :harvard_aeon,
    },
  }
}

raise 'No config found for request_list plugin!' unless AppConfig.has_key?(:request_list)

cfg = AppConfig[:request_list]

Plugins::extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Plugins::add_menu_item('/plugin/request_list/list', 'plugin.request_list.menu_label')

Plugins::add_record_page_action_erb(cfg.fetch(:record_types, ['archival_object', 'accession']),
                                    'request_list/action_button',
                                    cfg.fetch(:button_position, nil))

ArchivesSpacePublic::Application.class_eval do
    config.paths["app/mailers"].concat(ASUtils.find_local_directories("public/mailers"))
end

Rails.application.config.after_initialize do
  RequestList.init(cfg)
end
