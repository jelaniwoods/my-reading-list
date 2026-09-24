module ApplicationHelper
  def full_page_title
    page_title = content_for(:title).presence
    titles = hotwire_native_app? ? [page_title] : [page_title, t("app_name")]

    safe_join(titles.compact.presence || [t("app_name")], " · ")
  end
end
