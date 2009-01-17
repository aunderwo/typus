module Typus

  module User

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def enable_as_typus_user

        extend ClassMethodsMixin

        attr_accessor :password

        validates_presence_of :email
        validates_presence_of :password, :password_confirmation, :if => :new_record?
        validates_uniqueness_of :email
        validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
        validates_confirmation_of :password, :if => lambda { |i| i.new_record? or not i.password.blank? }
        validates_length_of :password, :within => 8..40, :if => lambda { |i| i.new_record? or not i.password.blank? }

        validates_inclusion_of :roles, 
                               :in => self.roles, 
                               :message => "has to be in #{Typus::Configuration.roles.keys.reverse.join(", ")}."

        before_create :set_token
        before_save :encrypt_password

        include InstanceMethods

      end

    end

    module ClassMethodsMixin

      def roles
        Typus::Configuration.roles.keys.sort
      end

      def authenticate(email, password)
        user = find_by_email_and_status(email, true)
        user && user.authenticated?(password) ? user : nil
      end

    end

    module InstanceMethods

      def full_name(*args)
        options = args.extract_options!
        full_name = (!first_name.empty? && !last_name.empty?) ? "#{first_name} #{last_name}" : email
        full_name << " (#{roles})" if options[:display_role]
        return full_name
      end

     def authenticated?(password)
        crypted_password == encrypt(password)
      end

      ##
      # Resources TypusUser has access to ...
      #
      def resources
        Typus::Configuration.roles[self.roles].compact
      end

      def can_perform?(resource, action, options = {})

        if options[:special]
          _action = action
        else
          _action = case action
                    when 'new', 'create':       'create'
                    when 'index', 'show':       'read'
                    when 'edit', 'update':      'update'
                    when 'position':            'update'
                    when 'toggle':              'update'
                    when 'relate', 'unrelate':  'update'
                    when 'destroy':             'delete'
                    else
                      action
                    end
        end

        self.resources[resource.to_s].split(', ').include?(_action) rescue false

      end

      def is_root?
        roles == Typus::Configuration.options[:root]
      end

    protected

      def encrypt_password
        return if password.blank?
        self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
        self.crypted_password = encrypt(password)
      end

      def encrypt(password)
        Digest::SHA1.hexdigest("--#{salt}--#{password}")
      end

      def set_token
        record = "#{self.class.name}#{id}"
        chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
        @attributes['token'] = chars.sort_by{rand}.to_s[0..12]
      end

    end

  end

end

ActiveRecord::Base.send :include, Typus::User