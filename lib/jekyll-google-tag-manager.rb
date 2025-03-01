# frozen_string_literal: true

require 'jekyll-google-tag-manager/errors'
require 'jekyll-google-tag-manager/version'
require 'liquid'

# Add our tag to the Jekyll top-level module
module Jekyll
  # Google Tag Manager tag, renders Liquid templates
  class GoogleTagManager < Liquid::Tag
    attr_accessor :context

    DEFAULT_TRANSPORT_URL = 'https://www.googletagmanager.com'
    PLACEHOLDER_ID = 'GTM-NNNNNNN'
    VALID_SECTIONS = %w[body head].freeze

    @@warning_shown = false

    def initialize(_tag_name, _markup, _parse_context)
      super
      message = <<~MSG
        Invalid section specified: #{section}.
        Please specify one of the following sections: #{VALID_SECTIONS.join(', ')}
      MSG
      raise InvalidSectionError, message unless VALID_SECTIONS.include?(section)
    end

    def render(context)
      @context = context
      template.render!(payload)
    end

    private

    def container_id(config)
      gtm_container_id = config.dig('google', 'tag_manager', 'container_id')
      return fallback if gtm_container_id.nil?

      gtm_container_id
    rescue TypeError
      fallback
    end

    def fallback
      produce_warning!
      PLACEHOLDER_ID
    end

    def fallback_transport_url
      DEFAULT_TRANSPORT_URL
    end

    def produce_warning!
      return if @@warning_shown

      @@warning_shown = true
      Jekyll.logger.warn(<<~WARNING)
        [WARNING]: jekyll-google-tag-manager
          Your GTM container id is malformed or missing.
          Using fallback: #{PLACEHOLDER_ID}
      WARNING
    end

    def payload
      {
        'container_id' => container_id(context.registers.fetch(:site).config),
        'gtm_tag' => {
          'version' => VERSION
        },
        'transport_url' => transport_url(context.registers.fetch(:site).config)
      }
    end

    def section
      @section ||= @markup.strip
    end

    def template
      @template ||= Liquid::Template.parse(template_contents)
    end

    def template_contents
      @template_contents ||= File.read(template_path)
    end

    def template_path
      @template_path ||= File.expand_path("./template-#{section}.html", this_file_dirname)
    end

    def this_file_dirname
      File.dirname(__FILE__)
    end

    def transport_url(config)
      gtm_transport_url = config.dig('google', 'tag_manager', 'transport_url')
      return fallback_transport_url if gtm_transport_url.nil?

      gtm_transport_url
    rescue TypeError
      fallback_transport_url
    end
  end
end

Liquid::Template.register_tag('gtm', Jekyll::GoogleTagManager)
