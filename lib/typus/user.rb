module Typus

  module EnableAsTypusUser

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def enable_as_typus_user

        extend ClassMethodsMixin

        attr_accessor :password

        validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/
        validates_presence_of :email
        validates_uniqueness_of :email

        validates_confirmation_of :password, :if => :password_required?
        validates_length_of :password, :within => 8..40, :if => :password_required?
        validates_presence_of :password, :if => :password_required?

        validates_inclusion_of :roles, :in => roles, :message => "has to be #{Typus.roles_sentence}."

        before_save :initialize_salt, :encrypt_password, :initialize_token

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
        Typus::Configuration.roles[roles].compact
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

        # OPTIMIZE
        resources[resource.to_s].split(', ').include?(_action) rescue false

      end

      def is_root?
        roles == Typus::Configuration.options[:root]
      end

    protected

      def generate_hash(string)
        Digest::SHA1.hexdigest(string)
      end

      def encrypt_password
        return if password.blank?
        self.crypted_password = encrypt(password)
      end

      def encrypt(string)
        generate_hash("--#{salt}--#{string}")
      end

      def initialize_salt
        self.salt = generate_hash("--#{Time.now.utc.to_s}--#{email}--") if new_record?
      end

      def initialize_token
        generate_token if new_record?
      end

      def generate_token
        self.token = encrypt("--#{Time.now.utc.to_s}--#{password}--")
      end

      def password_required?
        crypted_password.blank? || !password.blank?
      end

    end

  end

end

ActiveRecord::Base.send :include, Typus::EnableAsTypusUser