import React, { useEffect } from "react";
import MessageBox from "../../Shared/MessageBox";
import { Table, Header } from "semantic-ui-react";
import RenderValue from "../../Shared/RenderValue";
import { tableSortReducer } from "../../Shared/TableSort";

const PackingSlipsTimeline = ({ records, searchInput }) => {
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
      <MessageBox title={"Packing Slips"} message={"No records matched search text"} />
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
              <Header>Packing Slips</Header>
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Header>
          <Table.Row textAlign="center">
          <Table.HeaderCell
              sorted={column === "id" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "id" })}
            >
              ID
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
              sorted={column === "approved_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "approved_date" })
              }
            >
              Approved Date
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
              sorted={column === "company" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "company" })
              }
            >
              Company
            </Table.HeaderCell>

            <Table.HeaderCell
              sorted={column === "created_at" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "created_at" })
              }
            >
              Created At
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {data.map((record) => {
            return (
              <Table.Row key={record.id} textAlign="center">
            <Table.Cell>
                  <RenderValue value={record.id} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.project} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.approved_date} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.shipped_date} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.company} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={record.created_at} />
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    </div>
  );
};

export default PackingSlipsTimeline;
