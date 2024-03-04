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
const UnrejectTimeline = (props) => {
  const [records, setRecords] = useState(props.rejected_tiles);
  const [poly_id, setPolyId] = useState(records.poly_id);
  const [searchInput, setSearchInput] = useState("");
  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: records,
    direction: null,
  });
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
    // console.log({ records, searchInput });

    let filteredData = [];

    // if the searchinput is empty then store the original records
    // => If there is text then filter it by the searchinput
    if (searchInput.length === "") {
      filteredData = records;
    } else {
      filteredData = records.filter((record) => {
        return Object.values(record)
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
      return (
        <MessageBox
          title={"Rejected Tiles"}
          message={"No records matched search text"}
        />
      );
    }
  };
  // Return table with records
  return (
    <div className="table-overflow" style={{ marginBottom: "1em" }}>
      <Fragment>
        <Breadcrumbs>
          <Breadcrumb.Section>Manage</Breadcrumb.Section>
          <Breadcrumb.Divider />
          <Breadcrumb.Section active>Unreject Tile</Breadcrumb.Section>
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
      {data.length > 0 ? (
        <Table selectable unstackable sortable celled striped>
          <Table.Header></Table.Header>

          <Table.Header>
            <Table.Row>
              <Table.HeaderCell
                sorted={column === "poly_id" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "poly_id" })
                }
                textAlign="center"
              >
                Poly ID
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "poly_id" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "poly_id" })
                }
                textAlign="center"
              >
                Project
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "num_of_rejected_tiles" ? direction : null}
                onClick={() =>
                  dispatch({
                    type: "CHANGE_SORT",
                    column: "num_of_rejected_tiles",
                  })
                }
                textAlign="center"
              >
                Total Rejections
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>
          <Table.Body>
            {data.map((record) => {
              return (
                <Table.Row
                  style={{ cursor: "pointer" }}
                  key={record.poly_id}
                  onClick={() => {
                    window.location.href = `/unreject_tile/${record.poly_id}`;
                  }}
                  textAlign="center"
                >
                  <Table.Cell>
                    <RenderValue value={record.poly_id} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.project} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.num_of_rejected_tiles} />
                  </Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
        </Table>
      ) : (
        Empty()
      )}
    </div>
  );
};

export default UnrejectTimeline;
