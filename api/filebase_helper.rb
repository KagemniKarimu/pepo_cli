# frozen_string_literal: true

require 'aws-sdk-s3'

# Standard Object for handling all Filebase S3 API requests
# Each instance of Filebase credentials can be assigned its own Helper
class FilebaseHelper
  attr_reader :access_key, :secret_key, :region, :end_point, :s3

  def initialize(access_key, secret_key, region = default_region, end_point = default_end_point)
    @access_key = access_key
    @secret_key = secret_key
    @region = region
    @end_point = end_point
    initialize_s3
  end

  def default_region
    'us-east-1'
  end

  def default_end_point
    'https://s3.filebase.com/'
  end

  def standard_attributes
    [@access_key, @secret_key, @region, @end_point]
  end

  def initialize_s3
    raise ArgumentError if standard_attributes.any?(&:nil?)

    @s3 = Aws::S3::Client.new(
      access_key_id: @access_key,
      secret_access_key: @secret_key,
      region: @region,
      endpoint: @end_point
    )

    @s3.list_buckets
  end

  # S3-compatible Methods
  def create_bucket(bucket_name)
    @s3.create_bucket(bucket: bucket_name)
    # rescue StandardError => e
    # e.message
  end

  def delete_bucket(bucket_name)
    @s3.delete_bucket(bucket_name)
    # rescue StandardError => e
    # e.message
  end

  def upload_object(bucket_name, object_key, object_path)
    File.open(object_path, 'rb') do |file|
      @s3.put_object(bucket: bucket_name, key: object_key, body: file)
    end
  end

  def download_object(bucket_name, object_key)
    @s3.get_object(bucket: bucket_name, key: object_key)
  end

  def remove_object(bucket_name, object_key)
    @s3.delete_object(bucket: bucket_name, key: object_key)
  end

  def bucket_list
    @s3.list_buckets.buckets.map(&:name)
  end

  def check_bucket(bucket_name)
    @s3.list_objects(bucket: bucket_name).contents.map(&:key)
  end
end
