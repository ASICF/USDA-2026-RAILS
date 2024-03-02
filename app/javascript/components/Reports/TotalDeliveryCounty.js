import React, { Fragment, useState, useEffect } from "react";
import {
  Button,
  Header,
  Table,
  Divider,
  Breadcrumb,
  Input,
} from "semantic-ui-react";
import _ from "lodash";
import moment from "moment";
import { tableSortReducer } from "../Shared/TableSort";
import "semantic-ui-css/semantic.min.css";
import "../Styles/default";
import axios from "axios";
import Breadcrumbs from "../Shared/Breadcrumb";
import RenderValue from "../Shared/RenderValue";
import MessageBox from "../Shared/MessageBox";

const TotalDeliveryCounty = ({ states }) => {
  const [searchInput, setSearchInput] = useState("");
  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: states,
    direction: null,
  });
  console.log({ states });
  const { column, data, direction } = state;
  var inputTimeout;
  const searchItems = (searchValue) => {
    // Clear the timeout if the user keeps typing
    clearTimeout(inputTimeout);

    // Start a half second timeout
    inputTimeout = setTimeout(() => {
      // if the timeout occurs then store the text
      setSearchInput(searchValue.toLowerCase());
    }, 500);
  };

  // Filter the results when the
  useEffect(() => {
    let filteredData = [];

    // if the searchinput is empty then store the original records
    // => If there is text then filter it by the searchinput
    if (searchInput.length === "") {
      filteredData = states.name;
    } else {
      filteredData = states.filter((state) => {
        return Object.values(state)
          .join("")
          .toLowerCase()
          .includes(searchInput);
      });
    }

    // update the data in the table
    dispatch({
      data: filteredData,
      type: "UPDATE_DATA",
      column,
      direction,
    });
  }, [searchInput]);

  const Empty = () => {
    if (data.length === 0) {
      return <MessageBox message={"No States matched the searched text"} />;
    }
  };
  // Return table with records
  return (
    <div className="table-overflow" style={{ marginBottom: "1em" }}>
      <Fragment>
        <Breadcrumbs>
          <Breadcrumb.Section>Manage</Breadcrumb.Section>
          <Breadcrumb.Divider />
          <Breadcrumb.Section active>
            Total Delivery By County and State
          </Breadcrumb.Section>
        </Breadcrumbs>
        <Divider />
      </Fragment>

      <Input
        icon="search"
        style={{ overflow: "auto", float: "right" }}
        placeholder="Search..."
        onChange={(e) => searchItems(e.target.value)}
      />
      <br />
      <br />
      {data.length > 0 && (
        <Fragment>
          <Table unstackable sortable selectable celled striped>
            <Table.Header>
              <Table.Row>
                <Table.HeaderCell
                  sorted={column === "states_name" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "states_name" })
                  }
                  textAlign="center"
                >
                  Name
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "total" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "total" })
                  }
                  textAlign="center"
                >
                  Total Tiles
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "flown" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "flown" })
                  }
                  textAlign="center"
                >
                  Flown
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "AT Done" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "AT Done" })
                  }
                  textAlign="center"
                >
                  AT Done
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "ortho_processed" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "ortho_processed" })
                  }
                  textAlign="center"
                >
                  Ortho Processed
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "shipped" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "shipped" })
                  }
                  textAlign="center"
                >
                  Shipped
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "usda_accepted" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "usda_accepted" })
                  }
                  textAlign="center"
                >
                  USDA Accepted
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "invoiced" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "invoiced" })
                  }
                  textAlign="center"
                >
                  Invoiced
                </Table.HeaderCell>
              </Table.Row>
            </Table.Header>
            <Table.Body>
              {data.map((state) => {
                return (
                  <Table.Row
                    style={{ cursor: "pointer" }}
                    key={state.id}
                    textAlign="center"
                    onClick={() => {
                      // onClick go to this server url
                      window.location.href = `/total_delivery_by_state_and_county/${state.abv}`;
                    }}
                  >
                    <Table.Cell>
                      <RenderValue value={state.name} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={state.total} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={state.flown} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={state.at_done} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={state.ortho_processed} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={state.shipped} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={state.usda_accepted} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={state.invoiced} />
                    </Table.Cell>
                  </Table.Row>
                );
              })}
            </Table.Body>
          </Table>
          <br />
        </Fragment>
      )}
    </div>
  );
};

export default TotalDeliveryCounty;
