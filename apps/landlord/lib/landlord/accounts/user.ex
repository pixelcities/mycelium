defmodule Landlord.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Jason.Encoder, only: [:id, :email, :name, :picture, :confirmed_at]}
  schema "users" do
    field :email, :string
    field :name, :string
    field :picture, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :is_agent, :boolean, default: false

    has_many :data_spaces__users, Landlord.Tenants.DataSpaceUser
    has_many :data_spaces, through: [:data_spaces__users, :data_space]

    timestamps()
  end

  @doc """
  A user changeset for registration.

  ## Options
    * `:hash_password` - Hashes the password for extra security (passwords
    are already hashed on the client side as well).
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email()
    |> validate_password(opts)
  end

  def agent_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :confirmed_at, :is_agent])
    |> validate_email()
    |> validate_password(opts)
  end


  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Landlord.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 44, max: 72) # 32 bytes (base64)
    |> validate_format(:password, ~r/^[a-zA-Z0-9+\/=]+$/, message: "expected to be hashed and base64 encoded")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing some profile info.
  """
  def profile_changeset(user, attrs) do

    # Ensure empty fields do not overwrite anything
    changes =
      Map.keys(attrs)
      |> Enum.filter( fn x -> Map.fetch!(attrs, x) not in [nil, ""] end)
      |> Enum.map( fn x -> case x do
          "name" -> :name
          "picture" -> :picture
        end
      end)

    user
    |> cast(attrs, changes)
    |> validate_picture()
  end

  defp validate_picture(changeset) do
    changeset
    |> validate_format(:picture, ~r/^data:image\/(?:png|jpe?g);base64,[a-zA-Z0-9+\/=]+$/, message: "must be an image data url")
    |> validate_length(:picture, max: 349554) # 24 + (1024 * 256) / 3 * 4 + padding
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added. The
  email changeset also requires a new password because the email is used
  as a salt on the client side.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email()
    |> validate_password(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  Post confirmation email changeset

  The (hashed) password is expected to already have been validated.
  """
  def confirm_email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :hashed_password])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end


  @doc """
  A user changeset for changing the password.

  ## Options
    * `:hash_password`
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Landlord.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
