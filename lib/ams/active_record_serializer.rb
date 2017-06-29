# frozen_string_literal: true

require "ams/serializer"
module AMS
  class ActiveRecordSerializer < Serializer
    class << self
      # @example
      #   relation :articles, type: :articles, to: :many, key: :posts
      #
      #     def related_articles_ids
      #       object.aritcles.pluck(:id)
      #     end
      #
      #     def related_articles_data
      #       related_articles_ids.map {|id| relationship_data(id, :articles) }
      #     end
      #
      #     def related_articles_links
      #       related_link_to_many(:articles)
      #     end
      #
      #     def articles
      #       {}.tap do |hash|
      #         hash[:data] = related_articles_data
      #         hash[:links] = related_articles_links if link_builder?
      #       end
      #     end
      #
      def _relation_to_many(relation_name, type:, key: relation_name, **options)
        options.fetch(:ids) do
          options[:ids] = "object.#{relation_name}.pluck(:id)"
        end
        add_instance_method <<-METHOD, self
          def related_#{relation_name}_links
            related_link_to_many("#{type}")
          end
        METHOD
        options[:relation_hash] = <<-METHOD
          hash[:links] = related_#{relation_name}_links if link_builder?
        METHOD
        super
      end

      # @example
      #   relation :article, type: :articles, to: :one, key: :post
      #
      #     def related_article_id
      #       object.article.id
      #     end
      #
      #     def related_article_data
      #       relationship_data(related_article_id, :articles)
      #     end
      #
      #     def related_article_links
      #       related_link_to_one(related_article_id, :articles)
      #     end
      #
      #     def article
      #       {}.tap do |hash|
      #         hash[:data] = related_article_data
      #         hash[:links] = related_article_links if link_builder?
      #       end
      #     end
      #
      def _relation_to_one(relation_name, type:, key: relation_name, **options)
        options.fetch(:id) do
          options[:id] = "object.#{relation_name}.id"
        end
        add_instance_method <<-METHOD, self
          def related_#{relation_name}_links
            related_link_to_one(related_#{relation_name}_id, "#{type}")
          end
        METHOD
        options[:relation_hash] = <<-METHOD
          hash[:links] = related_#{relation_name}_links if link_builder?
        METHOD
        super
      end
    end

    attr_reader :link_builder

    def initialize(object, link_builder: :no_links)
      super(object)
      @link_builder = link_builder
    end

    def to_h
      super.merge!(
        links: resource_links_object
      )
    end

    def relations
      hash = {}
      _relations.each do |relation_name, config|
        hash[config[:key]] =
        if :many == config[:to] && link_builder?
          relation_type = config.fetch(:type)
          { links: related_link_to_many(relation_type) }
        else
          send(relation_name)
        end
      end
      hash
    end

    private

      def link_builder?
        link_builder != :no_links
      end

      def related_link_to_one(id, type)
        { related: show_url_for(id, type) } # related resource link object
      end

      # related resource link object
      def related_link_to_many(type)
        filter = { foreign_key => object.id }
        query_params = { filter: filter }
        { related: index_url_for(type, query_params) }
      end

      def resource_links_object
        return {} unless link_builder?
        {
          self: show_url_for(id, type)
        }
      end

      def show_url_for(id, type)
        link_builder.url_for(controller: type, action: :show, id: id)
      end

      def index_url_for(type, query_params)
        link_builder.url_for(controller: type, action: :index, params: query_params)
      end

      def foreign_key
        "#{AMS::Inflector.singularize(object.class.table_name)}_id"
      end
  end
end
