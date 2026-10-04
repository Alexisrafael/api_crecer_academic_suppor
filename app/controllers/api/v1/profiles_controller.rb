class Api::V1::ProfilesController < Api::V1::BaseController
  # Método: show
  # Descripción: Retorna la información del perfil del usuario actualmente autenticado.
  # Parámetros: Ninguno (usa el token de acceso).
  # Retorna: Objeto JSON con los datos del usuario.
  def show
    render json: current_user, status: :ok
  end
end
