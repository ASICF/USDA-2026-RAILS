import React, { useState, Fragment } from "react";
import { Breadcrumb } from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

export default function Breadcrumbs({ children }) {
  return (
    <Breadcrumb>
      {children}
    </Breadcrumb>
  );
}
