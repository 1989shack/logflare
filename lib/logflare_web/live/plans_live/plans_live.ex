defmodule LogflareWeb.PlansLive do
  @moduledoc false
  use Phoenix.LiveView, layout: {LogflareWeb.SharedView, "live_widget.html"}
  use Phoenix.HTML

  alias Logflare.Plans
  alias Logflare.Users
  alias LogflareWeb.BillingHelpers

  alias LogflareWeb.Router.Helpers, as: Routes

  def mount(_params, %{"user_id" => user_id}, socket) do
    user =
      Users.get_user(user_id)
      |> Users.preload_sources()
      |> Users.preload_billing_account()

    plan = Plans.get_plan_by_user(user)

    socket =
      socket
      |> assign(:period, "month")
      |> assign(:plans, Plans.list_plans())
      |> assign(:plan, plan)
      |> assign(:user, user)

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:period, "month")
      |> assign(:plans, Plans.list_plans())
      |> assign(:plan, nil)
      |> assign(:user, nil)

    {:ok, socket}
  end

  def handle_event("switch_period", %{"period" => period}, socket) do
    {:noreply, assign(socket, :period, period)}
  end

  def render(assigns) do
    ~L"""
    <div class="scrolling-wrapper">
    <div class="min-pricing-width">
    <div class="d-flex justify-content-around my-5">
    <div class="card py-3 bg-transparent">
        <div class="card-header-min-height p-4 border-0">
        </div>
        <div class="card-body p-0">
          <ul class="list-unstyled">
            <li class="p-2">Team members </li>
            <li class="p-2">Sources <%= link to: Routes.marketing_path(@socket, :pricing) <> "#sources", class: "position-absolute absolute-right" do %><i class="fas fa-info-circle"></i><% end %></li>
            <hr />
            <li class="p-2">Alert frequency</li>
            <li class="p-2">Dashboards <%= link to: Routes.marketing_path(@socket, :pricing) <> "#dashboards", class: "position-absolute absolute-right" do %><i class="fas fa-info-circle"></i><% end %></li>
            <hr />
            <li class="p-2">Backend <%= link to: Routes.marketing_path(@socket, :pricing) <> "#backend", class: "position-absolute absolute-right" do %><i class="fas fa-info-circle"></i><% end %></li>
            <li class="p-2">Fields <%= link to: Routes.marketing_path(@socket, :pricing) <> "#fields", class: "position-absolute absolute-right" do %><i class="fas fa-info-circle"></i><% end %></li>
            <hr />
            <li class="p-2">Event Retention <%= link to: Routes.marketing_path(@socket, :pricing) <> "#retention", class: "position-absolute absolute-right" do %><i class="fas fa-info-circle"></i><% end %></li>
            <li class="p-2">Events per month</li>
            <hr />
            <li class="p-2">Rate limit <%= link to: Routes.marketing_path(@socket, :pricing) <> "#rate-limit", class: "position-absolute absolute-right" do %><i class="fas fa-info-circle"></i><% end %></li>
            <li class="p-2">Rate burst</li>
          </ul>
          <div class="py-4 px-2">
            <p>Get 2 months free with a yearly plan!</p>
            <button phx-click="switch_period" phx-value-period=<%= period!(@period) %> class="btn btn-dark text-white w-100 mr-0">Choose <%= period!(@period) <> "ly" %></button>
          </div>
        </div>
      </div>
      <div class="card card-active-hover text-center py-3">
        <div class="card-header-min-height p-4 border-0">
          <h3 class="text-white">Free</h3>
        </div>
        <div class="card-body p-0">
          <ul class="list-unstyled">
            <li class="p-2">0 additional</li>
            <li class="p-2">Unlimited</li>
            <hr />
            <li class="p-2">4 hours</li>
            <li class="p-2">None</li>
            <hr />
            <li class="p-2">Logflare</li>
            <li class="p-2">Up to 50</li>
            <hr />
            <li class="p-2">3 days</li>
            <li class="p-2">12,960,000</li>
            <hr />
            <li class="p-2">5 per second</li>
            <li class="p-2">300</li>
          </ul>
          <div class="py-4">
            <h2 class="text-white mb-1">$<span class="price">0</span></h2>
            <small class="text-muted">per <%= @period %> / per source</small>
          </div>
          <div class="py-4">
            <%= link "Continue", to: Routes.auth_path(@socket, :login), class: "btn btn-dark text-white w-75 mr-0" %>
          </div>
        </div>
      </div>
      <div class="card card-active-hover text-center py-3">
        <div class="card-header-min-height p-4 border-0">
          <h3 class="text-white">Hobby</h3>
        </div>
        <div class="card-body p-0">
          <ul class="list-unstyled">
            <li class="p-2">1 additional</li>
            <li class="p-2">Unlimited</li>
            <hr />
            <li class="p-2">1 hour</li>
            <li class="p-2">Google Data Studio</li>
            <hr />
            <li class="p-2">Logflare || BYOB BigQuery<sup>1</sup></li>
            <li class="p-2">Up to 100</li>
            <hr />
            <li class="p-2">7 days || Unlimited</li>
            <li class="p-2">64,800,000</li>
            <hr />
            <li class="p-2">25 per second</li>
            <li class="p-2">1,500</li>
          </ul>
          <div class="py-4">
            <%= if @period == "year" do %>
              <h2 class="text-white"><%= Plans.find_plan(@plans, @period, "Hobby").price |> div(12) |> Money.new(:USD) |> Money.to_string(fractional_unit: true) %></h2>
            <% else %>
              <h2 class="text-white"><%= Plans.find_plan(@plans, @period, "Hobby").price |> Money.new(:USD) |> Money.to_string(fractional_unit: false) %></h2>
            <% end %>
            <small class="text-muted">per month / per source</small></br>
            <small class="text-muted">paid <%= @period %>ly</small>
          </div>
          <div class="py-4">
            <div>
              <%= BillingHelpers.sub_button(@plan, @socket, @plans, @period, "Hobby") %>
            </div>
          <div>
            <small class="text-muted">14-day trial</small>
          </div>
          </div>
        </div>
      </div>
      <div class="card card-active-popular text-center py-3">
        <div class="card-header-min-height p-4 border-0">
          <h3 class="text-white">Pro</h3>
        </div>
        <div class="card-body p-0">
          <ul class="list-unstyled">
            <li class="p-2">4 additional</li>
            <li class="p-2">Unlimited</li>
            <hr />
            <li class="p-2">15 minutes</li>
            <li class="p-2">Google Data Studio</li>
            <hr />
            <li class="p-2">Logflare || BYOB BigQuery<sup>1</sup></li>
            <li class="p-2">Up to 250</li>
            <hr />
            <li class="p-2">30 days || Unlimited</li>
            <li class="p-2">64,800,000</li>
            <hr />
            <li class="p-2">25 per second</li>
            <li class="p-2">1,500</li>
          </ul>
          <div class="py-4">
            <%= if @period == "year" do %>
              <h2 class="text-white"><%= Plans.find_plan(@plans, @period, "Pro").price |> div(12) |> Money.new(:USD) |> Money.to_string(fractional_unit: true) %></h2>
            <% else %>
              <h2 class="text-white"><%= Plans.find_plan(@plans, @period, "Pro").price |> Money.new(:USD) |> Money.to_string(fractional_unit: false) %></h2>
            <% end %>
            <small class="text-muted">per month / per source</small></br>
            <small class="text-muted">paid <%= @period %>ly</small>
          </div>
          <div class="py-4">
            <div>
              <%= BillingHelpers.sub_button(@plan, @socket, @plans, @period, "Pro") %>
            </div>
          <div>
            <small class="text-muted">14-day trial</small>
          </div>
          </div>
        </div>
      </div>
      <div class="card card-active-hover text-center py-3">
        <div class="card-header-min-height p-4 border-0">
          <h3 class="text-white">Business</h3>
        </div>
        <div class="card-body p-0">
          <ul class="list-unstyled">
            <li class="p-2">9 additional</li>
            <li class="p-2">Unlimited</li>
            <hr />
            <li class="p-2">1 minute</li>
            <li class="p-2">Google Data Studio</li>
            <hr />
            <li class="p-2">Logflare || BYOB BigQuery<sup>1</sup></li>
            <li class="p-2">Up to 500</li>
            <hr />
            <li class="p-2">60 days || Unlimited</li>
            <li class="p-2">64,800,000</li>
            <hr />
            <li class="p-2">25 per second</li>
            <li class="p-2">1,500</li>
          </ul>
          <div class="py-4">
            <%= if @period == "year" do %>
              <h2 class="text-white"><%= Plans.find_plan(@plans, @period, "Business").price |> div(12) |> Money.new(:USD) |> Money.to_string(fractional_unit: true) %></h2>
            <% else %>
              <h2 class="text-white"><%= Plans.find_plan(@plans, @period, "Business").price |> Money.new(:USD) |> Money.to_string(fractional_unit: false) %></h2>
            <% end %>
            <small class="text-muted">per month / per source</small></br>
            <small class="text-muted">paid <%= @period %>ly</small>
          </div>
          <div class="py-4">
            <div>
              <%= BillingHelpers.sub_button(@plan, @socket, @plans, @period, "Business") %>
            </div>
          <div>
            <small class="text-muted">14-day trial</small>
          </div>
          </div>
        </div>
      </div>
    </div>
    </div>
    </div>
    <div class="">
            <p class="nam-consectetur-an"><sup>1</sup> Bring Your Own Backend™ to use with Logflare. Give our service account access to your Google Cloud Platform account and all reads and writes from Logflare will be performed directly on your BigQuery tables. Never archive to object storage again.</p>
            <p class="nam-consectetur-an"><sup>2</sup> Standard plans are subject to our <%= link "fair use", to: Routes.marketing_path(@socket, :pricing) <> "#fair-use" %> policy.</p>
    </div>
    """
  end

  defp period!("month"), do: "year"
  defp period!("year"), do: "month"
end
