module NativePresentationHelpers
  # Chrome cannot resolve iOS's content-size preference. Substitute its resolved
  # system font in the compiled CSS to exercise our root selector and cascade.
  def resolve_native_body_font(size:)
    stylesheet = Rails.root.join("app/assets/builds/application.css").read
      .gsub("-apple-system-body", "#{size}px serif")

    page.execute_script(<<~JS, stylesheet)
      const sheet = new CSSStyleSheet();
      sheet.replaceSync(arguments[0]);
      document.adoptedStyleSheets = [sheet];
    JS
  end

  def add_narrow_button_group
    page.execute_script(<<~JS)
      const group = document.createElement("section");
      group.id = "narrow-buttons";
      group.style.width = "296px";
      group.style.display = "flex";
      group.style.flexWrap = "wrap";
      group.innerHTML = `
        <button class="btn" id="long-button" type="button">Create storage location</button>
        <button class="btn" id="unbroken-button" type="button">CreateAVeryLongStorageLocation</button>
        <a class="btn" href="/privacy" id="long-button-link">Return to storage locations</a>
      `;
      document.querySelector("main").append(group);
    JS
  end

  def rendered_text_bounds(selector)
    page.evaluate_script(<<~JS, selector)
      (() => {
        const range = document.createRange();
        range.selectNodeContents(document.querySelector(arguments[0]));
        const bounds = range.getBoundingClientRect();
        return { width: bounds.width, height: bounds.height };
      })()
    JS
  end

  # Core has no Domain forms or tables; these exercise their shared component
  # styles through the real compiled stylesheet, without adding a public route.
  def add_native_presentation_controls
    page.execute_script(<<~JS)
      document.querySelector("main").insertAdjacentHTML("beforeend", `
        <section>
          <button class="btn" data-size="xs" id="small-button" type="button">Save</button>
          <button class="btn" data-size="lg" id="large-button" type="button">Continue</button>
          <label for="small-input">Name</label>
          <input class="input" id="small-input">
          <label for="small-select">Category</label>
          <select class="select" id="small-select"><option>Equipment</option></select>
          <table class="table">
            <thead><tr><th>Action</th><th>Details</th></tr></thead>
            <tbody><tr>
            <td><a href="/privacy" id="table-link">Edit</a></td>
            <td><a href="/privacy" class="hotwire-native:hidden" id="browser-table-link">Details</a></td>
            </tr></tbody>
          </table>
          <h2 class="hotwire-native:sr-only" id="native-heading">Page heading</h2>
          <p class="hotwire-native:hidden" id="browser-only">Browser navigation</p>
        </section>
      `)
    JS
  end

  def rendered_size(selector)
    page.evaluate_script(<<~JS, selector)
      (() => {
        const bounds = document.querySelector(arguments[0]).getBoundingClientRect();
        return { width: bounds.width, height: bounds.height };
      })()
    JS
  end

  def computed_property(selector, property)
    page.evaluate_script("getComputedStyle(document.querySelector(arguments[0]))[arguments[1]]", selector, property)
  end
end
