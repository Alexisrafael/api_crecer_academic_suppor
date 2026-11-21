# frozen_string_literal: true

class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:register, :login, :refresh]

  # Método: register
  # Descripción: Registra un nuevo usuario en el sistema y retorna sus credenciales y tokens JWT.
  # Parámetros: email, password, password_confirmation, first_name, last_name, register_as_tutor (opcional boolean).
  # Retorna: Objeto JSON con user, token, refresh_token y expires_in (status: 201 Created).
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
      render json: {
        user: user,
        token: tokens[:access_token],
        refresh_token: tokens[:refresh_token],
        expires_in: tokens[:access_expires_in]
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Método: login
  # Descripción: Autentica las credenciales del usuario y genera un nuevo par de tokens de acceso y refresco.
  # Parámetros: email, password.
  # Retorna: Objeto JSON con user, token, refresh_token y expires_in (status: 200 OK), o error 401 si falla.
  def login
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      tokens = generate_tokens(user.id, 0)
      set_cookie_tokens(tokens)
      render json: {
        user: user,
        token: tokens[:access_token],
        refresh_token: tokens[:refresh_token],
        expires_in: tokens[:access_expires_in]
      }, status: :ok
    else
      render json: { error: I18n.t('api.auth.invalid_email_password') }, status: :unauthorized
    end
  end

  # Método: logout
  # Descripción: Elimina las cookies de sesión (access y refresh) e invalida la sesión del cliente.
  # Parámetros: Ninguno.
  # Retorna: Mensaje JSON de confirmación con status 200 OK.
  def logout
    response.delete_cookie(:access_token, path: '/')
    response.delete_cookie(:refresh_token, path: '/')
    render json: {
      message: I18n.t('api.auth.logout_success', default: 'Sesión cerrada exitosamente')
    }, status: :ok
  end

  # Método: refresh
  # Descripción: Emite un nuevo par de tokens usando un refresh_token válido proveniente de cookie, params o headers.
  # Parámetros: refresh_token (opcional en params, cookie o header).
  # Retorna: Objeto JSON con token, refresh_token y expires_in, o error 401 si el token expiró o es inválido.
  def refresh
    refresh_token = request.cookies['refresh_token'] ||
                    params[:refresh_token] ||
                    request.headers['X-Refresh-Token'] ||
                    request.headers['Authorization']&.split(' ')&.last

    unless refresh_token.present?
      return render json: { error: I18n.t('api.auth.unauthorized') }, status: :unauthorized
    end

    begin
      secret_key = Rails.application.secret_key_base
      decoded = JWT.decode(refresh_token, secret_key, true, { algorithm: 'HS256' })
      payload = decoded[0]

      unless payload['token_type'] == 'refresh'
        return render json: { error: I18n.t('api.auth.invalid_token_type') }, status: :unauthorized
      end

      user_id = payload['user_id']
      refresh_count = payload['refresh_count'].to_i + 1

      tokens = generate_tokens(user_id, refresh_count)
      set_cookie_tokens(tokens)

      render json: {
        token: tokens[:access_token],
        refresh_token: tokens[:refresh_token],
        expires_in: tokens[:access_expires_in]
      }, status: :ok
    rescue JWT::DecodeError
      render json: { error: I18n.t('api.auth.invalid_or_expired_refresh_token') }, status: :unauthorized
    end
  end

  # Método: update_profile
  # Descripción: Actualiza los datos de perfil del usuario autenticado, soportando subida de avatar.
  # Parámetros: first_name, last_name, avatar (Active Storage).
  # Retorna: Objeto JSON con el usuario actualizado.
  def update_profile
    if @current_user.update(profile_params)
      render json: { user: @current_user }, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Método: user_params
  # Descripción: Strong parameters para el registro inicial de usuarios.
  def user_params
    params.permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  # Método: profile_params
  # Descripción: Strong parameters para la actualización de perfil y avatar.
  def profile_params
    params.permit(:first_name, :last_name, :avatar)
  end

  # Método: generate_tokens
  # Descripción: Genera los JWTs de acceso y refresco firmados con Rails.application.secret_key_base.
  #              El refresh token tiene una vigencia de 30 días para estabilidad de sesión.
  # Parámetros: user_id (Integer), refresh_count (Integer).
  # Retorna: Hash con :access_token, :refresh_token, :access_expires_in y :refresh_expires_in.
  def generate_tokens(user_id, refresh_count)
    access_duration = case refresh_count
                      when 0 then 15.minutes
                      when 1 then 30.minutes
                      else 1.hour
                      end

    refresh_duration = 30.days
    secret_key = Rails.application.secret_key_base

    access_token = JWT.encode({
      user_id: user_id,
      token_type: 'access',
      exp: access_duration.from_now.to_i
    }, secret_key, 'HS256')

    refresh_token = JWT.encode({
      user_id: user_id,
      token_type: 'refresh',
      refresh_count: refresh_count,
      exp: refresh_duration.from_now.to_i
    }, secret_key, 'HS256')

    {
      access_token: access_token,
      refresh_token: refresh_token,
      access_expires_in: access_duration.to_i,
      refresh_expires_in: refresh_duration.to_i
    }
  end

  # Método: set_cookie_tokens
  # Descripción: Establece las cookies HttpOnly para navegadores web respetando entornos productivos (secure: true).
  # Parámetros: tokens (Hash generado por generate_tokens).
  def set_cookie_tokens(tokens)
    cookie_options = {
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax,
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
        expires: tokens[:refresh_expires_in].seconds.from_now
      )
    )
  end
end
