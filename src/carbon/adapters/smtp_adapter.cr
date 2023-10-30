class Carbon::SmtpAdapter < Carbon::Adapter
  Habitat.create do
    setting host : String = "localhost"
    setting port : Int32 = 25
    setting helo_domain : String? = nil
    setting use_tls : Bool = true
    setting username : String? = nil
    setting password : String? = nil
  end

  def deliver_now(email : Carbon::Email)
    auth = get_auth_tuple

    helo_domain = settings.helo_domain || settings.host
    use_tls = settings.use_tls ? ::EMail::Client::TLSMode::STARTTLS : ::EMail::Client::TLSMode::NONE
    ::EMail.send(settings.host, settings.port, helo_domain: helo_domain, auth: auth, use_tls: use_tls) do
      subject email.subject

      from(email.from.address, email.from.name)

      email.to.each do |to_address|
        to(to_address.address, to_address.name)
      end

      email.cc.each do |cc_address|
        cc(cc_address.address, cc_address.name)
      end

      email.bcc.each do |bcc_address|
        bcc(bcc_address.address, bcc_address.name)
      end

      email.headers.each do |key, value|
        case key.downcase
        when "reply-to"
          reply_to(value)
        when "message-id"
          message_id(value)
        when "return-path"
          return_path(value)
        when "sender"
          sender(value)
        else
          custom_header(key, value)
        end
      end

      if text = email.text_body.presence
        message(text)
      end

      if html = email.html_body.presence
        message_html(html)
      end
    end
  end

  private def get_auth_tuple : Tuple(String, String)?
    username = settings.username
    password = settings.password

    if username && password.nil?
      raise "You need to provide a password when setting a username"
    end
    if password && username.nil?
      raise "You need to set a username when providing a password"
    end

    if username && password
      {username, password}
    end
  end
end
