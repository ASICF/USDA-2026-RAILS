import React, { useEffect, useState, Fragment } from "react";
import { Button, Divider, Form, Breadcrumb, Table } from "semantic-ui-react";
import Breadcrumbs from "../Shared/Breadcrumb";
import MessageBox from "../Shared/MessageBox";
import { tableSortReducer } from "../Shared/TableSort";

function ReadyToShipCounty({ meta, tiles, message }) {
  console.log("ReadyToShipCounty", { meta, tiles, message });

  if (message) {
    return (
      <div>
        <Breadcrumbs>
          <Breadcrumb.Section>Reports</Breadcrumb.Section>
          <Breadcrumb.Divider />
          <Breadcrumb.Section link href="/ready_to_ship">Ready to Ship</Breadcrumb.Section>
          {meta && meta.state_name && (
            <Fragment>
              <Breadcrumb.Divider />
              <Breadcrumb.Section>{meta.state_name}</Breadcrumb.Section>
            </Fragment>
          )}
          {meta && meta.county_name && (
            <Fragment>
              <Breadcrumb.Divider />
              <Breadcrumb.Section active>
                {meta.county_name} County
              </Breadcrumb.Section>
            </Fragment>
          )}
        </Breadcrumbs>
        <MessageBox message={message} />
      </div>
    );
  }

  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: tiles || [],
    direction: null,
  });
  const { column, data, direction } = state;

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
          <Breadcrumb.Section link href="/ready_to_ship">Ready to Ship</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>{meta.state_name}</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>
          {meta.county_name} County
        </Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      <Table unstackable celled striped structured sortable textAlign="center">
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell
              sorted={column === "easement_no" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "easement_no" })
              }
            >
              Easement #
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "flight_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "flight_date" })
              }
            >
              Flight Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "at_done_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "at_done_date" })
              }
            >
              AT Done Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "ortho_proc_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "ortho_proc_date" })
              }
            >
              Ortho Processed Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "dump_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "dump_date" })
              }
            >
              Dumped
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "ship_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "ship_date" })
              }
            >
              Ship Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "flown_by" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "flown_by" })
              }
            >
              Flown By
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "camera" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "camera" })
              }
            >
              Plane
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "camera" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "camera" })
              }
            >
              Plane
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "county_flown_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "county_flown_date" })
              }
            >
              County Flown Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "county_due_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "county_due_date" })
              }
            >
              County Due Date
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Body>
          {data.map((record) => {
            console.log(record);
            return (
              <Table.Row key={record.id}>
                <Table.Cell>{record.easement_no}</Table.Cell>
                <Table.Cell>{record.flight_date_formatted}</Table.Cell>
                <Table.Cell>{record.at_done_date_formatted}</Table.Cell>
                <Table.Cell>{record.ortho_proc_formatted}</Table.Cell>
                <Table.Cell>{record.dump_date_formatted}</Table.Cell>
                <Table.Cell>{record.ship_date_formatted}</Table.Cell>
                <Table.Cell>{record.flown_by}</Table.Cell>
                <Table.Cell>{record.plane}</Table.Cell>
                <Table.Cell>{record.camera}</Table.Cell>
                <Table.Cell>{record.county_flown_date_formatted}</Table.Cell>
                <Table.Cell>{record.county_due_date_formatted}</Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
      <br />
      <br />
      <br />
    </div>
  );
}

export default ReadyToShipCounty;
