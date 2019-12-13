import componentTest from "helpers/component-test";

moduleForComponent("payment-options", { integration: true });

componentTest("Discourse Subscriptions payment options have no plans", {
  template: `{{payment-options plans=plans}}`,

  async test(assert) {
    this.set("plans", false);

    assert.equal(
      find(".btn-discourse-subscriptions-subscribe").length,
      0,
      "The plan buttons are not shown"
    );
  }
});

componentTest("Discourse Subscriptions payment options has content", {
  template: `{{payment-options plans=plans planTypeIsSelected=planTypeIsSelected}}`,

  async test(assert) {
    this.set("plans", [
      { currency: "aud", interval: "year", amountDollars: "44.99" },
      { currency: "gdp", interval: "month", amountDollars: "9.99" }
    ]);

    this.set("planTypeIsSelected", true);

    assert.equal(
      find(".btn-discourse-subscriptions-payment-type").length,
      2,
      "The payment type buttons are shown"
    );
    assert.equal(
      find(".btn-discourse-subscriptions-subscribe").length,
      2,
      "The plan buttons are shown"
    );
    assert.equal(
      find("#subscribe-buttons .btn-primary").length,
      0,
      "No plan buttons are selected by default"
    );
    assert.equal(
      find(".btn-discourse-subscriptions-subscribe:first-child .interval")
        .text()
        .trim(),
      "Yearly",
      "The plan interval is shown"
    );
    assert.equal(
      find(".btn-discourse-subscriptions-subscribe:first-child .amount")
        .text()
        .trim(),
      "$AUD 44.99",
      "The plan amount and currency is shown"
    );
  }
});

componentTest("Discourse Subscriptions payment type plan", {
  template: `{{payment-options plans=plans planTypeIsSelected=planTypeIsSelected}}`,

  async test(assert) {
    this.set("plans", [
      { currency: "aud", interval: "year", amountDollars: "44.99" }
    ]);

    this.set("planTypeIsSelected", true);

    assert.equal(
      find("#discourse-subscriptions-payment-type-plan.btn-primary").length,
      1,
      "The plan type button is selected"
    );

    assert.equal(
      find("#discourse-subscriptions-payment-type-payment.btn-primary").length,
      0,
      "The payment type button is not selected"
    );

    await click("#discourse-subscriptions-payment-type-payment");

    assert.equal(
      find("#discourse-subscriptions-payment-type-plan.btn-primary").length,
      0,
      "The plan type button is selected"
    );

    assert.equal(
      find("#discourse-subscriptions-payment-type-payment.btn-primary").length,
      1,
      "The payment type button is not selected"
    );
  }
});
