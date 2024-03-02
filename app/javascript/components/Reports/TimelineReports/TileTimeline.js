import React, { useEffect } from "react";
import MessageBox from "../../Shared/MessageBox";
import { Table, Header } from "semantic-ui-react";
import RenderValue from "../../Shared/RenderValue";
import { tableSortReducer } from "../../Shared/TableSort";

const TileTimeline = ({ records, searchInput }) => {
  // Load the table reducer with the default records
  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: records,
    direction: null,
  });
  const { column, data, direction } = state;

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

  // if there is no records in the array after filtering then return message
  if (data.length === 0) {
    return (
      <MessageBox title={"Tiles"} message={"No records matched search text"} />
    );
  }

  // Return table with records
  return (
    <div className="table-overflow" style={{ marginBottom: "1em" }}>
      <Table unstackable sortable celled striped>
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell
              colSpan="100%"
              style={{
                backgroundColor: "#ededed",
                textAlign: "center",
                cursor: "default",
              }}
            >
              <Header>Tiles</Header>
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Header>
          <Table.Row textAlign="center">
            <Table.HeaderCell
              sorted={column === "county_name" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "county_name" })
              }
            >
              County Name
            </Table.HeaderCell>

            <Table.HeaderCell
              sorted={column === "filename" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "filename" })
              }
            >
              Filename
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
              sorted={column === "id" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "id" })}
            >
              ID
            </Table.HeaderCell>

            <Table.HeaderCell
              sorted={column === "poly_id" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "poly_id" })
              }
            >
              Poly ID
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
              sorted={column === "project_no" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "project_no" })
              }
            >
              Project No
            </Table.HeaderCell>

            <Table.HeaderCell
              sorted={column === "state_name" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "state_name" })
              }
            >
              State Name
            </Table.HeaderCell>

            <Table.HeaderCell
              sorted={column === "utm_zone" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "utm_zone" })
              }
            >
              UTM Zone
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {data.map((record) => {
            return (
              <Table.Row key={record} textAlign="center">
                <Table.Cell>
                  <RenderValue value={record.county_name} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.filename} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.flight_date} date />
                </Table.Cell>
                <Table.Cell>
                  {record.id !== null && (
                  <RenderValue value={record.id} />
                  )}
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.poly_id} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.project} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.project_no} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.state_name} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.utm_zone} />
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    </div>
  );
};

export default TileTimeline;
