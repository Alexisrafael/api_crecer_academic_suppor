class Api::V1::BaseController < ApplicationController
  before_action :authenticate_user!

  private

  # Método: authenticate_user!
  # Descripción: Autentica al usuario verificando la validez del token JWT enviado en el header Authorization.
  # Parámetros: Ninguno directo (usa request.headers['Authorization']).
  # Retorna: Nada (Renderiza un error 401 si el token no es válido o no es de tipo 'access').
  def authenticate_user!
    # Extraemos el token: puede venir en la cookie 'access_token' o en el header Authorization
    token = request.cookies['access_token'] || request.headers['Authorization']&.split(' ')&.last
    begin
      decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
      payload = decoded[0]
      
      if payload['token_type'] != 'access'
        return render json: { error: I18n.t('api.auth.invalid_token_type') }, status: :unauthorized
      end
      
      @current_user = User.find(payload['user_id'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: I18n.t('api.auth.unauthorized') }, status: :unauthorized
    end
  end

  # Método: current_user
  # Descripción: Devuelve el usuario actualmente autenticado.
  # Parámetros: Ninguno.
  # Retorna: Instancia de User (@current_user).
  def current_user
    @current_user
  end
end
