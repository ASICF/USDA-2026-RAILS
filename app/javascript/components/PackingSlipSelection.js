import React, { useState, useEffect, useRef, Fragment } from "react";
import {
  Input,
  Button,
  Breadcrumb,
  Table,
  Segment,
  Divider,
  Header,
  Icon,
} from "semantic-ui-react";
import _ from "lodash";
import moment from "moment";

import "semantic-ui-css/semantic.min.css";
import "./Styles/default";

import Breadcrumbs from "./Shared/Breadcrumb";
import MessageBox from "./Shared/MessageBox";
import { tableSortReducer } from "./Shared/TableSort";

export default function PackingSlipSelection(props) {
  const [term, setTerm] = useState("");

  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: props.psns,
    direction: null,
  });
  const { column, data, direction } = state;

  useEffect(() => {
    if (term.length === 0) {
      dispatch({ data: props.psns, type: "UPDATE_DATA", column, direction });
    } else {
      dispatch({
        data: props.psns.filter((psn) => psn.name.indexOf(term) >= 0),
        type: "UPDATE_DATA",
        column,
        direction,
      });
    }
  }, [term]);

  const handleChange = (e, { value }) => {
    setTerm(value);
  };

  const handleClick = (id) => {
    window.location = `/packing_slip_worksheets/${id}`;
  };

  console.log(props);

  if (props.psns.length === 0) {
    return (
      <Fragment>
        {renderBreadCrumbs()}
        <MessageBox message={"No Packing Slips Found"} />
      </Fragment>
    );
  }

  // console.log("PackingSlipSelection", { props, data });
  return (
    <Fragment>
      {renderBreadCrumbs()}

      <Input
        fluid
        icon="search"
        iconPosition="left"
        placeholder="Filter Packing Slips by Name"
        onChange={handleChange}
        value={term}
      />

      <Divider />

      {data.length === 0 ? (
        <MessageBox message={"No Packing Slips Found"} />
      ) : null}

      {renderTable()}

      <br />
      <br />
    </Fragment>
  );

  function renderBreadCrumbs() {
    return (
      <Fragment>
        <Breadcrumbs>
          <Breadcrumb.Section>Reports</Breadcrumb.Section>
          <Breadcrumb.Divider />
          <Breadcrumb.Section active>Packing Slip Selction</Breadcrumb.Section>
        </Breadcrumbs>
        <Divider />
      </Fragment>
    );
  }

  function renderTable() {
    if (data.length === 0) return null;

    return (
      <div className="table-overflow">
        <Table selectable unstackable sortable celled striped>
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell
                sorted={column === "name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "name" })
                }
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
                sorted={column === "doqqs_count" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "doqqs_count" })
                }
              >
                Number of Doqqs
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "created_at" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "created_at" })
                }
              >
                Create Date
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "approved_date" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "approved_date" })
                }
              >
                Approve Date
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
            {data.map((record) => {
              return (
                <Table.Row
                  style={{ cursor: "pointer" }}
                  key={record.id}
                  onClick={() => handleClick(record.id)}
                >
                  <Table.Cell>{record.name}</Table.Cell>
                  <Table.Cell>{record.states}</Table.Cell>
                  <Table.Cell>{record.project}</Table.Cell>
                  <Table.Cell>{record.tile_count}</Table.Cell>
                  <Table.Cell>{record.doqqs_count}</Table.Cell>
                  <Table.Cell>
                    {record.created_at
                      ? moment(record.created_at).format("l HH:mm A")
                      : "Not Available"}
                  </Table.Cell>
                  <Table.Cell
                    positive={record.approved_date ? true : false}
                    negative={record.approved_date ? false : true}
                  >
                    {record.approved_date
                      ? moment(record.approved_date).format("l")
                      : "Not Available"}
                  </Table.Cell>
                  <Table.Cell
                    positive={record.shipped_date ? true : false}
                    negative={record.shipped_date ? false : true}
                  >
                    {record.shipped_date
                      ? moment(record.shipped_date).format("l")
                      : "Not Available"}
                  </Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>

          <Table.Footer>
            <Table.Row>
              <Table.HeaderCell colSpan="6">
                <Header as="h4">
                  Showing {data.length} out of {props.psns.length} Packing Slips
                </Header>
              </Table.HeaderCell>
            </Table.Row>
          </Table.Footer>
        </Table>
      </div>
    );
  }
}
