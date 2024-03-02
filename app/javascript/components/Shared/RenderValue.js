import React, { Fragment } from "react";
import moment from "moment";

function RenderValue({ value, date, utc, currency, percentage, numeric }) {
  // console.error("RenderValue", {
  //   value,
  //   date,
  //   utc,
  //   currency,
  //   percentage,
  //   numeric,
  // });

  // date then format with momment
  if (value && date) {
    return <Fragment>{moment(value).format("l")}</Fragment>;
  }

  if (value && utc) {
    return moment.utc(value).format("l h:mm A");
  }

  // check if the value is a number
  if (Number.isFinite(parseFloat(value)) && currency) {
    return formatter.format(value);
  }

  if (value && percentage) {
    return `${value}%`;
  }

  // check if the value is a number
  if (Number.isFinite(value) && numeric) {
    return value;
  }

  // If no type then just render as is
  // => if the value is zero then it won't render so use numeric if you want it to render
  if (value) {
    return value;
  }

  // return if no value
  return <Fragment> - </Fragment>;
}

// format currency
const formatter = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
});

export default RenderValue;
