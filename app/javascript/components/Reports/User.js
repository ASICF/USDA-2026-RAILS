import React, { useState, Fragment, useEffect } from "react";

import { Button, Table, Icon, Divider, Breadcrumb } from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import { tableSortReducer } from "../Shared/TableSort";

export default function User({ records }) {
  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: records,
    direction: null,
  });
  const { column, data, direction } = state;

//   console.error("User", { records });

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Manage</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Users</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>All</Breadcrumb.Section>
      </Breadcrumbs>
      <Button primary floated="right" size="tiny" href="/users/new">
        <Icon name="plus" />
        Create User
      </Button>
      <Divider />
      {renderTable()}
      <br />
      <br />
    </div>
  );

  function renderTable() {
    return (
      <Table sortable celled textAlign="center">
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell
              sorted={column === "first_name" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "first_name" })}
            >
              Name
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "role" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "role" })}
            >
              Role
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "approved" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "approved" })}
            >
              Approved
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "marked_as_destroyed" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "marked_as_destroyed" })}
            >
              Marked as Destroyed
            </Table.HeaderCell>
            <Table.HeaderCell collapsing></Table.HeaderCell>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {data.map((record, index) => {
            return (
              <Table.Row key={index}>
                <Table.Cell>
                  {record.first_name} {record.last_name}
                </Table.Cell>
                <Table.Cell>{record.role}</Table.Cell>
                <Table.Cell>
                  {record.approved ? (
                    <Icon name="checkmark" color="green" />
                  ) : (
                    <Icon name="remove" color="red" />
                  )}
                </Table.Cell>
                <Table.Cell>
                  {record.marked_as_destroyed ? (
                    <Icon name="checkmark" color="green" />
                  ) : (
                    <Icon name="remove" color="red" />
                  )}
                </Table.Cell>

                <Table.Cell>
                  <Button
                    icon
                    secondary
                    size="small"
                    href={`/users/${record.id}/edit`}
                  >
                    <Icon name="setting" />
                  </Button>
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    );
  }
}
