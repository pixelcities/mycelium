defmodule Landlord.Tenants do
  @moduledoc """
  The Tenants context.

  Each tenant is a group of users behind a subscription. Users may be part
  of multiple tenants.

  A tenant provides the data space for users to collaborate in.
  """

  import Ecto.Query, warn: false
  require Logger

  alias Landlord.Repo
  alias Landlord.Accounts
  alias Landlord.Accounts.{User, UserNotifier}
  alias Landlord.Tenants.{DataSpace, DataSpaceUser, DataSpaceToken, Subscription, SubscriptionApi}


  ## Database getters

  @doc """
  Get data space handles

  Note that a handle is expected to be an atom.
  """
  def get() do
    try do
      tenants = Repo.all(DataSpace.get_active_data_spaces())
        |> Enum.map(fn data_space -> String.to_atom(data_space.handle) end)
      {:ok, tenants}
    rescue
      e in Postgrex.Error ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        {:error, e.postgres.code}
      e ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        reraise e, __STACKTRACE__
    end
  end

  def get!() do
    {:ok, tenants} = __MODULE__.get()
    tenants
  end

  @doc """
  Gets all data spaces
  """
  def get_data_spaces(), do: Repo.all(DataSpace.get_active_data_spaces())

  @doc """
  Get data spaces for given user

  Allows pending members to retrieve the data space as well. They are a valid
  member to receive events, but should not yet be able to dispatch any.
  """
  def get_data_spaces_by_user(user) do
    Repo.all(from d in DataSpace.get_active_data_spaces(),
      join: u in assoc(d, :data_spaces__users),
      where: u.user_id == ^user.id and (u.status == "confirmed" or u.status == "pending")
    )
  end

  @doc """
  Get data spaces for given user, which may be inactive
  """
  def get_inactive_data_spaces_by_user(user) do
    Repo.all(from d in DataSpace.get_inactive_data_spaces(),
      join: u in assoc(d, :data_spaces__users),
      where: u.user_id == ^user.id and u.status == "confirmed"
    )
  end

  @doc """
  Get data space role for given user
  """
  def get_data_space_role(user, data_space) do
    case Repo.one(from d in DataSpace.get_active_data_spaces(),
      join: u in assoc(d, :data_spaces__users),
      where: d.id == ^data_space.id and u.user_id == ^user.id and u.status == "confirmed",
      select: u
    ) do
      nil -> {:error, nil}
      data_space_user -> {:ok, data_space_user.role}
    end
  end
  def get_data_space_role!(user, data_space), do: elem(get_data_space_role(user, data_space), 1)

  @doc """
  Get a single data space
  """
  def get_data_space!(id), do: Repo.get!(DataSpace, id)

  def get_data_space_by_handle(handle, opts \\ [])
  def get_data_space_by_handle(handle, opts) when is_atom(handle), do:
    get_data_space_by_handle(Atom.to_string(handle), opts)
  def get_data_space_by_handle(handle, opts) do
    unsafe = Keyword.get(opts, :unsafe, false)

    Repo.one(from d in (if unsafe, do: DataSpace, else: DataSpace.get_active_data_spaces()),
      where: d.handle == ^handle
    )
  end

  @doc """
  Get a single data space by user and handle

  Users should not be able to get data spaces they are not a part of.
  """
  def get_data_space_by_user_and_handle(user, handle, opts \\ []) do
    unsafe = Keyword.get(opts, :unsafe, false)

    case Repo.one(from d in (if unsafe, do: DataSpace, else: DataSpace.get_active_data_spaces()),
      join: u in assoc(d, :data_spaces__users),
      where: d.handle == ^handle and u.user_id == ^user.id and (u.status == "confirmed" or u.status == "pending")
    ) do
      nil -> {:error, nil}
      data_space -> {:ok, data_space}
    end
  end

  @doc """
  Convert handle to atom

  Verifies the user has access to the handle and that it already exists
  """
  def to_atom(user, handle) do
    case get_data_space_by_user_and_handle(user, handle) do
      {:ok, data_space} -> {:ok, String.to_existing_atom(data_space.handle)}
      {:error, _} -> {:error, :invalid_handle}
    end
  end

  @doc """
  Confirm a user is member of the given data space
  """
  def is_member?(%DataSpace{} = data_space, %User{} = user), do: is_member?(data_space, user.id)
  def is_member?(%DataSpace{} = data_space, user_id) do
    query = from u in DataSpaceUser,
      where: u.user_id == ^user_id and u.data_space_id == ^data_space.id and u.status == "confirmed"

    Repo.exists?(query)
  end

  def is_owner?(%DataSpace{} = data_space, %User{} = user), do: is_owner?(data_space, user.id)
  def is_owner?(%DataSpace{} = data_space, user_id) do
    query = from u in DataSpaceUser,
      where: u.user_id == ^user_id and u.data_space_id == ^data_space.id and u.role == "owner" and u.status == "confirmed"

    Repo.exists?(query)
  end

  def get_subscription(%DataSpace{} = data_space), do:
    Repo.one(from s in Subscription, where: s.data_space_id == ^data_space.id, preload: [:data_space])
  def get_subscription(subscription_id), do:
    Repo.one(from s in Subscription, where: s.subscription_id == ^subscription_id, preload: [:data_space])

  @doc """
  Validate if the current user can create a subscription with this product id

  Inactive spaces also count towards this limit, as they are effectively a wildcard.
  Deleting an inactive data spaces will free up this limit.
  """
  def subscription_available?(%User{} = user, product_id) do
    nr_subscriptions =
      Repo.all(Subscription.subscription_plan_query(product_id))
      |> Enum.filter(fn s -> is_owner?(s.data_space, user) end)
      |> Enum.count()

    nr_inactive =
      get_inactive_data_spaces_by_user(user)
      |> Enum.filter(fn ds -> is_owner?(ds, user) end)
      |> Enum.count()

    SubscriptionApi.within_plan_limit?(product_id, nr_subscriptions + nr_inactive + 1)
  end

  def subscription_downgrade_available?(%DataSpace{} = data_space, product_id) do
    nr_users = Repo.one(from u in DataSpaceUser,
      where: u.data_space_id == ^data_space.id,
      select: count(u.id)
    )

    SubscriptionApi.within_user_limit?(product_id, nr_users)
  end

  @doc """
  Get data space during checkout process

  Uses the checkout id to get a subscription. When the subscription is found and active,
  it will return the linked data space.

  Only the owner role can interact with subscriptions.
  """
  def get_data_space_by_checkout_id(%User{} = user, checkout_id) do
    case Repo.one(Subscription.checkout_query(checkout_id)) do
      nil -> {:error, :invalid_subscription}
      data_space ->
        if is_owner?(data_space, user) do
          {:ok, data_space}
        else
          {:error, :unauthorized}
        end
    end
  end


  ## Database setters

  @doc """
  Prepare for the creation of a new data space

  A dataspace requires a metadata key, which should be created beforehand.
  The key id is then associated with the data space.

  Will insert a row for the soon to be created data space, but not set it to
  active just yet, nor trigger any of the application callbacks.

  Complete the creation process with create_data_space/3.
  """
  def prepare_data_space(%User{} = user, %{key_id: _key_id} = attrs, _opts \\ []) do
    %DataSpace{}
    |> DataSpace.changeset(attrs, is_active: false)
    |> Ecto.Changeset.put_assoc(:data_spaces__users, [%{user: user, role: "owner", status: "confirmed"}])
    |> Repo.insert()
  end

  @doc """
  Create a new data space

  Takes a previously prepared data space and launches it by setting it to active and
  triggering all the required application callbacks.

  Collaborators may be invited using invite_to_data_space/4.
  """
  def create_data_space(%User{} = user, %DataSpace{is_active: false} = data_space, opts \\ []) do
    user_create = Keyword.get(opts, :user_create, false)

    {:ok, data_space} = Repo.update(DataSpace.set_is_active_changeset(data_space))

    # Verified by the DataSpace changeset
    handle = String.to_atom(data_space.handle)

    Landlord.Registry.dispatch(handle)

    if user_create do
      Landlord.create_user(Map.put(Map.from_struct(user), :role, "owner"), %{"user_id" => user.id, "ds_id" => handle})
    end

    {:ok, data_space}
  end

  @doc """
  Invite a user to a data space

  ## Examples

      iex> invite_to_data_space(data_space, user, "hello@pixelcities.io", &Routes.data_space_path(host, :accept_invite, &1))
      {:ok, _}

  """
  def invite_to_data_space(%DataSpace{} = data_space, %User{} = user, recipient_email, email_url_fun, _attrs \\ %{}) do
    if not is_owner?(data_space, user) || email_is_member?(data_space, recipient_email) do
      {:error, :invalid_membership}
    else
      {encoded_token, invite_token} = DataSpaceToken.build_invite_token(data_space, recipient_email)

      with {:ok, _} <- Repo.insert(invite_token),
           {:ok, _} <- UserNotifier.deliver_invitation(recipient_email, user.email, email_url_fun.(encoded_token)),
           {:ok, handle} <- to_atom(user, data_space.handle)
      do
        Landlord.invite_user(%{email: recipient_email, role: "collaborator"}, %{"user_id" => user.id, "ds_id" => handle})
      else
        err -> err
      end
    end
  end

  def accept_invite(user, token) do
    with {:ok, query} <- DataSpaceToken.verify_invite_token_query(user, token),
         %DataSpace{} = data_space <- Repo.one(query),
         {:ok, %{}} <- Repo.transaction(accept_invite_multi(user, data_space))
    do
      # Verified by the DataSpace changeset
      handle = String.to_existing_atom(data_space.handle)

      Landlord.accept_invite(%{email: user.email, id: user.id}, %{"user_id" => user.id, "ds_id" => handle})
    else
      _ -> {:error, :invalid_token}
    end
  end

  def confirm_member(%DataSpace{} = data_space, %User{} = user, new_member_id) do
    if email_is_member?(data_space, user.email) do
      case Repo.one(from u in DataSpaceUser, where: u.user_id == ^new_member_id and u.data_space_id == ^data_space.id) do
        nil -> {:error, :member_has_not_accepted_invite}
        changeset ->
          with {:ok, %{data_space_user: data_space_user}} <- Repo.transaction(confirm_member_multi(changeset, data_space)) do
            handle = String.to_existing_atom(data_space.handle)

            Landlord.confirm_invite(%{email: data_space_user.user.email}, %{"user_id" => user.id, "ds_id" => handle})
            Landlord.create_user(Map.put(Map.from_struct(data_space_user.user), :role, data_space_user.role), %{"user_id" => user.id, "ds_id" => handle})
          else
            err -> err
          end
      end
    else
      {:error, :invalid_membership}
    end
  end

  def cancel_invite(%DataSpace{} = data_space, %User{} = user, invite_email) do
    if email_is_member?(data_space, user.email) do
      case Repo.one(from t in DataSpaceToken, where: t.sent_to == ^invite_email and t.data_space_id == ^data_space.id) do
        nil -> {:error, :no_such_invite}
        changeset ->
          Repo.delete!(changeset)
          handle = String.to_existing_atom(data_space.handle)

          Landlord.cancel_invite(%{email: invite_email}, %{"user_id" => user.id, "ds_id" => handle})
      end
    else
      {:error, :invalid_membership}
    end
  end

  @doc """
  Directly add a user to a data space.

  Only to be used internally. The metadata key still has te be shared beforehand.
  """
  def add_user_to_data_space(%DataSpace{} = data_space, %User{} = user) do
    Repo.transaction(accept_invite_multi(user, data_space, status: "confirmed"))
  end

  @doc """
  Remove a user from a data space
  """
  def delete_user_from_data_space(%DataSpace{} = data_space, %User{} = user) do
    cond do
      !email_is_member?(data_space, user.email) ->
        {:error, :invalid_membership}
      is_owner?(data_space, user) ->
        {:error, :owner_cannot_abandon}
      true ->
        with {:ok, _} <- Repo.transaction(delete_member_multi(user, data_space)) do
          Landlord.delete_user(%{id: user.id}, %{"user_id" => user.id, "ds_id" => data_space.handle})
        else
          err -> err
        end
    end
  end

  @doc """
  Delete a data space

  This will first trigger a callback to all other applications, where they can
  handle the graceful shutdown of a data space (e.g. by stopping the appropiate
  supervisors and cleaning the read models).
  """
  def delete_data_space(%DataSpace{} = data_space) do
    subscription = get_subscription(data_space)

    active_subscription? = if subscription != nil && subscription.status != :deleted do
      case SubscriptionApi.cancel(subscription.subscription_id) do
        {:ok, _} -> false
        _ -> true
      end
    else
      false
    end

    unless active_subscription? do
      if data_space.is_active do
        Landlord.Registry.dispatch(String.to_existing_atom(data_space.handle), [mode: "stop"])
      end

      Repo.delete(data_space)
    else
      {:error, :data_space_has_active_subscription}
    end
  end

  @doc """
  Reset a data space

  This is identical to deleting and recreating a data space with all the
  existing members. The data space id will change.
  """
  def reset_data_space(%DataSpace{} = data_space) do
    members = Repo.all(from u in DataSpaceUser, where: u.data_space_id == ^data_space.id)
    {[creator | owners], collaborators} = Enum.split_with(members, fn member -> member.role == "owner" end)

    # Special case for the trial space. We have to make sure most user information
    # is redacted before sending the command to the data space application.
    is_trial? = data_space.handle == "trial"

    with {:ok, _} <- delete_data_space(data_space),
         user <- Accounts.get_user!(creator.user_id),
         {:ok, new_data_space} <- prepare_data_space(user, Map.from_struct(data_space)),
         {:ok, new_data_space} <- create_data_space(user, new_data_space, [user_create: !is_trial?])
    do
      handle = String.to_existing_atom(new_data_space.handle)

      Enum.each(owners ++ collaborators, fn member ->
        user = Accounts.get_user!(member.user_id)
        add_user_to_data_space(new_data_space, user)

        if is_trial? do
          Landlord.create_trial_user(user.id, %{"user_id" => user.id, "ds_id" => :trial})
        else
          Landlord.create_user(Map.put(Map.from_struct(user), :role, member.role), %{"user_id" => user.id, "ds_id" => handle})
        end
      end)
    else
      err ->
        Logger.error(Exception.format(:error, err))
        err
    end
  end


  ## Subscription events

  @doc """
  Manage the subscription lifecycle

  Receives webhook events that keep our state in sycn with the external subscription provider. A
  subscription is generally never deleted, the status field is continously updated to reflect the
  subscription status instead.

  The passthrough field contains the data space handle.
  """
  def manage_subscription(%{"alert_name" => alert_name, "passthrough" => handle} = params) when
    alert_name in ["subscription_created", "subscription_updated", "subscription_cancelled", "subscription_payment_succeeded"]
  do
    case get_data_space_by_handle(handle, unsafe: true) do
      nil -> {:error, :no_such_data_space}
      data_space ->
        case Repo.get(Subscription, params["subscription_id"]) do
          nil -> %Subscription{}
          subscription -> Repo.preload(subscription, [:data_space])
        end
        |> Subscription.changeset(params)
        |> Ecto.Changeset.put_assoc(:data_space, data_space)
        |> Repo.insert_or_update()
    end
  end
  def manage_subscription(_params), do: {:error, :not_interested}


  defp accept_invite_multi(user, data_space, opts \\ []) do
    status = Keyword.get(opts, :status, "pending")

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, %DataSpaceUser{user: user, data_space: data_space, role: "collaborator", status: status})
    |> Ecto.Multi.delete_all(:tokens, DataSpaceToken.user_and_data_space_query(user, data_space))
  end

  defp confirm_member_multi(data_space_user, data_space) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:nr_users, fn repo, _ ->
      {:ok, repo.all(from u in DataSpaceUser,
        where: u.data_space_id == ^data_space.id,
        select: u.status,
        lock: "FOR UPDATE"
      ) |> Enum.filter(fn status -> status == "confirmed" end) |> Enum.count()} # Only count the results after obtaining the lock
    end)
    |> Ecto.Multi.one(:subscription, (from s in Subscription, where: s.data_space_id == ^data_space.id, select: [:subscription_id, :subscription_plan_id]))
    |> Ecto.Multi.run(:data_space_user, fn repo, _ ->
      unless data_space_user.status == "confirmed" do
        {:ok, repo.update!(DataSpaceUser.confirm_member_changeset(data_space_user)) |> repo.preload(:user)}
      else
        {:error, :user_already_confirmed}
      end
    end)
    |> Ecto.Multi.run(:change_seats, fn _repo, %{subscription: subscription, nr_users: nr_users} ->
      sub = subscription && Map.from_struct(subscription)

      if SubscriptionApi.within_user_limit?(sub[:subscription_plan_id], nr_users + 1) do
        SubscriptionApi.change_seats(sub[:subscription_id], nr_users + 1)
      else
        {:error, :plan_limit_reached}
      end
    end)
  end

  defp delete_member_multi(user, data_space) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:nr_users, fn repo, _ ->
      {:ok, repo.all(from u in DataSpaceUser,
        where: u.data_space_id == ^data_space.id,
        select: u.status,
        lock: "FOR UPDATE"
      ) |> Enum.filter(fn status -> status == "confirmed" end) |> Enum.count()}
    end)
    |> Ecto.Multi.one(:subscription, (from s in Subscription, where: s.data_space_id == ^data_space.id, select: [:subscription_id]))
    |> Ecto.Multi.one(:data_space_user, (from u in DataSpaceUser, where: u.user_id == ^user.id and u.data_space_id == ^data_space.id))
    |> Ecto.Multi.delete(:delete, fn %{data_space_user: data_space_user} -> data_space_user end)
    |> Ecto.Multi.run(:change_seats, fn _repo, %{subscription: subscription, nr_users: nr_users} ->
      sub = subscription && Map.from_struct(subscription)

      SubscriptionApi.change_seats(sub[:subscription_id], nr_users - 1)
    end)
  end

  defp email_is_member?(%DataSpace{} = data_space, email) do
    query = from u in User,
      join: d in assoc(u, :data_spaces),
      where: d.id == ^data_space.id and u.email == ^email

    Repo.exists?(query)
  end
end

