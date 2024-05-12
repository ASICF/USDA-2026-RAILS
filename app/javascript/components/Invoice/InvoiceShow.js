import React, { useState, Fragment, useEffect } from "react";

import {
  Button,
  Header,
  Modal,
  Icon,
  Divider,
  Segment,
  Breadcrumb,
  Table,
  Grid,
  Form,
  ButtonContent,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import moment from "moment";
import { tableSortReducer } from "../Shared/TableSort";
import RenderValue from "../Shared/RenderValue";

const InvoiceShow = ({ invoice, packing_slip }) => {
  console.log("InvoiceShow", { invoice, packing_slip });
  return <div>InvoiceShow</div>;
};

export default InvoiceShow;
