class String

  def typus_actions_for(filter)
    if self.respond_to?("admin_actions_for_#{filter}")
      self.send("admin_actions_for_#{filter}").map { |a| a.to_s }
    else
      Typus::Configuration.config[self]['actions'][filter.to_s].split(', ') rescue []
    end
  end

end