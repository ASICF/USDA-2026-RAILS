import React, { Fragment, useState, useEffect } from "react";
import {
  Button,
  Header,
  Table,
  Divider,
  Breadcrumb,
  Input,
  Tab,
} from "semantic-ui-react";
import _ from "lodash";
import moment from "moment";
import { tableSortReducer } from "../Shared/TableSort";
import "semantic-ui-css/semantic.min.css";
import "../Styles/default";
import axios from "axios";
import Breadcrumbs from "../Shared/Breadcrumb";
// import RenderValue
//  from "../Shared/RenderValue";
import MessageBox from "../Shared/MessageBox";
import RenderValue from "../Shared/RenderValue";

const TotalDeliveryCountyShow = ({ selected_state, counties }) => {
  console.log("TotalDeliveryCountyShow", { selected_state, counties });

  const [searchInput, setSearchInput] = useState("");
  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: counties,
    direction: null,
  });
  console.log(counties);
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
      filteredData = counties;
    } else {
      filteredData = counties.filter((county) => {
        return Object.values(county)
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

  // Return table with records
  return (
    <div className="table-overflow" style={{ marginBottom: "1em" }}>
      <Fragment>
        <Breadcrumbs>
          <Breadcrumb.Section>Manage</Breadcrumb.Section>
          <Breadcrumb.Divider />
          <Breadcrumb.Section>
            {" "}
            <a href="./">Total Delivery by County and State</a>
          </Breadcrumb.Section>
          <Breadcrumb.Divider />
          <Breadcrumb.Section active>{selected_state.name}</Breadcrumb.Section>
        </Breadcrumbs>
        <Divider />
      </Fragment>

      {data.length === 0 && (
        <MessageBox message={"No Counties matched the searched text"} />
      )}

      {data.length > 0 && (
        <Fragment>
          <Input
            icon="search"
            style={{ overflow: "auto", float: "right" }}
            placeholder="Search..."
            onChange={(e) => searchItems(e.target.value)}
          />
          <br />
          <br />
          <Table unstackable sortable celled striped>
            <Table.Header>
              <Table.Row textAlign="center">
                <Table.HeaderCell
                  sorted={column === "county" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "county" })
                  }
                >
                  County
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "total" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "total" })
                  }
                >
                  Total Tiles
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "due_date" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "due_date" })
                  }
                >
                  Due Date
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "shipped_date" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "shipped_date" })
                  }
                >
                  Shipped Date
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "ready_to_ship" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "ready_to_ship" })
                  }
                >
                  Total Ready To Ship
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "shipped_total" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "shipped_total" })
                  }
                >
                  Shipped Total
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "usda_approved" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "usda_approved" })
                  }
                >
                  USDA Approved
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "invoiced_date" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "invoiced_date" })
                  }
                >
                  Invoiced Date
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "total_invoiced" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "total_invoiced" })
                  }
                >
                  Total Invoiced
                </Table.HeaderCell>
              </Table.Row>
            </Table.Header>

            <Table.Body>
              {data.map((county) => {
                return (
                  <Table.Row key={county.id} textAlign="center">
                    <Table.Cell>
                      <RenderValue value={county.name} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={county.total_easements} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={county.due_date} date />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={county.ship_date} date />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={county.total_ready_to_ship} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={county.ship_total} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={county.usda_approved} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={county.invoiced_date} date />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={county.invoiced} />
                    </Table.Cell>
                  </Table.Row>
                );
              })}
            </Table.Body>
          </Table>
          <br/>
        </Fragment>
      )}
    </div>
  );
};

export default TotalDeliveryCountyShow;
