class User < ApplicationRecord
  has_secure_password

  belongs_to :plan, optional: true
  belongs_to :country, optional: true
  belongs_to :department, optional: true
  belongs_to :city, optional: true

  validates :email, presence: true, uniqueness: true

  # status: 1 = active, 2 = suspended, 3 = cancelled, 4 = deleted
  enum :status, { active: 1, suspended: 2, cancelled: 3, deleted: 4 }, default: :active

  # user_type: 1 = student, 2 = tutor, 3 = super_user
  enum :user_type, { student: 1, tutor: 2, super_user: 3 }, default: :student

  # role: 1 = user, 2 = admin
  enum :role, { user: 1, admin: 2 }, default: :user

  has_many :enrollments, dependent: :destroy
  has_many :courses, dependent: :destroy # Cursos que dicta si es profesor
  has_many :enrolled_courses, through: :enrollments, source: :course # Cursos en los que es estudiante
  has_many :user_progresses, dependent: :destroy

  has_one_attached :avatar

  # Método: as_json
  # Descripción: Serializa el modelo a formato JSON garantizando la exclusión permanente de password_digest
  # y agregando la URL pública/directa del avatar si está adjunto.
  # Parámetros: options (Hash)
  # Retorna: Hash serializable a JSON sin password_digest.
  def as_json(options = {})
    options = (options || {}).deep_dup
    except_fields = Array(options[:except]).map(&:to_sym) | [:password_digest]
    options[:except] = except_fields

    result = super(options)
    result.delete('password_digest')
    result.delete(:password_digest)
    result.merge({
      avatar_url: avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true) : self[:avatar_url]
    })
  end
end
