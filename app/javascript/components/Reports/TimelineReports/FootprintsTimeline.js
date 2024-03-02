import React, { useEffect } from "react";
import MessageBox from "../../Shared/MessageBox";
import { Table, Header } from "semantic-ui-react";
import RenderValue from "../../Shared/RenderValue";
import { tableSortReducer } from "../../Shared/TableSort";

const FootprintsTimeline = ({ records, searchInput }) => {
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
      <MessageBox title={"Footprints"} message={"No records matched search text"} />
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
              <Header>Footprints</Header>
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Header>
          <Table.Row textAlign="center">
          <Table.HeaderCell
              sorted={column === "centroid_latitude" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "centroid_latitude" })
              }
            >
              Centroid Latitude
            </Table.HeaderCell>

            <Table.HeaderCell
              sorted={column === "centroid_longitude" ? direction : null}
              onClick={() =>
                dispatch({
                  type: "CHANGE_SORT",
                  column: "centroid_longitude",
                })
              }
            >
              Centroid Longitude
            </Table.HeaderCell>

            <Table.HeaderCell
              sorted={column === "county_name" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "county_name" })
              }
            >
              County Name
            </Table.HeaderCell>

            <Table.HeaderCell
              sorted={column === "id" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "id" })}
            >
              ID
            </Table.HeaderCell>

            <Table.HeaderCell
              sorted={column === "original_strip_frame" ? direction : null}
              onClick={() =>
                dispatch({
                  type: "CHANGE_SORT",
                  column: "original_strip_frame",
                })
              }
            >
              Original Strip Frame
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
              sorted={column === "state_name" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "state_name" })
              }
            >
              State Name
            </Table.HeaderCell>

            <Table.HeaderCell
              sorted={column === "strip_frame" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "strip_frame" })
              }
            >
              Strip Frame
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
              <Table.Row key={record.id} textAlign="center">
               <Table.Cell>
                    <RenderValue value={record.centroid_latitude} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.centroid_longitude} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.county_name} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.id} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.original_strip_frame} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.project} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.state_name} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.strip_frame} />
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

export default FootprintsTimeline;
