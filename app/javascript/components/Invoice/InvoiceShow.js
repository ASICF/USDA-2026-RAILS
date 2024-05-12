import React, { useState, Fragment, useEffect } from "react";

import {
  Button,
  Header,
  Divider,
  Segment,
  Breadcrumb,
  Table,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import moment from "moment";
import { tableSortReducer } from "../Shared/TableSort";
import RenderValue from "../Shared/RenderValue";

const InvoiceShow = ({ invoice, packing_slips }) => {
  console.log("InvoiceShow", { invoice, packing_slips });

  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: packing_slips,
    direction: null,
  });
  const { column, data: sorted_packing_slips, direction } = state;

  return (
    <div>
      <div style={{ marginTop: "15px", display: "inline-block" }}>
        <Breadcrumbs>
          <Breadcrumb.Section href="/invoices">
            Invoices
          </Breadcrumb.Section>
          <Breadcrumb.Divider />
          <Breadcrumb.Section active>{invoice.number}</Breadcrumb.Section>
        </Breadcrumbs>
      </div>
      <Button
        floated="right"
        secondary
        as="a"
        href={`/invoices/${invoice.id}/edit`}
      >
        Edit
      </Button>
      <div style={{ clear: "both" }} />
      <Divider />

      <Segment>
        <Table basic="very" celled>
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell>Number</Table.HeaderCell>
              <Table.HeaderCell>Project</Table.HeaderCell>
              <Table.HeaderCell>Invoiced Date</Table.HeaderCell>
              <Table.HeaderCell>Acres</Table.HeaderCell>
              <Table.HeaderCell>Amount</Table.HeaderCell>
            </Table.Row>
          </Table.Header>

          <Table.Body>
            <Table.Row>
              <Table.Cell>{invoice.number}</Table.Cell>
              <Table.Cell>{invoice.project}</Table.Cell>
              <Table.Cell>
                <RenderValue value={invoice.invoice_date} date />
              </Table.Cell>
              <Table.Cell>
                <RenderValue value={invoice.acres} numeric />
              </Table.Cell>
              <Table.Cell>
                <RenderValue value={invoice.amount} currency />
              </Table.Cell>
            </Table.Row>
          </Table.Body>
        </Table>
      </Segment>

      <Header as="h4" block inverted>
        Associated Packing Slips
      </Header>

      <Table unstackable sortable celled striped>
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell
              sorted={column === "name" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "name" })}
            >
              Name
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "states" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "states" })
              }
            >
              State
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "project" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "project" })
              }
            >
              Project
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "tile_count" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "tile_count" })
              }
            >
              Number of Tiles
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "shipped_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "shipped_date" })
              }
            >
              Ship Date
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {sorted_packing_slips.map((record) => {
            return (
              <Table.Row key={record.id}>
                <Table.Cell>{record.name}</Table.Cell>
                <Table.Cell>{record.state_abv}</Table.Cell>
                <Table.Cell>{record.project}</Table.Cell>
                <Table.Cell>{record.tile_count}</Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.shipped_date} date />
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    </div>
  );
};

export default InvoiceShow;
