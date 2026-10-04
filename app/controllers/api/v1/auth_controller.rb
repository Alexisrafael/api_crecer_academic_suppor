class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:register, :login, :refresh]

  # Método: register
  # Descripción: Registra un nuevo usuario en la base de datos y le genera sus tokens de acceso y refresco.
  # Parámetros: email, password, password_confirmation, first_name, last_name, register_as_tutor (opcional, boolean).
  # Retorna: Objeto JSON con el usuario creado y los tokens.
  def register
    user = User.new(user_params)
    
    if params[:register_as_tutor]
      user.user_type = :tutor
    else
      user.user_type = :student
    end

    if user.save
      tokens = generate_tokens(user.id, 0)
      set_cookie_tokens(tokens)
      render json: { user: user }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Método: login
  # Descripción: Autentica a un usuario existente verificando sus credenciales y genera tokens de acceso y refresco.
  # Parámetros: email, password.
  # Retorna: Objeto JSON con el usuario y los tokens, o un error 401 si falla.
  def login
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      tokens = generate_tokens(user.id, 0)
      set_cookie_tokens(tokens)
      render json: { user: user }, status: :ok
    else
      render json: { error: I18n.t('api.auth.invalid_email_password') }, status: :unauthorized
    end
  end

  # Método: logout
  # Descripción: Elimina las cookies de sesión del usuario.
  # Parámetros: Ninguno.
  # Retorna: 200 OK.
  def logout
    response.delete_cookie(:access_token, path: '/')
    response.delete_cookie(:refresh_token, path: '/')
    head :ok
  end

  # Método: refresh
  # Descripción: Genera un nuevo par de tokens (access y refresh) usando un refresh_token válido. La duración del access_token varía según la cantidad de refrescos (refresh_count).
  # Parámetros: refresh_token (string).
  # Retorna: Objeto JSON con los nuevos tokens, o un error 401 si falla la decodificación.
  def refresh
    refresh_token = request.cookies['refresh_token'] || params[:refresh_token]
    
    unless refresh_token
      return render json: { error: I18n.t('api.auth.unauthorized') }, status: :unauthorized
    end

    begin
      decoded = JWT.decode(refresh_token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
      payload = decoded[0]
      
      unless payload['token_type'] == 'refresh'
        return render json: { error: I18n.t('api.auth.invalid_token_type') }, status: :unauthorized
      end

      user_id = payload['user_id']
      refresh_count = payload['refresh_count'].to_i + 1
      
      tokens = generate_tokens(user_id, refresh_count)
      set_cookie_tokens(tokens)
      
      head :ok
    rescue JWT::DecodeError
      render json: { error: I18n.t('api.auth.invalid_or_expired_refresh_token') }, status: :unauthorized
    end
  end

  # Método: update_profile
  # Descripción: Actualiza los datos personales del usuario actual, incluyendo su avatar.
  def update_profile
    if @current_user.update(profile_params)
      # Retornamos el usuario actualizado para que el frontend guarde en localStorage
      render json: { user: @current_user }, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Método: user_params
  # Descripción: Strong parameters para el registro de usuarios.
  def user_params
    params.permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  # Método: profile_params
  # Descripción: Strong parameters para la actualización del perfil.
  def profile_params
    params.permit(:first_name, :last_name, :avatar)
  end

  # Método: generate_tokens
  # Descripción: Genera los tokens de acceso y refresco, aplicando reglas de expiración escalonada basadas en el contador de refrescos.
  # Parámetros: user_id (entero), refresh_count (entero).
  # Retorna: Hash con :access_token, :refresh_token y :access_expires_in.
  def generate_tokens(user_id, refresh_count)
    # Determine access token duration based on refresh count
    access_duration = case refresh_count
                      when 0 then 15.minutes
                      when 1 then 30.minutes
                      else 1.hour
                      end

    access_token = JWT.encode({ 
      user_id: user_id, 
      token_type: 'access',
      exp: access_duration.from_now.to_i 
    }, Rails.application.credentials.secret_key_base)

    refresh_token = JWT.encode({ 
      user_id: user_id, 
      token_type: 'refresh',
      refresh_count: refresh_count,
      exp: 1.hour.from_now.to_i 
    }, Rails.application.credentials.secret_key_base)

    {
      access_token: access_token,
      refresh_token: refresh_token,
      access_expires_in: access_duration.to_i
    }
  end

  # Método: set_cookie_tokens
  # Descripción: Guarda los tokens generados en cookies firmadas y HttpOnly.
  def set_cookie_tokens(tokens)
    cookie_options = {
      httponly: true,
      secure: Rails.env.production?, # Solo HTTPS en producción
      same_site: :lax, # Cambiar a :none si front y back están en dominios completamente distintos (requiere secure: true)
      path: '/'
    }

    response.set_cookie(
      :access_token,
      cookie_options.merge(
        value: tokens[:access_token],
        expires: tokens[:access_expires_in].seconds.from_now
      )
    )

    response.set_cookie(
      :refresh_token,
      cookie_options.merge(
        value: tokens[:refresh_token],
        expires: 1.hour.from_now
      )
    )
  end
end
