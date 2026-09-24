class UiFixtureController < ApplicationController
  prepend_view_path Rails.root.join("spec/fixtures/ui_views")

  VIEW = <<~ERB.freeze
    <% content_for :title, "UI fixture" %>
    <% content_for :inline_flash, true if params[:inline] %>
    <section class="content-narrow page-section">
      <%= render "shared/flash", inline: true if params[:inline] %>
      <h1 class="text-2xl font-semibold">UI fixture</h1>
      <%= link_to "Leave fixture", privacy_path, class: "text-link" %>
    </section>
  ERB

  def show
    render inline: VIEW, layout: "application", formats: [:html], content_type: "text/html"
  end

  def forbidden
    render "errors/forbidden", layout: "application", status: :forbidden
  end

  def record_header
    render inline: <<~ERB, layout: "application"
      <% content_for :title, params.fetch(:title) %>
      <section class="page-section content-detail">
        <article class="card scaffold-card">
          <header class="record-header">
            <%= render "shared/ui/page_heading", title: params.fetch(:title), hide_in_native: true %>
            <div class="record-toolbar">
              <div class="content-actions flex-nowrap">
                <%= render "shared/ui/back", url: privacy_path, label: params.fetch(:label) %>
                <%= link_to "Add Credit", terms_path, class: "btn" %>
              </div>
            </div>
          </header>
        </article>
      </section>
    ERB
  end

  def record_list
    render inline: <<~ERB, layout: "application"
      <% content_for :title, "Record list" %>
      <section class="page-section content-list">
        <article class="card scaffold-card">
          <header>
            <%= render "shared/ui/page_heading", title: "Record list" %>
            <button type="button" id="before-record-list" class="btn">Before rows</button>
          </header>
          <section class="record-list-body">
            <ul id="record-list" class="record-list">
              <li>
                <%= link_to privacy_path, class: "item record-list-item" do %>
                  <section>
                    <dl class="record-details record-list-details">
                      <div>
                        <dt>Movie</dt>
                        <dd>A favorite film</dd>
                      </div>
                      <div>
                        <dt>Notes</dt>
                        <dd><span class="text-muted-foreground">Not set</span></dd>
                      </div>
                    </dl>
                  </section>
                  <aside aria-hidden="true">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-4 shrink-0 text-muted-foreground" focusable="false">
                      <path d="m9 18 6-6-6-6" />
                    </svg>
                  </aside>
                <% end %>
              </li>
              <li>
                <div class="item record-list-item">
                  <section>
                    <span class="record-list-title">Unavailable</span>
                  </section>
                </div>
              </li>
            </ul>
          </section>
        </article>
      </section>
    ERB
  end

  def success
    redirect_to "/__ui/fixture", success: "Saved the record", status: :see_other
  end

  def guidance
    flash.now[:notice] = "Check your email to continue"
    flash.now[:alert] = "The request needs attention"
    flash.now[:warning] = params[:blank_warning] ? "" : "Keep this recovery code"
    show
  end
end

Rails.application.routes.prepend do
  get "/__ui/fixture", to: "ui_fixture#show"
  get "/__ui/forbidden", to: "ui_fixture#forbidden"
  post "/__ui/fixture", to: "ui_fixture#success"
  get "/__ui/success", to: "ui_fixture#success"
  get "/__ui/guidance", to: "ui_fixture#guidance"
  get "/__ui/record_header", to: "ui_fixture#record_header"
  get "/__ui/record_list", to: "ui_fixture#record_list"
end
Rails.application.reload_routes!
