import "/test/components/nesting/absolute.sly";
import "/test/components/nesting/relative.sly";

describe("component handling", () => {
  let container;
  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });
  afterEach(() => {
    container.remove();
  });

  it("creating nested absolute component", () => {
    const element = document.createElement("test-components-nesting-absolute");
    container.appendChild(element);

    expect(element.shadowRoot.childNodes.length).toBe(1);
    expect(element.shadowRoot.childNodes[0].tagName).toBe(
      "TEST-COMPONENTS-NESTING-DEEP-INDEX"
    );
    expect(element.shadowRoot.childNodes[0].shadowRoot.childNodes.length).toBe(
      1
    );
    expect(
      element.shadowRoot.childNodes[0].shadowRoot.childNodes[0].tagName
    ).toBe("DIV");
    expect(
      element.shadowRoot.childNodes[0].shadowRoot.childNodes[0].textContent
    ).toBe("nested component");
  });

  it("creating nested relative component", () => {
    const element = document.createElement("test-components-nesting-relative");
    container.appendChild(element);

    expect(element.shadowRoot.childNodes.length).toBe(1);
    expect(element.shadowRoot.childNodes[0].tagName).toBe(
      "TEST-COMPONENTS-NESTING-DEEP-INDEX"
    );
    expect(element.shadowRoot.childNodes[0].shadowRoot.childNodes.length).toBe(
      1
    );
    expect(
      element.shadowRoot.childNodes[0].shadowRoot.childNodes[0].tagName
    ).toBe("DIV");
    expect(
      element.shadowRoot.childNodes[0].shadowRoot.childNodes[0].textContent
    ).toBe("nested component");
  });
});
