import { Promise } from "rsvp";

export function stubStripe() {
  window.Stripe = () => {
    return {
      createPaymentMethod() {
        return new Promise((resolve) => {
          resolve({});
        });
      },
      paymentRequest() {
        const paymentRequestStub = () => {};
        paymentRequestStub.canMakePayment = () => {
          return new Promise((resolve) => {
            resolve(true);
          });
        };
        paymentRequestStub.on = (eventName) => {
          if (eventName === "token") {
            return new Promise((resolve) => {
              resolve({
                token: {
                  id: "test_token",
                },
              });
            });
          }
        };
        return paymentRequestStub;
      },
      elements() {
        return {
          create() {
            return {
              on() {},
              card() {},
              mount() {},
              update() {},
            };
          },
        };
      },
    };
  };
}
