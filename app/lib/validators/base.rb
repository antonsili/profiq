# frozen_string_literal: true

module Validators
  class Base
    include ActiveModel::Validations

    OPTS = {}.freeze

    class_attribute :attributes, instance_writer: false
    self.attributes = []

    class_attribute :additional_attributes, instance_writer: false
    self.additional_attributes = []

    class_attribute :squish_attributes, instance_writer: false
    self.squish_attributes = []

    def self.fields(*names)
      self.attributes ||= []
      self.attributes += Array(names)
      send :attr_accessor, *attributes
    end

    def self.additional_params(*names)
      self.additional_attributes ||= []
      self.additional_attributes += Array(names)
      send :attr_accessor, *additional_attributes
    end

    def self.squish_params(*names)
      self.squish_attributes ||= []
      self.squish_attributes += Array(names)
      send :attr_accessor, *squish_attributes
    end

    def initialize(params, additional_params = OPTS)
      params = params.to_hash&.with_indifferent_access if params.is_a? ActionController::Parameters
      params = params&.except(:format, :controller, :action)&.with_indifferent_access
      not_valid_params = params&.except(*(attributes + additional_attributes))&.keys
      raise ActionController::UnpermittedParameters, not_valid_params if not_valid_params.present?

      assign_attributes(params&.slice(*attributes))
      additional_params = additional_params&.with_indifferent_access
      assign_attributes(additional_params.slice(*additional_attributes))
    end

    def to_hash(raise_error: true)
      raise Validators::InvalidParameters, errors if invalid? && raise_error

      attributes.compact.each_with_object({}) do |attr, result|
        result[attr] = send(attr)
      end
    end

    def hash_attributes
      attributes.compact.each_with_object({}) do |attr, result|
        result[attr] = send(attr)
      end
    end

    private

    def assign_attributes(new_attributes)
      new_attributes = new_attributes.to_hash if new_attributes.is_a? ActionController::Parameters
      attr_hash = Hash(new_attributes).deep_symbolize_keys
      attr_hash.each do |k, v|
        v.squish! if squish_attributes.include?(k)
        send("#{k}=", v) if respond_to?(k)
      end

      self
    end
  end
end
