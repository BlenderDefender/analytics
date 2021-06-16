defmodule PlausibleWeb.AuthorizeSiteAccess do
  import Plug.Conn
  use Plausible.Repo

  def init([]), do: [:public, :viewer, :admin, :owner]
  def init(allowed_roles), do: allowed_roles

  def call(conn, allowed_roles) do
    site = Repo.get_by(Plausible.Site, domain: conn.params["domain"] || conn.params["website"])
    shared_link_auth = conn.params["auth"]

    shared_link_record =
      shared_link_auth && Repo.get_by(Plausible.Site.SharedLink, slug: shared_link_auth)

    if !site do
      PlausibleWeb.ControllerHelpers.render_error(conn, 404) |> halt
    else
      user = conn.assigns[:current_user]
      membership_role = user && Plausible.Sites.role(user.id, site)

      role =
        cond do
          user && membership_role ->
            membership_role

          site.public ->
            :public

          shared_link_record && shared_link_record.site_id == site.id ->
            :public

          user.email in admin_emails() ->
            :admin

          true ->
            nil
        end

      if role in allowed_roles do
        merge_assigns(conn, site: site, current_user_role: role)
      else
        PlausibleWeb.ControllerHelpers.render_error(conn, 404) |> halt
      end
    end
  end

  defp admin_emails() do
    Application.get_env(:plausible, :admin_emails)
  end
end