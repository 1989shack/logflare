defmodule LogflareWeb.Auth.OauthController do
  use LogflareWeb, :controller

  plug Ueberauth

  alias Logflare.JSON
  alias Logflare.Source
  alias LogflareWeb.AuthController

  def callback(
        %{assigns: %{ueberauth_auth: _auth}} = conn,
        %{"state" => "", "provider" => "slack"} = params
      ) do
    callback(conn, Map.drop(params, ["state"]))
  end

  def callback(
        %{assigns: %{ueberauth_auth: auth}} = conn,
        %{"state" => state, "provider" => "slack"} = _params
      )
      when is_binary(state) do
    state = JSON.decode!(state)

    case state["action"] do
      "save_hook_url" ->
        source = state["source"]
        slack_hook_url = auth.extra.raw_info.token.other_params["incoming_webhook"]["url"]
        source_changes = %{slack_hook_url: slack_hook_url}

        changeset =
          Source.changeset(
            %Source{id: source["id"], name: source["name"], token: source["token"]},
            source_changes
          )

        case RepoWithCache.update(changeset) do
          {:ok, _source} ->
            conn
            |> put_flash(:info, "Slack connected!")
            |> redirect(to: Routes.source_path(conn, :edit, source["id"]))

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Something went wrong!")
            |> redirect(to: Routes.source_path(conn, :edit, source["id"]))
        end
    end
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => "google"} = _params) do
    auth_params = %{
      token: auth.credentials.token,
      email: auth.info.email,
      email_preferred: auth.info.email,
      provider: "google",
      image: auth.info.image,
      name: auth.info.name,
      provider_uid: generate_provider_uid(auth, auth.provider),
      valid_google_account: true
    }

    AuthController.check_invite_token_and_signin(conn, auth_params)
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    auth_params = %{
      token: auth.credentials.token,
      email: auth.info.email,
      email_preferred: auth.info.email,
      provider: Atom.to_string(auth.provider),
      image: auth.info.image,
      name: auth.info.name,
      provider_uid: generate_provider_uid(auth, auth.provider)
    }

    AuthController.check_invite_token_and_signin(conn, auth_params)
  end

  def callback(%{assigns: %{ueberauth_failure: _auth}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication error! Please contact support if this continues.")
    |> redirect(to: Routes.source_path(conn, :dashboard))
  end

  defp generate_provider_uid(auth, :slack) do
    auth.credentials.other.user_id
  end

  defp generate_provider_uid(auth, provider) when provider in [:google, :github] do
    if is_integer(auth.uid) do
      Integer.to_string(auth.uid)
    else
      auth.uid
    end
  end
end
