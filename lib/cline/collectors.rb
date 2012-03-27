# coding: utf-8

module Cline::Collectors
  class Base
    class << self
      attr_accessor :message_filter

      def create_or_pass(message, notified_at)
        message     = message.encode(Encoding::UTF_8)

        if message_filter
          message = message_filter.(message)
          return if message.nil?
        end

        notified_at = parse_time_string_if_needed(notified_at)

        return if oldest_notification && oldest_notification.notified_at.to_time > notified_at

        Cline::Notification.instance_exec message, notified_at do |message, notified_at|
          create(message: message, notified_at: notified_at) unless find_by_message_and_notified_at(message, notified_at)
        end
      rescue ActiveRecord::StatementInvalid => e
        puts e.class, e.message
      end

      private

      def parse_time_string_if_needed(time)
        if time.is_a?(String)
          Time.parse(time)
        else
          time
        end
      end

      def oldest_notification
        @oldest_notification ||=
          Cline::Notification.order(:notified_at).limit(1).first
      end

      def reset_oldest_notification
        @oldest_notification = nil
      end
    end
  end
end

require 'cline/collectors/feed'
require 'cline/collectors/github'
