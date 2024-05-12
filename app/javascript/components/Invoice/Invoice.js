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

const Invoices = ({ invoices }) => {
  console.log("Invoices", { invoices });

  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: invoices,
    direction: null,
  });
  const { column, data, direction } = state;

  return (
    <div>
      <div style={{ marginTop: "15px", display: "inline-block" }}>
        <Breadcrumbs>
          <Breadcrumb.Section active>Invoices</Breadcrumb.Section>
        </Breadcrumbs>
      </div>

      <Button floated="right" primary as="a" href="/invoices/new">
        Create new Invoice
      </Button>
      <div style={{ clear: "both" }} />

      <Divider />
      <Table sortable selectable celled textAlign="center">
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell
              sorted={column === "name" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "name" })}
            >
              Number
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "easement_count" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "easement_count" })
              }
            >
              Invoice Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "easement_acres" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "easement_acres" })
              }
            >
              Total Acres
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "total_cost" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "total_cost" })
              }
            >
              Amount
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "awarded" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "awarded" })
              }
            >
              Packing Slip Count
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {data.map((invoice) => {
            return (
              <Table.Row
                key={invoice.id}
                onClick={() => {
                  location.href = `/invoices/${invoice.id}`;
                }}
              >
                <Table.Cell>{invoice.number}</Table.Cell>
                <Table.Cell>
                  {moment(invoice.invoice_date).format("l")}
                </Table.Cell>
                <Table.Cell>{invoice.acres}</Table.Cell>
                <Table.Cell>
                  <RenderValue value={invoice.amount} currency />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={invoice.packing_slips} number />
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    </div>
  );
};

export default Invoices;
